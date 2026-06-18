import 'package:flutter/material.dart';

import '../data/demo_data.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// A horizontal worker card: emoji avatar, name, skill, rating, distance, rate.
/// Data-driven: it renders whatever [Worker] it is given. Tapping is delegated
/// to the caller, and all styling comes from theme tokens.
class WorkerCard extends StatelessWidget {
  final Worker worker;
  final VoidCallback onTap;

  const WorkerCard({super.key, required this.worker, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs + 2),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              _Avatar(emoji: worker.emoji, available: worker.isAvailableNow),
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
                      "${worker.skill} • ${worker.experience}",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.hintColor),
                    ),
                    const SizedBox(height: AppSpacing.xs + 2),
                    Row(
                      children: [
                        Icon(Icons.location_on,
                            size: 14, color: theme.hintColor),
                        const SizedBox(width: AppSpacing.xxs),
                        Text("${worker.distanceMiles} mi",
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: theme.hintColor)),
                        const SizedBox(width: AppSpacing.md),
                        Flexible(
                          child: Text(
                            "${worker.hourlyRateMmk} MMK/hr",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.orange,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xs + 2),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String emoji;
  final bool available;
  const _Avatar({required this.emoji, required this.available});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: AppSizes.avatar,
          height: AppSizes.avatar,
          decoration: BoxDecoration(
            color: AppColors.teal.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(emoji, style: const TextStyle(fontSize: 26)),
        ),
        if (available)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: AppColors.success,
                shape: BoxShape.circle,
                border: Border.all(
                    color: Theme.of(context).cardColor, width: 2),
              ),
            ),
          ),
      ],
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
