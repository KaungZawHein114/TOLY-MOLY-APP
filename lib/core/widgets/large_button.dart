import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// A big, tappable primary button with haptic feedback. Pure presentation —
/// it takes a label + callback and pulls all styling from the theme tokens.
class LargeButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onTap;
  final bool filled;
  final Gradient gradient;
  final Color outlineColor;
  final bool celebratory;

  const LargeButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.filled = true,
    this.gradient = AppColors.tealGradient,
    this.outlineColor = AppColors.teal,
    this.celebratory = false,
  });

  @override
  State<LargeButton> createState() => _LargeButtonState();
}

class _LargeButtonState extends State<LargeButton> with SingleTickerProviderStateMixin {
  bool _pressed = false;
  late final AnimationController _popController = AnimationController(
    vsync: this,
    duration: AppMotion.slow,
  );
  bool _appliedReduceMotion = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_appliedReduceMotion) {
      _appliedReduceMotion = true;
      final reduceMotion = MediaQuery.of(context).disableAnimations;
      if (widget.celebratory && !reduceMotion) {
        _popController.forward();
      } else {
        _popController.value = 1.0;
      }
    }
  }

  @override
  void dispose() {
    _popController.dispose();
    super.dispose();
  }

  void _setPressed(bool value) {
    if (MediaQuery.of(context).disableAnimations) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadius.md);
    final fg = widget.filled ? AppColors.onBrand : widget.outlineColor;
    final popScale = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _popController, curve: AppMotion.enter),
    );

    return GestureDetector(
      onTapDown: (_) => _setPressed(true),
      onTapCancel: () => _setPressed(false),
      onTapUp: (_) => _setPressed(false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: AppMotion.fast,
        curve: AppMotion.press,
        child: ScaleTransition(
          scale: popScale,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: radius,
              onTap: () {
                HapticFeedback.lightImpact();
                widget.onTap();
              },
              child: Ink(
                decoration: BoxDecoration(
                  gradient: widget.filled ? widget.gradient : null,
                  borderRadius: radius,
                  border: widget.filled
                      ? null
                      : Border.all(color: widget.outlineColor, width: 2),
                  boxShadow: widget.filled
                      ? [
                          BoxShadow(
                            color: widget.gradient.colors.first.withValues(alpha: 0.35),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ]
                      : null,
                ),
                child: Container(
                  height: AppSizes.buttonHeight,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (widget.icon != null) ...[
                        Icon(widget.icon, color: fg, size: AppSizes.iconMd),
                        const SizedBox(width: AppSpacing.sm),
                      ],
                      Flexible(
                        child: Text(
                          widget.label,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.button.copyWith(color: fg),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
