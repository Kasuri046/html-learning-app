
import 'package:flutter/material.dart';

import '../resources/navigation_helper.dart';
import '../resources/shared_preferences.dart';
import '../validations/letsgetstarted.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> _pages = [
    {
      "image": "assets/4.png",
      "title": "Welcome to Our App",
      "description": "Discover a wide range of courses and resources to enhance your learning."
    },
    {
      "image": "assets/5.png",
      "title": "Interactive Learning",
      "description": "Engage with interactive content and quizzes to test your knowledge."
    },
    {
      "image": "assets/1.png",
      "title": "Track Your Progress",
      "description": "Monitor your learning journey and achieve your goals with ease."
    },
  ];

  void _onGetStarted() async {
    await SharedPrefHelper.setIntroSeen();
    NavigationHelper.pushReplacementWithFade(context, const Start());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/splash.png"),
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        _pages[index]["image"]!,
                        height: 150,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _pages[index]["title"]!,
                        style: const TextStyle(
                          fontSize: 24,
                          color: Colors.white,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 30),
                        child: Text(
                          _pages[index]["description"]!,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            color: Colors.white,
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 40),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _pages.length,
                      (index) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 5),
                    width: _currentPage == index ? 14 : 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: _currentPage == index ? Color(0xff023047) : Colors.grey,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 30),
              child: ElevatedButton(
                onPressed: () {
                  if (_currentPage < _pages.length - 1) {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeIn,
                    );
                  } else {
                    _onGetStarted();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xff023047),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  minimumSize: Size(MediaQuery.of(context).size.width * 0.9, 50), // Responsive width
                ),
                child: Text(
                  _currentPage == _pages.length - 1 ? 'Get Started' : 'Next',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}