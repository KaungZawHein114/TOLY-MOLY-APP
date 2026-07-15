import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/onboarding_strings.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/mascot/mascot_state.dart';
import '../../../core/widgets/onboarding/onboarding_scaffold.dart';
import '../../../core/widgets/onboarding/success_state.dart';
import '../onboarding_models.dart';

/// Account-created celebration for clients: an animated success badge and a
/// status checklist (what's done ✓ / what's still pending ⏳) instead of a
/// paragraph — the user SEES where they stand at a glance.
class ClientWelcomeScreen extends StatelessWidget {
  const ClientWelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return OnboardingScaffold(
      progress: const OnboardingProgress(step: 4, totalSteps: 4),
      mascotState: PhoWaYokeState.success,
      mascotMessage: OnboardingStrings.successMascotMessage,
      // No recorded clip for the completion screen (auth screens don't use TTS).
      layout: OnboardingLayoutMode.moment,
      body: const Column(
        children: [
          SuccessState(
            title: OnboardingStrings.completionTitle,
            items: [
              SuccessItem(OnboardingStrings.otpVerifiedMessage, done: true),
              SuccessItem(OnboardingStrings.successAccountCreated, done: true),
              SuccessItem(OnboardingStrings.successPendingVerification,
                  done: false),
            ],
          ),
          SizedBox(height: AppSpacing.xl),
        ],
      ),
      // Primary action last (bottom = thumb rest); secondary above it, same
      // size but outlined so hierarchy is weight, not a smaller tap target.
      bottomBar: Column(
        children: [
          AppSecondaryButton(
            label: OnboardingStrings.completionContinueButton,
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("ဤ Demo တွင် Profile ဆက်ဖြည့်ခြင်းကို ပံ့ပိုးမထားပါသေးပါ"),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AppPrimaryButton(
            label: OnboardingStrings.completionUseNowButton,
            icon: Icons.check_circle_outline,
            onTap: () => context.go(Routes.customerHome),
          ),
        ],
      ),
    );
  }
}
