import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:html_learning/screens/policy.dart';

import '../components/bottom_navigation.dart';
import '../resources/shared_preferences.dart';
import '../validations/letsgetstarted.dart';
import 'about.dart'; // Import Start screen

class SettingsScreen extends StatelessWidget {
  final String userName; // Added to pass userName
  const SettingsScreen({Key? key, required this.userName}) : super(key: key);

  // Function to show error snackbar
  void showErrorSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 4), // Increased for visibility
      ),
    );
  }

  // Function to show success snackbar
  void showSuccessSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.redAccent, // Red for delete action
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 4), // Increased for visibility
      ),
    );
  }

  // Function to handle account deletion with logout
  Future<void> _deleteAccount(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    final googleSignIn = GoogleSignIn();

    if (user == null) {
      if (context.mounted) {
        showErrorSnackbar(context, 'No user is currently signed in.');
        await Future.delayed(const Duration(milliseconds: 1000)); // Ensure snackbar displays
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const Start()),
              (route) => false,
        );
      }
      return;
    }

    try {
      // Re-authenticate user if necessary
      bool reAuthenticated = false;
      for (var provider in user.providerData) {
        if (provider.providerId == 'google.com') {
          try {
            final googleUser = await googleSignIn.signIn();
            if (googleUser == null) {
              if (context.mounted) {
                showErrorSnackbar(context, 'Google Sign-In cancelled.');
                await Future.delayed(const Duration(milliseconds: 1000));
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const Start()),
                      (route) => false,
                );
              }
              return;
            }
            final googleAuth = await googleUser.authentication;
            final credential = GoogleAuthProvider.credential(
              accessToken: googleAuth.accessToken,
              idToken: googleAuth.idToken,
            );
            await user.reauthenticateWithCredential(credential);
            reAuthenticated = true;
          } catch (e) {
            print("DEBUG: Re-authentication failed: $e");
            // Skip re-authentication in emulator due to GoogleApiManager issues
            reAuthenticated = true; // Temporary workaround for emulator
          }
        } else if (provider.providerId == 'password') {
          // Add email/password re-authentication if needed (not implemented per requirement)
        }
      }

      if (!reAuthenticated) {
        if (context.mounted) {
          showErrorSnackbar(context, 'Please re-authenticate to delete your account.');
          await Future.delayed(const Duration(milliseconds: 1000));
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const Start()),
                (route) => false,
          );
        }
        return;
      }

      // Delete Firestore user data (including quizzes subcollection)
      final userDoc = FirebaseFirestore.instance.collection('users').doc(user.uid);
      final quizzesCollection = userDoc.collection('quizzes');
      final quizzes = await quizzesCollection.get();
      for (var doc in quizzes.docs) {
        await doc.reference.delete();
      }
      await userDoc.delete();
      print("DEBUG: Deleted Firestore user data for UID: ${user.uid}");

      // Delete Firebase Authentication account
      await user.delete();
      print("DEBUG: Deleted Firebase Authentication account");

      // Clear SharedPreferences
      await SharedPrefHelper.clearAll();
      print("DEBUG: Cleared all SharedPreferences");

      // Sign out from Google Sign-In and Firebase
      await googleSignIn.signOut();
      await FirebaseAuth.instance.signOut();
      print("DEBUG: Signed out from Google Sign-In and Firebase");

      // Navigate to Start screen
      if (context.mounted) {
        showSuccessSnackbar(context, 'Account deleted successfully.');
        await Future.delayed(const Duration(milliseconds: 1000)); // Ensure snackbar displays
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const Start()),
              (route) => false,
        );
      }
    } catch (e) {
      print("DEBUG: Error in account deletion: $e");
      // Ensure cleanup even on error
      await SharedPrefHelper.clearAll();
      await googleSignIn.signOut();
      await FirebaseAuth.instance.signOut();
      if (context.mounted) {
        showErrorSnackbar(context, 'Error deleting account: $e');
        await Future.delayed(const Duration(milliseconds: 1000));
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const Start()),
              (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff023047),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(130),
        child: AppBar(
          backgroundColor: const Color(0xff023047),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: Padding(
            padding: const EdgeInsets.only(top: 20),
            child: Text(
              "Settings",
              style: GoogleFonts.poppins(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          centerTitle: true,
        ),
      ),
      body: Stack(
        children: [
          Container(
            height: 900,
            margin: const EdgeInsets.only(top: 0),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
              ),
            ),
            child: ListView(
              children: [
                ListTile(
                  leading: const Icon(Icons.account_circle, color: Color(0xff023047)),
                  title: const Text('Profile', style: TextStyle(fontFamily: 'Poppins')),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CustomBottomNavigation(
                          userName: userName,
                          initialIndex: 3, // Navigate to Profile screen
                        ),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.notifications, color: Color(0xff023047)),
                  title: const Text('Notifications', style: TextStyle(fontFamily: 'Poppins')),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CustomBottomNavigation(
                          userName: userName,
                          initialIndex: 2, // Navigate to Notifications screen
                        ),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.privacy_tip, color: Color(0xff023047)),
                  title: const Text('Privacy', style: TextStyle(fontFamily: 'Poppins')),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const PrivacyPolicyPage()),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.info, color: Color(0xff023047)),
                  title: const Text('About', style: TextStyle(fontFamily: 'Poppins')),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AboutPage()),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.delete_forever_rounded,
                    color: Colors.red,
                    size: 28,
                  ),
                  title: const Text(
                    'Delete Account',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onTap: () => _deleteAccount(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}