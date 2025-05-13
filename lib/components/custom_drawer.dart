import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../resources/navigation_helper.dart';
import '../resources/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';

import '../screens/calenderscreen.dart';
import '../screens/settingsc.dart';
import '../validations/letsgetstarted.dart';
import 'bottom_navigation.dart';

extension StringExtension on String {
  String capitalizeFirst() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1);
  }
}

class CustomDrawer extends StatefulWidget {
  final String userName;
  const CustomDrawer({super.key, required this.userName});

  @override
  _CustomDrawerState createState() => _CustomDrawerState();
}

class _CustomDrawerState extends State<CustomDrawer> {
  String userName = "Loading...";
  String userEmail = "Loading...";
  String? userPhotoUrl;
  bool isGoogleUser = false;
  File? _imageFile;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    _loadSavedImage();
  }

  void _fetchUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() => userEmail = user.email ?? "No Email");

      if (widget.userName.isNotEmpty) {
        setState(() => userName = StringExtension(widget.userName).capitalizeFirst());
      } else {
        String? storedName = await SharedPrefHelper.getUserName();
        if (storedName != null && storedName.isNotEmpty) {
          setState(() => userName = StringExtension(storedName).capitalizeFirst());
        } else {
          try {
            DocumentSnapshot userDoc = await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .get();
            if (userDoc.exists) {
              final data = userDoc.data() as Map<String, dynamic>;
              setState(() {
                userName = (data['name'] ?? "User").capitalizeFirst();
              });
              await SharedPrefHelper.setUserName(userName);
            } else {
              setState(() => userName = "User");
            }
          } catch (e) {
            print("Error fetching user data: $e");
            setState(() => userName = "User");
          }
        }
      }

      isGoogleUser = user.providerData.any((info) => info.providerId == "google.com");
      if (isGoogleUser) {
        setState(() {
          userName = StringExtension(user.displayName ?? userName).capitalizeFirst();
          userPhotoUrl = user.photoURL;
        });
      }
    } else {
      setState(() {
        userName = "Guest";
        userEmail = "Not logged in";
      });
    }
  }

  Future<void> _loadSavedImage() async {
    final prefs = await SharedPreferences.getInstance();
    final savedImagePath = prefs.getString('profile_image_path');
    if (savedImagePath != null && File(savedImagePath).existsSync()) {
      setState(() {
        _imageFile = File(savedImagePath);
      });
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
                  color:  Color(0xff023047),
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

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [ Color(0xff023047),  Color(0xff023045)],
                begin: Alignment.topRight,
                end: Alignment.bottomRight,
              ),
            ),
            accountName: Text(
              StringExtension(userName).capitalizeFirst(),
              style: const TextStyle(
                fontSize: 16,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w500,
              ),
            ),
            accountEmail: Text(
              userEmail,
              style: const TextStyle(
                fontSize: 14,
                fontFamily: 'Poppins',
                color: Colors.white70,
              ),
            ),
            currentAccountPicture: GestureDetector(
              onTap: isGoogleUser ? null : _pickImage,
              child: CircleAvatar(
                radius: 35,
                backgroundColor: Colors.white,
                child: ClipOval(
                  child: _imageFile != null
                      ? Image.file(_imageFile!, fit: BoxFit.cover, width: 72, height: 72)
                      : (userPhotoUrl != null && userPhotoUrl!.isNotEmpty
                      ? Image.network(userPhotoUrl!, fit: BoxFit.cover, width: 72, height: 72)
                      : Image.asset('assets/profilepic.png', fit: BoxFit.cover, width: 72, height: 72)),
                ),
              ),
            ),
          ),
          _buildDrawerItem(Icons.person, "Profile", () {
            Navigator.pop(context); // Close drawer
            if (ModalRoute.of(context)?.settings.name != '/profile') {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => CustomBottomNavigation(userName: userName, initialIndex: 3),
                  settings: const RouteSettings(name: '/profile'),
                ),
              );
            }
          }),
          _buildDrawerItem(Icons.calendar_today, "Calendar", () {
            Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(builder: (_) => CalendarScreen(userName: userName)));
          }),
          _buildDrawerItem(Icons.settings, "Settings", () {
            Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(builder: (_) => SettingsScreen(userName: userName)));
          }),
          const Spacer(),
          const Divider(),
          _buildDrawerItem(Icons.logout, "Logout", () => _logout(context), color: Colors.redAccent),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, VoidCallback onTap, {Color color =  const Color(0xff023047)}) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        title,
        style: TextStyle(color: color, fontFamily: 'Poppins', fontSize: 15, fontWeight: FontWeight.w500),
      ),
      onTap: onTap,
    );
  }
}