import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/onboarding_strings.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/large_button.dart';
import '../../../core/widgets/mascot/mascot_state.dart';
import '../../../core/widgets/onboarding/onboarding_scaffold.dart';
import '../../../core/widgets/onboarding/phone_otp_form.dart';
import '../../auth/audio/auth_audio_map.dart';
import '../../auth/data/auth_failure.dart';
import '../../auth/providers/auth_provider.dart';
import '../onboarding_models.dart';
import '../onboarding_state.dart';

class ClientPhoneVerificationScreen extends ConsumerWidget {
  const ClientPhoneVerificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(clientDraftProvider);

    return OnboardingScaffold(
      progress: const OnboardingProgress(step: 2, totalSteps: 4),
      mascotState: draft.otpVerified ? PhoWaYokeState.success : PhoWaYokeState.pointing,
      mascotMessage: OnboardingStrings.phoneVerificationTitle,
      title: OnboardingStrings.phoneVerificationTitle,
      readAloudAudioKey: AuthAudioKeys.phoneVerification,
      onBack: () => context.pop(),
      body: PhoneOtpForm(
        initialPhone: draft.phone,
        initiallyVerified: draft.otpVerified,
        alreadySent: draft.otpSent,
        initialDevCode: draft.lastDevOtpCode,
        phoneAudioKey: AuthAudioKeys.phone,
        otpAudioKey: AuthAudioKeys.otp,
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
      bottomBar: LargeButton(
        label: OnboardingStrings.continueButton,
        icon: Icons.arrow_forward,
        gradient: AppColors.purpleGradient,
        onTap: draft.otpVerified
            ? () => context.push(Routes.clientRules)
            : () => ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(OnboardingStrings.otpInvalidError)),
                ),
      ),
    );
  }
}
