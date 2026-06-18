import 'package:flutter/material.dart';

/// TOLY MOLY color tokens — the ONLY place raw color values live.
/// Screens must reference these tokens (or `Theme.of(context)`), never hex.
/// Swapping the palette here is enough to re-skin the whole app.
class AppColors {
  AppColors._();

  // Brand
  static const Color teal = Color(0xFF00BFA5);
  static const Color tealDark = Color(0xFF00897B);
  static const Color tealLight = Color(0xFF5DF2D6);

  static const Color orange = Color(0xFFFF6D00);
  static const Color orangeDark = Color(0xFFE65100);
  static const Color orangeLight = Color(0xFFFF9E40);

  // Foreground used on top of brand gradients/solid brand fills.
  static const Color onBrand = Color(0xFFFFFFFF);
  static Color onBrandMuted = const Color(0xFFFFFFFF).withValues(alpha: 0.9);

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

  // Elevation shadow (used by cards, raised tiles, splash logo).
  static Color shadow = const Color(0xFF000000).withValues(alpha: 0.2);

  // Gradients
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
