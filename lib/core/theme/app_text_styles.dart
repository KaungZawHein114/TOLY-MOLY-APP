import 'package:flutter/material.dart';

/// Typography tokens — sizes/weights only, NO color.
/// Color is applied by the theme (light/dark) or by `.copyWith(color:)` for
/// text drawn on brand gradients. Screens reference these tokens (directly or
/// via `Theme.of(context).textTheme`) so the type ramp can be redesigned here
/// without touching any screen.
class AppTextStyles {
  AppTextStyles._();

  static const TextStyle displayLarge =
      TextStyle(fontSize: 34, fontWeight: FontWeight.w900, letterSpacing: 1.5);

  static const TextStyle headlineMedium =
      TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: 1);

  static const TextStyle headlineSmall =
      TextStyle(fontSize: 22, fontWeight: FontWeight.w900);

  static const TextStyle titleLarge =
      TextStyle(fontSize: 20, fontWeight: FontWeight.w800);

  static const TextStyle titleMedium =
      TextStyle(fontSize: 16, fontWeight: FontWeight.w700);

  static const TextStyle titleSmall =
      TextStyle(fontSize: 14, fontWeight: FontWeight.w600);

  static const TextStyle bodyLarge = TextStyle(fontSize: 16, height: 1.4);

  static const TextStyle bodyMedium = TextStyle(fontSize: 14, height: 1.35);

  static const TextStyle bodySmall = TextStyle(fontSize: 12);

  static const TextStyle label =
      TextStyle(fontSize: 13, fontWeight: FontWeight.w600);

  static const TextStyle button =
      TextStyle(fontSize: 17, fontWeight: FontWeight.w700, letterSpacing: 0.3);

  /// Builds a Material [TextTheme] from these tokens, applying the given
  /// foreground [color]. Used by AppTheme for both light and dark modes.
  static TextTheme themed(Color color) => TextTheme(
        displayLarge: displayLarge.copyWith(color: color),
        headlineMedium: headlineMedium.copyWith(color: color),
        headlineSmall: headlineSmall.copyWith(color: color),
        titleLarge: titleLarge.copyWith(color: color),
        titleMedium: titleMedium.copyWith(color: color),
        titleSmall: titleSmall.copyWith(color: color),
        bodyLarge: bodyLarge.copyWith(color: color),
        bodyMedium: bodyMedium.copyWith(color: color),
        bodySmall: bodySmall.copyWith(color: color),
        labelLarge: button.copyWith(color: color),
        labelMedium: label.copyWith(color: color),
      );
}
