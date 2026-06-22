import 'package:flutter/material.dart';

import '../../../features/onboarding/onboarding_models.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';

/// Step label + linear progress bar shown at the top of every onboarding step.
class OnboardingProgressHeader extends StatelessWidget {
  final OnboardingProgress progress;

  const OnboardingProgressHeader({super.key, required this.progress});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: "${progress.stepLabel}, ${(progress.percent * 100).round()}%",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            progress.stepLabel,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(color: AppColors.purple700),
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: LinearProgressIndicator(
              value: progress.percent,
              minHeight: 8,
              backgroundColor: AppColors.purple100,
              color: AppColors.purple700,
            ),
          ),
        ],
      ),
    );
  }
}
