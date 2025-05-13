import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_api_availability/google_api_availability.dart';
import '../components/bottom_navigation.dart';
import '../resources/shared_preferences.dart';
import 'signin.dart';
import 'signup.dart';

class Start extends StatefulWidget {
  const Start({super.key});

  @override
  _StartState createState() => _StartState();
}

class _StartState extends State<Start> {
  bool _isSigningIn = false; // Track sign-in state to show progress indicator

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

    if (isLoggedIn) {
      User? user = FirebaseAuth.instance.currentUser;
      String displayName = await _getDisplayName(user);
      if (mounted) {
        print("✅ Logged in, navigating with displayName='$displayName'");
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => CustomBottomNavigation(userName: displayName),
          ),
        );
      }
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
    if (_isSigningIn) return; // Prevent multiple sign-in attempts

    setState(() => _isSigningIn = true);

    try {
      // Check Google Play Services availability
      GooglePlayServicesAvailability availability = await GoogleApiAvailability.instance.checkGooglePlayServicesAvailability();
      if (availability != GooglePlayServicesAvailability.success) {
        // Handle user-resolvable issues (e.g., update required, service disabled)
        if (availability == GooglePlayServicesAvailability.serviceVersionUpdateRequired ||
            availability == GooglePlayServicesAvailability.serviceDisabled) {
          await GoogleApiAvailability.instance.makeGooglePlayServicesAvailable();
        }
        _showSnackBar(context, 'Please update Google Play Services.', isError: true);
        setState(() => _isSigningIn = false);
        return;
      }

      final GoogleSignIn googleSignIn = GoogleSignIn();
      final FirebaseAuth auth = FirebaseAuth.instance;

      // Check if already signed in
      GoogleSignInAccount? currentUser = await googleSignIn.signInSilently();
      if (currentUser != null) {
        print("🔍 User already signed in silently: ${currentUser.email}");
      } else {
        currentUser = await googleSignIn.signIn();
      }

      if (currentUser == null) {
        _showSnackBar(context, 'Sign-in canceled.', isError: true);
        setState(() => _isSigningIn = false);
        return;
      }

      final GoogleSignInAuthentication googleAuth = await currentUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential = await auth.signInWithCredential(credential);
      User? user = userCredential.user;

      if (user != null) {
        String displayName = user.displayName ?? 'No Name';
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

        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);
        await SharedPrefHelper.setUserName(displayName);

        _showSnackBar(context, 'Welcome, $displayName!', isError: false);

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => CustomBottomNavigation(userName: displayName),
            ),
          );
        }
      }
    } catch (e, stackTrace) {
      print("⚠️ Google Sign-In error: $e\nStackTrace: $stackTrace");
      String errorMessage;
      if (e.toString().contains('network_error')) {
        errorMessage = 'Network error. Please check your connection and try again.';
      } else if (e.toString().contains('sign_in_canceled')) {
        errorMessage = 'Sign-in canceled.';
      } else if (e.toString().contains('failed-precondition')) {
        errorMessage = 'Firestore query failed. Please try again later.';
      } else {
        errorMessage = 'Sign-in failed. Please try again.';
      }
      _showSnackBar(context, errorMessage, isError: true);
    } finally {
      if (mounted) {
        setState(() => _isSigningIn = false);
      }
    }
  }

  void _showSnackBar(BuildContext context, String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle,
              color: Colors.white,
              size: 22,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 14,
                  fontFamily: 'Poppins',
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? Colors.redAccent : const Color(0xff023047),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ),
    );
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
                  padding: EdgeInsets.only(top: 150),
                  child: Text(
                    'Let\'s Get Started',
                    style: TextStyle(
                      fontSize: 25,
                      fontFamily: 'Poppins',
                      color: Color(0xff023047),
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 350),
                if (Platform.isAndroid)
                  _isSigningIn
                      ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xff023047)),
                    ),
                  )
                      : _buildSocialButton(
                    context,
                    'Continue With Google',
                    'assets/img.png',
                        () => _handleGoogleSignIn(context),
                  )
                else if (Platform.isIOS)
                  _buildSocialButton(
                    context,
                    'Continue With Apple',
                    'assets/apple.png',
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

  Widget _buildSocialButton(BuildContext context, String title, String imagePath, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
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
            Image.asset(imagePath, height: 24),
            const SizedBox(width: 10),
            Text(
              title,
              style: const TextStyle(
                color: Colors.black,
                fontFamily: 'Poppins',
                fontSize: 16,
              ),
            ),
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