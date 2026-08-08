import 'package:flutter/material.dart';

import '../data/demo_data.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'modern_service_card.dart';

/// A horizontal worker card: person avatar, name, trust badge, rating,
/// distance, completed tasks, verification. No pricing —
/// Toly Moly is a task-based, not a time-based, marketplace; clients pick
/// workers on trust/skill/availability, never on an hourly rate.
/// Data-driven: it renders whatever [Worker] it is given. Tapping is delegated
/// to the caller, and all styling comes from theme tokens. Scales down
/// slightly on press for tactile feedback, matching the category/onboarding
/// cards elsewhere in the app.
class WorkerCard extends StatefulWidget {
  final Worker worker;
  final VoidCallback onTap;

  const WorkerCard({super.key, required this.worker, required this.onTap});

  @override
  State<WorkerCard> createState() => _WorkerCardState();
}

class _WorkerCardState extends State<WorkerCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final worker = widget.worker;
    final distanceKm = (worker.distanceMiles * 1.609).toStringAsFixed(1);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: AppMotion.fast,
        curve: AppMotion.press,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap,
          onTapDown: (_) => setState(() => _pressed = true),
          onTapCancel: () => setState(() => _pressed = false),
          onTapUp: (_) => setState(() => _pressed = false),
          child: ModernServiceCard(
            child: Row(
              children: [
                const _Avatar(),
                const SizedBox(width: AppSpacing.md + 2),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              worker.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleMedium,
                            ),
                          ),
                          const Icon(Icons.star,
                              color: AppColors.star, size: AppSizes.iconSm),
                          const SizedBox(width: AppSpacing.xxs),
                          Text(worker.rating.toString(),
                              style: theme.textTheme.bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.w600)),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        worker.skill,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: theme.hintColor),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      TrustBadgePill(tier: worker.currentTier),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        children: [
                          Icon(Icons.location_on,
                              size: 14, color: theme.hintColor),
                          const SizedBox(width: AppSpacing.xxs),
                          Text("$distanceKm km",
                              style: theme.textTheme.bodySmall
                                  ?.copyWith(color: theme.hintColor)),
                          const SizedBox(width: AppSpacing.md),
                          Flexible(
                            child: Text(
                              "${worker.completedTasks} Tasks",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall
                                  ?.copyWith(color: theme.hintColor),
                            ),
                          ),
                          if (worker.isVerified) ...[
                            const SizedBox(width: AppSpacing.xs),
                            const Icon(Icons.verified,
                                size: 14, color: AppColors.success),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.xs + 2),
                Icon(Icons.chevron_right, color: theme.hintColor),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Client-facing trust badge pill — derives its label from [trustBadgeFor];
/// never shows the raw tier number.
class TrustBadgePill extends StatelessWidget {
  final int tier;
  const TrustBadgePill({super.key, required this.tier});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm, vertical: AppSpacing.xxs),
      decoration: BoxDecoration(
        color: AppColors.purple100,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        "🏅 ${trustBadgeFor(tier)}",
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.purple700,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppSizes.avatar,
      height: AppSizes.avatar,
      decoration: BoxDecoration(
        color: AppColors.purple100,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      alignment: Alignment.center,
      child: const Icon(
        Icons.person_rounded,
        color: AppColors.purple700,
        size: AppSizes.iconLg,
      ),
    );
  }
}

/// A small colored status badge for bookings (Completed / Active / Pending).
/// The status->color mapping lives here so screens stay free of style rules.
class StatusBadge extends StatelessWidget {
  final String status;
  const StatusBadge({super.key, required this.status});

  static Color colorFor(String status) {
    switch (status) {
      case "Completed":
        return AppColors.success;
      case "Active":
        return AppColors.teal;
      default:
        return AppColors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = colorFor(status);
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm + 2, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        status,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}
