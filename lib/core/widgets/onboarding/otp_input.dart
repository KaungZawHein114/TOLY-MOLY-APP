import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';

/// Boxed OTP entry — the pattern every Myanmar user already knows from
/// Viber/Telegram/Wave Money (Jakob's law): one large box per digit, number
/// pad only, the active box highlighted, and [onCompleted] fired the moment
/// the last digit lands so there is no separate "verify" hunt.
///
/// Implementation: one invisible [TextField] owns focus/keyboard/input while
/// the boxes are a pure visual projection of its value — keeps every
/// platform text behavior (paste, backspace, screen readers) for free.
class OtpInput extends StatefulWidget {
  final int length;
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;

  /// Called once when all [length] digits are filled.
  final ValueChanged<String> onCompleted;
  final String? errorText;
  final bool enabled;

  const OtpInput({
    super.key,
    required this.controller,
    required this.onCompleted,
    this.length = 6,
    this.onChanged,
    this.errorText,
    this.enabled = true,
  });

  @override
  State<OtpInput> createState() => _OtpInputState();
}

class _OtpInputState extends State<OtpInput> {
  final FocusNode _focusNode = FocusNode();
  bool _completedFired = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onValue);
    _focusNode.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onValue);
    _focusNode.dispose();
    super.dispose();
  }

  void _onValue() {
    final value = widget.controller.text;
    setState(() {});
    widget.onChanged?.call(value);
    if (value.length >= widget.length) {
      if (!_completedFired) {
        _completedFired = true;
        HapticFeedback.lightImpact();
        widget.onCompleted(value.substring(0, widget.length));
      }
    } else {
      _completedFired = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final value = widget.controller.text;
    final activeIndex = value.length.clamp(0, widget.length - 1);
    final hasError = widget.errorText != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          label: "OTP",
          textField: true,
          child: GestureDetector(
            // Tapping anywhere on the boxes summons the number pad.
            onTap: widget.enabled
                ? () => FocusScope.of(context).requestFocus(_focusNode)
                : null,
            child: Stack(
              children: [
                // The real input — visually hidden but fully functional.
                Positioned.fill(
                  child: Opacity(
                    opacity: 0,
                    child: TextField(
                      controller: widget.controller,
                      focusNode: _focusNode,
                      enabled: widget.enabled,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(widget.length),
                      ],
                      decoration:
                          const InputDecoration(counterText: ""),
                    ),
                  ),
                ),
                IgnorePointer(
                  child: Row(
                    children: [
                      for (int i = 0; i < widget.length; i++) ...[
                        if (i > 0) const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: AnimatedContainer(
                            duration: AppMotion.fast,
                            curve: AppMotion.press,
                            height: 56,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: AppColors.lightSurface,
                              borderRadius:
                                  BorderRadius.circular(AppRadius.md),
                              border: Border.all(
                                color: hasError
                                    ? AppColors.error
                                    : (_focusNode.hasFocus && i == activeIndex)
                                        ? AppColors.purple700
                                        : i < value.length
                                            ? AppColors.purple300
                                            : AppColors.onboardingDivider,
                                width: (_focusNode.hasFocus &&
                                        i == activeIndex) ||
                                        hasError
                                    ? 2
                                    : 1.4,
                              ),
                            ),
                            child: Text(
                              i < value.length ? value[i] : "",
                              style: theme.textTheme.headlineSmall
                                  ?.copyWith(color: AppColors.textPrimary),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              const Icon(Icons.error_outline,
                  color: AppColors.error, size: AppSizes.iconSm),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  widget.errorText!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.error, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
