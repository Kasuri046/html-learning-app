import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/arduino-light.dart';
import 'package:html_learning/screens/progressprovider.dart';
import 'package:provider/provider.dart';
import 'content_quiz.dart';

class TopicDetailScreen extends StatefulWidget {
  final String title;
  final List<Map<String, dynamic>> content;
  final List<String> fileL;
  final int currentIndex;
  final int filesLength;
  final String topic;

  const TopicDetailScreen({
    super.key,
    required this.title,
    required this.content,
    required this.fileL,
    required this.currentIndex,
    required this.filesLength,
    required this.topic,
  });

  @override
  _TopicDetailScreenState createState() => _TopicDetailScreenState();
}

class _TopicDetailScreenState extends State<TopicDetailScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _filteredContent = [];
  List<Map<String, dynamic>> courseContent = [];
  int _currentIndex = 0;
  late ScrollController _scrollController;
  String currentTitle = '';
  bool _hasMarkedRead = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.currentIndex;
    _scrollController = ScrollController();
    currentTitle = widget.title;
    print("DEBUG: Initializing TopicDetailScreen, topic: ${widget.topic}, index: $_currentIndex");
    _loadCourseContent();
    _setupScrollListener();
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent * 0.9 &&
          !_hasMarkedRead) {
        _markFileRead();
      }
    });
    print("DEBUG: Scroll listener set up for 90% scroll detection");
  }

  void _markFileRead() {
    String currentFile = widget.fileL[_currentIndex];
    if (!currentFile.toLowerCase().contains("quiz")) {
      final progressProvider = Provider.of<ProgressProvider>(context, listen: false);
      progressProvider.markFileRead(currentFile, widget.topic);
      _hasMarkedRead = true;
      print("DEBUG: File marked read: $currentFile, topic: ${widget.topic}");
    } else {
      print("DEBUG: Skipping mark read for quiz file: $currentFile");
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    print("DEBUG: Disposing TopicDetailScreen, topic: ${widget.topic}");
    super.dispose();
  }

  void _navigateToTopic(int direction) {
    int newIndex = _currentIndex + direction;
    int totalFiles = widget.fileL.length;
    print("DEBUG: Navigating to topic, direction: $direction, newIndex: $newIndex, totalFiles: $totalFiles");

    if (newIndex >= 0 && newIndex < totalFiles) {
      if (!_hasMarkedRead && !widget.fileL[_currentIndex].toLowerCase().contains("quiz")) {
        _markFileRead();
      }
      setState(() {
        _currentIndex = newIndex;
        _hasMarkedRead = false;
      });
      print("DEBUG: Navigating to file index: $_currentIndex, file: ${widget.fileL[_currentIndex]}");
      _loadCourseContent();
      Future.delayed(Duration(milliseconds: 500), () {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(0);
          print("DEBUG: Scrolled to top for new file");
        }
      });
    } else if (newIndex == totalFiles && widget.fileL.last.toLowerCase().contains("quiz")) {
      var lastFile = widget.fileL.last;
      print("DEBUG: Attempting to load quiz: $lastFile");
      rootBundle.loadString(lastFile).then((jsonString) {
        if (jsonString.isNotEmpty) {
          print("DEBUG: Quiz JSON loaded, length: ${jsonString.length}");
          Map<String, dynamic> jsonData = jsonDecode(jsonString);
          List<Map<String, dynamic>> quizItems = [];
          if (jsonData["questions"] is List) {
            quizItems = List<Map<String, dynamic>>.from(jsonData["questions"]);
            print("DEBUG: Quiz contains ${quizItems.length} questions");
          }
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => QuizScreen(
                quizData: quizItems,
                courseTitle: widget.topic,
              ),
            ),
          ).then((result) {
            if (result == null) {
              print("DEBUG: Quiz cancelled for ${widget.topic}");
              return;
            }
            double score = (result is double)
                ? result
                : (result is int)
                ? result / 100.0
                : 0.0;
            print("DEBUG: Quiz result for ${widget.topic}: score=$score, passed=${score >= 0.7}");
            Provider.of<ProgressProvider>(context, listen: false).updateQuizResult(widget.topic, score);
          });
        } else {
          print("DEBUG: Quiz JSON empty for $lastFile");
        }
      }).catchError((e) {
        print("DEBUG: Error loading quiz JSON: $e");
      });
    }
  }

  void _loadCourseContent() async {
    if (_currentIndex < 0 || _currentIndex >= widget.fileL.length) {
      print("DEBUG: 🚫 Index out of range: $_currentIndex");
      return;
    }
    List<Map<String, dynamic>> allTopics = [];
    try {
      String currentFile = widget.fileL[_currentIndex];
      print("DEBUG: 🔍 Loading file: $currentFile");
      String jsonString = await rootBundle.loadString(currentFile);
      if (jsonString.isEmpty) {
        print("DEBUG: ⚠️ Empty JSON file: $currentFile");
        return;
      }
      Map<String, dynamic> jsonData = jsonDecode(jsonString);
      if (jsonData.isEmpty) {
        print("DEBUG: ❌ JSON data empty for file: $currentFile");
        return;
      }
      if (!currentFile.toLowerCase().contains("quiz")) {
        allTopics.add(jsonData);
      }
      setState(() {
        courseContent = allTopics;
        _filteredContent = courseContent;
        currentTitle = jsonData['title'] ?? widget.title;
        _hasMarkedRead = false;
        print("DEBUG: Updated currentTitle to: $currentTitle, content loaded");
      });
    } catch (e) {
      print("DEBUG: ❌ Error loading file: ${widget.fileL[_currentIndex]} - $e");
      setState(() {
        currentTitle = widget.title;
        _hasMarkedRead = false;
      });
    }
    print("DEBUG: 🏁 Course content loaded successfully for topic index $_currentIndex!");
  }

  void _filterContent(String query) {
    print("DEBUG: 🔍 Filter called with query: '$query'");
    setState(() {
      _filteredContent = courseContent.map((section) {
        Map<String, dynamic> updatedSection = Map<String, dynamic>.from(section);
        var contentList = updatedSection["content"] as List<dynamic>?;
        if (contentList != null) {
          print("DEBUG: 📋 Content list found with ${contentList.length} items");
          updatedSection["content"] = contentList.map((contentItem) {
            Map<String, dynamic> updatedContent = Map<String, dynamic>.from(contentItem);
            List<dynamic> paragraphs = List<dynamic>.from(updatedContent["paragraphs"] ?? []);
            if (query.isNotEmpty) {
              updatedContent["paragraphs"] = paragraphs.where((p) {
                if (p is String) {
                  bool matches = p.toLowerCase().contains(query.toLowerCase());
                  if (matches) print("DEBUG: 🎯 Paragraph match: $p");
                  return matches;
                } else if (p is Map && p.containsKey("table")) {
                  var table = p["table"] as Map<String, dynamic>;
                  var rows = table["rows"] as List<dynamic>? ?? [];
                  bool matches = rows.any((row) => (row as List<dynamic>).any((cell) =>
                  cell is String && cell.toLowerCase().contains(query.toLowerCase())));
                  if (matches) print("DEBUG: 🎯 Table row match for query: $query");
                  return matches;
                }
                return false;
              }).toList();
            } else {
              print("DEBUG: 🌀 Query empty, resetting paragraphs");
            }
            return updatedContent;
          }).where((content) {
            return (content["paragraphs"] as List).isNotEmpty;
          }).toList();
        } else {
          print("DEBUG: ⚠️ No 'content' key in section: $updatedSection");
        }
        return updatedSection;
      }).where((section) {
        return (section["content"] as List?)?.isNotEmpty ?? false;
      }).toList();
      print("DEBUG: ✅ Filtered content length: ${_filteredContent.length}");
    });
  }

  Widget _highlightText(String text, String query) {
    if (query.isEmpty || !text.toLowerCase().contains(query.toLowerCase())) {
      print("DEBUG: No highlighting needed for text: $text, query: $query");
      return Text(
        text,
        style: TextStyle(
          fontSize: 14,
          height: 1.6,
          color: Colors.grey.shade900,
          fontFamily: "Poppins",
        ),
      );
    }
    final RegExp regExp = RegExp(RegExp.escape(query), caseSensitive: false);
    final parts = text.split(regExp);
    final matches = regExp.allMatches(text).toList();
    List<Widget> children = [];
    int lastEnd = 0;
    for (int i = 0; i < matches.length; i++) {
      final match = matches[i];
      if (match.start > lastEnd) {
        children.add(Text(
          text.substring(lastEnd, match.start),
          style: TextStyle(
            fontSize: 14,
            height: 1.6,
            color: Colors.grey.shade900,
            fontFamily: "Poppins",
          ),
        ));
      }
      String matchedText = text.substring(match.start, match.end);
      children.add(Container(
        color: Colors.blue.shade100,
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Text(
          matchedText,
          style: TextStyle(
            fontSize: 14,
            height: 1.6,
            color: Colors.blue.shade800,
            fontFamily: "Poppins",
          ),
        ),
      ));
      lastEnd = match.end;
    }
    if (lastEnd < text.length) {
      children.add(Text(
        text.substring(lastEnd),
        style: TextStyle(
          fontSize: 14,
          height: 1.6,
          color: Colors.grey.shade900,
          fontFamily: "Poppins",
        ),
      ));
    }
    print("DEBUG: ✨ Highlighted text: '$text' with matches: ${matches.length}");
    return Wrap(children: children);
  }

  Widget _buildTable(Map<String, dynamic> tableData) {
    var headers = (tableData["headers"] as List<dynamic>?)?.cast<String>() ?? [];
    var rows = (tableData["rows"] as List<dynamic>?)?.cast<List<dynamic>>() ?? [];
    if (headers.isEmpty || rows.isEmpty) {
      print("DEBUG: ⚠️ Empty table, headers: ${headers.length}, rows: ${rows.length}");
      return const SizedBox.shrink();
    }
    print("DEBUG: 📊 Building table with ${headers.length} headers and ${rows.length} rows");
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.blue.shade900, width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Table(
        border: TableBorder.all(
          color: Colors.blue.shade500,
          width: 1,
        ),
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        children: [
          // Header row
          TableRow(
            decoration: BoxDecoration(
              color: Colors.blue.shade200,
            ),
            children: headers.map((header) => Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                header,
                style: const TextStyle(
                  fontSize: 14,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  color: Color(0xff023047),
                ),
                textAlign: TextAlign.center,
              ),
            )).toList(),
          ),
          // Data rows
          ...rows.asMap().entries.map((entry) {
            int index = entry.key;
            List<dynamic> row = entry.value;
            return TableRow(
              decoration: BoxDecoration(
                color: index % 2 == 0 ? Colors.white : Colors.blue.shade50,
              ),
              children: row.map((cell) => Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  cell.toString(),
                  style: TextStyle(
                    fontSize: 14,
                    fontFamily: 'Poppins',
                    color: Color(0xff023047),
                  ),
                  textAlign: TextAlign.left,
                ),
              )).toList(),
            );
          }),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double appBarHeight = MediaQuery.of(context).size.height * 0.20;
    double minHeight = 140.0;
    double maxHeight = 170.0;
    appBarHeight = appBarHeight.clamp(minHeight, maxHeight);
    double screenWidth = MediaQuery.of(context).size.width;
    double titleFontSize = (screenWidth * 0.05).clamp(18.0, 24.0);
    double subtitleFontSize = (screenWidth * 0.04).clamp(14.0, 18.0);
    print("DEBUG: Building TopicDetailScreen, title: $currentTitle, index: $_currentIndex");
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(appBarHeight),
        child: AppBar(
          backgroundColor: Color(0xff023047),
          elevation: 0,
          automaticallyImplyLeading: false,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back,
              color: Colors.white,
              size: 30,
            ),
            onPressed: () {
              print("DEBUG: Back button pressed, navigating back");
              Navigator.pop(context);
            },
          ),
          flexibleSpace: Padding(
            padding: const EdgeInsets.fromLTRB(15, 60, 15, 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        currentTitle,
                        style: TextStyle(
                          fontSize: titleFontSize,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Dive Deeper into Topic",
                        style: TextStyle(
                          fontSize: subtitleFontSize,
                          fontFamily: 'Poppins',
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Align(
                    alignment: Alignment.center,
                    child: Image.asset(
                      'assets/3.png',
                      fit: BoxFit.contain,
                      height: appBarHeight * 1.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          Container(
            height: 90,
            color: Color(0xff023047),
          ),
          Container(
            margin: const EdgeInsets.only(top: 10),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 25),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 0,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: SingleChildScrollView(
              controller: _scrollController,
              child: Column(
                children: [
                  _currentIndex == widget.fileL.length - 1
                      ? const SizedBox.shrink()
                      : Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: TextField(
                      controller: _searchController,
                      textInputAction: TextInputAction.search,
                      onSubmitted: (value) {
                        print("DEBUG: Search query submitted: '$value'");
                        _filterContent(value);
                      },
                      decoration: InputDecoration(
                        hintText: 'Search...',
                        hintStyle: TextStyle(fontFamily: 'Poppins'),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.search, color: Color(0xff023047)),
                          onPressed: () {
                            print("DEBUG: Search button clicked, query: ${_searchController.text}");
                            _filterContent(_searchController.text);
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xff023047)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xff023047)),
                        ),
                      ),
                    ),
                  ),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _filteredContent.length,
                    itemBuilder: (context, index) {
                      var section = _filteredContent[index];
                      var contentList = section["content"];
                      if (contentList == null || contentList.isEmpty) {
                        print("DEBUG: Empty content list for section at index $index");
                        return const SizedBox.shrink();
                      }
                      print("DEBUG: Building content list with ${contentList.length} items");
                      return Column(
                        children: contentList.map<Widget>((content) {
                          String heading = content["heading"] ?? "No Heading";
                          List<dynamic> paragraphs = content["paragraphs"] ?? [];
                          print("DEBUG: Rendering card with heading: $heading");
                          return Card(
                            color: Colors.white.withOpacity(0.9),
                            margin: const EdgeInsets.only(bottom: 10),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            child: Padding(
                              padding: const EdgeInsets.all(15),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    heading,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontFamily: 'Poppins',
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xff023047),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  ...paragraphs.map((p) {
                                    bool isCodeExample = heading
                                        .toLowerCase()
                                        .contains("example") ||
                                        heading.toLowerCase().contains("syntax");
                                    print("DEBUG: Rendering paragraph, isCodeExample: $isCodeExample, type: ${p.runtimeType}");
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 10, top: 12),
                                      child: Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: isCodeExample
                                              ? Colors.white
                                              : Colors.transparent,
                                          borderRadius: BorderRadius.circular(8),
                                          border: isCodeExample
                                              ? Border.all(
                                              color: Colors.blue.shade900,
                                              width: 1)
                                              : null,
                                        ),
                                        child: p is String
                                            ? isCodeExample
                                            ? HighlightView(
                                          p,
                                          language: 'htmlbars',
                                          theme: arduinoLightTheme,
                                          padding: const EdgeInsets.all(10),
                                          textStyle: const TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 14,
                                            height: 1.6,
                                            color:Color(0xff023047),
                                          ),
                                        )
                                            : _highlightText(p, _searchController.text)
                                            : p is Map && p.containsKey("table")
                                            ? _buildTable(p["table"])
                                            : const SizedBox.shrink(),
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton(
                        onPressed: _currentIndex > 0
                            ? () {
                          print("DEBUG: Previous button pressed, navigating to index ${_currentIndex - 1}");
                          _navigateToTopic(-1);
                        }
                            : null,
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor:Color(0xff023047),
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text(
                          "Previous",
                          style: TextStyle(fontFamily: 'Poppins'),
                        ),
                      ),
                      _currentIndex == widget.fileL.length - 1
                          ? ElevatedButton(
                        onPressed: () {
                          print("DEBUG: Take Quiz button pressed, navigating to quiz");
                          _navigateToTopic(1);
                        },
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Color(0xff023047),
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text(
                          "Take Quiz",
                          style: TextStyle(fontFamily: 'Poppins'),
                        ),
                      )
                          : ElevatedButton(
                        onPressed: () {
                          print("DEBUG: Next button pressed, navigating to index ${_currentIndex + 1}");
                          _navigateToTopic(1);
                        },
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor:Color(0xff023047),
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text(
                          "Next",
                          style: TextStyle(fontFamily: 'Poppins'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

        ],
      ),
    );
  }
}