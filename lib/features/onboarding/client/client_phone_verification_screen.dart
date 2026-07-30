import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/onboarding_strings.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_error_message.dart';
import '../../../core/widgets/mascot/mascot_state.dart';
import '../../../core/widgets/onboarding/inline_terms_agreement.dart';
import '../../../core/widgets/onboarding/onboarding_scaffold.dart';
import '../../../core/widgets/onboarding/phone_otp_form.dart';
import '../../auth/audio/auth_audio_map.dart';
import '../../auth/data/auth_failure.dart';
import '../../auth/providers/auth_provider.dart';
import '../onboarding_models.dart';
import '../onboarding_state.dart';

/// Final client signup step: phone verification + inline Terms agreement (the
/// standalone Terms page has been consolidated here). This is the ONLY place a
/// client account is actually created — reachable only after every prior step
/// (name, phone verification) and the T&C agreement have succeeded, so there's
/// no way to end up with a half-finished account in the database.
class ClientPhoneVerificationScreen extends ConsumerStatefulWidget {
  const ClientPhoneVerificationScreen({super.key});

  @override
  ConsumerState<ClientPhoneVerificationScreen> createState() =>
      _ClientPhoneVerificationScreenState();
}

class _ClientPhoneVerificationScreenState
    extends ConsumerState<ClientPhoneVerificationScreen> {
  bool _termsAccepted = false;
  bool _showTermsWarning = false;
  String? _error;
  bool _isSubmitting = false;

  void _setTerms(bool value) {
    setState(() {
      _termsAccepted = value;
      if (value) _showTermsWarning = false;
    });
  }

  Future<void> _agreeAndCreate() async {
    if (_isSubmitting) return;

    // Gate: must have agreed to the terms. Surface a warning instead of
    // silently doing nothing.
    if (!_termsAccepted) {
      setState(() => _showTermsWarning = true);
      return;
    }

    ref.read(clientDraftProvider.notifier).state =
        ref.read(clientDraftProvider).copyWith(rulesAgreed: true);
    final draft = ref.read(clientDraftProvider);

    setState(() {
      _error = null;
      _isSubmitting = true;
    });
    try {
      await ref.read(authRepositoryProvider).register(
            name: draft.name,
            phoneNumber: draft.phone,
            password: draft.password,
            gender: draft.gender!.name,
            age: draft.age!,
            role: "CLIENT",
          );
      if (!mounted) return;
      context.push(Routes.clientWelcome);
    } on AuthFailure catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(clientDraftProvider);

    return OnboardingScaffold(
      progress: const OnboardingProgress(step: 3, totalSteps: 4),
      mascotState: draft.otpVerified ? PhoWaYokeState.success : PhoWaYokeState.pointing,
      mascotMessage: OnboardingStrings.phoneVerificationTitle,
      title: OnboardingStrings.phoneVerificationTitle,
      readAloudAudioKey: AuthAudioKeys.phoneVerification,
      onBack: () => context.pop(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PhoneOtpForm(
            initialPhone: draft.phone,
            initiallyVerified: draft.otpVerified,
            alreadySent: draft.otpSent,
            initialDevCode: draft.lastDevOtpCode,
            phoneAudioKey: AuthAudioKeys.phone,
            otpAudioKey: AuthAudioKeys.otp,
            // "ပြင်မည်" pops back to the Account step, where the phone lives.
            onEditPhone: () => context.pop(),
            onPhoneChanged: (v) {
              final notifier = ref.read(clientDraftProvider.notifier);
              notifier.state = notifier.state.copyWith(phone: v);
            },
            onSendOtp: (phone) async {
              try {
                final result = await ref.read(authRepositoryProvider).sendOtp(phone);
                return result.devCode;
              } on AuthFailure catch (e) {
                throw e.message;
              }
            },
            onVerifyOtp: (code) async {
              try {
                await ref.read(authRepositoryProvider).verifyOtp(phoneNumber: draft.phone, code: code);
                return null;
              } on AuthFailure catch (e) {
                return e.message;
              }
            },
            onVerified: () {
              final notifier = ref.read(clientDraftProvider.notifier);
              notifier.state = notifier.state.copyWith(otpVerified: true);
            },
          ),
          // Inline Terms agreement — only meaningful once the phone is verified.
          if (draft.otpVerified) ...[
            const SizedBox(height: AppSpacing.xl),
            InlineTermsAgreement(
              accepted: _termsAccepted,
              onChanged: _setTerms,
              fullRulesText: OnboardingStrings.rulesBodyText,
              audioKey: AuthAudioKeys.rules,
              errorText: _showTermsWarning ? OnboardingStrings.termsRequiredWarning : null,
            ),
          ],
          AppErrorMessage(message: _error),
        ],
      ),
      // Enabled once the phone is verified; the terms gate is enforced on tap
      // (with a warning) so the user always understands what's required.
      bottomBar: AppPrimaryButton(
        label: OnboardingStrings.rulesAgreeCta,
        icon: Icons.check_circle_outline,
        enabled: draft.otpVerified,
        loading: _isSubmitting,
        onTap: _agreeAndCreate,
      ),
    );
  }
}
