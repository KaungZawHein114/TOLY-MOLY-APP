import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../activity_chat.dart' show ActivityRole;
import '../discussion_state.dart';

/// A casual chat line. The log is shared by both sides, so "mine" is decided
/// by comparing the author to whoever is looking — not baked into the message.
class DiscussionChatBubble extends StatelessWidget {
  final DiscussionMessage message;
  final ActivityRole viewerRole;

  const DiscussionChatBubble({
    super.key,
    required this.message,
    required this.viewerRole,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (message.kind != DiscussionMsgKind.text) {
      final isWarning = message.kind == DiscussionMsgKind.warning;
      return Container(
        margin: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color:
              (isWarning ? AppColors.error : AppColors.success).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Text(
          message.text,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: isWarning ? AppColors.error : AppColors.tealDark,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    final isMe = message.authorRole == viewerRole;
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 280),
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: isMe ? AppColors.purple700 : AppColors.lightSurface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(AppRadius.lg),
            topRight: const Radius.circular(AppRadius.lg),
            bottomLeft: Radius.circular(isMe ? AppRadius.lg : AppRadius.sm),
            bottomRight: Radius.circular(isMe ? AppRadius.sm : AppRadius.lg),
          ),
          border: isMe ? null : Border.all(color: AppColors.onboardingDivider),
        ),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              message.text,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isMe ? AppColors.onBrand : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              message.time,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isMe ? AppColors.onBrandMuted : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
