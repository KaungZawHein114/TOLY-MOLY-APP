import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../activity_chat.dart' show ActivityRole;
import '../discussion_models.dart';
import 'discussion_status_badge.dart';

/// The shared shell every discussion card is built from: type icon, title,
/// who asked, status badge, the question itself, then a type-specific body.
///
/// Type cards (photo, materials, cost…) only supply [child] — spacing, colour,
/// the highlight pulse and the "waiting on the other side" footer all live
/// here so the six cards can never drift apart visually.
class DiscussionCard extends StatelessWidget {
  final DiscussionItem item;
  final ActivityRole viewerRole;
  final Widget child;

  /// Briefly ringed after being created or jumped to from the action bar.
  final bool highlighted;

  /// Plays the scripted counterpart answer. Demo-only affordance, shown just
  /// while the card waits on the other side.
  final VoidCallback? onDemoAnswer;

  const DiscussionCard({
    super.key,
    required this.item,
    required this.viewerRole,
    required this.child,
    this.highlighted = false,
    this.onDemoAnswer,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final awaiting = item.awaitingRole;
    final waitingOnThem = awaiting != null && awaiting != viewerRole;
    final myTurn = awaiting == viewerRole;

    return AnimatedContainer(
      duration: AppMotion.medium,
      curve: AppMotion.enter,
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.lightSurface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: highlighted
              ? item.type.accent
              : myTurn
                  ? AppColors.warning.withValues(alpha: 0.45)
                  : Colors.transparent,
          width: highlighted ? 2 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: highlighted ? AppColors.selectedShadowMd : AppColors.shadowSm,
            blurRadius: highlighted ? AppSpacing.lg : AppSpacing.md,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: item.type.accentBg,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(
                  item.type.icon,
                  size: AppSizes.iconMd,
                  color: item.type.accent,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      '${roleLabel(item.creatorRole)} · ${item.createdAt}',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              // Flexible so a long status label at large text scales eats into
              // its own pill instead of pushing off the card.
              Flexible(child: DiscussionStatusBadge(status: item.status)),
            ],
          ),
          if (item.description.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.lightBg,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Text(
                '“${item.description}”',
                style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textPrimary),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          AnimatedSize(
            duration: AppMotion.medium,
            curve: AppMotion.enter,
            alignment: Alignment.topCenter,
            child: child,
          ),
          if (waitingOnThem) ...[
            const SizedBox(height: AppSpacing.md),
            _WaitingFooter(
              awaiting: awaiting,
              onDemoAnswer: onDemoAnswer,
            ),
          ],
        ],
      ),
    );
  }
}

class _WaitingFooter extends StatelessWidget {
  final ActivityRole awaiting;
  final VoidCallback? onDemoAnswer;

  const _WaitingFooter({required this.awaiting, required this.onDemoAnswer});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        const Icon(Icons.hourglass_empty_rounded,
            size: AppSizes.iconSm, color: AppColors.textSecondary),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(
            '${roleLabel(awaiting)}၏ အဖြေကို စောင့်နေပါသည်',
            style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
        ),
        if (onDemoAnswer != null)
          TextButton.icon(
            onPressed: onDemoAnswer,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.indigo700,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            ),
            icon: const Icon(Icons.play_circle_outline, size: AppSizes.iconSm),
            label: const Text('သရုပ်ပြ အဖြေ'),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Small building blocks shared by the six type cards.
// ---------------------------------------------------------------------------

/// One label → value line inside a card body.
class DiscussionDetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const DiscussionDetailRow({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The settled banner every card shows once its decision is recorded — the
/// "after" half of the before/after the whole workspace is built around.
class DiscussionResultNote extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const DiscussionResultNote({
    super.key,
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: AppSizes.iconMd, color: color),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: color, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

/// The accept / reject pair. 48dp minimum, always two words, never icon-only.
class DiscussionDecisionButtons extends StatelessWidget {
  final String acceptLabel;
  final String rejectLabel;
  final IconData acceptIcon;
  final IconData rejectIcon;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const DiscussionDecisionButtons({
    super.key,
    required this.acceptLabel,
    required this.rejectLabel,
    required this.onAccept,
    required this.onReject,
    this.acceptIcon = Icons.check_rounded,
    this.rejectIcon = Icons.close_rounded,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onReject,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              foregroundColor: AppColors.textSecondary,
              side: const BorderSide(color: AppColors.onboardingDivider),
            ),
            icon: Icon(rejectIcon, size: AppSizes.iconSm),
            label: Text(rejectLabel, textAlign: TextAlign.center),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: FilledButton.icon(
            onPressed: onAccept,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              backgroundColor: AppColors.purple700,
              foregroundColor: AppColors.onBrand,
            ),
            icon: Icon(acceptIcon, size: AppSizes.iconSm),
            label: Text(acceptLabel, textAlign: TextAlign.center),
          ),
        ),
      ],
    );
  }
}
