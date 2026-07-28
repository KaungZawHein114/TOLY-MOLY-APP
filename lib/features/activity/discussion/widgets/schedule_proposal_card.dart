import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../activity_chat.dart' show ActivityRole;
import '../discussion_models.dart';
import 'discussion_card.dart';

/// Old time → new time, side by side.
///
/// Accepting rewrites the shared task, so the booking card and the escrow
/// summary show the new time immediately — no stale value left anywhere.
class ScheduleProposalCard extends StatelessWidget {
  final DiscussionItem item;
  final ActivityRole viewerRole;
  final bool highlighted;
  final ValueChanged<DiscussionItem> onUpdate;
  final VoidCallback? onDemoAnswer;

  const ScheduleProposalCard({
    super.key,
    required this.item,
    required this.viewerRole,
    required this.onUpdate,
    this.highlighted = false,
    this.onDemoAnswer,
  });

  @override
  Widget build(BuildContext context) {
    final myTurn = item.isMyTurn(viewerRole);
    final accepted = item.status == DiscussionStatus.accepted;

    return DiscussionCard(
      item: item,
      viewerRole: viewerRole,
      highlighted: highlighted,
      onDemoAnswer: onDemoAnswer,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _SlotBox(
                  label: 'လက်ရှိ',
                  date: item.fromDate,
                  time: item.fromTime,
                  muted: true,
                  strikethrough: accepted,
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                child: Icon(Icons.arrow_forward_rounded,
                    color: AppColors.purple500, size: AppSizes.iconMd),
              ),
              Expanded(
                child: _SlotBox(
                  label: 'အဆိုပြု',
                  date: item.toDate,
                  time: item.toTime,
                  muted: false,
                  strikethrough: false,
                ),
              ),
            ],
          ),
          if (myTurn) ...[
            const SizedBox(height: AppSpacing.md),
            DiscussionDecisionButtons(
              acceptLabel: 'လက်ခံသည်',
              rejectLabel: 'မရပါ',
              onAccept: () => onUpdate(item.copyWith(status: DiscussionStatus.accepted)),
              onReject: () => onUpdate(item.copyWith(status: DiscussionStatus.rejected)),
            ),
          ],
          if (item.status.isSettled) ...[
            const SizedBox(height: AppSpacing.md),
            DiscussionResultNote(
              icon: accepted ? Icons.event_available_outlined : Icons.event_busy_outlined,
              color: accepted ? AppColors.tealDark : AppColors.error,
              text: accepted
                  ? 'ချိန်းဆိုချိန် အသစ်သို့ ပြောင်းလဲပြီး — ${item.toDate} · ${item.toTime}'
                  : 'မူလ ချိန်းဆိုချိန်အတိုင်း ဆက်ထားပါမည်',
            ),
          ],
        ],
      ),
    );
  }
}

class _SlotBox extends StatelessWidget {
  final String label;
  final String date;
  final String time;
  final bool muted;
  final bool strikethrough;

  const _SlotBox({
    required this.label,
    required this.date,
    required this.time,
    required this.muted,
    required this.strikethrough,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = muted ? AppColors.textSecondary : AppColors.purple700;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: muted ? AppColors.lightBg : AppColors.purple100,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            date,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: muted ? AppColors.textSecondary : AppColors.textPrimary,
              decoration: strikethrough ? TextDecoration.lineThrough : null,
            ),
          ),
          Text(
            time,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: muted ? AppColors.textSecondary : AppColors.purple700,
              decoration: strikethrough ? TextDecoration.lineThrough : null,
            ),
          ),
        ],
      ),
    );
  }
}
