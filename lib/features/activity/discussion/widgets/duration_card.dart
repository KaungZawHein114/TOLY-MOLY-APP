import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../activity_chat.dart' show ActivityRole;
import '../discussion_models.dart';
import 'discussion_card.dart';

/// "How long will the repair take?" — the tasker answers with one tap.
///
/// Choice chips instead of a text field: recognition over recall, and no
/// keyboard for a user who struggles to type.
const List<String> kDurationChoices = [
  '၁ နာရီ',
  '၁ နာရီခွဲ',
  '၂ နာရီ',
  '၃ နာရီ',
  'တစ်နေ့စာ',
];

class DurationCard extends StatelessWidget {
  final DiscussionItem item;
  final ActivityRole viewerRole;
  final bool highlighted;
  final ValueChanged<DiscussionItem> onUpdate;
  final VoidCallback? onDemoAnswer;

  const DurationCard({
    super.key,
    required this.item,
    required this.viewerRole,
    required this.onUpdate,
    this.highlighted = false,
    this.onDemoAnswer,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final myTurn = item.isMyTurn(viewerRole);

    return DiscussionCard(
      item: item,
      viewerRole: viewerRole,
      highlighted: highlighted,
      onDemoAnswer: onDemoAnswer,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (myTurn) ...[
            Text(
              'ခန့်မှန်း ကြာမြင့်ချိန်ကို ရွေးပါ',
              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final choice in kDurationChoices)
                  _DurationChip(
                    label: choice,
                    onTap: () => onUpdate(
                      item.withData({'duration': choice}).copyWith(
                          status: DiscussionStatus.answered),
                    ),
                  ),
              ],
            ),
          ] else if (item.duration != null)
            Row(
              children: [
                const Icon(Icons.timer_outlined,
                    color: AppColors.indigo700, size: AppSizes.iconLg),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ခန့်မှန်းချက်',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: AppColors.textSecondary),
                      ),
                      Text(
                        item.duration!,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.indigo700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _DurationChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _DurationChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
          decoration: BoxDecoration(
            color: AppColors.indigo100,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: Center(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.indigo700,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
