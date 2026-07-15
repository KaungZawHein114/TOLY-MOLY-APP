import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';

/// One row of the success checklist: what already happened (green check) or
/// what comes next (amber hourglass).
class SuccessItem {
  final String label;

  /// true → completed (green check); false → pending (amber hourglass).
  final bool done;

  const SuccessItem(this.label, {required this.done});
}

/// Celebration block for the account-created screens: an animated check
/// badge with a soft expanding halo, a headline, and a checklist card that
/// SHOWS the user where they stand ("phone verified ✓, account created ✓,
/// verification pending ⏳") instead of describing it in a paragraph —
/// visibility of system status, readable at a glance.
class SuccessState extends StatelessWidget {
  final String title;
  final List<SuccessItem> items;

  const SuccessState({super.key, required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    return Column(
      children: [
        // ── Animated check badge: halo grows + badge pops in ──
        TweenAnimationBuilder<double>(
          tween: Tween(begin: reduceMotion ? 1 : 0, end: 1),
          duration: AppMotion.slow,
          curve: Curves.easeOutBack,
          builder: (context, value, child) {
            final clamped = value.clamp(0.0, 1.0);
            return SizedBox(
              width: 120,
              height: 120,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 120 * clamped,
                    height: 120 * clamped,
                    decoration: BoxDecoration(
                      color: AppColors.success
                          .withValues(alpha: 0.10 * clamped),
                      shape: BoxShape.circle,
                    ),
                  ),
                  Container(
                    width: 92 * clamped,
                    height: 92 * clamped,
                    decoration: BoxDecoration(
                      color: AppColors.success
                          .withValues(alpha: 0.16 * clamped),
                      shape: BoxShape.circle,
                    ),
                  ),
                  Transform.scale(
                    scale: value,
                    child: Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color:
                                AppColors.success.withValues(alpha: 0.35),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.check_rounded,
                          color: AppColors.onBrand, size: 40),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          title,
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall,
        ),
        const SizedBox(height: AppSpacing.xl),
        // ── Status checklist card ──
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl, vertical: AppSpacing.sm),
          decoration: BoxDecoration(
            color: AppColors.lightSurface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.onboardingDivider),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowSm,
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              for (int i = 0; i < items.length; i++) ...[
                if (i > 0)
                  const Divider(
                      height: 1, color: AppColors.onboardingDivider),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: items[i].done
                              ? AppColors.success.withValues(alpha: 0.12)
                              : AppColors.warning.withValues(alpha: 0.14),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          items[i].done
                              ? Icons.check_rounded
                              : Icons.hourglass_top_rounded,
                          size: AppSizes.iconMd,
                          color: items[i].done
                              ? AppColors.success
                              : AppColors.warning,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(
                          items[i].label,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            height: 1.4,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
