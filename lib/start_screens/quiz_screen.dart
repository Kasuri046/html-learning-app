
import 'package:flutter/material.dart';

import '../resources/navigation_helper.dart';
import '../resources/shared_preferences.dart';
import '../validations/letsgetstarted.dart';

class StartQuizScreen extends StatefulWidget {
  const StartQuizScreen({super.key});

  @override
  _QuizScreenState createState() => _QuizScreenState();
}

class _QuizScreenState extends State<StartQuizScreen> {
  int _currentQuestionIndex = 0;
  List<int?> _selectedAnswers = [null, null, null];

  final List<Map<String, dynamic>> _questions = [
    {
      'question': 'How familiar are you with C++?',
      'options': ['I’ve never used it before', 'I know a little bit', 'I’ve used it a lot'],
      'icons': [Icons.sentiment_dissatisfied, Icons.sentiment_neutral, Icons.sentiment_satisfied],
    },
    {
      'question': 'Have you ever built something using C++?',
      'options': ['No, I’m just getting started', 'Yes, small programs', 'Yes, I’ve built full projects'],
      'icons': [Icons.code_off, Icons.build_outlined, Icons.auto_awesome],
    },
    {
      'question': 'How would you like to learn?',
      'options': ['Step by step from basics', 'Concise lessons', 'Short challenges'],
      'icons': [Icons.school_outlined, Icons.format_list_bulleted, Icons.extension_outlined],
    },
  ];

  @override
  void initState() {
    super.initState();
    _checkQuizStatus();
  }

  Future<void> _checkQuizStatus() async {
    bool isQuizCompleted = await SharedPrefHelper.isQuizCompleted();
    if (isQuizCompleted) {
      _finishQuiz();
    }
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
      });
    } else {
      _finishQuiz();
    }
  }

  Future<void> _finishQuiz() async {
    await SharedPrefHelper.setQuizCompleted();
    NavigationHelper.pushReplacementWithFade(context, const Start());
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/pagee.png',
              fit: BoxFit.cover,
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.08, vertical: screenHeight * 0.3),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                LinearProgressIndicator(
                  value: (_currentQuestionIndex + 1) / _questions.length,
                  backgroundColor: Colors.grey[300],
                  valueColor: const AlwaysStoppedAnimation(Colors.teal),
                ),
                SizedBox(height: screenHeight * 0.03),
                Text(
                  _questions[_currentQuestionIndex]['question'],
                  style: TextStyle(
                    fontSize: screenWidth * 0.05,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: screenHeight * 0.02),
                ...List.generate(_questions[_currentQuestionIndex]['options'].length, (index) {
                  bool isSelected = _selectedAnswers[_currentQuestionIndex] == index;
                  return Padding(
                    padding: EdgeInsets.symmetric(vertical: screenHeight * 0.008),
                    child: SizedBox(
                      width: double.infinity,
                      height: screenHeight * 0.07,
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _selectedAnswers[_currentQuestionIndex] = index;
                          });
                          Future.delayed(const Duration(milliseconds: 300), _nextQuestion);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isSelected ? Colors.teal : Colors.white,
                          foregroundColor: isSelected ? Colors.white : Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 2,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Icon(
                              _questions[_currentQuestionIndex]['icons'][index],
                              color: isSelected ? Colors.white : Colors.teal,
                              size: screenWidth * 0.06,
                            ),
                            SizedBox(width: screenWidth * 0.04),
                            Expanded(
                              child: Text(
                                _questions[_currentQuestionIndex]['options'][index],
                                style: TextStyle(
                                  fontSize: screenWidth * 0.04,
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.w500,
                                  color: isSelected ? Colors.white : Colors.black,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
                const Spacer(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}