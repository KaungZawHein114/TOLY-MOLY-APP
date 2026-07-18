import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_strings.dart';
import '../../core/constants/onboarding_strings.dart';
import '../../core/routing/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/mascot/mascot_state.dart';
import '../../core/widgets/mascot/pho_wa_yoke.dart';
import '../../core/widgets/onboarding/staggered_entrance.dart';

/// First screen of the onboarding journey. Purely a warm, branded greeting —
/// no form fields, no async, single primary action.
///
/// Layout: greeting content centers in the scrollable area while the one CTA
/// stays pinned at the bottom inside thumb reach (Fitts's law) — it never
/// scrolls away, and there is exactly one thing to do (Hick's law).
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(gradient: AppColors.purpleGradient),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // Scrolls on short screens instead of overflowing;
                    // centers once content fits the viewport on tall ones.
                    return SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xxl, vertical: AppSpacing.xl),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: (constraints.maxHeight - AppSpacing.xl * 2)
                              .clamp(0.0, double.infinity),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            StaggeredEntrance(
                              children: [
                                const Center(
                                  child: PhoWaYoke(
                                      state: PhoWaYokeState.happy, size: 200),
                                ),
                                const SizedBox(height: AppSpacing.xxl),
                                Text(
                                  AppStrings.appName,
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.displayLarge
                                      ?.copyWith(color: AppColors.onBrand),
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                Text(
                                  OnboardingStrings.welcomeHeadline,
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    color: AppColors.onBrandMuted,
                                    height: 1.5,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.xxl),
                                // Pho Wa Yoke's greeting as a speech-bubble
                                // card: white surface + a soft lift so it
                                // reads as "the mascot talking to you".
                                Container(
                                  padding: const EdgeInsets.all(AppSpacing.xl),
                                  decoration: BoxDecoration(
                                    color: AppColors.onBrand,
                                    borderRadius:
                                        BorderRadius.circular(AppRadius.lg),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.purple900
                                            .withValues(alpha: 0.25),
                                        blurRadius: 20,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    OnboardingStrings.welcomeMessageV2,
                                    textAlign: TextAlign.center,
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      color: AppColors.purple700,
                                      fontWeight: FontWeight.w600,
                                      height: 1.6,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              // Pinned actions — always visible, always in thumb reach. New
              // users get the big white CTA; returning users get their own
              // clearly-labeled path (Jakob's law) instead of a hidden tab.
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xxl, AppSpacing.md, AppSpacing.xxl, AppSpacing.lg),
                child: Column(
                  children: [
                    AppPrimaryButton(
                      label: OnboardingStrings.getStarted,
                      icon: Icons.arrow_forward,
                      inverse: true,
                      onTap: () => context.push(Routes.onboardingCreateAccount),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextButton(
                      onPressed: () => context.push(Routes.onboardingSignIn),
                      style: TextButton.styleFrom(
                        minimumSize: const Size(48, 48),
                      ),
                      child: Text(
                        "${OnboardingStrings.haveAccountPrompt} ${OnboardingStrings.loginTab}",
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: AppColors.onBrand,
                          fontWeight: FontWeight.w700,
                          decoration: TextDecoration.underline,
                          decorationColor: AppColors.onBrandMuted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
