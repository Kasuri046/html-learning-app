import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:html_learning/screens/policy.dart';

import '../components/bottom_navigation.dart';
import '../resources/shared_preferences.dart';
import '../validations/letsgetstarted.dart';
import 'about.dart';

class SettingsScreen extends StatelessWidget {
  final String userName;
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
        duration: const Duration(seconds: 4),
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
        backgroundColor: const Color(0xff023047),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  // Reusable text field widget inspired by Signin screen
  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    IconData? prefixIcon,
    bool obscureText = false,
    Widget? suffixIcon,
    required double height,
    String? errorText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: height,
          child: TextFormField(
            controller: controller,
            style: const TextStyle(color: Colors.black, fontFamily: 'Poppins'),
            obscureText: obscureText,
            textAlign: TextAlign.left,
            decoration: InputDecoration(
              prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: const Color(0xff023047)) : null,
              suffixIcon: suffixIcon,
              hintText: hintText,
              hintStyle: const TextStyle(color: Colors.grey, fontFamily: 'Poppins'),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xff023047)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xff023047), width: 2),
              ),
              errorText: null, // Disable default error text
              errorStyle: const TextStyle(height: 0), // Prevent default error spacing
            ),
          ),
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 5, left: 12),
            child: Text(
              errorText,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                color: Colors.red,
                fontWeight: FontWeight.w400,
              ),
              maxLines: 2,
            ),
          ),
      ],
    );
  }

  // Function to show confirmation dialog with Signin-inspired UI
  Future<bool> _showConfirmationDialog(BuildContext context, User user) async {
    final screenSize = MediaQuery.of(context).size;
    final double containerWidth = screenSize.width * 0.92; // 90% of screen width
    final double textFieldHeight = screenSize.height * 0.07; // Consistent with Signin

    return await showDialog<bool>(

      context: context,
      barrierDismissible: false,
      builder: (context) {
        final TextEditingController controller = TextEditingController();
        bool isObscure = true;
        String? errorMessage;
        bool isPassword = user.providerData.any((provider) => provider.providerId == 'password');

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              backgroundColor: Colors.white,
              contentPadding: EdgeInsets.zero,
              content: Container(
                width: containerWidth,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Confirm Account Deletion',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xff023047),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isPassword
                          ? 'Please enter your password to confirm account deletion.'
                          : 'Please enter your email to confirm account deletion.',
                      style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(
                      controller: controller,
                      hintText: isPassword ? 'Password' : 'Email',
                      prefixIcon: isPassword ? Icons.lock_outline : Icons.email_outlined,
                      obscureText: isPassword ? isObscure : false,
                      suffixIcon: isPassword
                          ? IconButton(
                        icon: Icon(
                          isObscure ? Icons.visibility_off : Icons.visibility,
                          color: const Color(0xff023047),
                        ),
                        onPressed: () {
                          setState(() {
                            isObscure = !isObscure;
                          });
                        },
                      )
                          : null,
                      height: textFieldHeight,
                      errorText: errorMessage,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop(false);
                          },
                          child: Text(
                            'Cancel',
                            style: GoogleFonts.poppins(
                              color: const Color(0xff023047),
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xff023047),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          ),
                          onPressed: () async {
                            String input = controller.text.trim();
                            if (input.isEmpty) {
                              setState(() {
                                errorMessage = isPassword
                                    ? 'Please enter your password to continue.'
                                    : 'Please enter your email to continue.';
                              });
                              return;
                            }

                            if (isPassword) {
                              try {
                                final credential = EmailAuthProvider.credential(
                                  email: user.email!,
                                  password: input,
                                );
                                await user.reauthenticateWithCredential(credential);
                                Navigator.of(context).pop(true);
                              } catch (e) {
                                String error = 'That password doesn’t seem right. Try again?';
                                if (e is FirebaseAuthException) {
                                  debugPrint("Firebase error code: ${e.code}");
                                  switch (e.code) {
                                    case 'wrong-password':
                                      error = 'That password doesn’t seem right. Try again?';
                                      break;
                                    case 'too-many-requests':
                                      error = 'Too many attempts. Please try again later.';
                                      break;
                                    case 'invalid-credential':
                                      error = 'Please check your password.';
                                      break;
                                    case 'user-not-found':
                                      error = 'Account not found. Please check your credentials.';
                                      break;
                                    default:
                                      error = 'An error occurred. Please try again.';
                                  }
                                }
                                setState(() {
                                  errorMessage = error;
                                });
                              }
                            } else {
                              if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(input)) {
                                setState(() {
                                  errorMessage = 'Please enter a valid email address.';
                                });
                                return;
                              }
                              if (input.toLowerCase() == user.email?.toLowerCase()) {
                                Navigator.of(context).pop(true);
                              } else {
                                setState(() {
                                  errorMessage = 'Email does not match. Please try again.';
                                });
                              }
                            }
                          },
                          child: Text(
                            'Confirm',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).then((value) => value ?? false);
  }

  // Function to handle account deletion with improved error handling
  Future<void> _deleteAccount(BuildContext context) async {
    // Debounce to prevent multiple dialog triggers
    bool isProcessing = false;
    if (isProcessing) return;
    isProcessing = true;

    final user = FirebaseAuth.instance.currentUser;
    final googleSignIn = GoogleSignIn();

    if (user == null) {
      if (context.mounted) {
        showErrorSnackbar(context, 'No user is currently signed in.');
      }
      isProcessing = false;
      return;
    }

    // Show confirmation dialog
    bool confirmed = await _showConfirmationDialog(context, user);
    if (!confirmed) {
      isProcessing = false;
      return;
    }

    try {
      // Delete Firestore user data
      final userDoc = FirebaseFirestore.instance.collection('users').doc(user.uid);
      final quizzesCollection = userDoc.collection('quizzes');
      final quizzes = await quizzesCollection.get();
      for (var doc in quizzes.docs) {
        await doc.reference.delete();
      }
      final progressCollection = userDoc.collection('progress');
      final progressDocs = await progressCollection.get();
      for (var doc in progressDocs.docs) {
        await doc.reference.delete();
      }
      final notificationsCollection = userDoc.collection('notifications');
      final notifications = await notificationsCollection.get();
      for (var doc in notifications.docs) {
        await doc.reference.delete();
      }
      await userDoc.delete();
      debugPrint("DEBUG: Deleted Firestore user data for UID: ${user.uid}");

      // Delete Firebase Authentication account
      await user.delete();
      debugPrint("DEBUG: Deleted Firebase Authentication account");

      // Clear SharedPreferences
      await SharedPrefHelper.clearAll();
      debugPrint("DEBUG: Cleared all SharedPreferences");

      // Sign out from Google Sign-In and Firebase
      await googleSignIn.signOut();
      await FirebaseAuth.instance.signOut();
      debugPrint("DEBUG: Signed out from Google Sign-In and Firebase");

      // Navigate to Start screen with fade transition
      if (context.mounted) {
        showSuccessSnackbar(context, 'Account deleted successfully.');
        await Future.delayed(const Duration(milliseconds: 1000));
        Navigator.of(context).pushAndRemoveUntil(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const Start(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 500),
          ),
              (route) => false,
        );
      }
    } catch (e) {
      debugPrint("DEBUG: Error in account deletion: $e");
      String errorMessage = 'An error occurred while deleting your account. Please try again.';
      if (e is FirebaseAuthException) {
        debugPrint("Firebase error code: ${e.code}");
        switch (e.code) {
          case 'requires-recent-login':
            errorMessage = 'Your session has expired. Please sign in again to delete your account.';
            break;
          case 'too-many-requests':
            errorMessage = 'Too many attempts. Please try again later.';
            break;
          default:
            errorMessage = 'An error occurred. Please try again.';
        }
      }
      if (context.mounted) {
        showErrorSnackbar(context, errorMessage);
      }
    } finally {
      isProcessing = false;
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
                          initialIndex: 3,
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
                          initialIndex: 2,
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