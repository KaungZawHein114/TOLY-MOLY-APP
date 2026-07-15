import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/onboarding_strings.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'onboarding/field_label_with_voice.dart';

/// The design system's canonical text field: label row (with optional
/// per-field listen/speak controls), leading icon, comfortable 56dp height,
/// rounded filled surface with a clear focus ring, and inline validation.
///
/// Every text input in the app should be this widget instead of a hand-rolled
/// `TextField` + `InputDecoration`, so focus/error/disabled states look and
/// behave identically everywhere.
///
/// ```dart
/// AppTextField(
///   label: OnboardingStrings.phoneLabel,
///   leadingIcon: Icons.phone_outlined,
///   keyboardType: TextInputType.phone,
///   controller: _phoneController,
///   errorText: _phoneError,
///   onChanged: (v) => ...,
/// )
/// ```
///
/// Voice accessibility: pass [audioKey] (pre-recorded clip) or rely on the
/// default TTS listen button for the label; pass [mockTranscript] +
/// [onSpeechResult] to get a microphone INSIDE the field (Messenger/Viber
/// pattern — voice is part of the input, never a separate step). Tapping the
/// mic shows a live "listening" state, then fills the field. Password fields
/// ([obscureText]) get a built-in show/hide toggle and intentionally never
/// show a mic.
class AppTextField extends StatefulWidget {
  /// Burmese-first field label rendered above the input. Null hides the row.
  final String? label;

  /// Listen-button behavior for the label row — see [FieldLabelWithVoice].
  final String? audioKey;
  final String? mockTranscript;
  final ValueChanged<String>? onSpeechResult;

  final TextEditingController? controller;
  final String? hintText;
  final String? errorText;

  /// Muted single-line helper below the field (hidden while an error shows).
  final String? helperText;
  final IconData? leadingIcon;

  /// Fixed lead-in text (e.g. "MM +95" for phone numbers). Wins over
  /// [leadingIcon] when both are given.
  final String? prefixText;
  final TextInputType? keyboardType;
  final bool obscureText;
  final bool enabled;
  final int? maxLength;
  final int maxLines;
  final bool autofocus;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  /// Standard [TextField] passthroughs — e.g. centered, letter-spaced digits
  /// for OTP entry.
  final TextAlign textAlign;
  final TextStyle? style;

