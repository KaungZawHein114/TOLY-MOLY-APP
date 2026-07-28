import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../activity_chat.dart' show ActivityRole;
import '../discussion_models.dart';
import 'discussion_card.dart';

/// "I would like to bring one apprentice because the motor is heavy."
///
/// Who enters the client's home is the client's decision, so this card is a
/// plain approve / reject — recorded, not buried in chat.
class ApprenticeRequestCard extends StatelessWidget {
  final DiscussionItem item;
  final ActivityRole viewerRole;
  final bool highlighted;
  final ValueChanged<DiscussionItem> onUpdate;
  final VoidCallback? onDemoAnswer;

  const ApprenticeRequestCard({
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
              const Icon(Icons.person_add_alt_1_outlined,
                  color: AppColors.purple500, size: AppSizes.iconLg),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  'လက်ထောက် ၁ ယောက် ပါလာမည်',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          if (myTurn) ...[
            const SizedBox(height: AppSpacing.md),
            DiscussionDecisionButtons(
              acceptLabel: 'ခွင့်ပြုသည်',
              rejectLabel: 'မလိုပါ',
              onAccept: () => onUpdate(item.copyWith(status: DiscussionStatus.accepted)),
              onReject: () => onUpdate(item.copyWith(status: DiscussionStatus.rejected)),
            ),
          ] else if (item.status.isSettled)
            DiscussionResultNote(
              icon: item.status == DiscussionStatus.accepted
                  ? Icons.verified_user_outlined
                  : Icons.person_off_outlined,
              color: item.status == DiscussionStatus.accepted
                  ? AppColors.tealDark
                  : AppColors.error,
              text: item.status == DiscussionStatus.accepted
                  ? 'လက်ထောက် ၁ ယောက် ခေါ်လာရန် သဘောတူပြီး'
                  : 'လက်ထောက် မခေါ်ရန် သဘောတူပြီး',
            ),
        ],
      ),
    );
  }
}
