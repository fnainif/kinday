import 'package:shared_preferences/shared_preferences.dart';

class PreferenceHandler {
  static late SharedPreferences _prefs;
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static const _keyIsLogin = "isLogin";
  static const _keyLanguage = "language";
  static const _keyTheme = "app_theme";

  static Future<void> setLogin(bool isLogin) async {
    await _prefs.setBool(_keyIsLogin, isLogin);
  }

  static bool get isLogin {
    return _prefs.getBool(_keyIsLogin) ?? false;
  }

  static Future<void> logOut() async {
    await _prefs.remove(_keyIsLogin);
  }

  static Future<void> setLanguage(String languageCode) async {
    await _prefs.setString(_keyLanguage, languageCode);
  }

  static String get language {
    return _prefs.getString(_keyLanguage) ?? "en";
  }

  static Future<void> setTheme(String themeName) async {
    await _prefs.setString(_keyTheme, themeName);
  }

  static String get theme {
    return _prefs.getString(_keyTheme) ?? "Lavender Dreams";
  }
}
