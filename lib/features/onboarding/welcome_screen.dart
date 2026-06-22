import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_strings.dart';
import '../../core/constants/onboarding_strings.dart';
import '../../core/routing/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/large_button.dart';
import '../../core/widgets/mascot/mascot_state.dart';
import '../../core/widgets/mascot/pho_wa_yoke.dart';

/// First screen of the onboarding journey. Purely a warm, branded greeting —
/// no form fields, no async, single primary action.
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
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Scrolls on short screens instead of overflowing; centers via
              // spaceBetween once content fits the viewport on tall ones.
              return SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.xxl),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - AppSpacing.xxl * 2,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const PhoWaYoke(state: PhoWaYokeState.happy, size: 220),
                      const SizedBox(height: AppSpacing.xxl),
                      Text(
                        AppStrings.appName,
                        style: theme.textTheme.displayLarge
                            ?.copyWith(color: AppColors.onBrand),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        OnboardingStrings.welcomeHeadline,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyLarge
                            ?.copyWith(color: AppColors.onBrandMuted),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        decoration: BoxDecoration(
                          color: AppColors.onBrand,
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                        ),
                        child: Text(
                          OnboardingStrings.welcomeMessageV2,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: AppColors.purple700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxxl),
                      LargeButton(
                        label: OnboardingStrings.getStarted,
                        icon: Icons.arrow_forward,
                        filled: false,
                        outlineColor: AppColors.onBrand,
                        onTap: () => context.push(Routes.onboardingCreateAccount),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
