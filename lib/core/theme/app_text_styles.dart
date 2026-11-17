import 'package:flutter/material.dart';

abstract final class AppTextStyles {
  static const fontFamily = 'Lexend Deca';

  static const title = TextStyle(
    fontFamily: fontFamily,
    fontSize: 19,
    fontWeight: FontWeight.w600,
  );

  static const body = TextStyle(fontFamily: fontFamily, fontSize: 14);

  static const caption = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    color: Color(0xFF6E6A7C),
  );
}
