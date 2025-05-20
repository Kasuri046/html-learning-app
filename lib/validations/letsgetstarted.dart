import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:html_learning/validations/signin.dart';
import 'package:html_learning/validations/signup.dart';

import '../components/bottom_navigation.dart';
import '../resources/shared_preferences.dart';

class Start extends StatefulWidget {
  const Start({super.key});

  @override
  _StartState createState() => _StartState();
}

class _StartState extends State<Start> {
  bool _isLoading = false; // Track loading state

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    bool isLoggedIn = await SharedPrefHelper.isLoggedIn();
    User? user = FirebaseAuth.instance.currentUser;

    if (isLoggedIn && user != null) {
      String displayName = await _getDisplayName(user);
      print("✅ Logged in, navigating with displayName='$displayName'");
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => CustomBottomNavigation(userName: displayName),
          ),
        );
      }
    } else if (isLoggedIn && user == null) {
      // Reset SharedPreferences if isLoggedIn is true but no user exists
      await SharedPrefHelper.clearAll();
      print("DEBUG: Cleared SharedPreferences due to no authenticated user");
    }
  }

  Future<String> _getDisplayName(User? user) async {
    if (user == null) {
      print("⚠️ No user signed in");
      return "Guest";
    }

    String email = user.email?.toLowerCase() ?? "";
    String displayName = user.displayName ?? (await SharedPrefHelper.getUserName()) ?? "Guest";

    // Check Firestore
    DocumentSnapshot doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    if (doc.exists) {
      var data = doc.data() as Map<String, dynamic>;
      displayName = data['displayName'] ?? data['name'] ?? displayName;
      print("🔍 Firestore displayName: '$displayName' for uid=${user.uid}, email='$email'");
    }

    // Sync Firebase Auth
    if (user.displayName != displayName) {
      await user.updateDisplayName(displayName);
      print("✅ Synced Firebase Auth displayName to: '$displayName'");
    }

    await SharedPrefHelper.setUserName(displayName);
    return displayName;
  }

  Future<void> _handleGoogleSignIn(BuildContext context) async {
    if (_isLoading) return; // Prevent multiple clicks

    setState(() {
      _isLoading = true; // Start loading
    });

    final GoogleSignIn googleSignIn = GoogleSignIn();
    final FirebaseAuth auth = FirebaseAuth.instance;

    try {
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Sign-in canceled.',
                    style: const TextStyle(
                      fontSize: 14,
                      fontFamily: 'Poppins',
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            duration: const Duration(seconds: 3),
          ),
        );
        setState(() {
          _isLoading = false; // Stop loading
        });
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential = await auth.signInWithCredential(credential);
      User? user = userCredential.user;

      if (user != null) {
        String displayName = user.displayName ?? 'Learner';
        String email = user.email?.toLowerCase() ?? '';

        // Check Firestore for existing displayName
        QuerySnapshot query = await FirebaseFirestore.instance
            .collection('users')
            .where('email', isEqualTo: email)
            .limit(1)
            .get();

        if (query.docs.isNotEmpty) {
          var existing = query.docs.first.data() as Map<String, dynamic>;
          displayName = existing['displayName'] ?? existing['name'] ?? displayName;
          print("🔍 Found existing user for '$email', using displayName: '$displayName'");
        }

        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'email': email,
          'displayName': displayName,
          'signInMethod': 'google',
          'lastLogin': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        print("✅ Saved Google user: uid=${user.uid}, displayName='$displayName'");

        // Sync Firebase Auth
        if (user.displayName != displayName) {
          await user.updateDisplayName(displayName);
          print("✅ Synced Firebase Auth displayName to: '$displayName'");
        }

        await SharedPrefHelper.setLoggedIn(true);
        await SharedPrefHelper.setUserName(displayName);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Welcome, $displayName!',
                    style: const TextStyle(
                      fontSize: 14,
                      fontFamily: 'Poppins',
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xff023047),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            duration: const Duration(seconds: 3),
          ),
        );

        if (context.mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => CustomBottomNavigation(userName: displayName),
            ),
          );
        }
      }
    } catch (e) {
      print("⚠️ Google Sign-In error: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Sign-in failed. Please check your network and try again.',
                    style: const TextStyle(
                      fontSize: 14,
                      fontFamily: 'Poppins',
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false; // Stop loading
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/get.png', fit: BoxFit.cover),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 95),
                  child: Text(
                    'Let\'s Get Started',
                    style: TextStyle(
                      fontSize: 20,
                      fontFamily: 'Poppins',
                      color: Color(0xff023047),
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 350),
                if (Platform.isAndroid)
                  _buildSocialButton(
                    context,
                    'Continue With Google',
                    'assets/img.png',
                    _isLoading,
                        () => _handleGoogleSignIn(context),
                  )
                else if (Platform.isIOS)
                  _buildSocialButton(
                    context,
                    'Continue With Apple',
                    'assets/apple.png',
                    false, // Apple sign-in not implemented
                        () {},
                  ),
                const SizedBox(height: 20),
                Row(
                  children: const <Widget>[
                    Expanded(child: Divider(thickness: 1, color: Colors.grey)),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Text("or", style: TextStyle(fontFamily: 'Poppins')),
                    ),
                    Expanded(child: Divider(thickness: 1, color: Colors.grey)),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildActionButton(context, 'Log In', const Color(0xff023047), const Signin()),
                    _buildActionButton(context, 'Sign Up', const Color(0xff023047), const Signup()),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialButton(BuildContext context, String title, String imagePath, bool isLoading, VoidCallback onTap) {
    return GestureDetector(
      onTap: isLoading ? null : onTap, // Disable tap when loading
      child: Container(
        width: double.infinity,
        height: 50,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xff023047)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!isLoading) ...[
              Image.asset(imagePath, height: 24),
              const SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  color: isLoading ? Colors.grey : Colors.black,
                  fontFamily: 'Poppins',
                  fontSize: 16,
                ),
              ),
            ] else ...[
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xff023047)),
                strokeWidth: 2,
              ),
              const SizedBox(width: 10),
              const Text(
                'Signing In...',
                style: TextStyle(
                  color: Colors.grey,
                  fontFamily: 'Poppins',
                  fontSize: 16,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, String title, Color color, Widget navigateTo) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => navigateTo));
      },
      child: Container(
        width: MediaQuery.of(context).size.width * 0.42,
        height: 50,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontFamily: 'Poppins',
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }
}