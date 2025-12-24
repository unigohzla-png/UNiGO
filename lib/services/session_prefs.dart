import 'package:shared_preferences/shared_preferences.dart';

class SessionPrefs {
  static const _kRememberMe = 'remember_me';
  static const _kLastEmail = 'last_email';

  static Future<bool> rememberMe() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getBool(_kRememberMe) ?? false; // default = false
  }

  static Future<void> setRememberMe(bool value) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setBool(_kRememberMe, value);
  }

  static Future<String?> lastEmail() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getString(_kLastEmail);
  }

  static Future<void> setLastEmail(String value) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kLastEmail, value);
  }

  static Future<void> clearLastEmail() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove(_kLastEmail);
  }
}
