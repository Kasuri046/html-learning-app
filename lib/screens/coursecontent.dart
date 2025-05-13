import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:html_learning/screens/topicdetails.dart';
import 'package:provider/provider.dart'; // NEW: For ProgressProvider
import '../resources/model_class.dart';

import 'content_quiz.dart';
import 'progressprovider.dart'; // NEW: Import ProgressProvider

class CourseContentScreen extends StatefulWidget {
  final List<String> filenames;
  final String title;

  const CourseContentScreen({
    super.key,
    required this.filenames,
    required this.title,
  });

  @override
  State<CourseContentScreen> createState() => _CourseContentScreenState();
}

class _CourseContentScreenState extends State<CourseContentScreen> {
  List<Map<String, dynamic>> courseContent = [];
  final int _currentIndex = 0;
  List<String> fileL = [];

  ModelCpp? _courseData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCourseContent();
  }

  void _loadCourseContent() async {
    List<Map<String, dynamic>> allTopics = [];
    Map<String, dynamic>? currentQuizData;
    print('number of files 😊 ${widget.filenames}');

    for (String file in widget.filenames) {
      try {
        print("🔍 Loading file: $file");
        setState(() {
          fileL.add(file);
        });
        String jsonString = await rootBundle.loadString(file);

        if (jsonString.isEmpty) {
          print("⚠️ Empty JSON file: $file");
          continue;
        }

        print('file location is $fileL');

        Map<String, dynamic> jsonData = json.decode(jsonString);

        if (jsonData.isEmpty) {
          print("❌ JSON data empty for file: $file");
          continue;
        }

        if (file.contains("/quiz/")) {
          if (jsonData.containsKey("questions") && jsonData["questions"] is List) {
            currentQuizData = {
              "isQuizTile": true,
              "quizData": List<Map<String, dynamic>>.from(jsonData["questions"]),
            };
            print("✅ Quiz data added for $file");
          } else {
            print("⚠️ Quiz key missing or incorrect format in: $file");
          }
        } else {
          allTopics.add(jsonData);
        }
      } catch (e) {
        print("❌ Error loading file: $file - $e");
      }
    }

    if (currentQuizData != null) {
      allTopics.add(currentQuizData);
    }

    setState(() {
      courseContent = allTopics;
      _isLoading = false;
    });

    print("🏁 Course content loaded successfully!");
  }

  @override
  Widget build(BuildContext context) {
    double appBarHeight = MediaQuery.of(context).size.height * 0.20;
    double minHeight = 120.0;
    double maxHeight = 170.0;
    appBarHeight = appBarHeight.clamp(minHeight, maxHeight);

    double screenWidth = MediaQuery.of(context).size.width;
    double titleFontSize = (screenWidth * 0.05).clamp(18.0, 24.0);
    double subtitleFontSize = (screenWidth * 0.04).clamp(14.0, 18.0);

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
                        widget.title,
                        style: TextStyle(
                          fontSize: titleFontSize,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        "Let's Learn HTML!",
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
                      'assets/4.png',
                      fit: BoxFit.contain,
                      height: appBarHeight * 1.3,
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
            height: 40,
            color: Color(0xff023047),
          ),
          Container(
            margin: EdgeInsets.only(top: 10),
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 25),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 5,
                  spreadRadius: 1,
                )
              ],
            ),
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Consumer<ProgressProvider>( // NEW: Wrap ListView in Consumer
              builder: (context, progressProvider, child) {
                return ListView.builder(
                  itemCount: courseContent.length + 1,
                  itemBuilder: (context, index) {
                    if (index == courseContent.length) {
                      var lastQuizData = courseContent.lastWhere(
                            (topic) =>
                        topic.containsKey("isQuizTile") &&
                            topic["isQuizTile"] == true,
                        orElse: () => {"quizData": []},
                      );

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: ElevatedButton(
                          onPressed: () {
                            var quizData = lastQuizData["quizData"] ?? [];
                            if (quizData.isEmpty) {
                              print("🚨 No quiz data available!");
                              return;
                            }

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => QuizScreen(
                                  quizData: quizData,
                                  courseTitle: widget.title,
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor:Color(0xff023047),
                            padding: const EdgeInsets.symmetric(
                                vertical: 18, horizontal: 20),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            "Take Quiz",
                            style: TextStyle(
                                color: Colors.white,
                                fontFamily: 'Poppins',
                                fontSize: 18),
                          ),
                        ),
                      );
                    }

                    var topic = courseContent[index];
                    List<dynamic>? contentList = topic["content"];

                    if (contentList == null || contentList.isEmpty) {
                      return ListTile();
                    }

                    // NEW: Check if file is read
                    bool isRead = progressProvider.isFileRead(
                        widget.title, fileL[index]);

                    return Card(
                      color: isRead
                          ? Colors.blue[100]
                          : Colors.white.withOpacity(0.9), // NEW: Teal for read
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(
                          vertical: 5, horizontal: 4),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 6, horizontal: 10),
                        title: Text(
                          topic["title"] ?? "No Title",
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xff023047),
                            fontFamily: 'Poppins',
                          ),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios_rounded,
                            color: Color(0xff023047)),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TopicDetailScreen(
                                title: topic["title"] ?? widget.title,
                                content: contentList
                                    .map((section) => {
                                  "heading": section["heading"],
                                  "paragraphs":
                                  section["paragraphs"] ?? []
                                })
                                    .toList(),
                                fileL: fileL,
                                currentIndex: index,
                                filesLength: fileL.length,
                                topic: widget.title,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavIcon(IconData icon, int index) {
    bool isSelected = _currentIndex == index;
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      padding: EdgeInsets.all(isSelected ? 10 : 5),
      decoration: BoxDecoration(
        color: isSelected ? Colors.teal.withOpacity(0.2) : Colors.transparent,
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        size: isSelected ? 26 : 22,
        color: isSelected ? Colors.teal : Colors.grey.shade600,
      ),
    );
  }

  Widget _buildTopicCard(ContentSection topic, BuildContext context) {
    return Card(
      elevation: 5,
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.all(5),
        title: Text(
          topic.heading,
          style: const TextStyle(
            color: Color(0xff15BE9D),
            fontSize: 18,
            fontWeight: FontWeight.w500,
            fontFamily: 'Poppins',
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: Text(
              topic.paragraphs.join("\n\n"),
              style: const TextStyle(fontSize: 14, fontFamily: 'Poppins'),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 160, bottom: 10),
            child: TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: const Color(0xff15be9d),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Continue >>',
                  style: TextStyle(fontFamily: 'Poppins')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavIcon(IconData icon, int index) {
    Color? iconColor = Colors.black;

    return AnimatedScale(
      scale: 1.2,
      duration: const Duration(milliseconds: 150),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor),
          Text(
            index == 0
                ? 'Home'
                : index == 1
                ? 'Compiler'
                : index == 2
                ? 'Profile'
                : index == 3
                ? 'Courses'
                : 'Settings',
            style: TextStyle(color: iconColor, fontFamily: 'Poppins'),
          ),
        ],
      ),
    );
  }
}