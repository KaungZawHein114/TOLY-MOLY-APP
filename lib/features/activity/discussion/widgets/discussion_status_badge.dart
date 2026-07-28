import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../discussion_models.dart';

/// The one place a discussion status turns into colour + words.
///
/// Status is never communicated by colour alone — every badge carries its icon
/// and its Burmese label, per the accessibility rules.
class DiscussionStatusBadge extends StatelessWidget {
  final DiscussionStatus status;
  final bool compact;

  const DiscussionStatusBadge({
    super.key,
    required this.status,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      label: 'အခြေအနေ — ${status.label}',
      child: AnimatedContainer(
        duration: AppMotion.medium,
        curve: AppMotion.enter,
        padding: EdgeInsets.symmetric(
          horizontal: compact ? AppSpacing.sm : AppSpacing.md,
          vertical: AppSpacing.xxs,
        ),
        decoration: BoxDecoration(
          color: status.bg,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(status.icon, size: AppSizes.iconSm, color: status.fg),
            const SizedBox(width: AppSpacing.xs),
            Flexible(
              child: Text(
                status.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: status.fg,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
