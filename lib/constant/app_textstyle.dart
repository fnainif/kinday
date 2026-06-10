import 'package:flutter/material.dart';
import 'package:kinday/constant/app_colors.dart';

class AppTextStyles {
  static const TextStyle greeting = TextStyle(
    fontFamily: "Quicksand",
    fontSize: 20,
    letterSpacing: 0,

    fontWeight: FontWeight.bold,
    color: AppColors.button,
  );

  static const TextStyle username = TextStyle(
    fontFamily: "Nunito",
    fontSize: 30,
    letterSpacing: 0,

    color: Colors.white,
  );

  static const TextStyle affirmation = TextStyle(
    fontFamily: "Nunito",
    fontSize: 15,
    letterSpacing: 0,

    fontWeight: FontWeight.bold,
    color: AppColors.button,
  );

  static const TextStyle bodytext = TextStyle(
    fontFamily: "Nunito",
    color: AppColors.button,
    letterSpacing: 0,
  );
}
