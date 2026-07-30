import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../activity_chat.dart' show ActivityRole;
import '../discussion_models.dart';

/// A familiar chat bubble — mine on the right, theirs on the left.
///
/// The timeline is shared by both roles, so "mine" is decided by comparing the
/// author with whoever is looking, never baked into the message.
class ChatBubble extends StatelessWidget {
  final DiscussionMessage message;
  final ActivityRole viewerRole;

  /// Extra controls rendered inside the bubble (a question's answer buttons).
  final Widget? footer;

  const ChatBubble({
    super.key,
    required this.message,
    required this.viewerRole,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (message.kind == MessageKind.system || message.kind == MessageKind.warning) {
      final isWarning = message.kind == MessageKind.warning;
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
          style: theme.textTheme.bodyMedium?.copyWith(
            color: isWarning ? AppColors.error : AppColors.tealDark,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    final isMe = message.author == viewerRole;
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.82,
        ),
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.md),
        decoration: BoxDecoration(
          color: isMe ? AppColors.purple700 : AppColors.lightSurface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(AppRadius.lg),
            topRight: const Radius.circular(AppRadius.lg),
            bottomLeft: Radius.circular(isMe ? AppRadius.lg : AppRadius.sm),
            bottomRight: Radius.circular(isMe ? AppRadius.sm : AppRadius.lg),
          ),
          boxShadow: [
            BoxShadow(color: AppColors.shadowSm, blurRadius: AppSpacing.sm),
          ],
        ),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              message.text,
              // Body text stays at 16sp minimum — this is the whole page now.
              style: theme.textTheme.bodyLarge?.copyWith(
                color: isMe ? AppColors.onBrand : AppColors.textPrimary,
                height: 1.4,
              ),
            ),
            if (message.photos > 0) ...[
              const SizedBox(height: AppSpacing.sm),
              _PhotoStrip(count: message.photos),
            ],
            if (footer != null) ...[
              const SizedBox(height: AppSpacing.md),
              footer!,
            ],
            const SizedBox(height: AppSpacing.xs),
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

/// Placeholder thumbnails for a sent photo. A real picker drops in here later
/// without the bubble changing shape.
class _PhotoStrip extends StatelessWidget {
  final int count;

  const _PhotoStrip({required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < count; i++)
          Semantics(
            image: true,
            label: 'ပေးပို့ထားသော ဓာတ်ပုံ ${i + 1}',
            child: Container(
              width: 72,
              height: 72,
              margin: EdgeInsets.only(right: i == count - 1 ? 0 : AppSpacing.sm),
              decoration: BoxDecoration(
                gradient: AppColors.guidanceSurfaceGradient,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: const Icon(Icons.image_outlined,
                  color: AppColors.purple500, size: AppSizes.iconLg),
            ),
          ),
      ],
    );
  }
}
