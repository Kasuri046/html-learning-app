
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:html_learning/screens/progressprovider.dart';
import 'package:html_learning/start_screens/logoscreen.dart';
import 'package:html_learning/start_screens/splashscreen.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest.dart' as tz;

import 'components/bottom_navigation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  tz.initializeTimeZones();

  runApp(
    ChangeNotifierProvider(
      create: (context) => ProgressProvider(),
      child: const MyApp(),
    ),
  );
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Color(0xff023047)),
        useMaterial3: true,
      ),
      home: FutureBuilder<bool>(
        future: _checkLoginStatus(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SplashScreen();
          }
          if (snapshot.hasData && snapshot.data == true) {
            final user = FirebaseAuth.instance.currentUser;
            final userName = user?.displayName ?? 'User';
            print("Main: userName set to $userName");
            return CustomBottomNavigation(userName: userName);
          }
          return const LogoScreen();
        },
      ),
    );
  }

  Future<bool> _checkLoginStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    return user != null;
  }
}