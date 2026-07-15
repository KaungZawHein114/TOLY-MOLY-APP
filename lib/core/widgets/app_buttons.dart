import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// The design system's primary CTA: brand purple gradient, 58dp tall,
/// rounded, haptic tap, press-scale feedback, and a built-in [loading]
/// state (spinner + taps ignored) so screens stop hand-rolling
/// `_isSubmitting ? "ခဏစောင့်ပါ..." : label` swaps.
///
/// One per screen — this is the single obvious next step (Hick's law).
class AppPrimaryButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onTap;
  final bool loading;
  final bool enabled;

  /// White-filled variant for brand (purple) surfaces, where the standard
  /// purple gradient would disappear into the background. Highest-contrast
  /// affordance available on a gradient hero (e.g. the Welcome CTA).
  final bool inverse;

  const AppPrimaryButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.loading = false,
    this.enabled = true,
    this.inverse = false,
  });

  @override
  Widget build(BuildContext context) {
    return _AppButtonBase(
      label: label,
      icon: icon,
      onTap: onTap,
      loading: loading,
      enabled: enabled,
      gradient: inverse ? null : AppColors.purpleGradient,
      fill: inverse ? AppColors.onBrand : null,
      foreground: inverse ? AppColors.purple700 : AppColors.onBrand,
      shadowColor: inverse
          ? AppColors.purple900.withValues(alpha: 0.30)
          : AppColors.purple500.withValues(alpha: 0.35),
    );
  }
}

/// Secondary action: same size and shape as [AppPrimaryButton] but outlined,
/// so hierarchy is carried by weight/fill, never by shrinking the tap target.
class AppSecondaryButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onTap;
  final bool loading;
  final bool enabled;
  final Color color;

  const AppSecondaryButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.loading = false,
    this.enabled = true,
    this.color = AppColors.purple700,
  });

  @override
  Widget build(BuildContext context) {
    return _AppButtonBase(
      label: label,
      icon: icon,
      onTap: onTap,
      loading: loading,
      enabled: enabled,
      outlineColor: color,
      foreground: color,
    );
  }
}

class _AppButtonBase extends StatefulWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onTap;
  final bool loading;
  final bool enabled;
  final Gradient? gradient;
  final Color? fill;
  final Color? outlineColor;
  final Color foreground;
  final Color? shadowColor;

  const _AppButtonBase({
    required this.label,
    required this.onTap,
    required this.foreground,
    this.icon,
    this.loading = false,
    this.enabled = true,
    this.gradient,
    this.fill,
    this.outlineColor,
    this.shadowColor,
  });

  @override
  State<_AppButtonBase> createState() => _AppButtonBaseState();
}

class _AppButtonBaseState extends State<_AppButtonBase> {
  bool _pressed = false;

  bool get _interactive => widget.enabled && !widget.loading;

  void _setPressed(bool value) {
    if (MediaQuery.of(context).disableAnimations) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadius.md);
    final fg = widget.enabled
        ? widget.foreground
        : AppColors.textSecondary;

    return Semantics(
      label: widget.label,
      button: true,
      enabled: _interactive,
      child: GestureDetector(
        onTapDown: _interactive ? (_) => _setPressed(true) : null,
        onTapCancel: () => _setPressed(false),
        onTapUp: (_) => _setPressed(false),
        child: AnimatedScale(
          scale: _pressed ? 0.97 : 1.0,
          duration: AppMotion.fast,
          curve: AppMotion.press,
          child: AnimatedOpacity(
            opacity: widget.enabled ? 1 : 0.55,
            duration: AppMotion.fast,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: radius,
                onTap: _interactive
                    ? () {
                        HapticFeedback.lightImpact();
                        widget.onTap();
                      }
                    : null,
                child: Ink(
                  decoration: BoxDecoration(
                    gradient: widget.enabled ? widget.gradient : null,
                    color: !widget.enabled &&
                            (widget.gradient != null || widget.fill != null)
                        ? AppColors.onboardingDivider
                        : widget.fill,
                    borderRadius: radius,
                    border: widget.outlineColor != null
                        ? Border.all(
                            color: widget.enabled
                                ? widget.outlineColor!
                                : AppColors.onboardingDivider,
                            width: 2)
                        : null,
                    boxShadow: widget.shadowColor != null && widget.enabled
                        ? [
                            BoxShadow(
                              color: widget.shadowColor!,
                              blurRadius: 18,
                              offset: const Offset(0, 8),
                            ),
                          ]
                        : null,
                  ),
                  child: Container(
                    height: AppSizes.buttonHeight,
                    alignment: Alignment.center,
                    padding:
                        const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                    child: AnimatedSwitcher(
                      duration: AppMotion.fast,
                      child: widget.loading
                          ? SizedBox(
                              key: const ValueKey("btn-loading"),
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: fg,
                              ),
                            )
                          : Row(
                              key: const ValueKey("btn-content"),
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (widget.icon != null) ...[
                                  Icon(widget.icon,
                                      color: fg, size: AppSizes.iconMd),
                                  const SizedBox(width: AppSpacing.sm),
                                ],
                                Flexible(
                                  child: Text(
                                    widget.label,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTextStyles.button
                                        .copyWith(color: fg),
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
        ),
      ),
    );
  }
}
