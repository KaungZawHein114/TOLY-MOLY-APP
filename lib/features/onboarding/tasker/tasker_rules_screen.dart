import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/onboarding_strings.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/large_button.dart';
import '../../../core/widgets/mascot/mascot_state.dart';
import '../../../core/widgets/onboarding/onboarding_scaffold.dart';
import '../../../core/widgets/onboarding/rules_agreement_panel.dart';
import '../onboarding_models.dart';
import '../onboarding_state.dart';

class TaskerRulesScreen extends ConsumerStatefulWidget {
  const TaskerRulesScreen({super.key});

  @override
  ConsumerState<TaskerRulesScreen> createState() => _TaskerRulesScreenState();
}

class _TaskerRulesScreenState extends ConsumerState<TaskerRulesScreen> {
  String? _error;

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(taskerDraftProvider);
    final notifier = ref.read(taskerDraftProvider.notifier);

    return OnboardingScaffold(
      progress: const OnboardingProgress(step: 4, totalSteps: 5),
      mascotState: PhoWaYokeState.pointing,
      mascotMessage: OnboardingStrings.rulesTitle,
      title: OnboardingStrings.rulesTitle,
      onBack: () => context.pop(),
      body: RulesAgreementPanel(
        rulesText: OnboardingStrings.rulesBodyText,
        agreementLabel: OnboardingStrings.rulesAgreeTaskerLabel,
        agreed: draft.rulesAgreed,
        errorText: _error,
        onChanged: (v) {
          setState(() => _error = null);
          notifier.state = notifier.state.copyWith(rulesAgreed: v);
        },
      ),
      bottomBar: LargeButton(
        label: OnboardingStrings.continueButton,
        icon: Icons.arrow_forward,
        gradient: AppColors.purpleGradient,
        onTap: () {
          if (!draft.rulesAgreed) {
            setState(() => _error = OnboardingStrings.rulesAgreeRequiredError);
            return;
          }
          context.push(Routes.taskerWelcome);
        },
      ),
    );
  }
}
