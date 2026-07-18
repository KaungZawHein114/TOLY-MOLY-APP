import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/onboarding_strings.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_error_message.dart';
import '../../../core/widgets/mascot/mascot_state.dart';
import '../../../core/widgets/onboarding/onboarding_scaffold.dart';
import '../../../core/widgets/onboarding/rules_summary_panel.dart';
import '../../auth/audio/auth_audio_map.dart';
import '../../auth/data/auth_failure.dart';
import '../../auth/providers/auth_provider.dart';
import '../onboarding_models.dart';
import '../onboarding_state.dart';

/// Redesigned Terms step: rules as recognizable icon rows (full text behind
/// "အပြည့်အစုံ ဖတ်မည်"), and agreement is the screen's single big CTA — one
/// tap agrees AND creates the account, instead of checkbox-then-continue.
class ClientRulesScreen extends ConsumerStatefulWidget {
  const ClientRulesScreen({super.key});

  @override
  ConsumerState<ClientRulesScreen> createState() => _ClientRulesScreenState();
}

class _ClientRulesScreenState extends ConsumerState<ClientRulesScreen> {
  String? _error;
  bool _isSubmitting = false;

  Future<void> _agreeAndCreate() async {
    if (_isSubmitting) return;
    // The big CTA IS the agreement — record it on the draft, then create.
    ref.read(clientDraftProvider.notifier).state =
        ref.read(clientDraftProvider).copyWith(rulesAgreed: true);
    final draft = ref.read(clientDraftProvider);

    // This is the only place a client account actually gets created — only
    // reachable once every prior step (incl. phone verification) has
    // succeeded, so there's no way to end up with a half-finished account
    // in the database.
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
    return OnboardingScaffold(
      progress: const OnboardingProgress(step: 3, totalSteps: 4),
      mascotState: PhoWaYokeState.pointing,
      mascotMessage: OnboardingStrings.rulesTitle,
      title: OnboardingStrings.rulesTitle,
      onBack: () => context.pop(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const RulesSummaryPanel(
            fullRulesText: OnboardingStrings.rulesBodyText,
            audioKey: AuthAudioKeys.rules,
          ),
          AppErrorMessage(message: _error),
        ],
      ),
      bottomBar: AppPrimaryButton(
        label: OnboardingStrings.rulesAgreeCta,
        icon: Icons.check_circle_outline,
        loading: _isSubmitting,
        onTap: _agreeAndCreate,
      ),
    );
  }
}
