import 'package:flutter/material.dart';

import '../../../features/onboarding/onboarding_models.dart';
import '../app_progress_indicator.dart';

/// Thin alias over the design system's [AppProgressIndicator] — kept so
/// existing onboarding call sites stay unchanged while rendering the shared
/// component. New screens should use [AppProgressIndicator] directly.
class OnboardingProgressHeader extends StatelessWidget {
  final OnboardingProgress progress;

  const OnboardingProgressHeader({super.key, required this.progress});

  @override
  Widget build(BuildContext context) {
    return AppProgressIndicator(progress: progress);
  }
}
