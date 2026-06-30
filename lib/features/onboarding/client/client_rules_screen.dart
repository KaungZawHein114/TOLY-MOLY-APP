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

class ClientRulesScreen extends ConsumerStatefulWidget {
  const ClientRulesScreen({super.key});

  @override
  ConsumerState<ClientRulesScreen> createState() => _ClientRulesScreenState();
}

class _ClientRulesScreenState extends ConsumerState<ClientRulesScreen> {
  String? _error;

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(clientDraftProvider);
    final notifier = ref.read(clientDraftProvider.notifier);

    return OnboardingScaffold(
      progress: const OnboardingProgress(step: 3, totalSteps: 4),
      mascotState: PhoWaYokeState.pointing,
      mascotMessage: OnboardingStrings.rulesTitle,
      title: OnboardingStrings.rulesTitle,
      onBack: () => context.pop(),
      body: RulesAgreementPanel(
        rulesText: OnboardingStrings.rulesBodyText,
        agreementLabel: OnboardingStrings.rulesAgreeClientLabel,
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
          context.push(Routes.clientWelcome);
        },
      ),
    );
  }
}
