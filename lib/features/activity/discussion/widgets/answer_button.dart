import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

/// The one button style used to answer a question inside a bubble.
///
/// Always a word plus an icon, never an icon alone, and never smaller than
/// 48dp — these are the taps an elderly or low-literacy user has to make.
class AnswerButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  /// Primary = the expected/positive answer.
  final bool primary;

  const AnswerButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    this.primary = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
          decoration: BoxDecoration(
            color: primary ? AppColors.purple700 : AppColors.lightBg,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: primary
                ? null
                : Border.all(color: AppColors.onboardingDivider, width: 1.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: AppSizes.iconMd,
                color: primary ? AppColors.onBrand : AppColors.textSecondary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: primary ? AppColors.onBrand : AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
