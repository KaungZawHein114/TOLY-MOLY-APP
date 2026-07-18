import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/onboarding_strings.dart';
import '../../core/routing/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/mascot/mascot_state.dart';
import '../../core/widgets/onboarding/onboarding_scaffold.dart';
import '../../core/widgets/onboarding/role_selection_card.dart';
import 'onboarding_models.dart';
import 'onboarding_state.dart';

/// Step 1 of signup — ONLY the role question ("what would you like to do?").
///
/// Redesigned from the old tabbed create-account/login screen: sign-in moved
/// to its own [SignInScreen], and the two role cards became the whole screen.
/// Tapping a card answers the question AND advances (the card is the button),
/// going straight to that role's About You step — name/phone/password come
/// later, one comfortable chunk at a time (progressive disclosure).
class CreateAccountScreen extends ConsumerWidget {
  const CreateAccountScreen({super.key});

  void _selectRole(BuildContext context, WidgetRef ref, UserRole role) {
    ref.read(selectedRoleProvider.notifier).state = role;
    // Brief selected flash before advancing, so the choice is visibly
    // acknowledged without a second "continue" tap.
    Future.delayed(AppMotion.fast, () {
      if (!context.mounted) return;
      context.push(
        role == UserRole.tasker ? Routes.taskerPersonal : Routes.clientPersonal,
      );
    });
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final role = ref.watch(selectedRoleProvider);

    return OnboardingScaffold(
      mascotState: PhoWaYokeState.pointing,
      mascotMessage: OnboardingStrings.chooseRolePromptV2,
      onBack: () => context.pop(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.md),
          Text(OnboardingStrings.chooseRolePrompt,
              style: theme.textTheme.headlineSmall),
          const SizedBox(height: AppSpacing.xl),
          RoleSelectionCard(
            emoji: "💼",
            label: OnboardingStrings.roleClientLabel,
            sublabel: OnboardingStrings.roleClientSublabel,
            selected: role == UserRole.client,
            onTap: () => _selectRole(context, ref, UserRole.client),
          ),
          const SizedBox(height: AppSpacing.lg),
          RoleSelectionCard(
            emoji: "🛠️",
            label: OnboardingStrings.roleTaskerLabel,
            sublabel: OnboardingStrings.roleTaskerSublabel,
            selected: role == UserRole.tasker,
            onTap: () => _selectRole(context, ref, UserRole.tasker),
          ),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
      // No bottom action — the cards themselves advance. A quiet sign-in
      // escape hatch sits where a form's CTA would be, for anyone who came
      // this far by mistake.
      bottomBar: Center(
        child: TextButton(
          onPressed: () => context.push(Routes.onboardingSignIn),
          style: TextButton.styleFrom(
            minimumSize: const Size(48, 48),
            foregroundColor: AppColors.purple700,
          ),
          child: Text(
            "${OnboardingStrings.haveAccountPrompt} ${OnboardingStrings.loginTab}",
            style: theme.textTheme.bodyLarge?.copyWith(
              color: AppColors.purple700,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
