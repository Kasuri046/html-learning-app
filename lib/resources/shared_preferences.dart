import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefHelper {
  static const String _introSeenKey = "isIntroSeen";
  static const String _quizCompletedKey = "isQuizCompleted";
  static const String _isLoggedInKey = "isLoggedIn";
  static const String _userNameKey = "userName";

  static Future<void> setIntroSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_introSeenKey, true);
  }

  static Future<bool> isIntroSeen() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_introSeenKey) ?? false;
  }

  static Future<void> setQuizCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_quizCompletedKey, true);
  }

  static Future<bool> isQuizCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_quizCompletedKey) ?? false;
  }

  static Future<void> setLoggedIn(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isLoggedInKey, value);
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isLoggedInKey) ?? false;
  }

  static Future<void> setUserName(String userName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userNameKey, userName);
  }

  static Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userNameKey);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    // Fetch values before clearing
    final bool isLoggedInValue = await isLoggedIn();
    final bool introSeen = await isIntroSeen();
    final bool quizCompleted = await isQuizCompleted();
    final String userName = await getUserName() ?? '';
    await prefs.clear();
    // Restore non-progress keys
    await prefs.setBool(_introSeenKey, introSeen);
    await prefs.setBool(_quizCompletedKey, quizCompleted);
    await prefs.setBool(_isLoggedInKey, isLoggedInValue);
    await prefs.setString(_userNameKey, userName);
    print("DEBUG: Cleared SharedPreferences, retained non-progress keys");
  }

  static Future<void> clearProgressData(String? uid) async {
    final prefs = await SharedPreferences.getInstance();
    if (uid != null) {
      for (var key in await prefs.getKeys()) {
        if (key.startsWith('topicFiles_$uid')) {
          await prefs.remove(key);
        }
      }
    }
    print("DEBUG: Cleared progress data for UID: $uid");
  }

  // Added for complete SharedPreferences cleanup during account deletion
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    print("DEBUG: Completely cleared SharedPreferences");
  }
}