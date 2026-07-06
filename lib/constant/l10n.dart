import 'package:flutter/material.dart';
import 'package:kinday/constant/app_dictionary.dart';
import 'package:kinday/database/preference_handler.dart';

class L10n {
  static final ValueNotifier<String> languageNotifier = ValueNotifier<String>("en");

  static void init() {
    languageNotifier.value = PreferenceHandler.language;
  }

  static String get lang => languageNotifier.value;
  
  static bool get isEn => lang == "en";
  static bool get isId => lang == "id";

  static String tr(String enVal, [String? idVal]) {
    if (isEn) return enVal;
    final dictTranslation = AppDictionary.translate(enVal);
    if (dictTranslation != null) return dictTranslation;
    return idVal ?? enVal;
  }

  static void setLanguage(String code) {
    PreferenceHandler.setLanguage(code);
    languageNotifier.value = code;
  }
}
