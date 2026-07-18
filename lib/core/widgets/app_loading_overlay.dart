import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Full-screen modal loading state: dims the page and shows a spinner card
/// with an optional Burmese message. Wrap any screen body:
///
/// ```dart
/// AppLoadingOverlay(
///   visible: _isSubmitting,
///   message: OnboardingStrings.submittingLabel,
///   child: ...screen body...,
/// )
/// ```
///
/// While visible, taps are absorbed (error prevention: no double submits)
/// and the state is announced to screen readers.
class AppLoadingOverlay extends StatelessWidget {
  final bool visible;
  final String? message;
  final Widget child;

  const AppLoadingOverlay({
    super.key,
    required this.visible,
    required this.child,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Stack(
      children: [
        child,
        // AnimatedSwitcher (not Opacity on a live barrier) so the barrier is
        // fully gone from hit-testing the moment loading ends.
        AnimatedSwitcher(
          duration: AppMotion.medium,
          child: !visible
              ? const SizedBox.shrink()
              : Positioned.fill(
                  key: const ValueKey("loading-overlay"),
                  child: Semantics(
                    label: message ?? "Loading",
                    liveRegion: true,
                    child: AbsorbPointer(
                      child: ColoredBox(
                        color: AppColors.purple900.withValues(alpha: 0.45),
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.all(AppSpacing.xxl),
                            decoration: BoxDecoration(
                              color: AppColors.lightSurface,
                              borderRadius:
                                  BorderRadius.circular(AppRadius.lg),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.shadowLg,
                                  blurRadius: 24,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SizedBox(
                                  width: 36,
                                  height: 36,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 3,
                                    color: AppColors.purple700,
                                  ),
                                ),
                                if (message != null) ...[
                                  const SizedBox(height: AppSpacing.lg),
                                  Text(
                                    message!,
                                    textAlign: TextAlign.center,
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}
