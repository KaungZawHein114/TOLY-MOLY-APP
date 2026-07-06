import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/onboarding_strings.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/large_button.dart';
import '../../../core/widgets/mascot/mascot_state.dart';
import '../../../core/widgets/onboarding/onboarding_scaffold.dart';
import '../../../core/widgets/onboarding/staggered_entrance.dart';
import '../onboarding_models.dart';

class ClientWelcomeScreen extends StatelessWidget {
  const ClientWelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return OnboardingScaffold(
      progress: const OnboardingProgress(step: 4, totalSteps: 4),
      mascotState: PhoWaYokeState.success,
      mascotMessage: OnboardingStrings.completionUnverifiedMessage,
      title: OnboardingStrings.completionTitle,
      // No recorded clip for the completion screen (auth screens don't use TTS).
      layout: OnboardingLayoutMode.moment,
      body: StaggeredEntrance(
        children: [
          const SizedBox(height: AppSpacing.md),
          Text(
            OnboardingStrings.completionContinuePrompt,
            style: theme.textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          Text(
            OnboardingStrings.completionOrPrompt,
            style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          Text(
            OnboardingStrings.completionUseNowPrompt,
            style: theme.textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
      bottomBar: Column(
        children: [
          LargeButton(
            label: OnboardingStrings.completionContinueButton,
            filled: false,
            outlineColor: AppColors.purple700,
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("ဤ Demo တွင် Profile ဆက်ဖြည့်ခြင်းကို ပံ့ပိုးမထားပါသေးပါ"),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          LargeButton(
            label: OnboardingStrings.completionUseNowButton,
            icon: Icons.check_circle_outline,
            gradient: AppColors.purpleGradient,
            celebratory: true,
            onTap: () => context.go(Routes.customerHome),
          ),
        ],
      ),
    );
  }
}
