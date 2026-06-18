import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_strings.dart';
import '../../core/routing/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// Two giant tiles: Customer | Worker. This is also the universal fallback
/// screen for any unknown route, so it must always render valid content.
class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            children: [
              const SizedBox(height: AppSpacing.md),
              const Text("🧰", style: TextStyle(fontSize: 40)),
              const SizedBox(height: AppSpacing.sm),
              Text(AppStrings.appName, style: theme.textTheme.headlineMedium),
              const SizedBox(height: AppSpacing.xs),
              Text(
                AppStrings.chooseRole,
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
              ),
              const SizedBox(height: AppSpacing.xxl + 4),
              Expanded(
                child: _RoleTile(
                  emoji: "🧑",
                  title: AppStrings.customer,
                  subtitle: AppStrings.customerMm,
                  caption: "Find trusted workers near you",
                  gradient: AppColors.tealGradient,
                  onTap: () => context.push(Routes.customerHome),
                ),
              ),
              const SizedBox(height: AppSpacing.lg + 2),
              Expanded(
                child: _RoleTile(
                  emoji: "🛠️",
                  title: AppStrings.worker,
                  subtitle: AppStrings.workerMm,
                  caption: "Get booked for jobs today",
                  gradient: AppColors.orangeGradient,
                  onTap: () => context.push(Routes.onboarding),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleTile extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final String caption;
  final Gradient gradient;
  final VoidCallback onTap;

  const _RoleTile({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.caption,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final radius = BorderRadius.circular(AppRadius.xl);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: radius,
            boxShadow: [
              BoxShadow(
                color: gradient.colors.first.withValues(alpha: 0.4),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: Row(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 60)),
                const SizedBox(width: AppSpacing.xl),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.headlineSmall
                            ?.copyWith(color: AppColors.onBrand, fontSize: 26),
                      ),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: AppColors.onBrandMuted),
                      ),
                      const SizedBox(height: AppSpacing.xs + 2),
                      Text(
                        caption,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: AppColors.onBrandMuted, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios,
                    color: AppColors.onBrand, size: AppSpacing.xl),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
