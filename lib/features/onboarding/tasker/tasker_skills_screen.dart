import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/onboarding_strings.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/large_button.dart';
import '../../../core/widgets/mascot/mascot_state.dart';
import '../../../core/widgets/onboarding/onboarding_scaffold.dart';
import '../../../core/widgets/onboarding/onboarding_selection_card.dart';
import '../../../core/widgets/onboarding/speech_to_text_button.dart';
import '../onboarding_models.dart';
import '../onboarding_state.dart';

class TaskerSkillsScreen extends ConsumerStatefulWidget {
  const TaskerSkillsScreen({super.key});

  @override
  ConsumerState<TaskerSkillsScreen> createState() => _TaskerSkillsScreenState();
}

class _TaskerSkillsScreenState extends ConsumerState<TaskerSkillsScreen> {
  late final TextEditingController _customSkillController;
  String? _skillsError;

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
    final experience = Map<TaskerSkill, ExperienceLevel>.from(notifier.state.skillExperience);
    if (skills.contains(skill)) {
      skills.remove(skill);
      experience.remove(skill);
    } else {
      skills.add(skill);
    }
    notifier.state = notifier.state.copyWith(skills: skills, skillExperience: experience);
    setState(() => _skillsError = null);
  }

  void _setExperience(TaskerSkill skill, ExperienceLevel level) {
    final notifier = ref.read(taskerDraftProvider.notifier);
    final experience = Map<TaskerSkill, ExperienceLevel>.from(notifier.state.skillExperience);
    experience[skill] = level;
    notifier.state = notifier.state.copyWith(skillExperience: experience);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final draft = ref.watch(taskerDraftProvider);
    final notifier = ref.read(taskerDraftProvider.notifier);

    return OnboardingScaffold(
      progress: const OnboardingProgress(step: 3, totalSteps: 5),
      mascotState: PhoWaYokeState.pointing,
      mascotMessage: OnboardingStrings.skillsMascotMessage,
      title: OnboardingStrings.skillsTitle,
      readAloudText: OnboardingStrings.skillsMascotMessage,
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
          if (_skillsError != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(_skillsError!, style: theme.textTheme.bodySmall?.copyWith(color: AppColors.error)),
          ],
          if (draft.skills.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xl),
            Text(OnboardingStrings.experienceQuestion, style: theme.textTheme.titleMedium),
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
          Text(OnboardingStrings.customSkillLabel, style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _customSkillController,
                  style: theme.textTheme.bodyLarge,
                  onChanged: (v) => notifier.state = notifier.state.copyWith(customSkill: v),
                  decoration: InputDecoration(
                    hintText: OnboardingStrings.customSkillLabel,
                    contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              SpeechToTextButton(
                semanticPrompt: OnboardingStrings.customSkillLabel,
                mockTranscript: "ပန်းခြံပြုပြင်ခြင်း",
                onResult: (v) {
                  _customSkillController.text = v;
                  notifier.state = notifier.state.copyWith(customSkill: v);
                },
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
      bottomBar: LargeButton(
        label: OnboardingStrings.continueButton,
        icon: Icons.arrow_forward,
        gradient: AppColors.purpleGradient,
        onTap: () {
          if (draft.skills.isEmpty && draft.customSkill.trim().isEmpty) {
            setState(() => _skillsError = OnboardingStrings.skillsRequiredError);
            return;
          }
          context.push(Routes.taskerRules);
        },
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
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
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
              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
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
