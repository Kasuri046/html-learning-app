import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter/services.dart';
import '../components/bottom_navigation.dart';
import '../resources/helper_notifi.dart';

class NotificationDisplayPage extends StatefulWidget {
  final String userName;

  const NotificationDisplayPage({super.key, required this.userName});

  @override
  State<NotificationDisplayPage> createState() => _NotificationDisplayPageState();
}

class _NotificationDisplayPageState extends State<NotificationDisplayPage> {
  List<Map<String, dynamic>> _userNotifications = [];
  bool _isProcessingClick = false;
  bool _isLoading = true;
  int _retryCount = 0;
  static const int _maxRetries = 3;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchNotifications());
  }

  Future<void> _fetchNotifications() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _userNotifications = [];
        });
      }
      return;
    }

    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      print('Query now: $now');
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .get();

      print('Fetched docs: ${snapshot.docs.length}');
      for (var doc in snapshot.docs) {
        print('Doc data: ${doc.data()}');
      }

      if (!mounted) return;

      final notifications = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          'title': data['title'] ?? 'Reminder',
          'message': data['message'] ?? 'Your reminder is ready!',
          'isRead': data['isRead'] ?? false,
          'isUserReminder': data['isUserReminder'] ?? true,
          'timestamp': data['timestamp'] ?? now,
          'scheduledTime': data['scheduledTime'] ?? now,
        };
      }).toList()
        ..sort((a, b) => (b['scheduledTime'] as num).compareTo(a['scheduledTime'] as num));

      if (!mounted) return;

      setState(() {
        _userNotifications = notifications;
        _isLoading = false;
        _retryCount = 0;
      });
    } catch (e) {
      print("Error fetching notifications: $e");
      if (_retryCount < _maxRetries) {
        _retryCount++;
        print('Retrying fetch notifications: Attempt $_retryCount/$_maxRetries');
        await Future.delayed(const Duration(seconds: 2));
        return _fetchNotifications();
      }
      if (mounted) {
        setState(() {
          _userNotifications = [];
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Failed to load notifications. Please check your connection.',
              style: TextStyle(fontFamily: 'Poppins', color: Colors.white),
            ),
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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

  void _markAsReadAndNavigate(int index) async {
    if (_isProcessingClick || !mounted) return;
    setState(() => _isProcessingClick = true);

    final notif = _userNotifications[index];
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser?.uid)
          .collection('notifications')
          .doc(notif['id'])
          .update({'isRead': true});
      print("Marked notification as read: ${notif['title']} (ID: ${notif['id']})");
    } catch (e) {
      print("Error marking notification as read: $e");
    }

    if (mounted) {
      setState(() {
        _userNotifications[index]['isRead'] = true;
      });
    }

    _navigateToHomePage(widget.userName);

    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      setState(() => _isProcessingClick = false);
    }
  }

  void _deleteNotification(int index, {bool showUndo = false, Map<String, dynamic>? deletedNotif}) {
    if (!mounted) return;
    final removed = deletedNotif ?? _userNotifications[index];

    setState(() {
      _userNotifications.removeAt(index);
    });

    FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser?.uid)
        .collection('notifications')
        .doc(removed['id'])
        .delete()
        .then((_) => print("Deleted: ${removed['title']}"))
        .catchError((e) => print("Delete error: $e"));

    if (showUndo) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            "Notification deleted",
            style: TextStyle(fontFamily: 'Poppins', fontSize: 14, color: Colors.white),
          ),
          backgroundColor: Colors.redAccent,
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          action: SnackBarAction(
            label: 'UNDO',
            textColor: Colors.white,
            onPressed: () {
              FirebaseFirestore.instance
                  .collection('users')
                  .doc(FirebaseAuth.instance.currentUser?.uid)
                  .collection('notifications')
                  .doc(removed['id'])
                  .set(removed)
                  .then((_) {
                setState(() {
                  _userNotifications.insert(index, removed);
                });
                print("Restored notification: ${removed['title']}");
              });
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _navigateToHomePage(widget.userName);
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(120),
          child: AppBar(
            backgroundColor: Color(0xff023047),
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => _navigateToHomePage(widget.userName),
            ),
            title: const Text(
              'Notifications',
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            centerTitle: true,
            flexibleSpace: Container(
              padding: const EdgeInsets.only(top: 60),
              alignment: Alignment.center,
              child: const Text(
                'Stay Updated with HTML',
                style: TextStyle(
                  color: Colors.white70,
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ),
        ),
        body: Stack(
          children: [
            Container(height: 35, color: Color(0xff023047)),
            Container(
              margin: const EdgeInsets.only(top: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(25),
                  topRight: Radius.circular(25),
                ),
              ),
              child: _isLoading
                  ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xff023047)),
                ),
              )
                  : _userNotifications.isEmpty
                  ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.notifications_off, size: 48, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      "No notifications yet!",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              )
                  : RefreshIndicator(
                onRefresh: _fetchNotifications,
                color: const Color(0xff023047),
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: _userNotifications.length,
                  itemBuilder: (context, index) {
                    final notif = _userNotifications[index];
                    return _buildNotificationTile(
                      notif['id']!,
                      notif['title']!,
                      notif['message']!,
                      notif['isRead']!,
                      notif['isUserReminder']!,
                      index,
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationTile(
      String id, String title, String message, bool isRead, bool isUserReminder, int index) {
    const double tileHeight = 120.0; // Increased from 80.0

    return Dismissible(
      key: Key(id),
      direction: DismissDirection.startToEnd,
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.all(16), // Increased from 12
        decoration: BoxDecoration(
          color: Colors.redAccent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.delete, color: Colors.white, size: 28), // Increased from 24
      ),
      onDismissed: (_) {
        HapticFeedback.lightImpact();
        final deletedNotif = _userNotifications[index];
        _deleteNotification(index, showUndo: true, deletedNotif: deletedNotif);
      },
      child: GestureDetector(
        onTap: () => _markAsReadAndNavigate(index),
        child: Container(
          height: tileHeight,
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          padding: const EdgeInsets.all(16), // Increased from 12
          decoration: BoxDecoration(
            color: isRead ? Colors.grey[200] : const Color(0xff023047).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isRead ? Colors.grey[400]! : const Color(0xff023047).withOpacity(0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                isRead ? Icons.notifications : Icons.notifications_active,
                color: isRead ? Colors.grey[600] : const Color(0xff023047),
                size: 28, // Increased from 24
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontFamily: 'Poppins',
                        fontWeight: isUserReminder ? FontWeight.bold : FontWeight.w600,
                        color: isRead ? Colors.grey[600] : const Color(0xff023047),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6), // Increased from 4
                    Flexible(
                      child: Text(
                        message,
                        style: const TextStyle(
                          fontSize: 13, // Reduced from 14
                          fontFamily: 'Poppins',
                          color: Colors.black54,
                        ),
                        maxLines: 4, // Increased from 2
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                isRead ? Icons.check_circle : Icons.arrow_forward_ios_outlined,
                size: 20, // Increased from 16
                color: isRead ? Colors.grey[600] : const Color(0xff023047),
              ),
            ],
          ),
        ),
      ),
    );
  }
}