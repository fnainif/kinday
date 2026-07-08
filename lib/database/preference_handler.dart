import 'package:shared_preferences/shared_preferences.dart';

class PreferenceHandler {
  static late SharedPreferences _prefs;
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static const _keyIsLogin = "isLogin";
  static const _keyLanguage = "language";
  static const _keyTheme = "app_theme";
  static const _keyHasSeenOnboarding = "has_seen_onboarding";

  static Future<void> setLogin(bool isLogin) async {
    await _prefs.setBool(_keyIsLogin, isLogin);
  }

  static bool get isLogin {
    return _prefs.getBool(_keyIsLogin) ?? false;
  }

  static Future<void> setHasSeenOnboarding(bool hasSeen) async {
    await _prefs.setBool(_keyHasSeenOnboarding, hasSeen);
  }

  static bool get hasSeenOnboarding {
    return _prefs.getBool(_keyHasSeenOnboarding) ?? false;
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

  static const _keyAiBreakdownCount = "ai_breakdown_count";
  static const _keyAiBreakdownLastDate = "ai_breakdown_last_date";
  static const int maxAiUsagePerDay = 5;

  static bool checkAndIncrementAiUsage() {
    final now = DateTime.now();
    final todayStr = "${now.year}-${now.month}-${now.day}";
    final lastDate = _prefs.getString(_keyAiBreakdownLastDate) ?? "";

    if (lastDate != todayStr) {
      _prefs.setString(_keyAiBreakdownLastDate, todayStr);
      _prefs.setInt(_keyAiBreakdownCount, 1);
      return true;
    }

    final currentCount = _prefs.getInt(_keyAiBreakdownCount) ?? 0;
    if (currentCount >= maxAiUsagePerDay) {
      return false;
    }

    _prefs.setInt(_keyAiBreakdownCount, currentCount + 1);
    return true;
  }

  static int getRemainingAiUsage() {
    final now = DateTime.now();
    final todayStr = "${now.year}-${now.month}-${now.day}";
    final lastDate = _prefs.getString(_keyAiBreakdownLastDate) ?? "";

    if (lastDate != todayStr) {
      return maxAiUsagePerDay;
    }

    final currentCount = _prefs.getInt(_keyAiBreakdownCount) ?? 0;
    final remaining = maxAiUsagePerDay - currentCount;
    return remaining < 0 ? 0 : remaining;
  }

  static const _keyIsPremium = "is_premium";

  static bool get isPremium {
    return _prefs.getBool(_keyIsPremium) ?? false;
  }

  static Future<void> setPremium(bool value) async {
    await _prefs.setBool(_keyIsPremium, value);
  }
}

