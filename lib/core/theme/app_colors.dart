import 'package:flutter/material.dart';

import '../constants/bmi_thresholds.dart';

/// Calm health palette: teal/sage primary, coral accent for attention.
class AppColors {
  AppColors._();

  // Brand (calm health palette)
  static const Color teal = Color(0xFF0F6B6B);
  static const Color sage = Color(0xFF7BAE8D);
  static const Color coral = Color(0xFFE07A5F);
  static const Color softSand = Color(0xFFF3F6F4);
  static const Color deepInk = Color(0xFF1A2332);
  static const Color mist = Color(0xFFE8EEED);
  @Deprecated('Use softSand')
  static const Color softCream = softSand;

  // BMI category colors (always paired with icons/labels in UI)
  static const Color underweight = Color(0xFF5B8DEF);
  static const Color normal = Color(0xFF3D9B6E);
  static const Color overweight = Color(0xFFE9A825);
  static const Color obese = Color(0xFFD64545);

  static const ColorScheme lightScheme = ColorScheme.light(
    primary: teal,
    onPrimary: Colors.white,
    primaryContainer: Color(0xFFB8E0E1),
    onPrimaryContainer: Color(0xFF003D40),
    secondary: sage,
    onSecondary: Colors.white,
    secondaryContainer: Color(0xFFD4E8D6),
    onSecondaryContainer: Color(0xFF1B3A22),
    tertiary: coral,
    onTertiary: Colors.white,
    tertiaryContainer: Color(0xFFFFDBD0),
    onTertiaryContainer: Color(0xFF5C1F10),
    error: Color(0xFFBA1A1A),
    onError: Colors.white,
    surface: softSand,
    onSurface: deepInk,
    surfaceContainerHighest: mist,
    outline: Color(0xFF6F7978),
  );

  static const ColorScheme darkScheme = ColorScheme.dark(
    primary: Color(0xFF4DB6B8),
    onPrimary: Color(0xFF003739),
    primaryContainer: Color(0xFF005052),
    onPrimaryContainer: Color(0xFFB8E0E1),
    secondary: Color(0xFF9BC4A0),
    onSecondary: Color(0xFF0F2E16),
    secondaryContainer: Color(0xFF274B2E),
    onSecondaryContainer: Color(0xFFD4E8D6),
    tertiary: Color(0xFFFFB4A0),
    onTertiary: Color(0xFF5C1F10),
    tertiaryContainer: Color(0xFF7A3A28),
    onTertiaryContainer: Color(0xFFFFDBD0),
    error: Color(0xFFFFB4AB),
    onError: Color(0xFF690005),
    surface: Color(0xFF121A18),
    onSurface: Color(0xFFE1E3E2),
    surfaceContainerHighest: Color(0xFF2A3333),
    outline: Color(0xFF899392),
  );

  static Color colorForCategory(BMICategory category) {
    switch (category) {
      case BMICategory.underweight:
        return underweight;
      case BMICategory.normal:
        return normal;
      case BMICategory.overweight:
        return overweight;
      case BMICategory.obese:
        return obese;
    }
  }

  static IconData iconForCategory(BMICategory category) {
    switch (category) {
      case BMICategory.underweight:
        return Icons.trending_down_rounded;
      case BMICategory.normal:
        return Icons.check_circle_outline_rounded;
      case BMICategory.overweight:
        return Icons.trending_up_rounded;
      case BMICategory.obese:
        return Icons.warning_amber_rounded;
    }
  }

  static String labelForCategory(BMICategory category) => category.label;
}
