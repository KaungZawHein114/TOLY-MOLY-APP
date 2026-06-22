import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import 'mascot_state.dart';
import 'pho_wa_yoke.dart';

/// A guidance card that combines Pho Wa Yoke with a short supportive message.
///
/// Keep messages Burmese-first, concise, and free of technical language.
class MascotMessageCard extends StatelessWidget {
  final PhoWaYokeState state;
  final String message;
  final double mascotSize;
  final bool mascotOnRight;

  const MascotMessageCard({
    super.key,
    required this.state,
    required this.message,
    this.mascotSize = AppSizes.avatarLarge,
    this.mascotOnRight = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mascot = PhoWaYoke(state: state, size: mascotSize);
    final messageBubble = Expanded(
      child: Semantics(
        liveRegion: state == PhoWaYokeState.thinking,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.communityBlue,
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: Text(
            message,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: AppColors.brandPurple,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: mascotOnRight
          ? [
              messageBubble,
              const SizedBox(width: AppSpacing.md),
              mascot,
            ]
          : [
              mascot,
              const SizedBox(width: AppSpacing.md),
              messageBubble,
            ],
    );
  }
}
