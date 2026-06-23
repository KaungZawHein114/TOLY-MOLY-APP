import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'onboarding/read_aloud_button.dart';

/// A category card for the customer Home screen's "browse services" grid:
/// icon, name, and a compact listen button — borderless fill + soft shadow,
/// matching the look already established by SkillTile/OnboardingSelectionCard.
class ServiceCategoryCard extends StatelessWidget {
  final String emoji;
  final String label;
  final VoidCallback onTap;
  final bool selected;

  const ServiceCategoryCard({
    super.key,
    required this.emoji,
    required this.label,
    required this.onTap,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final radius = BorderRadius.circular(AppRadius.lg);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: radius,
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Container(
          decoration: BoxDecoration(
            gradient: selected ? AppColors.cardFillGradient : null,
            color: selected ? null : theme.cardColor,
            borderRadius: radius,
            boxShadow: [
              BoxShadow(
                color: selected ? AppColors.selectedShadowMd : AppColors.shadowMd,
                blurRadius: selected ? 14 : 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm, horizontal: AppSpacing.xs),
          // FittedBox is a safety net (mirrors SkillTile/OnboardingSelectionCard):
          // if a grid cell is ever shorter than the content (small phones,
          // big fonts, the added listen button), the card scales down instead
          // of overflowing.
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(emoji, style: const TextStyle(fontSize: 26)),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: AppSpacing.xxs),
                ReadAloudButton(textToRead: label, compact: true),
                if (selected) ...[
                  const SizedBox(height: AppSpacing.xxs),
                  const Icon(Icons.check_circle, color: AppColors.purple700, size: AppSizes.iconSm + 2),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
