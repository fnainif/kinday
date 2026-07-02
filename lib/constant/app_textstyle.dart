import 'package:flutter/material.dart';
import 'package:kinday/constant/app_colors.dart';

class AppTextStyles {
  static TextStyle get greeting => TextStyle(
        fontFamily: "Quicksand",
        fontSize: 20,
        letterSpacing: 0,
        fontWeight: FontWeight.bold,
        color: AppColors.button,
      );

  static TextStyle get username => const TextStyle(
        fontFamily: "Nunito",
        fontSize: 30,
        letterSpacing: 0,
        color: Colors.white,
      );

  static TextStyle get affirmation => TextStyle(
        fontFamily: "Nunito",
        fontSize: 15,
        letterSpacing: 0,
        fontWeight: FontWeight.bold,
        color: AppColors.button,
      );

  static TextStyle get bodytext => TextStyle(
        fontFamily: "Nunito",
        color: AppColors.button,
        letterSpacing: 0,
      );
}
