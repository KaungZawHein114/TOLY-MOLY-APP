import 'package:flutter/material.dart';

import 'mascot_state.dart';

/// Reusable visual guide for the TOLY MOLY app.
///
/// Feature screens select a [state] and never reference mascot asset paths
/// directly. The mascot has a gentle, continuous idle "breathing" float so it
/// reads as alive even between state changes, plus a cross-fade + pop when
/// [state] changes (e.g. pointing -> success).
class PhoWaYoke extends StatefulWidget {
  final PhoWaYokeState state;
  final double size;
  final BoxFit fit;
  final bool decorative;
  final Duration animationDuration;

  const PhoWaYoke({
    super.key,
    required this.state,
    this.size = 120,
    this.fit = BoxFit.contain,
    this.decorative = false,
    this.animationDuration = const Duration(milliseconds: 250),
  });

  @override
  State<PhoWaYoke> createState() => _PhoWaYokeState();
}

class _PhoWaYokeState extends State<PhoWaYoke> with SingleTickerProviderStateMixin {
  late final AnimationController _idleController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );

  late final Animation<double> _float =
      CurvedAnimation(parent: _idleController, curve: Curves.easeInOut);

  bool _reduceMotion = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Respect system reduced-motion: hold the idle breathing still instead of
    // looping it forever, since it's movement-only and serves no function.
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    if (reduceMotion) {
      _idleController.stop();
      _idleController.value = 0;
    } else if (!_idleController.isAnimating) {
      _idleController.repeat(reverse: true);
    }
    _reduceMotion = reduceMotion;
  }

  @override
  void dispose() {
    _idleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(
      widget.state.assetPath,
      key: ValueKey(widget.state),
      width: widget.size,
      height: widget.size,
      fit: widget.fit,
      excludeFromSemantics: widget.decorative,
      semanticLabel: widget.decorative ? null : widget.state.semanticLabel,
    );

    return SizedBox(
      width: widget.size,
      height: widget.size + 10, // a little breathing room for the float.
      child: AnimatedBuilder(
        animation: _float,
        builder: (context, child) {
          final lift = _float.value * 8; // bob up to 8px and back.
          final scale = 1 + _float.value * 0.03; // very subtle breathing.
          return Transform.translate(
            offset: Offset(0, -lift),
            child: Transform.scale(scale: scale, child: child),
          );
        },
        child: AnimatedSwitcher(
          duration: widget.animationDuration,
          // Only the celebratory "success" state earns the bouncy entrance;
          // calmer states (thinking, pointing, idle) use a settled ease-out
          // so frequent transitions don't feel jumpy or off-brand.
          switchInCurve: widget.state == PhoWaYokeState.success
              ? Curves.elasticOut
              : Curves.easeOutCubic,
          switchOutCurve: Curves.easeIn,
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                // Reduced motion keeps the fade but drops the pop/scale.
                scale: Tween<double>(begin: _reduceMotion ? 1 : 0.92, end: 1)
                    .animate(animation),
                child: child,
              ),
            );
          },
          child: image,
        ),
      ),
    );
  }
}
