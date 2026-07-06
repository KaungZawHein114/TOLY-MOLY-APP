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

class TaskerRulesScreen extends ConsumerStatefulWidget {
  const TaskerRulesScreen({super.key});

  @override
  ConsumerState<TaskerRulesScreen> createState() => _TaskerRulesScreenState();
}

class _TaskerRulesScreenState extends ConsumerState<TaskerRulesScreen> {
  String? _error;
  bool _isSubmitting = false;

  Future<void> _continue() async {
    if (_isSubmitting) return;
    final draft = ref.read(taskerDraftProvider);
    if (!draft.rulesAgreed) {
      setState(() => _error = OnboardingStrings.rulesAgreeRequiredError);
      return;
    }

    // This is the only place a tasker account actually gets created — only
    // reachable once every prior step (incl. phone verification, skills,
    // and rules agreement) has succeeded.
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
            role: "TASKER",
          );
      if (!mounted) return;
      context.push(Routes.taskerWelcome);
    } on AuthFailure catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

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
