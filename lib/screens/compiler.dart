import 'package:flutter/material.dart';

class CompilerScreen extends StatefulWidget {
  const CompilerScreen({super.key});

  @override
  State<CompilerScreen> createState() => _CompilerScreenState();
}

class _CompilerScreenState extends State<CompilerScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body:Center(
          child: Text("Working In Progress....",
          style:
            TextStyle(
              fontSize: 30,
              fontFamily: 'Poppins',
              color: Colors.teal
          ),
          )
      ),
    );
  }
}
