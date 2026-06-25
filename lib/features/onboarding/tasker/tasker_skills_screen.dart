import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/onboarding_strings.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/large_button.dart';
import '../../../core/widgets/mascot/mascot_state.dart';
import '../../../core/widgets/onboarding/choice_wrap.dart';
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
    final current = Set<TaskerSkill>.from(notifier.state.skills);
    if (current.contains(skill)) {
      current.remove(skill);
    } else {
      current.add(skill);
    }
    notifier.state = notifier.state.copyWith(skills: current);
    setState(() => _skillsError = null);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final draft = ref.watch(taskerDraftProvider);
    final notifier = ref.read(taskerDraftProvider.notifier);

    return OnboardingScaffold(
      progress: const OnboardingProgress(step: 3, totalSteps: 6),
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
          const SizedBox(height: AppSpacing.xl),
          Text(OnboardingStrings.experienceQuestion, style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.md),
          ChoiceWrap<ExperienceLevel>(
            values: ExperienceLevel.values,
            selected: draft.experienceLevel,
            labelOf: (v) => v.label,
            emojiOf: (_) => "⏱️",
            onSelect: (v) => notifier.state = notifier.state.copyWith(experienceLevel: v),
          ),
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
          context.push(Routes.taskerProfile);
        },
      ),
    );
  }
}
