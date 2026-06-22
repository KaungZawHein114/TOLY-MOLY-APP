import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import 'mascot_state.dart';
import 'pho_wa_yoke.dart';

/// A guidance card that combines Pho Wa Yoke with a short supportive message.
///
/// Keep messages Burmese-first, concise, and free of technical language. The
/// message bubble fades in shortly after the mascot itself, so it reads as
/// "the mascot is about to speak" rather than both popping in simultaneously.
class MascotMessageCard extends StatefulWidget {
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
  State<MascotMessageCard> createState() => _MascotMessageCardState();
}

class _MascotMessageCardState extends State<MascotMessageCard>
    with SingleTickerProviderStateMixin {
  // The bubble's fade is the back ~70% of a slightly longer timeline than
  // AppMotion.fast, so it visibly trails the mascot's own entrance instead of
  // popping in simultaneously — an Interval baked into one controller avoids
  // a separate Timer (which would otherwise leak past dispose/teardown).
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppMotion.medium,
  );
  late final Animation<double> _opacity = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.3, 1.0, curve: AppMotion.enter),
  );
  bool _appliedReduceMotion = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_appliedReduceMotion) return;
    _appliedReduceMotion = true;
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    if (reduceMotion) {
      _controller.value = 1.0;
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mascot = PhoWaYoke(state: widget.state, size: widget.mascotSize);
    final messageBubble = Expanded(
      child: FadeTransition(
        opacity: _opacity,
        child: Semantics(
          liveRegion: widget.state == PhoWaYokeState.thinking,
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              gradient: AppColors.guidanceSurfaceGradient,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Text(
              widget.message,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: AppColors.brandPurple,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: widget.mascotOnRight
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
