import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../activity_chat.dart' show ActivityRole;
import '../discussion_models.dart';
import 'answer_button.dart';
import 'chat_bubble.dart';

/// A normal chat bubble that happens to carry an answer control.
///
/// It is deliberately *not* a card: same width, same corners, same place in
/// the conversation as any other message. The only difference is that tapping
/// it moves the agreement forward — and once answered, the buttons disappear
/// and it settles back into an ordinary message.
class QuestionBubble extends StatelessWidget {
  final DiscussionMessage message;
  final ActivityRole viewerRole;

  /// positive = Yes / Accept / photo sent.
  final void Function(bool positive) onAnswer;

  /// Demo-only: play the counterpart's answer while waiting on them.
  final VoidCallback? onDemoAnswer;

  const QuestionBubble({
    super.key,
    required this.message,
    required this.viewerRole,
    required this.onAnswer,
    this.onDemoAnswer,
  });

  @override
  Widget build(BuildContext context) {
    final myTurn = message.isMyTurn(viewerRole);
    final waitingOnThem = message.isOpenQuestion && !myTurn;

    return ChatBubble(
      message: message,
      viewerRole: viewerRole,
      footer: myTurn
          ? _answerControls(context)
          : waitingOnThem
              ? _waitingNote(context)
              : null,
    );
  }

  Widget _answerControls(BuildContext context) {
    switch (message.answerStyle) {
      case AnswerStyle.upload:
        return AnswerButton(
          label: 'ဓာတ်ပုံ ပို့မည်',
          icon: Icons.add_a_photo_outlined,
          onTap: () => onAnswer(true),
        );
      case AnswerStyle.yesNo:
        return Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            AnswerButton(
              label: 'ရပါတယ်',
              icon: Icons.check_rounded,
              onTap: () => onAnswer(true),
            ),
            AnswerButton(
              label: 'မလိုပါ',
              icon: Icons.close_rounded,
              primary: false,
              onTap: () => onAnswer(false),
            ),
          ],
        );
      case AnswerStyle.accept:
        return Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            AnswerButton(
              label: 'လက်ခံမည်',
              icon: Icons.check_rounded,
              onTap: () => onAnswer(true),
            ),
            AnswerButton(
              label: 'မရပါ',
              icon: Icons.close_rounded,
              primary: false,
              onTap: () => onAnswer(false),
            ),
          ],
        );
      case AnswerStyle.none:
        return const SizedBox.shrink();
    }
  }

  Widget _waitingNote(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.hourglass_empty_rounded,
            size: AppSizes.iconSm, color: AppColors.onBrandMuted),
        const SizedBox(width: AppSpacing.xs),
        Flexible(
          child: Text(
            'အဖြေ စောင့်နေပါသည်',
            style: theme.textTheme.bodySmall?.copyWith(color: AppColors.onBrandMuted),
          ),
        ),
        if (onDemoAnswer != null)
          TextButton(
            onPressed: onDemoAnswer,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.onBrand,
              minimumSize: const Size(0, 36),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            ),
            child: const Text('သရုပ်ပြ'),
          ),
      ],
    );
  }
}
