import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:html_learning/screens/progressprovider.dart';
import 'package:html_learning/screens/settingsc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../components/bottom_navigation.dart';
import '../resources/navigation_helper.dart';
import '../resources/shared_preferences.dart';
import '../validations/letsgetstarted.dart';

extension StringExtension on String {
  String capitalizeFirst() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1);
  }
}

class ProfileScreen extends StatefulWidget {
  final String userName;
  const ProfileScreen({super.key, required this.userName});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String userName = "Loading...";
  String userEmail = "Loading...";
  String? userPhotoUrl;
  File? _imageFile;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    _loadSavedImage();
    print("DEBUG: ProfileScreen initialized, userName: ${widget.userName}");
  }

  void _fetchUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        userEmail = user.email ?? "No Email";
        userPhotoUrl = user.photoURL;
      });
      if (user.providerData.any((info) => info.providerId == "google.com")) {
        setState(() {
          userName = user.displayName ?? widget.userName;
        });
      } else {
        try {
          DocumentSnapshot userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
          if (userDoc.exists) {
            final userData = userDoc.data() as Map<String, dynamic>;
            setState(() {
              userName = userData['name'] ?? widget.userName;
            });
          } else {
            setState(() {
              userName = widget.userName;
            });
          }
        } catch (e) {
          print("DEBUG: Error fetching user name: $e");
          setState(() {
            userName = widget.userName;
          });
        }
      }
      print("DEBUG: Fetched user data, name: $userName, email: $userEmail");
    }
  }

  Future<void> _loadSavedImage() async {
    final prefs = await SharedPreferences.getInstance();
    final savedImagePath = prefs.getString('profile_image_path');
    if (savedImagePath != null && File(savedImagePath).existsSync()) {
      setState(() {
        _imageFile = File(savedImagePath);
      });
      print("DEBUG: Loaded saved profile image: $savedImagePath");
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final directory = await getApplicationDocumentsDirectory();
      final savedImagePath = '${directory.path}/profile_image.jpg';
      final savedImage = await File(pickedFile.path).copy(savedImagePath);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('profile_image_path', savedImage.path);
      setState(() {
        _imageFile = savedImage;
      });
      print("DEBUG: Picked and saved new profile image: $savedImagePath");
    }
  }

  void _logout(BuildContext context) async {
    bool? shouldLogout = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Confirm Logout',
            style: TextStyle(
              fontSize: 14,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            'Are you sure you want to log out?',
            style: TextStyle(fontFamily: 'Poppins', fontSize: 12),
          ),
          backgroundColor: Colors.teal[50],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                'Cancel',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  color:Color(0xff023047),
                ),
              ),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: const Text(
                'Logout',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  color: Colors.red,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );
    if (shouldLogout == true) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final progressCleared = prefs.getBool('progress_cleared') ?? false;
        final profileImagePath = prefs.getString('profile_image_path');
        await FirebaseAuth.instance.signOut();
        await prefs.clear();
        await prefs.setBool('progress_cleared', progressCleared);
        if (profileImagePath != null) {
          await prefs.setString('profile_image_path', profileImagePath);
        }
        print("DEBUG: Logout successful, preserved progress_cleared: $progressCleared, profile_image_path: $profileImagePath");
        NavigationHelper.pushReplacementWithFade(context, const Start());
      } catch (e) {
        print("DEBUG: Logout error: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Logout failed: $e')),
        );
      }
    }
  }

  void _resetProgress(BuildContext context) async {
    bool? shouldReset = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Reset Progress',
            style: TextStyle(
              fontSize: 14,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            'Are you sure you want to reset all your progress? This cannot be undone.',
            style: TextStyle(fontFamily: 'Poppins', fontSize: 12),
          ),
          backgroundColor: Colors.teal[50],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                'Cancel',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  color: Colors.teal[800],
                ),
              ),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: const Text(
                'Reset',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  color: Colors.red,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );
    if (shouldReset == true) {
      try {
        final progressProvider = Provider.of<ProgressProvider>(context, listen: false);
        await progressProvider.resetProgress();
        print("DEBUG: Progress reset successful");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Progress Reset Successfully.',
                    style: const TextStyle(
                      fontSize: 14,
                      fontFamily: 'Poppins',
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            duration: const Duration(seconds: 3),
          ),
        );
      } catch (e) {
        print("DEBUG: Reset progress error: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Progress Reset Failed.',
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
    }
  }

  void _navigateToHomePage(String userName) {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => CustomBottomNavigation(
          userName: userName,
          initialIndex: 0,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    print("DEBUG: Building ProfileScreen, userName: $userName, email: $userEmail");
    return PopScope(
      canPop: true, // Allow default pop behavior
      child: Scaffold(
        backgroundColor: Color(0xff023047),
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(80),
          child: AppBar(
            backgroundColor:Color(0xff023047),
            elevation: 0,
            automaticallyImplyLeading: true,
            iconTheme: IconThemeData(color: Colors.white),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () {
                print("DEBUG: Back button pressed, popping to previous screen");
                _navigateToHomePage(widget.userName);

              },
            ),
            title: const Text(
              'Profile',
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.settings, color: Colors.white),
                onPressed: () {
                  print("DEBUG: Settings button pressed, navigating to SettingsScreen");
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => SettingsScreen(userName: userName)),
                  );
                },
              ),
            ],
          ),
        ),
        body: Stack(
          children: [
            Container(
              height: 1100,
              margin: const EdgeInsets.only(top: 80),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 80),
                    Text(
                      userName.capitalizeFirst(),
                      style: const TextStyle(
                        fontSize: 24,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.bold,
                        color: Color(0xff023047),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      userEmail,
                      style: const TextStyle(
                        fontSize: 16,
                        fontFamily: 'Poppins',
                        color: Colors.black54,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 30),
                    Consumer<ProgressProvider>(
                      builder: (context, progressProvider, child) {
                        double progressValue = progressProvider.globalTotal > 0
                            ? progressProvider.globalProgress / progressProvider.globalTotal
                            : 0.0;
                        print("DEBUG: ProfileScreen progress: ${(progressValue * 100).toStringAsFixed(1)}%");
                        return Card(
                          color: Colors.blue[50],
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Learning Progress",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xff023047),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: LinearProgressIndicator(
                                    value: progressValue.clamp(0.0, 1.0),
                                    backgroundColor: Colors.grey.shade400,
                                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xff023047)),
                                    minHeight: 13,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  'Overall Progress: ${(progressValue * 100).toStringAsFixed(1)}%',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color:Color(0xff023047),
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton.icon(
                      onPressed: () => _logout(context),
                      icon: const Icon(Icons.logout, color: Colors.white),
                      label: const Text(
                        "Logout",
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xff023047),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // ElevatedButton.icon(
                    //   onPressed: () => _resetProgress(context),
                    //   icon: const Icon(Icons.refresh, color: Colors.white),
                    //   label: const Text(
                    //     "Reset Progress",
                    //     style: TextStyle(
                    //       fontFamily: 'Poppins',
                    //       color: Colors.white,
                    //       fontSize: 16,
                    //     ),
                    //   ),
                    //   style: ElevatedButton.styleFrom(
                    //     backgroundColor: Colors.red,
                    //     shape: RoundedRectangleBorder(
                    //       borderRadius: BorderRadius.circular(12),
                    //     ),
                    //     padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    //   ),
                    // ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 30,
              left: 0,
              right: 0,
              child: Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 65,
                        backgroundColor:Color(0xff023047),
                        child: CircleAvatar(
                          radius: 62,
                          backgroundImage: _imageFile != null
                              ? FileImage(_imageFile!)
                              : (userPhotoUrl != null && userPhotoUrl!.isNotEmpty
                              ? NetworkImage(userPhotoUrl!)
                              : const AssetImage('assets/profilepic.png')) as ImageProvider,
                          backgroundColor: Colors.white,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Color(0xff023047),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.edit, color: Colors.white, size: 18),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}