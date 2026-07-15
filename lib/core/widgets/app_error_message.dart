import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Inline error banner: icon + message on a soft red surface. Replaces bare
/// red `Text` fragments so errors are visually consistent and can't be
/// mistaken for body copy — important for low-literacy users who scan by
/// shape and color before reading.
///
/// Animates its own appearance (fade + settle) and renders nothing when
/// [message] is null, so call sites can write:
///
/// ```dart
/// AppErrorMessage(message: _phoneError),
/// ```
class AppErrorMessage extends StatelessWidget {
  final String? message;

  const AppErrorMessage({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedSize(
      duration: AppMotion.medium,
      curve: AppMotion.enter,
      alignment: Alignment.topCenter,
      child: message == null
          ? const SizedBox(width: double.infinity)
          : TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: AppMotion.medium,
              curve: AppMotion.enter,
              builder: (context, value, child) =>
                  Opacity(opacity: value, child: child),
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.only(top: AppSpacing.sm),
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                      color: AppColors.error.withValues(alpha: 0.35)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.error_outline,
                        color: AppColors.error, size: AppSizes.iconMd),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        message!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.error,
                          fontWeight: FontWeight.w600,
                          height: 1.4,
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
