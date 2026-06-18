import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/routing/app_router.dart';

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
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Text("🧰",
                  style: const TextStyle(fontSize: 40)),
              const SizedBox(height: 8),
              Text(
                AppStrings.appName,
                style: theme.textTheme.headlineMedium
                    ?.copyWith(fontWeight: FontWeight.w900, letterSpacing: 1),
              ),
              const SizedBox(height: 4),
              Text(
                AppStrings.chooseRole,
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
              ),
              const SizedBox(height: 28),
              Expanded(
                child: _RoleTile(
                  emoji: "🧑",
                  title: AppStrings.customer,
                  subtitle: AppStrings.customerMm,
                  caption: "Find trusted workers near you",
                  gradient: AppColors.tealGradient,
                  onTap: () => context.go(Routes.customerHome),
                ),
              ),
              const SizedBox(height: 18),
              Expanded(
                child: _RoleTile(
                  emoji: "🛠️",
                  title: AppStrings.worker,
                  subtitle: AppStrings.workerMm,
                  caption: "Get booked for jobs today",
                  gradient: AppColors.orangeGradient,
                  onTap: () => context.go(Routes.onboarding),
                ),
              ),
              const SizedBox(height: 12),
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
    final radius = BorderRadius.circular(24);
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
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 60)),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        caption,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios,
                    color: Colors.white, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
