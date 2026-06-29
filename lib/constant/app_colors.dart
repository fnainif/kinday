import 'package:flutter/material.dart';
import 'package:kinday/database/preference_handler.dart';

class AppThemeData {
  final Color background;
  final Color button;
  final Color container1;
  final Color containerline1;
  final Color container2;
  final Color containerline2;
  final Color normaltext;
  final Color background2;

  const AppThemeData({
    required this.background,
    required this.button,
    required this.container1,
    required this.containerline1,
    required this.container2,
    required this.containerline2,
    required this.normaltext,
    required this.background2,
  });
}

class AppColors {
  static const Map<String, AppThemeData> themes = {
    "Lavender Dreams": AppThemeData(
      background: Color(0xFF9999ec),
      background2: Colors.white,
      button: Color(0xFF5852A0),
      container1: Color(0xFFb6a1f0),
      containerline1: Color(0xFF987ee0),
      container2: Color(0xFFa6a6f6),
      containerline2: Color(0xFF7971cb),
      normaltext: Color.fromARGB(255, 111, 75, 179),
    ),
    "Sakura Bloom": AppThemeData(
      background: Color(0xFFFFD1DC),
      background2: Colors.white,
      button: Color(0xFFD67B9E),
      container1: Color(0xFFFFE3E8),
      containerline1: Color(0xFFEAA6B8),
      container2: Color(0xFFFFC0CB),
      containerline2: Color(0xFFE48EA6),
      normaltext: Color.fromARGB(255, 190, 85, 120),
    ),
    "Matcha Garden": AppThemeData(
      background: Color(0xFFE2F0D9),
      background2: Colors.white,
      button: Color(0xFF558252),
      container1: Color.fromARGB(255, 206, 237, 211),
      containerline1: Color(0xFFB1D0A8),
      container2: Color(0xFFC5E0B4),
      containerline2: Color(0xFF8BB585),
      normaltext: Color.fromARGB(255, 51, 111, 53),
    ),
    "Sky Blue": AppThemeData(
      background: Color(0xFFD0ECFC),
      background2: Colors.white,
      button: Color(0xFF4388B9),
      container1: Color.fromARGB(255, 232, 254, 254),
      containerline1: Color(0xFFA1D4F7),
      container2: Color(0xFFBBE3FC),
      containerline2: Color(0xFF74BAE7),
      normaltext: Color.fromARGB(255, 13, 70, 168),
    ),
    "Peach Cream": AppThemeData(
      background: Color(0xFFFFE5D9),
      background2: Colors.white,
      button: Color(0xFFE07A5F),
      container1: Color(0xFFFFF1EC),
      containerline1: Color(0xFFF4B2A1),
      container2: Color(0xFFFCD5C6),
      containerline2: Color(0xFFE78F7A),
      normaltext: Color.fromARGB(255, 249, 114, 73),
    ),
    "Moonlight Lavender": AppThemeData(
      background: Color(0xFF2E2A4F),
      background2: Colors.black87,
      button: Color(0xFF8E8CD8),
      container1: Color(0xFF3F3A66),
      containerline1: Color(0xFF5E5894),
      container2: Color(0xFF353059),
      containerline2: Color(0xFF4C4580),
      normaltext: Colors.white,
    ),
    "Twilight Blue": AppThemeData(
      background: Color(0xFF1D2A44),
      background2: Colors.black87,
      button: Color(0xFF5C93E6),
      container1: Color(0xFF283A5C),
      containerline1: Color(0xFF3E5A8E),
      container2: Color(0xFF223250),
      containerline2: Color(0xFF334B76),
      normaltext: Colors.white,
    ),
    "Midnight Forest": AppThemeData(
      background: Color(0xFF1E2F23),
      background2: Colors.black87,
      button: Color(0xFF63A375),
      container1: Color(0xFF2B4031),
      containerline1: Color(0xFF3D5C46),
      container2: Color(0xFF233528),
      containerline2: Color(0xFF314D3A),
      normaltext: Colors.white,
    ),
  };

  static final ValueNotifier<String> themeNotifier = ValueNotifier<String>(
    "Lavender Dreams",
  );

  static void init() {
    themeNotifier.value = PreferenceHandler.theme;
  }

  static AppThemeData get currentTheme =>
      themes[themeNotifier.value] ?? themes["Lavender Dreams"]!;

  static Color get background => currentTheme.background;
  static Color get background2 => currentTheme.background2;
  static Color get button => currentTheme.button;
  static Color get container1 => currentTheme.container1;
  static Color get containerline1 => currentTheme.containerline1;
  static Color get container2 => currentTheme.container2;
  static Color get containerline2 => currentTheme.containerline2;
  static Color get normaltext => currentTheme.normaltext;

  static void setTheme(String themeName) {
    if (themes.containsKey(themeName)) {
      PreferenceHandler.setTheme(themeName);
      themeNotifier.value = themeName;
    }
  }
}
