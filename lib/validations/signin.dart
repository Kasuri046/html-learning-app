import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:html_learning/validations/signup.dart';

import '../components/bottom_navigation.dart';
import '../resources/navigation_helper.dart';
import '../resources/shared_preferences.dart';
import 'forgot_pass.dart';

class Signin extends StatefulWidget {
  const Signin({super.key});

  @override
  State<Signin> createState() => _LoginState();
}

class _LoginState extends State<Signin> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool isLoading = false;
  bool _obscurePassword = true;

  String? emailError;
  String? passwordError;

  Future<String> getUserNameFromUid(String uid) async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        return data['displayName'] ?? data['name'] ?? 'User';
      } else {
        return 'User';
      }
    } catch (e) {
      debugPrint("Error fetching username for uid $uid: $e");
      return 'User';
    }
  }

  void _login() async {
    setState(() {
      emailError = null;
      passwordError = null;
    });

    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();

    if (email.isEmpty) {
      setState(() => emailError = 'Oops! Looks like you forgot to enter email.');
      return;
    }
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email)) {
      setState(() => emailError = 'Enter a valid email address (e.g. name@example.com).');
      return;
    }
    if (password.isEmpty) {
      setState(() => passwordError = 'Please enter your password to continue.');
      return;
    }

    setState(() => isLoading = true);

    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = userCredential.user;

      if (user != null) {
        String fetchedUserName = await getUserNameFromUid(user.uid);

        await SharedPrefHelper.setLoggedIn(true);
        await SharedPrefHelper.setUserName(fetchedUserName);

        _emailController.clear();
        _passwordController.clear();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Welcome, $fetchedUserName!',
                    style: const TextStyle(
                      fontSize: 14,
                      fontFamily: 'Poppins',
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: Color(0xff023047),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            duration: const Duration(seconds: 3),
          ),
        );

        NavigationHelper.pushReplacementWithFade(
          context,
          CustomBottomNavigation(userName: fetchedUserName),
        );
      }
    } catch (e) {
      String errorMessage = "Oops! Something went wrong. Please try again.";

      if (e is FirebaseAuthException) {
        debugPrint("Firebase message code ${e.code}");

        switch (e.code) {
          case 'user-not-found':
            errorMessage = "No account found with that email. Want to sign up instead?";
            break;
          case 'wrong-password':
            errorMessage = "That password doesn’t seem right. Try again?";
            break;
          case 'invalid-email':
            errorMessage = "That doesn’t look like a valid email address. Could you check it again?";
            break;
          case 'too-many-requests':
            errorMessage = "Too many failed login attempts. Please wait a moment and try again later.";
            break;
          case 'account-exists-with-different-credential':
            errorMessage = "This email is already associated with a different login provider. Please use Google or another login method.";
            break;
          case 'invalid-credential':
            errorMessage = "There was an issue with your credentials. Please double-check your email and password.";
            break;
          default:
            errorMessage = e.message ?? errorMessage;
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  errorMessage,
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
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final double padding = screenSize.width * 0.05;
    final double containerWidth = screenSize.width * 0.9;
    final double textFieldHeight = screenSize.height * 0.07;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(image: AssetImage('assets/des.png'), fit: BoxFit.cover),
            ),
          ),
          Column(
            children: [
              Center(
                child: Container(
                  width: containerWidth,
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(20)),
                  child: Column(
                    children: [
                      const SizedBox(height: 180),
                      const Text('Welcome',
                          style: TextStyle(
                              color: Color(0xff023047),
                              fontSize: 28,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Poppins')),
                      const SizedBox(height: 40),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: padding),
                        child: Column(
                          children: [
                            SizedBox(
                              height: textFieldHeight,
                              child: TextFormField(
                                controller: _emailController,
                                style: const TextStyle(color: Colors.black, fontFamily: 'Poppins'),
                                textAlign: TextAlign.left,
                                decoration: InputDecoration(
                                  prefixIcon: const Icon(Icons.email_outlined, color: Color(0xff023047)),
                                  hintText: 'Email',
                                  hintStyle: const TextStyle(color: Colors.grey, fontFamily: 'Poppins'),
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: Color(0xff023047))),
                                ),
                              ),
                            ),
                            if (emailError != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 5),
                                child: Text(emailError!, style: const TextStyle(color: Colors.red, fontFamily: 'Poppins', fontSize: 12)),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: padding),
                        child: Column(
                          children: [
                            SizedBox(
                              height: textFieldHeight,
                              child: TextFormField(
                                controller: _passwordController,
                                style: const TextStyle(color: Colors.black, fontFamily: 'Poppins'),
                                obscureText: _obscurePassword,
                                textAlign: TextAlign.left,
                                decoration: InputDecoration(
                                  prefixIcon: const Icon(Icons.lock_outline, color: Color(0xff023047)),
                                  hintText: 'Password',
                                  hintStyle: const TextStyle(color: Colors.grey, fontFamily: 'Poppins'),
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: Color(0xff023047))),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                      color: Color(0xff023047),
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                                  ),
                                ),
                              ),
                            ),
                            if (passwordError != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 5),
                                child: Text(passwordError!, style: const TextStyle(color: Colors.red, fontFamily: 'Poppins', fontSize: 12)),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      GestureDetector(
                        onTap: () => NavigationHelper.pushReplacementWithFade(context, const ForgotPasswordScreen()),
                        child: const Text('Forgot Password?',
                            style: TextStyle(color: Color(0xff023047), fontSize: 16, fontFamily: 'Poppins')),
                      ),
                      const SizedBox(height: 20),
                      isLoading
                          ? const CircularProgressIndicator()
                          : GestureDetector(
                        onTap: _login,
                        child: Container(
                          width: containerWidth * 0.9,
                          height: textFieldHeight,
                          decoration: BoxDecoration(
                              color: Color(0xff023047), borderRadius: BorderRadius.circular(12)),
                          child: const Center(
                            child: Text('Sign In',
                                style: TextStyle(color: Colors.white, fontSize: 18, fontFamily: 'Poppins')),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("Haven't Registered yet? ",
                              style: TextStyle(color: Colors.black, fontSize: 14, fontFamily: 'Poppins')),
                          InkWell(
                            onTap: () => NavigationHelper.pushReplacementWithFade(context, const Signup()),
                            child: const Text("Signup",
                                style: TextStyle(
                                    color: Color(0xff023047),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    fontFamily: 'Poppins')),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}