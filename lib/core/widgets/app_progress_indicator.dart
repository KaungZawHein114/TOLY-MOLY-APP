import 'package:flutter/material.dart';

import '../../features/onboarding/onboarding_models.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Stepped onboarding progress: Burmese step label ("အဆင့် ၂ / ၄") plus one
/// pill segment per step. Segments — not a continuous bar — because they can
/// be *counted*: a first-time user sees "four pieces, two filled" without
/// needing to judge a percentage (recognition over recall).
///
/// The active segment animates its fill so advancing a step is visibly
/// acknowledged (visibility of system status).
class AppProgressIndicator extends StatelessWidget {
  final OnboardingProgress progress;

  const AppProgressIndicator({super.key, required this.progress});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      label: "${progress.stepLabel}, ${(progress.percent * 100).round()}%",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            progress.stepLabel,
            style: theme.textTheme.titleMedium
                ?.copyWith(color: AppColors.purple700),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              for (int i = 1; i <= progress.totalSteps; i++) ...[
                if (i > 1) const SizedBox(width: AppSpacing.xs + 2),
                Expanded(
                  child: AnimatedContainer(
                    duration: AppMotion.slow,
                    curve: AppMotion.enter,
                    height: 8,
                    decoration: BoxDecoration(
                      color: i <= progress.step
                          ? AppColors.purple700
                          : AppColors.purple100,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
