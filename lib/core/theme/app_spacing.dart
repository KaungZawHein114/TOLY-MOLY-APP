import 'package:flutter/animation.dart';

/// Spacing + radius + sizing tokens — the ONLY place layout magic-numbers live.
/// Screens must use these instead of raw doubles so the whole app can be
/// re-spaced (denser, airier, different radius language) from one file.
class AppSpacing {
  AppSpacing._();

  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
  static const double huge = 40;

  /// Default screen edge padding.
  static const double screen = 16;
  /// Default card inner padding.
  static const double card = 16;
}

/// Corner-radius tokens.
class AppRadius {
  AppRadius._();

  static const double sm = 10;
  static const double md = 14;
  static const double lg = 18;
  static const double xl = 24;
  static const double pill = 999;
}

/// Common fixed sizes (avatars, buttons, controls).
class AppSizes {
  AppSizes._();

  static const double buttonHeight = 58;
  static const double avatarSm = 40;
  static const double avatar = 54;
  static const double avatarLarge = 96;
  static const double iconSm = 16;
  static const double iconMd = 22;
  static const double iconLg = 28;
}

/// Motion tokens — the ONLY place animation durations/curves live, so every
/// onboarding animation speaks the same timing language instead of ad-hoc
/// literals scattered through widget files.
class AppMotion {
  AppMotion._();

  static const Duration fast = Duration(milliseconds: 150);
  static const Duration medium = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 400);

  static const Curve enter = Curves.easeOutCubic;
  static const Curve press = Curves.easeOut;
}
