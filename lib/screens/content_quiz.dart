import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:html_learning/screens/progressprovider.dart';
import 'package:provider/provider.dart';

import '../components/bottom_navigation.dart';

class QuizScreen extends StatefulWidget {
  final String courseTitle;
  final List<Map<String, dynamic>> quizData;

  const QuizScreen({
    super.key,
    required this.courseTitle,
    required this.quizData,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int _currentQuestionIndex = 0;
  List<String?> _answers = [];
  bool _quizSubmitted = false;
  bool _showResults = false;

  @override
  void initState() {
    super.initState();
    _answers = List.filled(widget.quizData.length, null);
  }

  void _nextQuestion() {
    if (_answers[_currentQuestionIndex] != null || _quizSubmitted) {
      if (_currentQuestionIndex < widget.quizData.length - 1) {
        setState(() {
          _currentQuestionIndex++;
        });
      } else if (!_quizSubmitted) {
        _showResult();
      }
    }
  }

  void _previousQuestion() {
    if (_currentQuestionIndex > 0) {
      setState(() {
        _currentQuestionIndex--;
      });
    }
  }

  void _showResult() async {
    setState(() {
      _quizSubmitted = true;
    });
    int score = 0;
    for (int i = 0; i < widget.quizData.length; i++) {
      if (_answers[i] == widget.quizData[i]['correctAnswer']) {
        score++;
      }
    }

    // Update progress immediately after quiz submission
    await Provider.of<ProgressProvider>(context, listen: false)
        .updateQuizResult(widget.courseTitle, score / widget.quizData.length);

    if (score >= 10) {
      _showSuccessDialog(score);
    } else {
      _showFailureDialog(score);
    }
  }

  void _showSuccessDialog(int score) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        String message = score == widget.quizData.length
            ? 'You aced it! Perfect score—way to go!'
            : 'Nice work! You passed the quiz—keep it up!';
        final user = FirebaseAuth.instance.currentUser;
        final userName = user?.displayName ?? 'User'; // Fetch the signed-in user's display name
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
          backgroundColor: Colors.teal[50],
          title: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle, color: Colors.green.shade600, size: 28),
              const SizedBox(width: 10),
              Text(
                'Quiz Completed!',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  color: Colors.green.shade600,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Your score: $score out of ${widget.quizData.length}',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 14,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 10),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 14,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _resetQuiz();
              },
              child: Text(
                'Restart Quiz',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  color: Color(0xff023047),
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => CustomBottomNavigation(userName: userName)),
                      (route) => false,
                );
              },
              child: Text(
                'Back to Homepage',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  color: Color(0xff023047),
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _currentQuestionIndex = 0;
                  _showResults = true;
                });
                Navigator.of(context).pop();
              },
              child: const Text(
                'Check Results',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showFailureDialog(int score) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        String message = score < 4
            ? 'Don’t worry! Every try counts—review and bounce back!'
            : 'Almost there! A little more practice and you’ll nail it!';
        final user = FirebaseAuth.instance.currentUser;
        final userName = user?.displayName ?? 'User'; // Fetch the signed-in user's display name
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
          backgroundColor: Colors.teal[50],
          title: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.cancel, color: Colors.red.shade600, size: 28),
              const SizedBox(width: 10),
              Text(
                'Quiz Failed!',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  color: Colors.red.shade600,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Your score: $score out of ${widget.quizData.length}',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 14,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 10),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 14,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _resetQuiz();
              },
              child: const Text(
                'Retake Quiz',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => CustomBottomNavigation(userName: userName)),
                      (route) => false,
                );
              },
              child: Text(
                'Back to Homepage',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  color: Color(0xff014062),
                ),
              ),
            ),
            TextButton(
              onPressed: null,
              child: const Text(
                'Check Results',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _resetQuiz() {
    setState(() {
      _currentQuestionIndex = 0;
      _answers = List.filled(widget.quizData.length, null);
      _quizSubmitted = false;
      _showResults = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.quizData.isEmpty) {
      return const Scaffold(body: Center(child: Text('No questions available.')));
    }

    final user = FirebaseAuth.instance.currentUser;
    final userName = user?.displayName ?? 'User'; // Fetch the signed-in user's display name

    final double screenWidth = MediaQuery.of(context).size.width;
    final double padding = screenWidth * 0.05;
    final double courseTitleFontSize = (screenWidth * 0.025).clamp(18, 22);
    final double questionNumberFontSize = (screenWidth * 0.02).clamp(14, 16);
    final double questionFontSize = (screenWidth * 0.022).clamp(16, 18);
    final double optionFontSize = (screenWidth * 0.02).clamp(14, 16);

    return Scaffold(
      backgroundColor: Color(0xff023047),
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(70),
        child: AppBar(
          iconTheme: const IconThemeData(color: Colors.white),
          title: const Text('Quiz', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Poppins')),
          backgroundColor: Color(0xff023047),
        ),
      ),
      body: Container(
        height: double.infinity,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: padding, vertical: padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                widget.courseTitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: courseTitleFontSize,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "Question ${_currentQuestionIndex + 1} of ${widget.quizData.length}",
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: questionNumberFontSize,
                  fontWeight: FontWeight.w600,
                  color: Color(0xffB3C7e8),
                ),
              ),
              const SizedBox(height: 20),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(widget.quizData.length, (index) {
                    bool isCorrect = _answers[index] == widget.quizData[index]['correctAnswer'];
                    bool isAnswered = _answers[index] != null && _showResults;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _currentQuestionIndex = index;
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 5),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: index == _currentQuestionIndex
                              ? Color(0xff023047)
                              : (isAnswered && _showResults
                              ? (isCorrect ? Colors.green : Colors.red)
                              : Color(0xffE6ECEF)),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.black12),
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: index == _currentQuestionIndex || (isAnswered && _showResults) ? Colors.white : Colors.black,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 30),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Color(0xffE6ECEF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  widget.quizData[_currentQuestionIndex]['question'],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: questionFontSize,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Column(
                children: List.generate(
                  widget.quizData[_currentQuestionIndex]['options'].length,
                      (index) {
                    String optionText = widget.quizData[_currentQuestionIndex]['options'][index];
                    bool isSelected = _answers[_currentQuestionIndex] == optionText;
                    bool isCorrect = optionText == widget.quizData[_currentQuestionIndex]['correctAnswer'];
                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 5),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _showResults && isCorrect
                              ? Colors.green
                              : (isSelected && _showResults && !isCorrect ? Colors.red : Colors.black12),
                          width: _showResults && (isCorrect || isSelected) ? 2 : 1,
                        ),
                      ),
                      child: RadioListTile<String>(
                        title: Text(
                          optionText,
                          style: TextStyle(fontFamily: 'Poppins', fontSize: optionFontSize),
                          softWrap: true,
                        ),
                        value: optionText,
                        groupValue: _answers[_currentQuestionIndex],
                        activeColor: Color(0xff014062),
                        onChanged: _quizSubmitted
                            ? null
                            : (value) {
                          setState(() {
                            _answers[_currentQuestionIndex] = value;
                          });
                        },
                        dense: true,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_currentQuestionIndex > 0)
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xff023047),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                        minimumSize: Size(screenWidth * 0.35, 0),
                      ),
                      onPressed: _previousQuestion,
                      child: const Text('Previous', style: TextStyle(fontFamily: 'Poppins', color: Colors.white)),
                    )
                  else
                    const SizedBox(width: 0),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _showResults
                          ? Color(0xff023047)
                          : (_answers[_currentQuestionIndex] == null && !_quizSubmitted
                          ? Color(0xffE6ECEF)
                          : Color(0xff023047)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                      minimumSize: Size(screenWidth * 0.35, 0),
                    ),
                    onPressed: _answers[_currentQuestionIndex] == null && !_quizSubmitted
                        ? null
                        : (_quizSubmitted && _currentQuestionIndex == widget.quizData.length - 1
                        ? () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => CustomBottomNavigation(userName: userName)),
                            (route) => false,
                      );
                    }
                        : (_currentQuestionIndex == widget.quizData.length - 1 && !_quizSubmitted
                        ? _showResult
                        : _nextQuestion)),
                    child: Text(
                      _quizSubmitted && _currentQuestionIndex == widget.quizData.length - 1
                          ? 'Done'
                          : (_currentQuestionIndex == widget.quizData.length - 1 && !_quizSubmitted
                          ? 'Submit'
                          : 'Next'),
                      style: const TextStyle(fontFamily: 'Poppins', color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}