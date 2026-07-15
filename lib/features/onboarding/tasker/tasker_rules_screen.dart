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
import '../../profile/data/skills_repository_impl.dart';
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
    // The big CTA IS the agreement — record it on the draft, then create.
    ref.read(taskerDraftProvider.notifier).state =
        ref.read(taskerDraftProvider).copyWith(rulesAgreed: true);
    final draft = ref.read(taskerDraftProvider);

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
      // Seed the profile's Skills section from whatever the tasker picked
      // during signup, so they don't have to re-enter it manually. Best
      // effort: a failed sync here shouldn't block the account that was
      // just successfully created.
      await _syncSkillsToBackend(draft);
      if (!mounted) return;
      context.push(Routes.taskerWelcome);
    } on AuthFailure catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _syncSkillsToBackend(TaskerProfileDraft draft) async {
    final repo = SkillsRepositoryImpl();
    for (final skill in draft.skills) {
      try {
        await repo.create(
          skillName: skill.label,
          experienceYears: draft.skillExperience[skill]?.years ?? 0,
        );
      } catch (_) {
        // Ignore — one failed skill shouldn't stop the rest from syncing.
      }
    }
    final customSkill = draft.customSkill.trim();
    if (customSkill.isNotEmpty) {
      try {
        await repo.create(skillName: customSkill, experienceYears: 0);
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingScaffold(
      progress: const OnboardingProgress(step: 4, totalSteps: 5),
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
        onTap: _continue,
      ),
    );
  }
}
