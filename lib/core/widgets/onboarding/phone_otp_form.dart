import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../constants/onboarding_strings.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../large_button.dart';
import 'field_label_with_voice.dart';

/// Used by [PhoneOtpForm] to switch in the verified-success container with a
/// small scale+fade entrance instead of an instant swap — a rare, one-time
/// moment per user, so a touch of delight is appropriate (not overdone).
class _SuccessPop extends StatelessWidget {
  final Widget child;
  const _SuccessPop({required this.child});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: AppMotion.medium,
      curve: AppMotion.enter,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.scale(scale: 0.92 + (value * 0.08), child: child),
        );
      },
      child: child,
    );
  }
}

/// Shared phone-number + OTP verification widget, used by both the client
/// and tasker phone-verification steps. Talks to the real backend via the
/// two callbacks — this widget itself knows nothing about Dio/Riverpod/the
/// auth repository, only "send returns an error message or a dev-mode code"
/// and "verify returns an error message or null".
class PhoneOtpForm extends StatefulWidget {
  final String initialPhone;
  final bool initiallyVerified;

  /// True when the OTP was already sent before this screen even appeared
  /// (basic_info_screen sends it immediately on phone+password submit, so
  /// a duplicate-phone error shows right there instead of two screens
  /// later). Skips straight to the code-entry box instead of waiting for
  /// a "Send OTP" tap.
  final bool alreadySent;

  /// Dev-mode code from that earlier send, shown immediately if present.
  final String? initialDevCode;

  final ValueChanged<String> onPhoneChanged;
  final VoidCallback onVerified;

  /// Returns the dev-mode OTP code on success (shown directly in the UI
  /// since there's no real SMS gateway yet — see backend spec §2), or
  /// throws with a user-facing message on failure.
  final Future<String?> Function(String phone) onSendOtp;

  /// Returns null on success, or a user-facing error message on failure.
  final Future<String?> Function(String code) onVerifyOtp;

  const PhoneOtpForm({
    super.key,
    required this.initialPhone,
    required this.initiallyVerified,
    this.alreadySent = false,
    this.initialDevCode,
    required this.onPhoneChanged,
    required this.onVerified,
    required this.onSendOtp,
    required this.onVerifyOtp,
  });

  @override
  State<PhoneOtpForm> createState() => _PhoneOtpFormState();
}

class _PhoneOtpFormState extends State<PhoneOtpForm> {
  late final TextEditingController _phoneController =
      TextEditingController(text: widget.initialPhone);
  final TextEditingController _otpController = TextEditingController();

  bool _otpSent = false;
  bool _verified = false;
  bool _sending = false;
  bool _verifying = false;
  String? _otpError;
  String? _devOtpCode;

  @override
  void initState() {
    super.initState();
    _verified = widget.initiallyVerified;
    _otpSent = widget.initiallyVerified || widget.alreadySent;
    _devOtpCode = widget.initialDevCode;
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (_phoneController.text.trim().isEmpty || _sending) return;
    setState(() {
      _sending = true;
      _otpError = null;
    });
    try {
      final devCode = await widget.onSendOtp(_phoneController.text.trim());
      if (!mounted) return;
      HapticFeedback.lightImpact();
      setState(() {
        _otpSent = true;
        _devOtpCode = devCode;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(devCode == null
              ? OnboardingStrings.otpSentMessage
              : "${OnboardingStrings.otpSentMessage} — $devCode"),
          backgroundColor: AppColors.purple700,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _verifyOtp() async {
    if (_verifying) return;
    setState(() {
      _verifying = true;
      _otpError = null;
    });
    final error = await widget.onVerifyOtp(_otpController.text.trim());
    if (!mounted) return;
    if (error == null) {
      HapticFeedback.heavyImpact();
      setState(() => _verified = true);
      widget.onVerified();
    } else {
      HapticFeedback.vibrate();
      setState(() => _otpError = error);
    }
    setState(() => _verifying = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FieldLabelWithVoice(
          label: OnboardingStrings.phoneLabel,
          readAloudText: OnboardingStrings.phoneLabel,
          mockTranscript: _verified ? null : "09123456789",
          onSpeechResult: _verified
              ? null
              : (v) {
                  setState(() => _phoneController.text = v);
                  widget.onPhoneChanged(v);
                },
        ),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          controller: _phoneController,
          enabled: !_verified,
          keyboardType: TextInputType.phone,
          onChanged: widget.onPhoneChanged,
          style: theme.textTheme.bodyLarge,
          decoration: InputDecoration(
            prefixIcon: const Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Align(
                widthFactor: 1,
                child: Text("MM +95", style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
            hintText: "09•••••••••",
            contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        if (_verified)
          _SuccessPop(
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: AppColors.success),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(OnboardingStrings.otpVerifiedMessage,
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: AppColors.success, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
          )
        else ...[
          LargeButton(
            label: _sending ? OnboardingStrings.submittingLabel : OnboardingStrings.sendOtpButton,
            icon: _sending ? null : Icons.sms_outlined,
            filled: false,
            outlineColor: AppColors.purple700,
            onTap: _sendOtp,
          ),
          if (_otpSent) ...[
            const SizedBox(height: AppSpacing.lg),
            FieldLabelWithVoice(
              label: OnboardingStrings.otpLabel,
              readAloudText: OnboardingStrings.otpLabel,
              mockTranscript: _devOtpCode ?? "123456",
              onSpeechResult: (v) => setState(() => _otpController.text = v),
            ),
            if (_devOtpCode != null) ...[
              const SizedBox(height: AppSpacing.xxs),
              Text(
                "Dev OTP: $_devOtpCode",
                style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
              ),
            ],
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              style: theme.textTheme.bodyLarge,
              decoration: InputDecoration(
                counterText: "",
                hintText: "123456",
                errorText: _otpError,
                contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            LargeButton(
              label: _verifying ? OnboardingStrings.submittingLabel : OnboardingStrings.verifyOtpButton,
              gradient: AppColors.purpleGradient,
              onTap: _verifyOtp,
            ),
          ],
        ],
      ],
    );
  }
}
