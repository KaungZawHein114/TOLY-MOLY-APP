import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../activity_chat.dart';

/// What both sides are actually agreeing about, pinned to the top of the
/// workspace so nobody has to scroll back to remember the budget or the time.
///
/// It watches [discussionTaskProvider], so an accepted schedule card updates
/// this header in the same frame.
class DiscussionSummaryCard extends ConsumerWidget {
  final ActivityRole viewerRole;

  const DiscussionSummaryCard({super.key, required this.viewerRole});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final task = ref.watch(discussionTaskProvider);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: AppColors.purpleGradient,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(color: AppColors.shadowMd, blurRadius: AppSpacing.md),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  task.skillLabel,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AppColors.onBrand,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (task.isUrgent)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm, vertical: AppSpacing.xxs),
                  decoration: BoxDecoration(
                    color: AppColors.warning,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.bolt_rounded,
                          size: AppSizes.iconSm, color: AppColors.textPrimary),
                      const SizedBox(width: AppSpacing.xxs),
                      Text(
                        'အမြန်လိုအပ်',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _Party(
                  emoji: kClientEmoji,
                  role: 'အလုပ်ရှင်',
                  name: kDiscussionClientName,
                  isYou: viewerRole == ActivityRole.client,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _Party(
                  emoji: kTaskerEmoji,
                  role: 'ဝန်ဆောင်မှုပေးသူ',
                  name: kDiscussionTaskerName,
                  isYou: viewerRole == ActivityRole.tasker,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.onBrand.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Column(
              children: [
                _SummaryLine(
                  icon: Icons.event_outlined,
                  label: 'ချိန်းဆိုချိန်',
                  value: '${task.date} · ${task.timeSlot}',
                ),
                const SizedBox(height: AppSpacing.sm),
                _SummaryLine(
                  icon: Icons.place_outlined,
                  label: 'နေရာ',
                  value: task.location,
                ),
                const SizedBox(height: AppSpacing.sm),
                _SummaryLine(
                  icon: Icons.payments_outlined,
                  label: 'သဘောတူဈေး',
                  value: formatMmk(task.budgetMmk),
                  emphasize: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Party extends StatelessWidget {
  final String emoji;
  final String role;
  final String name;
  final bool isYou;

  const _Party({
    required this.emoji,
    required this.role,
    required this.name,
    required this.isYou,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.onBrand.withValues(alpha: isYou ? 0.20 : 0.10),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: AppSpacing.lg,
            backgroundColor: AppColors.onBrand,
            child: Text(emoji, style: theme.textTheme.bodyLarge),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isYou ? '$role (သင်)' : role,
                  style:
                      theme.textTheme.labelSmall?.copyWith(color: AppColors.onBrandMuted),
                ),
                Text(
                  name,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.onBrand,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryLine extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool emphasize;

  const _SummaryLine({
    required this.icon,
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: AppSizes.iconSm, color: AppColors.onBrandMuted),
        const SizedBox(width: AppSpacing.sm),
        // Both halves flex: at large text scales the Burmese labels are long
        // enough to push a fixed-width value off the card.
        Flexible(
          child: Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(color: AppColors.onBrandMuted),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: (emphasize ? theme.textTheme.titleSmall : theme.textTheme.bodyMedium)
                ?.copyWith(
              color: AppColors.onBrand,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
