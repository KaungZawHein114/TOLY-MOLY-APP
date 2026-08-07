import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/onboarding_strings.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_error_message.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/mascot/mascot_state.dart';
import '../../../core/widgets/onboarding/inline_terms_agreement.dart';
import '../../../core/widgets/onboarding/onboarding_scaffold.dart';
import '../../../core/widgets/onboarding/onboarding_selection_card.dart';
import '../../auth/data/auth_failure.dart';
import '../../auth/providers/auth_provider.dart';
import '../../profile/data/skills_repository_impl.dart';
import '../onboarding_models.dart';
import '../onboarding_state.dart';

/// Final tasker signup step: skills + experience + inline Terms agreement (the
/// standalone Terms page has been consolidated here). This is the ONLY place a
/// tasker account is actually created — reachable only after every prior step
/// (name, phone verification, skills) and the T&C agreement have succeeded.
class TaskerSkillsScreen extends ConsumerStatefulWidget {
  const TaskerSkillsScreen({super.key});

  @override
  ConsumerState<TaskerSkillsScreen> createState() => _TaskerSkillsScreenState();
}

class _TaskerSkillsScreenState extends ConsumerState<TaskerSkillsScreen> {
  late final TextEditingController _customSkillController;
  String? _skillsError;
  bool _termsAccepted = false;
  bool _showTermsWarning = false;
  String? _error;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _customSkillController =
        TextEditingController(text: ref.read(taskerDraftProvider).customSkill);
  }

  @override
  void dispose() {
    _customSkillController.dispose();
    super.dispose();
  }

  void _toggleSkill(TaskerSkill skill) {
    final notifier = ref.read(taskerDraftProvider.notifier);
    final skills = Set<TaskerSkill>.from(notifier.state.skills);
    final experience =
        Map<TaskerSkill, ExperienceLevel>.from(notifier.state.skillExperience);
    if (skills.contains(skill)) {
      skills.remove(skill);
      experience.remove(skill);
    } else {
      skills.add(skill);
    }
    notifier.state =
        notifier.state.copyWith(skills: skills, skillExperience: experience);
    setState(() => _skillsError = null);
  }

  void _setExperience(TaskerSkill skill, ExperienceLevel level) {
    final notifier = ref.read(taskerDraftProvider.notifier);
    final experience =
        Map<TaskerSkill, ExperienceLevel>.from(notifier.state.skillExperience);
    experience[skill] = level;
    notifier.state = notifier.state.copyWith(skillExperience: experience);
  }

  void _setTerms(bool value) {
    setState(() {
      _termsAccepted = value;
      if (value) _showTermsWarning = false;
    });
  }

  Future<void> _createAccount() async {
    if (_isSubmitting) return;

    final draft = ref.read(taskerDraftProvider);

    // Gate 1: at least one skill (existing rule).
    if (draft.skills.isEmpty && draft.customSkill.trim().isEmpty) {
      setState(() => _skillsError = OnboardingStrings.skillsRequiredError);
      return;
    }
    // Gate 2: must have agreed to the terms.
    if (!_termsAccepted) {
      setState(() => _showTermsWarning = true);
      return;
    }

    ref.read(taskerDraftProvider.notifier).state =
        ref.read(taskerDraftProvider).copyWith(rulesAgreed: true);
    final agreed = ref.read(taskerDraftProvider);

    setState(() {
      _error = null;
      _isSubmitting = true;
    });
    try {
      await ref.read(authRepositoryProvider).register(
            name: agreed.name,
            phoneNumber: agreed.phone,
            password: agreed.password,
            gender: agreed.gender!.name,
            age: agreed.age!,
            role: "TASKER",
          );
      // Seed the profile's Skills section from the signup choices — best
      // effort: a failed sync shouldn't block the account just created.
      await _syncSkillsToBackend(agreed);
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
    final theme = Theme.of(context);
    final draft = ref.watch(taskerDraftProvider);
    final notifier = ref.read(taskerDraftProvider.notifier);

    return OnboardingScaffold(
      progress: const OnboardingProgress(step: 4, totalSteps: 4),
      mascotState: PhoWaYokeState.pointing,
      mascotMessage: OnboardingStrings.skillsMascotMessage,
      title: OnboardingStrings.skillsTitle,
      onBack: () => context.pop(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: AppSpacing.md,
            crossAxisSpacing: AppSpacing.md,
            childAspectRatio: 0.78,
            children: TaskerSkill.values.map((s) {
              return OnboardingSelectionCard(
                emoji: s.emoji,
                label: s.label,
                selected: draft.skills.contains(s),
                onTap: () => _toggleSkill(s),
              );
            }).toList(),
          ),
          AppErrorMessage(message: _skillsError),
          if (draft.skills.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xl),
            Text(OnboardingStrings.experienceQuestion,
                style: theme.textTheme.titleMedium),
            const SizedBox(height: AppSpacing.md),
            // Stable, selection-order-independent layout: walk the enum's
            // own order rather than the Set's insertion order.
            for (final s in TaskerSkill.values.where(draft.skills.contains))
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _SkillExperienceRow(
                  skill: s,
                  selected: draft.skillExperience[s],
                  onSelect: (level) => _setExperience(s, level),
                ),
              ),
          ],
          const SizedBox(height: AppSpacing.xl),
          AppTextField(
            label: OnboardingStrings.customSkillLabel,
            controller: _customSkillController,
            leadingIcon: Icons.handyman_outlined,
            hintText: OnboardingStrings.customSkillLabel,
            onChanged: (v) =>
                notifier.state = notifier.state.copyWith(customSkill: v),
          ),
          const SizedBox(height: AppSpacing.xl),
          // Inline Terms agreement — consolidated from the old Terms page.
          InlineTermsAgreement(
            accepted: _termsAccepted,
            onChanged: _setTerms,
            fullRulesText: OnboardingStrings.rulesBodyText,
            errorText: _showTermsWarning
                ? OnboardingStrings.termsRequiredWarning
                : null,
          ),
          AppErrorMessage(message: _error),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
      bottomBar: AppPrimaryButton(
        label: OnboardingStrings.rulesAgreeCta,
        icon: Icons.check_circle_outline,
        loading: _isSubmitting,
        onTap: _createAccount,
      ),
    );
  }
}

/// One selected skill's row in the experience step: the skill's emoji/label
/// on the left, a duration dropdown ("၆ လ", "၁ နှစ်", ...) on the right.
/// Lets each skill carry its own experience instead of one duration for the
/// whole profile.
class _SkillExperienceRow extends StatelessWidget {
  final TaskerSkill skill;
  final ExperienceLevel? selected;
  final ValueChanged<ExperienceLevel> onSelect;

  const _SkillExperienceRow({
    required this.skill,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.onboardingDivider),
      ),
      child: Row(
        children: [
          Text(skill.emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              skill.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          DropdownButton<ExperienceLevel>(
            value: selected,
            hint: Text(OnboardingStrings.experienceDropdownPlaceholder),
            underline: const SizedBox.shrink(),
            onChanged: (v) {
              if (v != null) onSelect(v);
            },
            items: [
              for (final level in ExperienceLevel.values)
                DropdownMenuItem(value: level, child: Text(level.label)),
            ],
          ),
        ],
      ),
    );
  }
}
