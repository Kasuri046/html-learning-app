
import 'package:flutter/material.dart';
import 'package:html_learning/start_screens/splashscreen.dart';

import '../resources/navigation_helper.dart';
import '../resources/shared_preferences.dart';
import '../validations/letsgetstarted.dart';

class LogoScreen extends StatefulWidget {
  const LogoScreen({super.key});

  @override
  State<LogoScreen> createState() => _LogoScreenState();
}

class _LogoScreenState extends State<LogoScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
    _controller.forward();

    _checkInitialState();
  }

  void _checkInitialState() async {
    try {
      bool isIntroSeen = await SharedPrefHelper.isIntroSeen();
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;
      NavigationHelper.pushReplacementWithFade(
        context,
        isIntroSeen ? Start() : const SplashScreen(),
      );
    } catch (e) {
      print("⚠️ LogoScreen error: $e");
      if (!mounted) return;
      NavigationHelper.pushReplacementWithFade(
        context,
        const SplashScreen(),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xff023047),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Center(
          child: Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/logo.png'),
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ),
    );
  }
}