import 'package:flutter/material.dart';

import '../../theme/app_spacing.dart';

/// Fades + slides a list of children in with a per-child stagger delay.
/// Used by [OnboardingScaffold] so every onboarding screen gets entrance
/// motion for free. Honors the OS "reduce motion" accessibility setting —
/// when [MediaQuery.disableAnimations] is true, children appear instantly.
class StaggeredEntrance extends StatefulWidget {
  final List<Widget> children;
  final Duration staggerDelay;

  const StaggeredEntrance({
    super.key,
    required this.children,
    this.staggerDelay = const Duration(milliseconds: 60),
  });

  @override
  State<StaggeredEntrance> createState() => _StaggeredEntranceState();
}

class _StaggeredEntranceState extends State<StaggeredEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // MediaQuery.of(context) is not safe to call before the first build
    // completes — read the platform's accessibility flag directly instead.
    final reduceMotion =
        WidgetsBinding.instance.platformDispatcher.accessibilityFeatures.disableAnimations;
    _controller = AnimationController(
      vsync: this,
      duration: reduceMotion ? Duration.zero : AppMotion.medium,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final count = widget.children.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: List.generate(count, (i) {
        if (reduceMotion) {
          return widget.children[i];
        }
        // Each child's own slice of the shared controller's timeline,
        // offset by its stagger position, clamped to [0, 1].
        final start = (i * widget.staggerDelay.inMilliseconds) /
            AppMotion.medium.inMilliseconds;
        final clampedStart = start.clamp(0.0, 0.9);
        final animation = CurvedAnimation(
          parent: _controller,
          curve: Interval(clampedStart, 1.0, curve: AppMotion.enter),
        );
        return AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            return Opacity(
              opacity: animation.value,
              child: Transform.translate(
                offset: Offset(0, (1 - animation.value) * 16),
                child: child,
              ),
            );
          },
          child: widget.children[i],
        );
      }),
    );
  }
}
