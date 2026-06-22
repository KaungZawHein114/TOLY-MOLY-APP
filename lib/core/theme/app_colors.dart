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

  // Pho Wa Yoke mascot identity
  static const Color brandPurple = Color(0xFF2E266D);
  static const Color communityBlue = Color(0xFFBDD7FF);
  static const Color thanakaGold = Color(0xFFD8B36A);

  // Canonical onboarding palette (see CLAUDE.md "Canonical color system").
  // purple700 == brandPurple, blue500 == communityBlue — aliased, not duplicated.
  static const Color purple900 = Color(0xFF1D1847);
  static const Color purple700 = brandPurple;
  static const Color purple500 = Color(0xFF5549A3);
  static const Color purple300 = Color(0xFF8B84D6);
  static const Color purple100 = Color(0xFFE7E4FF);
  static const Color blue500 = communityBlue;
  static const Color blue300 = Color(0xFFDCEAFF);
  static const Color blue100 = Color(0xFFF2F7FF);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color textPrimary = Color(0xFF1F1F1F);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color onboardingDivider = Color(0xFFE5E7EB);

  static const LinearGradient purpleGradient = LinearGradient(
    colors: [purple500, purple900],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

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
  // Soft shadow for unselected category/choice cards (borderless — selection
  // is communicated through fill + this slightly stronger tinted shadow).
  static Color cardShadow = const Color(0xFF000000).withValues(alpha: 0.05);
  static Color selectedCardShadow = brandPurple.withValues(alpha: 0.18);
  // Soft depth tiers — replaces flat single-shadow cards with a small
  // elevation scale. cardShadow/selectedCardShadow above are kept for any
  // existing call sites; new onboarding widgets use these tiers instead.
  static Color shadowSm = const Color(0xFF000000).withValues(alpha: 0.04);
  static Color shadowMd = const Color(0xFF000000).withValues(alpha: 0.08);
  static Color shadowLg = const Color(0xFF000000).withValues(alpha: 0.14);
  static Color selectedShadowMd = brandPurple.withValues(alpha: 0.22);

  // Soft card-fill gradients (selected/elevated surfaces) — derived strictly
  // from the existing purple/blue scale, not new hues.
  static const LinearGradient cardFillGradient = LinearGradient(
    colors: [purple100, purple300],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient guidanceSurfaceGradient = LinearGradient(
    colors: [blue100, blue300],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

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
