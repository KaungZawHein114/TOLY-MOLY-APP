import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';

/// Full-width, tall role card for the dedicated role-choice step. The card IS
/// the action (no separate continue button) — one tap answers the only
/// question on the screen, so the biggest decision gets the biggest target
/// (Fitts) and the screen holds exactly one choice (Hick).
class RoleSelectionCard extends StatelessWidget {
  final String emoji;
  final String label;
  final String sublabel;
  final bool selected;
  final VoidCallback onTap;

  const RoleSelectionCard({
    super.key,
    required this.emoji,
    required this.label,
    required this.sublabel,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final radius = BorderRadius.circular(AppRadius.lg);

    return Semantics(
      label: "$label — $sublabel",
      button: true,
      selected: selected,
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        child: InkWell(
          borderRadius: radius,
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          child: AnimatedContainer(
            duration: AppMotion.fast,
            curve: AppMotion.press,
            constraints: const BoxConstraints(minHeight: 112),
            padding: const EdgeInsets.all(AppSpacing.xl),
            decoration: BoxDecoration(
              color: selected ? AppColors.purple100 : AppColors.lightSurface,
              borderRadius: radius,
              border: Border.all(
                color:
                    selected ? AppColors.purple700 : AppColors.onboardingDivider,
                width: selected ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: selected
                      ? AppColors.selectedShadowMd
                      : AppColors.shadowSm,
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                // Big pictorial anchor — the card is recognizable before a
                // single word is read.
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: selected ? AppColors.onBrand : AppColors.blue100,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(emoji, style: const TextStyle(fontSize: 32)),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        label,
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: selected
                              ? AppColors.purple700
                              : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        sublabel,
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Icon(
                  selected
                      ? Icons.check_circle
                      : Icons.arrow_forward_ios_rounded,
                  color: selected
                      ? AppColors.purple700
                      : AppColors.textSecondary,
                  size: selected ? AppSizes.iconLg : AppSizes.iconSm,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
