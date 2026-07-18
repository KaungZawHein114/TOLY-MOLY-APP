import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../constants/onboarding_strings.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../app_buttons.dart';
import 'otp_input.dart';

/// Matches the backend's OTP length (DEV_FIXED_OTP_CODE = "12345" — see
/// backend/apps/authentication/services.py). One box per digit, so this must
/// stay in sync or the auto-submit on the last box can never fire.
const int _otpLength = 5;

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

/// Redesigned OTP verification panel, shared by the client and tasker
/// verification steps.
///
/// The OTP was already sent when the user submitted their phone number on
/// the Account step, so this screen asks exactly ONE thing: the code. The
/// phone number is shown as plain text with an "ပြင်မည်" link (no editable
/// field — no "do I need to send it again?" confusion), the code goes into
/// large boxed digits that auto-verify on the last digit, and resending is a
/// single text action.
///
/// Talks to the real backend via the callbacks — this widget knows nothing
/// about Dio/Riverpod/the auth repository.
class PhoneOtpForm extends StatefulWidget {
  final String initialPhone;
  final bool initiallyVerified;

  /// True when the OTP was already sent before this screen appeared (the
  /// Account step sends it on submit). In the redesigned flow this is the
  /// normal case; false only on odd re-entries, where the resend action
  /// covers it.
  final bool alreadySent;

  /// Dev-mode code from that earlier send, shown as a helper (no real SMS
  /// gateway yet — see backend spec §2).
  final String? initialDevCode;

  final ValueChanged<String> onPhoneChanged;
  final VoidCallback onVerified;

  /// Pops back to the Account step so the phone can be corrected.
  final VoidCallback? onEditPhone;

  /// AUTH-ONLY: pre-recorded clip keys (from `AuthAudioKeys`) for the phone
  /// and OTP labels. (TTS is never used on auth screens.)
  final String? phoneAudioKey;
  final String? otpAudioKey;

  /// Returns the dev-mode OTP code on success, or throws with a user-facing
  /// message on failure.
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
    this.onEditPhone,
    this.phoneAudioKey,
    this.otpAudioKey,
  });

  @override
  State<PhoneOtpForm> createState() => _PhoneOtpFormState();
}

class _PhoneOtpFormState extends State<PhoneOtpForm> {
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
    _otpController.dispose();
    super.dispose();
  }

  /// Used both for the first explicit "OTP ပို့မည်" tap and for resends.
  Future<void> _sendOtp() async {
    if (_sending) return;
    setState(() {
      _sending = true;
      _otpError = null;
      _otpController.clear();
    });
    try {
      final devCode = await widget.onSendOtp(widget.initialPhone.trim());
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

  Future<void> _verifyOtp(String code) async {
    if (_verifying || _verified) return;
    setState(() {
      _verifying = true;
      _otpError = null;
    });
    final error = await widget.onVerifyOtp(code.trim());
    if (!mounted) return;
    if (error == null) {
      HapticFeedback.heavyImpact();
      setState(() => _verified = true);
      widget.onVerified();
    } else {
      HapticFeedback.vibrate();
      setState(() {
        _otpError = error;
        _otpController.clear();
      });
    }
    setState(() => _verifying = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Phone shown as FACT, not as a field to fill again ──
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg, vertical: AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.lightSurface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.onboardingDivider),
          ),
          child: Row(
            children: [
              const Icon(Icons.phone_android,
                  color: AppColors.purple700, size: AppSizes.iconMd),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  widget.initialPhone,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(letterSpacing: 1.2),
                ),
              ),
              if (widget.onEditPhone != null && !_verified)
                TextButton(
                  onPressed: widget.onEditPhone,
                  style: TextButton.styleFrom(
                    minimumSize: const Size(48, 44),
                    foregroundColor: AppColors.purple700,
                  ),
                  child: Text(
                    OnboardingStrings.otpEditPhone,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.purple700,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        if (_verified)
          _SuccessPop(
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                    color: AppColors.success.withValues(alpha: 0.35)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: AppColors.success),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(OnboardingStrings.otpVerifiedMessage,
                        style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.success,
                            fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
          )
        else if (!_otpSent)
          // No code in flight yet — one clear, explicit action ("OTP ပို့မည်")
          // instead of expecting the user to guess that a resend link would
          // also do the first send.
          AppPrimaryButton(
            label: OnboardingStrings.sendOtpButton,
            icon: Icons.sms_outlined,
            loading: _sending,
            onTap: _sendOtp,
          )
        else ...[
          Text(
            "${OnboardingStrings.otpSentToPrefix} ${widget.initialPhone}",
            style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
          ),
          if (_devOtpCode != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              "Dev OTP: $_devOtpCode",
              style:
                  theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          // Boxed digits, auto-verifies when the last digit lands — no
          // separate verify button to find.
          OtpInput(
            controller: _otpController,
            length: _otpLength,
            enabled: !_verifying,
            errorText: _otpError,
            onChanged: (_) {
              if (_otpError != null) setState(() => _otpError = null);
            },
            onCompleted: _verifyOtp,
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              if (_verifying) ...[
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppColors.purple700),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(OnboardingStrings.submittingLabel,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: AppColors.textSecondary)),
              ] else
                TextButton.icon(
                  onPressed: _sending ? null : _sendOtp,
                  icon: const Icon(Icons.refresh, size: AppSizes.iconMd),
                  label: Text(_sending
                      ? OnboardingStrings.submittingLabel
                      : OnboardingStrings.otpResendButton),
                  style: TextButton.styleFrom(
                    minimumSize: const Size(48, 48),
                    foregroundColor: AppColors.purple700,
                    textStyle: theme.textTheme.bodyLarge
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}
