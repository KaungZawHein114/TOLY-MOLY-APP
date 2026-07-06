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
import '../../auth/audio/auth_audio_map.dart';
import '../../auth/data/auth_failure.dart';
import '../../auth/providers/auth_provider.dart';
import '../onboarding_models.dart';
import '../onboarding_state.dart';

class ClientRulesScreen extends ConsumerStatefulWidget {
  const ClientRulesScreen({super.key});

  @override
  ConsumerState<ClientRulesScreen> createState() => _ClientRulesScreenState();
}

class _ClientRulesScreenState extends ConsumerState<ClientRulesScreen> {
  String? _error;
  bool _isSubmitting = false;

  Future<void> _continue() async {
    if (_isSubmitting) return;
    final draft = ref.read(clientDraftProvider);
    if (!draft.rulesAgreed) {
      setState(() => _error = OnboardingStrings.rulesAgreeRequiredError);
      return;
    }

    // This is the only place a client account actually gets created — only
    // reachable once every prior step (incl. phone verification and rules
    // agreement) has succeeded, so there's no way to end up with a
    // half-finished account in the database.
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
        audioKey: AuthAudioKeys.rules,
        agreed: draft.rulesAgreed,
        errorText: _error,
        onChanged: (v) {
          setState(() => _error = null);
          notifier.state = notifier.state.copyWith(rulesAgreed: v);
        },
      ),
      bottomBar: LargeButton(
        label: _isSubmitting ? OnboardingStrings.submittingLabel : OnboardingStrings.continueButton,
        icon: _isSubmitting ? null : Icons.arrow_forward,
        gradient: AppColors.purpleGradient,
        onTap: _continue,
      ),
    );
  }
}
