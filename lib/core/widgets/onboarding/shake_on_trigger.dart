import 'dart:math';

import 'package:flutter/material.dart';

import '../../theme/app_spacing.dart';

/// Wraps [child] with a brief, decaying horizontal shake whenever [trigger]
/// changes (increment a counter on validation failure). Feedback purpose —
/// kept fast and restrained, not a repeating effect.
class ShakeOnTrigger extends StatefulWidget {
  final Widget child;
  final int trigger;

  const ShakeOnTrigger({super.key, required this.child, required this.trigger});

  @override
  State<ShakeOnTrigger> createState() => _ShakeOnTriggerState();
}

class _ShakeOnTriggerState extends State<ShakeOnTrigger>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppMotion.medium,
  );

  @override
  void didUpdateWidget(ShakeOnTrigger oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trigger != oldWidget.trigger) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // Decaying oscillation: a few quick wobbles that settle to rest.
        final t = _controller.value;
        final dx = sin(t * pi * 6) * (1 - t) * 8;
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
      child: widget.child,
    );
  }
}
