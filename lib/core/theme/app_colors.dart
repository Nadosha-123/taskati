import 'package:flutter/material.dart';

abstract final class AppColors {
  static const primary = Color(0xFF5F33E1);
  static const secondaryText = Color(0xFF6E6A7C);
  static const darkText = Color(0xFF24252C);
  static const lightBackground = Color(0xFFFFFFFF);
  static const darkBackground = Color(0xFF24252C);
  static const lightSurface = Color(0xFFFFFFFF);
  static const darkSurface = Color(0xFF24252C);
  static const lightAccent = Color(0xFFEDE8FF);
  static const avatar = Color(0xFF786E9F);
  static const completedText = Color(0xFFAB94FF);
  static const inProgressBackground = Color(0xFFFFE9E1);
  static const inProgressText = Color(0xFFFF7D53);
  static const delete = Color(0xFFE53935);
  static const complete = Color(0xFF2E9D62);
  static const completed = Color(0xFF5F33E1);
  static const inProgress = Color(0xFFFF7D53);

  static const cardShadow = BoxShadow(
    color: Color(0x0A000000),
    blurRadius: 32,
    offset: Offset(0, 4),
  );
}
