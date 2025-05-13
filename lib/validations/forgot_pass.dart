import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  String? errorMessage;
  bool isLoading = false;
  bool showMessage = false;

  void _sendResetEmail() async {
    String rawEmail = _emailController.text.trim();
    String email = rawEmail.toLowerCase();
    print("📩 Raw email input: '$rawEmail', normalized: '$email'");

    if (email.isEmpty) {
      setState(() => errorMessage = "Please enter your email.");
      print("⚠️ Email field empty");
      return;
    }

    if (!RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$").hasMatch(email)) {
      setState(() => errorMessage = "Please enter a valid email.");
      print("⚠️ Invalid email format: '$email'");
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      // Check Firebase Auth
      print("🔍 Checking Firebase Auth for '$email'");
      try {
        List<String> methods = await FirebaseAuth.instance.fetchSignInMethodsForEmail(email);
        if (methods.isNotEmpty) {
          print("✅ Found user in Firebase Auth: methods=$methods");
          print("📧 Sending reset email to '$email'");
          await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
          print("✅ Reset email sent successfully");
          _showSuccess();
          return;
        }
        print("⚠️ No user in Firebase Auth for '$email'.");
      } catch (e) {
        print("⚠️ Auth check failed: $e");
      }

      // Check Firestore
      print("🔍 Querying Firestore for '$email'");
      QuerySnapshot query = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        print("🔍 Fallback: Querying Firestore for raw '$rawEmail'");
        query = await FirebaseFirestore.instance
            .collection('users')
            .where('email', isEqualTo: rawEmail)
            .limit(1)
            .get();
      }

      if (query.docs.isNotEmpty) {
        var doc = query.docs.first;
        print("✅ Found user in Firestore: id=${doc.id}, data=${doc.data()}");
        print("📧 Sending reset email to '$email'");
        await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
        print("✅ Reset email sent successfully");
        _showSuccess();
        return;
      }else{

        print("⚠️ No user found in Firestore for '$email' or '$rawEmail'");
        setState(() {
          errorMessage = "This email isn't registered.";
          isLoading = false;
        });
      }

    } catch (e) {
      print("⚠️ Error during reset process: $e");
      if (e.toString().contains('permission-denied')) {
        print("⚠️ Firestore rules blocking access! Check Firebase Console rules.");
      }
      setState(() {
        errorMessage = "Failed to send reset link. Try again.";
        isLoading = false;
      });
    }
  }

  void _showSuccess() {
    setState(() => showMessage = true);
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => showMessage = false);
        print("⏳ Navigating back to previous screen");
        Navigator.pop(context);
      }
    });
  }



  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Color(0xff023047),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(140),
        child: AppBar(
          backgroundColor: Color(0xff023047),
          iconTheme: const IconThemeData(color: Colors.white),
          title: Text(
            "Forgot Password",
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          centerTitle: true,
        ),
      ),
      body: Stack(
        children: [
          Container(
            height: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
              ),
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Enter your email to reset your password",
                    style: GoogleFonts.poppins(fontSize: 18, color: Color(0xff023047)),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: "Email",
                      labelStyle: const TextStyle(fontFamily: 'Poppins'),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.email, color: Color(0xff023047)),
                    ),
                  ),
                  if (errorMessage != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      errorMessage!,
                      style: const TextStyle(
                        color: Colors.red,
                        fontFamily: 'Poppins',
                        fontSize: 14,
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _sendResetEmail,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:Color(0xff023047),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        isLoading ? "Sending..." : "Send Reset Link",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (showMessage)
            Center(
              child: AnimatedOpacity(
                opacity: showMessage ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 500),
                child: AnimatedScale(
                  scale: showMessage ? 1.0 : 0.8,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutBack,
                  child: Material(
                    elevation: 12,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                      decoration: BoxDecoration(
                        color: Colors.teal.withOpacity(0.95),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.check_circle,
                            color: Colors.white70,
                            size: 28,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            "Reset Link Sent !",
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}