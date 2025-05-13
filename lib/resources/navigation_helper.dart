import 'package:flutter/material.dart';

class NavigationHelper {
  static void pushReplacementWithFade(
      BuildContext context,
      Widget destination, {
        Duration duration = const Duration(milliseconds: 300),
      }) {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, _) => destination,
        transitionsBuilder: (context, animation, _, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: duration,
      ),
    );
  }
}