import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../constants/onboarding_strings.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../large_button.dart';

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

/// Shared phone-number + mock-OTP verification widget. Used by both the
/// client and tasker phone-verification steps so the demo OTP behaviour
/// (12345) lives in exactly one place.
class PhoneOtpForm extends StatefulWidget {
  final String initialPhone;
  final bool initiallyVerified;
  final ValueChanged<String> onPhoneChanged;
  final VoidCallback onVerified;

  const PhoneOtpForm({
    super.key,
    required this.initialPhone,
    required this.initiallyVerified,
    required this.onPhoneChanged,
    required this.onVerified,
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
  String? _otpError;

  @override
  void initState() {
    super.initState();
    _verified = widget.initiallyVerified;
    _otpSent = widget.initiallyVerified;
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _sendOtp() {
    if (_phoneController.text.trim().isEmpty) return;
    HapticFeedback.lightImpact();
    setState(() {
      _otpSent = true;
      _otpError = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(OnboardingStrings.otpSentMessage),
        backgroundColor: AppColors.purple700,
      ),
    );
  }

  void _verifyOtp() {
    if (_otpController.text.trim() == OnboardingStrings.demoOtp) {
      HapticFeedback.heavyImpact();
      setState(() {
        _verified = true;
        _otpError = null;
      });
      widget.onVerified();
    } else {
      HapticFeedback.vibrate();
      setState(() => _otpError = OnboardingStrings.otpInvalidError);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(OnboardingStrings.phoneLabel, style: theme.textTheme.titleMedium),
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
            label: OnboardingStrings.sendOtpButton,
            icon: Icons.sms_outlined,
            filled: false,
            outlineColor: AppColors.purple700,
            onTap: _sendOtp,
          ),
          if (_otpSent) ...[
            const SizedBox(height: AppSpacing.lg),
            Text(OnboardingStrings.otpLabel, style: theme.textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              maxLength: 5,
              style: theme.textTheme.bodyLarge,
              decoration: InputDecoration(
                counterText: "",
                hintText: "12345",
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
              label: OnboardingStrings.verifyOtpButton,
              gradient: AppColors.purpleGradient,
              onTap: _verifyOtp,
            ),
          ],
        ],
      ],
    );
  }
}