  const AppTextField({
    super.key,
    this.label,
    this.audioKey,
    this.mockTranscript,
    this.onSpeechResult,
    this.controller,
    this.hintText,
    this.errorText,
    this.helperText,
    this.leadingIcon,
    this.prefixText,
    this.keyboardType,
    this.obscureText = false,
    this.enabled = true,
    this.maxLength,
    this.maxLines = 1,
    this.autofocus = false,
    this.onChanged,
    this.onSubmitted,
    this.textAlign = TextAlign.start,
    this.style,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  final FocusNode _focusNode = FocusNode();
  late bool _obscured = widget.obscureText;
  bool _listening = false;

  bool get _hasMic =>
      !widget.obscureText &&
      widget.enabled &&
      widget.mockTranscript != null &&
      widget.onSpeechResult != null;

  @override
  void initState() {
    super.initState();
    // Rebuild on focus flips so the leading icon can tint with the ring.
    _focusNode.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  // Mock capture with a real "listening" moment: the pause + pulsing mic is
  // what teaches "press, then speak" — an instant fill would read as a
  // glitch, not as the phone having heard you.
  Future<void> _startListening() async {
    if (_listening) return;
    HapticFeedback.mediumImpact();
    setState(() => _listening = true);
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    HapticFeedback.lightImpact();
    setState(() => _listening = false);
    widget.controller?.text = widget.mockTranscript!;
    widget.onSpeechResult!(widget.mockTranscript!);
  }

  OutlineInputBorder _border(Color color, double width) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: BorderSide(color: color, width: width),
      );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final focused = _focusNode.hasFocus;
    final iconColor = !widget.enabled
        ? AppColors.textSecondary.withValues(alpha: 0.5)
        : focused
            ? AppColors.purple700
            : AppColors.textSecondary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          // Label row keeps only the LISTEN control — the speak (mic) control
          // now lives inside the field itself, chat-app style.
          FieldLabelWithVoice(
            label: widget.label!,
            readAloudText: widget.label!,
            audioKey: widget.audioKey,
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        TextField(
          controller: widget.controller,
          focusNode: _focusNode,
          enabled: widget.enabled,
          autofocus: widget.autofocus,
          keyboardType: widget.keyboardType,
          obscureText: _obscured,
          maxLength: widget.maxLength,
          maxLines: widget.obscureText ? 1 : widget.maxLines,
          onChanged: widget.onChanged,
          onSubmitted: widget.onSubmitted,
          textAlign: widget.textAlign,
          style: widget.style ?? theme.textTheme.bodyLarge,
          decoration: InputDecoration(
            counterText: "",
            hintText: _listening
                ? OnboardingStrings.listeningLabel
                : widget.hintText,
            hintStyle: _listening
                ? theme.textTheme.bodyLarge?.copyWith(
                    color: AppColors.purple700, fontWeight: FontWeight.w600)
                : null,
            errorText: widget.errorText,
            helperText: widget.errorText == null ? widget.helperText : null,
            helperMaxLines: 2,
            errorMaxLines: 2,
            filled: true,
            fillColor: widget.enabled
                ? AppColors.lightSurface
                : AppColors.lightBg,
            // 16dp vertical padding + 16px bodyLarge line ≈ 56dp touch target.
            contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg, vertical: AppSpacing.lg),
            prefixIcon: widget.prefixText != null
                ? Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    child: Align(
                      widthFactor: 1,
                      child: Text(
                        widget.prefixText!,
                        style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w700, color: iconColor),
                      ),
                    ),
                  )
                : widget.leadingIcon != null
                    ? Icon(widget.leadingIcon,
                        color: iconColor, size: AppSizes.iconMd)
                    : null,
            suffixIcon: widget.obscureText
                ? Semantics(
                    label: _obscured
                        ? OnboardingStrings.showPasswordLabel
                        : OnboardingStrings.hidePasswordLabel,
                    button: true,
                    child: IconButton(
                      icon: Icon(
                        _obscured ? Icons.visibility_off : Icons.visibility,
                        color: AppColors.textSecondary,
                      ),
                      onPressed: () => setState(() => _obscured = !_obscured),
                    ),
                  )
                : _hasMic
                    ? Padding(
                        padding: const EdgeInsets.only(right: AppSpacing.sm),
                        child: _MicButton(
                          listening: _listening,
                          semanticLabel:
                              "${widget.label ?? ''} — ${OnboardingStrings.speakIntoMicLabel}",
                          onTap: _startListening,
                        ),
                      )
                    : null,
            suffixIconConstraints: _hasMic && !widget.obscureText
                ? const BoxConstraints(minWidth: 56, minHeight: 48)
                : null,
            border: _border(AppColors.onboardingDivider, 1),
            enabledBorder: _border(AppColors.onboardingDivider, 1),
            disabledBorder: _border(AppColors.onboardingDivider, 1),
            focusedBorder: _border(
                _listening ? AppColors.indigo500 : AppColors.purple700, 2),
            errorBorder: _border(AppColors.error, 1.4),
            focusedErrorBorder: _border(AppColors.error, 2),
          ),
        ),
      ],
    );
  }
}

/// In-field microphone (chat-app style). Idle: soft purple circle with a mic
/// glyph. Listening: pulses with the indigo "intelligence" accent so the
/// state change is unmistakable even without reading the hint text.
class _MicButton extends StatefulWidget {
  final bool listening;
  final String semanticLabel;
  final VoidCallback onTap;

  const _MicButton({
    required this.listening,
    required this.semanticLabel,
    required this.onTap,
  });

  @override
  State<_MicButton> createState() => _MicButtonState();
}

class _MicButtonState extends State<_MicButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    value: 1.0,
    duration: const Duration(milliseconds: 700),
    lowerBound: 0.85,
    upperBound: 1.1,
  );

  @override
  void didUpdateWidget(_MicButton old) {
    super.didUpdateWidget(old);
    if (widget.listening && !old.listening) {
      if (!MediaQuery.of(context).disableAnimations) {
        _pulse.repeat(reverse: true);
      }
    } else if (!widget.listening && old.listening) {
      _pulse.stop();
      _pulse.value = 1.0;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.semanticLabel,
      button: true,
      child: GestureDetector(
        onTap: widget.onTap,
        child: ScaleTransition(
          scale: _pulse,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: widget.listening
                  ? AppColors.indigo500
                  : AppColors.purple100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              widget.listening ? Icons.graphic_eq : Icons.mic_rounded,
              color: widget.listening
                  ? AppColors.onBrand
                  : AppColors.purple700,
              size: AppSizes.iconMd,
            ),
          ),
        ),
      ),
    );
  }
}
