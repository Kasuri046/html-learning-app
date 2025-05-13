import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';

class ProgressProvider with ChangeNotifier {
  double _globalProgress = 0.0;
  double _globalTotal = 185.0; // Total subtopic files (excluding quizzes)
  String? _currentUid;
  final Map<String, Set<String>> _readFiles = {};
  final Map<String, bool> _quizPassed = {};
  final Map<String, double> _topicProgress = {};
  final Map<String, bool> _isCompleted = {};

  double get globalProgress => _globalProgress;
  double get globalTotal => _globalTotal;
  Map<String, double> get topicProgress => _topicProgress;
  Map<String, bool> get isCompleted => _isCompleted;

  ProgressProvider() {
    _listenToAuthChanges();
    print("DEBUG: ProgressProvider initialized");
  }

  void _listenToAuthChanges() {
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null) {
        _currentUid = user.uid;
        _loadProgress(user.uid);
        print("DEBUG: User logged in, UID: $_currentUid");
      } else {
        _currentUid = null;
        _resetProgress();
        print("DEBUG: No user logged in, progress reset");
      }
    });
  }

  Future<void> markFileRead(String filePath, String topic) async {
    if (_currentUid == null) {
      print("DEBUG: No user logged in, skipping markFileRead");
      return;
    }
    _readFiles[topic] ??= {};
    if (_readFiles[topic]!.contains(filePath)) {
      print("DEBUG: File already read: $filePath");
      return;
    }
    _readFiles[topic]!.add(filePath);
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUid)
          .collection('progress')
          .doc(topic)
          .set({
        'readFiles': _readFiles[topic]!.toList(),
        'progress': _topicProgress[topic] ?? 0.0,
        'isCompleted': _isCompleted[topic] ?? false,
      }, SetOptions(merge: true));
      _updateTopicProgress(topic);
      await _recalculateProgress();
      print("DEBUG: Marked file read: $filePath, topic: $topic, progress: ${_topicProgress[topic]! * 100}%");
      notifyListeners();
    } catch (e) {
      print("DEBUG: Error saving file to Firestore: $e");
    }
  }

  Future<void> updateQuizResult(String topic, double score) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final topicDoc = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('quizzes')
        .doc(topic);

    final snapshot = await topicDoc.get();
    bool existingQuizPassed = snapshot.exists && (snapshot.data()?['quizPassed'] ?? false);
    bool newQuizPassed = score >= 0.7;

    if (!existingQuizPassed || newQuizPassed) {
      _quizPassed[topic] = newQuizPassed;
      await topicDoc.set({
        'score': score,
        'quizPassed': newQuizPassed,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      _updateTopicProgress(topic);
      // Skip global progress update, as quizzes don't count
      print('DEBUG: Quiz result for $topic: score=$score, passed=$newQuizPassed, topic progress: ${_topicProgress[topic]! * 100}%');
      notifyListeners();
    } else {
      print('DEBUG: Skipped quiz update for $topic: already passed, score=$score');
    }
  }

  bool isFileRead(String topic, String file) {
    return _readFiles[topic]?.contains(file) ?? false;
  }

  void _updateTopicProgress(String topic) {
    _readFiles[topic] ??= {};
    // Define subtopic file counts (excluding quiz) and total files (including quiz)
    final Map<String, Map<String, int>> topicFileCounts = {
      'HTML Fundamentals': {'subtopics': 8, 'total': 9},
      'Text Formatting': {'subtopics': 8, 'total': 9},
      'Advanced Text Elements': {'subtopics': 8, 'total': 9},
      'Document Structure': {'subtopics': 8, 'total': 9},
      'Content Sections': {'subtopics': 8, 'total': 9},
      'Navigation & Layout': {'subtopics': 7, 'total': 8},
      'Divs & Spans': {'subtopics': 6, 'total': 7},
      'Styling & CSS': {'subtopics': 6, 'total': 7},
      'Colors & Formatting': {'subtopics': 5, 'total': 6},
      'Images & Media': {'subtopics': 8, 'total': 9},
      'Audio & Video': {'subtopics': 7, 'total': 8},
      'Embedded Content': {'subtopics': 7, 'total': 8},
      'Links & Navigation': {'subtopics': 7, 'total': 8},
      'Lists': {'subtopics': 6, 'total': 7},
      'Description Lists': {'subtopics': 4, 'total': 5},
      'Tables': {'subtopics': 8, 'total': 9},
      'Advanced Table Elements': {'subtopics': 8, 'total': 9},
      'Forms & Inputs': {'subtopics': 8, 'total': 9},
      'Form Elements': {'subtopics': 8, 'total': 9},
      'Graphics & Canvas': {'subtopics': 7, 'total': 8},
      'Semantic HTML': {'subtopics': 8, 'total': 9},
      'HTML5 APIs': {'subtopics': 6, 'total': 7},
      'Accessibility': {'subtopics': 5, 'total': 6},
      'Character Sets & Symbols': {'subtopics': 4, 'total': 5},
      'Technical References': {'subtopics': 7, 'total': 8},
      'Web Standards & XHTML': {'subtopics': 4, 'total': 5},
      'Legacy & Deprecated Tags': {'subtopics': 7, 'total': 8},
      'Miscellaneous': {'subtopics': 8, 'total': 9},
    };

    int totalSubtopics = topicFileCounts[topic]?['subtopics'] ?? 4;
    int totalFiles = topicFileCounts[topic]?['total'] ?? 5; // subtopics + quiz
    // Count only subtopic files (exclude quiz)
    int readSubtopics = _readFiles[topic]!
        .where((file) => !file.contains('quiz_'))
        .length;
    bool quizPassed = _quizPassed[topic] ?? false;
    // Progress includes subtopics + quiz if passed
    double completedFiles = readSubtopics + (quizPassed ? 1 : 0);
    double topicProgress = completedFiles / totalFiles;
    _topicProgress[topic] = topicProgress.clamp(0.0, 1.0);

    // Completion requires all subtopics read and quiz passed
    _isCompleted[topic] = readSubtopics == totalSubtopics && quizPassed;

    if (_currentUid != null) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUid)
          .collection('progress')
          .doc(topic)
          .set({
        'progress': _topicProgress[topic],
        'isCompleted': _isCompleted[topic],
      }, SetOptions(merge: true));
    }

    print("DEBUG: Updated topic progress: $topic, ${_topicProgress[topic]! * 100}% (readSubtopics: $readSubtopics/$totalSubtopics, quizPassed: $quizPassed, completedFiles: $completedFiles/$totalFiles)");
  }

  Future<void> _recalculateProgress() async {
    double totalSubtopicsRead = 0.0;
    for (var topic in _readFiles.keys) {
      totalSubtopicsRead += _readFiles[topic]!
          .where((file) => !file.contains('quiz_'))
          .length;
    }
    _globalProgress = (totalSubtopicsRead / _globalTotal) * 100;

    if (_currentUid != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUid)
          .set({'progress': _globalProgress / 100}, SetOptions(merge: true));
    }

    print("DEBUG: Recalculated global progress: ${_globalProgress.toStringAsFixed(1)}% (totalSubtopicsRead: $totalSubtopicsRead/$_globalTotal)");
    notifyListeners();
  }

  Future<void> _loadProgress(String uid) async {
    try {
      QuerySnapshot progressDocs = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('progress')
          .get();
      _readFiles.clear();
      _topicProgress.clear();
      _isCompleted.clear();
      for (var doc in progressDocs.docs) {
        String topic = doc.id;
        var data = doc.data() as Map<String, dynamic>;
        _readFiles[topic] = List<String>.from(data['readFiles'] ?? []).toSet();
        _topicProgress[topic] = (data['progress'] ?? 0.0).toDouble();
        _isCompleted[topic] = data['isCompleted'] ?? false;
      }
      QuerySnapshot quizDocs = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('quizzes')
          .get();
      _quizPassed.clear();
      for (var doc in quizDocs.docs) {
        _quizPassed[doc.id] = doc['quizPassed'] ?? false;
      }
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      _globalProgress = (userDoc.data()?['progress'] ?? 0.0).toDouble() * 100;

      for (var topic in _readFiles.keys) {
        _updateTopicProgress(topic);
      }
      await _recalculateProgress();
      print("DEBUG: Loaded progress for $uid: ${_globalProgress.toStringAsFixed(1)}%, files: ${_readFiles.length}, quizzes: ${_quizPassed.length}");
      notifyListeners();
    } catch (e) {
      print("DEBUG: Error loading Firestore: $e");
      _globalProgress = 0.0;
      _topicProgress.clear();
      _readFiles.clear();
      _quizPassed.clear();
      _isCompleted.clear();
      notifyListeners();
    }
  }

  Future<void> resetProgress() async {
    if (_currentUid != null) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(_currentUid)
            .collection('progress')
            .get()
            .then((snapshot) {
          for (var doc in snapshot.docs) {
            doc.reference.delete();
          }
        });
        await FirebaseFirestore.instance
            .collection('users')
            .doc(_currentUid)
            .collection('quizzes')
            .get()
            .then((snapshot) {
          for (var doc in snapshot.docs) {
            doc.reference.delete();
          }
        });
        await FirebaseFirestore.instance
            .collection('users')
            .doc(_currentUid)
            .set({'progress': 0.0}, SetOptions(merge: true));
      } catch (e) {
        print("DEBUG: Error clearing Firestore: $e");
      }
      _globalProgress = 0.0;
      _readFiles.clear();
      _quizPassed.clear();
      _topicProgress.clear();
      _isCompleted.clear();
      print("DEBUG: Reset progress for $_currentUid: ${_globalProgress.toStringAsFixed(1)}%");
      notifyListeners();
    } else {
      _resetProgress();
    }
  }

  void _resetProgress() {
    _globalProgress = 0.0;
    _globalTotal = 185.0;
    _readFiles.clear();
    _quizPassed.clear();
    _topicProgress.clear();
    _isCompleted.clear();
    print("DEBUG: Reset progress (no user): ${_globalProgress.toStringAsFixed(1)}%");
    notifyListeners();
  }
}