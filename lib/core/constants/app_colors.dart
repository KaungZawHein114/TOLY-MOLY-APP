import 'package:flutter/material.dart';

/// TOLY MOLY brand palette.
/// Electric Teal (#00BFA5) + Warm Orange (#FF6D00).
class AppColors {
  AppColors._();

  static const Color teal = Color(0xFF00BFA5);
  static const Color tealDark = Color(0xFF00897B);
  static const Color tealLight = Color(0xFF5DF2D6);

  static const Color orange = Color(0xFFFF6D00);
  static const Color orangeDark = Color(0xFFE65100);
  static const Color orangeLight = Color(0xFFFF9E40);

  // Neutrals — light theme
  static const Color lightBg = Color(0xFFF7F9FB);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightText = Color(0xFF1A2228);
  static const Color lightTextMuted = Color(0xFF6B7884);

  // Neutrals — dark theme
  static const Color darkBg = Color(0xFF0E1417);
  static const Color darkSurface = Color(0xFF1A2228);
  static const Color darkText = Color(0xFFF2F5F7);
  static const Color darkTextMuted = Color(0xFF9AA7B0);

  // Semantic
  static const Color star = Color(0xFFFFC107);
  static const Color success = Color(0xFF2ECC71);
  static const Color danger = Color(0xFFE74C3C);

  static const LinearGradient tealGradient = LinearGradient(
    colors: [teal, tealDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient orangeGradient = LinearGradient(
    colors: [orange, orangeDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
