import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../activity_chat.dart' show ActivityRole, formatMmk;
import '../discussion_models.dart';
import 'discussion_card.dart';

/// Possible extra costs, agreed *before* the money is escrowed.
///
/// Two stages, because the card can start from either side:
///   • the client asks "are there extra charges?" → the tasker fills it in;
///   • the tasker declares one up front → the client understands or queries it.
///
/// "Understand" is not a payment. It records that the client was told, which is
/// exactly the argument this app exists to prevent.
class CostProposalCard extends StatelessWidget {
  final DiscussionItem item;
  final ActivityRole viewerRole;
  final bool highlighted;
  final ValueChanged<DiscussionItem> onUpdate;

  /// Opens the little "what might it cost?" composer for the tasker.
  final VoidCallback onFill;
  final VoidCallback? onDemoAnswer;

  const CostProposalCard({
    super.key,
    required this.item,
    required this.viewerRole,
    required this.onUpdate,
    required this.onFill,
    this.highlighted = false,
    this.onDemoAnswer,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final myTurn = item.isMyTurn(viewerRole);
    final filled = item.isCostFilled;

    return DiscussionCard(
      item: item,
      viewerRole: viewerRole,
      highlighted: highlighted,
      onDemoAnswer: onDemoAnswer,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (filled) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DiscussionDetailRow(label: 'ပစ္စည်း', value: item.costItem),
                  DiscussionDetailRow(
                    label: 'ခန့်မှန်းစရိတ်',
                    value: formatMmk(item.costAmountMmk),
                    valueColor: AppColors.orangeDark,
                  ),
                  if ((item.reason ?? '').isNotEmpty)
                    DiscussionDetailRow(label: 'အကြောင်းပြချက်', value: item.reason!),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                const Icon(Icons.info_outline,
                    size: AppSizes.iconSm, color: AppColors.textSecondary),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    'ဤစရိတ်ကို လိုအပ်မှသာ ကောက်ခံမည် ဖြစ်ပြီး၊ လက်ရှိ သဘောတူဈေးထဲ မပါဝင်ပါ။',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ],
          if (myTurn && !filled)
            FilledButton.icon(
              onPressed: onFill,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                backgroundColor: AppColors.indigo700,
                foregroundColor: AppColors.onBrand,
              ),
              icon: const Icon(Icons.edit_outlined),
              label: const Text('ဖြစ်နိုင်သော စရိတ် ဖြည့်ရန်'),
            ),
          if (myTurn && filled) ...[
            const SizedBox(height: AppSpacing.md),
            DiscussionDecisionButtons(
              acceptLabel: 'နားလည်ပါပြီ',
              rejectLabel: 'ထပ်ဆွေးနွေးမည်',
              acceptIcon: Icons.check_rounded,
              rejectIcon: Icons.forum_outlined,
              onAccept: () => onUpdate(item.copyWith(status: DiscussionStatus.accepted)),
              onReject: () =>
                  onUpdate(item.copyWith(status: DiscussionStatus.needsClarification)),
            ),
          ],
          if (item.status == DiscussionStatus.accepted) ...[
            const SizedBox(height: AppSpacing.md),
            const DiscussionResultNote(
              icon: Icons.handshake_outlined,
              color: AppColors.tealDark,
              text: 'ဖြစ်နိုင်သော စရိတ်ကို အလုပ်ရှင် နားလည် သဘောတူပြီး',
            ),
          ],
          if (item.status == DiscussionStatus.needsClarification) ...[
            const SizedBox(height: AppSpacing.md),
            const DiscussionResultNote(
              icon: Icons.forum_outlined,
              color: AppColors.purple700,
              text: 'အောက်က စကားပြောခန်းမှာ ထပ်ဆွေးနွေးရန် မှတ်သားထားပါသည်',
            ),
          ],
        ],
      ),
    );
  }
}
