import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../discussion_models.dart';
import '../discussion_state.dart';

/// The heart of the redesign: six fixed topics, always visible, always
/// countable. A user who cannot read a whole transcript can still see at a
/// glance what is agreed and what is still open.
class DiscussionProgressCard extends StatelessWidget {
  final List<DiscussionItem> items;

  /// Jump to an existing card. Null for topics nobody has opened yet.
  final void Function(DiscussionItem item) onOpenItem;

  const DiscussionProgressCard({
    super.key,
    required this.items,
    required this.onOpenItem,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = kDiscussionChecklist.length;
    final done = settledTopicCount(items);
    final pending = items.where((i) => i.status.isPending).length;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.lightSurface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(color: AppColors.shadowSm, blurRadius: AppSpacing.md),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.checklist_rounded, color: AppColors.purple700),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'ဆွေးနွေးမှု ပြီးစီးမှု',
                  style:
                      theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              Text(
                '$done / $total',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.purple700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Semantics(
            label: 'ဆွေးနွေးမှု ပြီးစီးမှု — $total ခုအနက် $done ခု',
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              child: TweenAnimationBuilder<double>(
                duration: AppMotion.slow,
                curve: AppMotion.enter,
                tween: Tween(begin: 0, end: done / total),
                builder: (context, value, _) => LinearProgressIndicator(
                  value: value,
                  minHeight: AppSpacing.sm,
                  backgroundColor: AppColors.onboardingDivider,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.purple700),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final type in kDiscussionChecklist)
                _TopicChip(
                  type: type,
                  item: openItemOfType(items, type),
                  onOpenItem: onOpenItem,
                ),
            ],
          ),
          if (pending > 0) ...[
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                const Icon(Icons.hourglass_top_rounded,
                    size: AppSizes.iconSm, color: AppColors.orangeDark),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    'ဖြေဆိုရန် ကျန်နေသေးသည် — $pending ခု',
                    style:
                        theme.textTheme.bodySmall?.copyWith(color: AppColors.orangeDark),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _TopicChip extends StatelessWidget {
  final DiscussionItemType type;
  final DiscussionItem? item;
  final void Function(DiscussionItem item) onOpenItem;

  const _TopicChip({
    required this.type,
    required this.item,
    required this.onOpenItem,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = item?.status;

    final (Color fg, Color bg, IconData icon, String stateLabel) = switch (status) {
      null => (
          AppColors.textSecondary,
          AppColors.lightBg,
          Icons.radio_button_unchecked,
          'မစတင်ရသေး',
        ),
      DiscussionStatus.pending => (
          AppColors.orangeDark,
          AppColors.warning.withValues(alpha: 0.16),
          Icons.hourglass_top_rounded,
          'စောင့်ဆိုင်းဆဲ',
        ),
      DiscussionStatus.rejected => (
          AppColors.error,
          AppColors.error.withValues(alpha: 0.12),
          Icons.close_rounded,
          'လက်မခံပါ',
        ),
      _ => (
          AppColors.tealDark,
          AppColors.success.withValues(alpha: 0.16),
          Icons.check_circle_rounded,
          'ပြီးပါပြီ',
        ),
    };

    final chip = AnimatedContainer(
      duration: AppMotion.medium,
      curve: AppMotion.enter,
      constraints: const BoxConstraints(minHeight: 40),
      padding:
          const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: AppSizes.iconSm, color: fg),
          const SizedBox(width: AppSpacing.xs),
          Text(
            type.checklistLabel,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: fg, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );

    final semanticsLabel = '${type.checklistLabel} — $stateLabel';
    if (item == null) {
      return Semantics(label: semanticsLabel, child: chip);
    }
    return Semantics(
      button: true,
      label: '$semanticsLabel။ ကတ်ကို ဖွင့်ရန်',
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        onTap: () => onOpenItem(item!),
        child: chip,
      ),
    );
  }
}
