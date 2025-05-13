import 'dart:io';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:permission_handler/permission_handler.dart';
import '../components/bottom_navigation.dart';

class NotificationHelper {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  static bool _isInitialized = false;
  static User? _cachedUser;

  static Future<void> initNotifications(String userName, {BuildContext? context}) async {
    if (_isInitialized) {
      print("Notifications already initialized");
      return;
    }

    _cachedUser = FirebaseAuth.instance.currentUser;
    if (_cachedUser == null) {
      print("⚠️ No user logged in, skipping notification init");
      return;
    }


    const AndroidInitializationSettings androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings settings = InitializationSettings(android: androidSettings);

    if (Platform.isAndroid) {
      final androidPlugin = _notificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.createNotificationChannel(
        const AndroidNotificationChannel(
          'reminder_channel',
          'C++ Reminders',
          description: 'Reminders for C++ learning',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
          enableLights: true,
          ledColor: Colors.blue,
        ),
      );
      print("Notification channel created");
    }

    await _notificationsPlugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (response) {
        print("Foreground notification: ${response.payload}");
        _onNotificationClick(response.payload, userName);
      },
      onDidReceiveBackgroundNotificationResponse: backgroundHandler,
    );

    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Karachi'));
    print("Timezone: Asia/Karachi");

    await requestPermissions(context: context);
    await _cleanOldNotifications();
    await showWelcomeNotification();
    _isInitialized = true;
  }

  static Future<void> requestPermissions({BuildContext? context}) async {
    if (Platform.isAndroid) {
      await _notificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();

      final status = await Permission.scheduleExactAlarm.status;
      if (!status.isGranted) {
        final newStatus = await Permission.scheduleExactAlarm.request();
        print(newStatus.isGranted ? "Exact Alarm Granted" : "Exact Alarm Denied");
      } else {
        print("Exact Alarm Already Granted");
      }
    }
  }

  static Future<void> showWelcomeNotification() async {
    final messages = [
      {'title': 'Welcome Back! 🌟', 'body': 'Ready to dive into C++?'},
      {'title': 'Hello Again! 🚀', 'body': 'Let’s crush some C++ code!'},
      {'title': 'Back for More? 💻', 'body': 'Time to level up C++ skills!'},
    ];
    final random = Random();
    final message = messages[random.nextInt(messages.length)];
    final id = DateTime.now().millisecondsSinceEpoch % 1000000;

    await showNotification(id: id, title: message['title']!, body: message['body']!, storeInFirestore: false);
    print("Welcome notification: ${message['title']}");
  }

  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    bool storeInFirestore = true,
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'reminder_channel',
      'C++ Reminders',
      channelDescription: 'Reminders for C++ learning',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: Color(0xFFb0ebe5),
      playSound: true,
      enableVibration: true,
      ticker: 'Reminder Ticker',
      fullScreenIntent: true,
    );

    const NotificationDetails details = NotificationDetails(android: androidDetails);

    try {
      await _notificationsPlugin.show(id, title, body, details, payload: 'open_reminder|$id|$title|$body');
      print("Notification shown: $title (ID: $id)");

      if (storeInFirestore && _cachedUser != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(_cachedUser!.uid)
            .collection('notifications')
            .doc(id.toString())
            .set({
          'title': title,
          'message': body,
          'isRead': false,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'isUserReminder': true,
          'scheduledTime': DateTime.now().millisecondsSinceEpoch,
        }, SetOptions(merge: true));
        print("Notification saved: $title (ID: $id)");
      }
    } catch (e) {
      print("Error showing notification: $e");
    }
  }

  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    required String userName,
  }) async {
    final tzScheduledTime = tz.TZDateTime(
      tz.local,
      scheduledTime.year,
      scheduledTime.month,
      scheduledTime.day,
      scheduledTime.hour,
      scheduledTime.minute,
      scheduledTime.second,
    );
    print("Scheduling: $scheduledTime, TZ: $tzScheduledTime");

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'reminder_channel',
      'C++ Reminders',
      channelDescription: 'Reminders for C++ learning',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      playSound: true,
      enableVibration: true,
      ticker: 'Scheduled Reminder',
      fullScreenIntent: true,
      timeoutAfter: 60000,
    );

    const NotificationDetails details = NotificationDetails(android: androidDetails);

    try {
      await _notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        tzScheduledTime,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: 'open_reminder|$id|$title|$body',
      );
      print("Scheduled: $title at $tzScheduledTime (ID: $id)");

      if (_cachedUser != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(_cachedUser!.uid)
            .collection('notifications')
            .doc(id.toString())
            .set({
          'title': title,
          'message': body,
          'isRead': false,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'isUserReminder': true,
          'scheduledTime': scheduledTime.millisecondsSinceEpoch,
        }, SetOptions(merge: true));
        print("Scheduled notification saved: $title (ID: $id)");

        final confirmId = id + 1000;
        await showNotification(
          id: confirmId,
          title: "Reminder Set!",
          body: "Reminder for $userName at ${scheduledTime.toString().substring(0, 16)}!",
          storeInFirestore: false,
        );
      }
    } catch (e) {
      print("Error scheduling: $e");
    }
  }

  static Future<void> _cleanOldNotifications() async {
    if (_cachedUser == null) {
      print("⚠️ No user, skipping clean");
      return;
    }

    try {
      final now = DateTime.now();
      final yesterday = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 1));
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(_cachedUser!.uid)
          .collection('notifications')
          .where('timestamp', isLessThan: yesterday.millisecondsSinceEpoch)
          .get();

      for (var doc in snapshot.docs) {
        await doc.reference.delete();
      }
      print("Deleted ${snapshot.docs.length} old notifications");
    } catch (e) {
      print("Error cleaning notifications: $e");
    }
  }

  static Future<List<PendingNotificationRequest>> getScheduledNotifications() async {
    try {
      final pending = await _notificationsPlugin.pendingNotificationRequests();
      print("Pending notifications: ${pending.length}");
      return pending;
    } catch (e) {
      print("Error fetching pending: $e");
      return [];
    }
  }

  static Future<void> clearAllNotifications() async {
    try {
      await _notificationsPlugin.cancelAll();
      print("All notifications cleared");
    } catch (e) {
      print("Error clearing notifications: $e");
    }
  }

  @pragma('vm:entry-point')
  static void backgroundHandler(NotificationResponse response) {
    print("Background notification: ${response.payload}");
  }

  static void _onNotificationClick(String? payload, String userName) {
    if (payload == null || navigatorKey.currentState == null) return;

    print("Notification clicked: $payload");
    final parts = payload.split('|');
    if (parts[0] == 'open_reminder' && parts.length >= 3) {
      final id = parts[1];
      final title = parts[2];

      if (_cachedUser != null) {
        FirebaseFirestore.instance
            .collection('users')
            .doc(_cachedUser!.uid)
            .collection('notifications')
            .doc(id)
            .update({'isRead': true}).catchError((e) {
          print("Error marking read: $e");
        });
        print("Marked read: $title");
      }

      navigatorKey.currentState!.pushReplacement(
        MaterialPageRoute(
          builder: (_) => CustomBottomNavigation(userName: userName, initialIndex: 0),
        ),
      );
    }
  }
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();