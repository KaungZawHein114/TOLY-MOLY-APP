import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// The TOLY MOLY logo badge + Burmese wordmark, sized for headers on brand
/// (purple) surfaces. One canonical rendering so every screen's brand mark
/// is identical — extracted from the onboarding scaffold's hand-rolled row.
class AppLogoHeader extends StatelessWidget {
  /// Badge diameter; wordmark scales with the theme's text styles.
  final double size;

  /// Hide the wordmark for tight layouts (icon-only badge).
  final bool showWordmark;

  const AppLogoHeader({super.key, this.size = 32, this.showWordmark = true});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Light backdrop badge keeps the logo readable on any header color —
        // its own dark-navy tones vanish against purple900 otherwise.
        Container(
          width: size,
          height: size,
          padding: EdgeInsets.all(size / 8),
          decoration: const BoxDecoration(
            color: AppColors.onBrand,
            shape: BoxShape.circle,
          ),
          child: Image.asset("assets/logo_circle.png"),
        ),
        if (showWordmark) ...[
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            child: Text(
              "တိုလီမိုလီ",
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleLarge?.copyWith(
                color: AppColors.onBrand,
                letterSpacing: 1,
                fontFamily: "Myanmar Thuriya",
                fontSize: 18,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
