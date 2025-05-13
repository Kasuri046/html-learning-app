import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:google_fonts/google_fonts.dart';

import '../components/bottom_navigation.dart';

class InterviewQuestionsScreen extends StatefulWidget {
  const InterviewQuestionsScreen({super.key});

  @override
  _InterviewQuestionsScreenState createState() => _InterviewQuestionsScreenState();
}

class _InterviewQuestionsScreenState extends State<InterviewQuestionsScreen> {
  List<dynamic> interviewQuestions = [];

  @override
  void initState() {
    super.initState();
    loadQuestions();
  }

  Future<void> loadQuestions() async {
    String jsonData = await rootBundle.loadString('assets/interview.json');
    setState(() {
      interviewQuestions = json.decode(jsonData)['interview_questions'];
    });
  }

  void _navigateToCustomBottomNavigation() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => CustomBottomNavigation(userName: ""),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Prevents default back navigation
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _navigateToCustomBottomNavigation(); // System back button redirects here
        }
      },
      child: Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(MediaQuery.of(context).size.height * 0.22),
        child: AppBar(
          backgroundColor: Color(0xff023047),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_)=> CustomBottomNavigation(userName: ''))), // Back navigation
          ),
          flexibleSpace: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  flex: 2, // Adjust flex to balance title and image
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 40,),

                      Text(
                        "Interview Questions",
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Prepare Yourself",
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 1, // Smaller flex for image to keep it proportional
                  child: Image.asset(
                    'assets/3.png',
                    fit: BoxFit.contain,
                    height: 150, // Reduced height for better alignment
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
            height: 45,
            color: Color(0xff023047), // Top curve background
          ),
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 0),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 05),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
              ),
            ),
            child: interviewQuestions.isEmpty
                ? const Center(child: CircularProgressIndicator(color: Color(0xff023047)))
                : ListView.builder(
              itemCount: interviewQuestions.length,
              itemBuilder: (context, index) {
                return Card(
                  color: Colors.white.withOpacity(0.9),
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ExpansionTile(
                    iconColor: Color(0xff023047),
                    shape: const RoundedRectangleBorder(),
                    title: Text(
                      interviewQuestions[index]['question'],
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Color(0xff023047),
                      ),

                    ),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(15.0),
                        color: Colors.grey[100],
                        child: Text(
                          interviewQuestions[index]['answer'],
                          style: GoogleFonts.poppins(
                            fontSize: 14.0,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      ),
    );
  }
}