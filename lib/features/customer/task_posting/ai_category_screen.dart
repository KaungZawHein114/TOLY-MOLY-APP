import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/task_posting_strings.dart';
import '../../../core/data/demo_data.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/ai_mock.dart';
import '../../../core/widgets/mascot/mascot_state.dart';
import '../../../core/widgets/onboarding/onboarding_scaffold.dart';
import '../../../core/widgets/onboarding/onboarding_selection_card.dart';
import '../../../core/widgets/onboarding/read_aloud_button.dart';
import '../../../core/widgets/onboarding/speech_to_text_button.dart';
import '../../../core/widgets/service_category_card.dart';
import '../../onboarding/onboarding_models.dart';
import 'task_posting_bottom_bar.dart';
import 'task_posting_models.dart';
import 'task_posting_state.dart';

/// Step 1 of 7: AI Task Assistant + Category Selection. The user either
/// describes the task in free text (Option A — categorizeJob detects a
/// skill) or picks a category card directly (Option B), using the same
/// categories/icons as the customer Home screen.
class AiCategoryScreen extends ConsumerStatefulWidget {
  const AiCategoryScreen({super.key});

  @override
  ConsumerState<AiCategoryScreen> createState() => _AiCategoryScreenState();
}

class _AiCategoryScreenState extends ConsumerState<AiCategoryScreen> {
  final TextEditingController _inputController = TextEditingController();
  String? _aiSuggestion;
  String? _categoryError;

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  void _onInputChanged(String text) {
    setState(() {
      _aiSuggestion = text.trim().isEmpty ? null : categorizeJob(text);
    });
  }

  void _confirmAiSuggestion() {
    if (_aiSuggestion == null) return;
    ref.read(taskDraftProvider.notifier).state =
        ref.read(taskDraftProvider).copyWith(category: _aiSuggestion);
    setState(() => _categoryError = null);
  }

  void _selectCategory(String skill) {
    ref.read(taskDraftProvider.notifier).state =
        ref.read(taskDraftProvider).copyWith(category: skill);
    setState(() => _categoryError = null);
  }

  Future<void> _handleBack() async {
    final draft = ref.read(taskDraftProvider);
    final isDirty = draft.category != null || _inputController.text.trim().isNotEmpty;
    if (!isDirty) {
      context.pop();
      return;
    }
    final shouldDiscard = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(TaskPostingStrings.discardDraftTitle),
        content: const Text(TaskPostingStrings.discardDraftMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(TaskPostingStrings.discardDraftCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(TaskPostingStrings.discardDraftConfirm),
          ),
        ],
      ),
    );
    if (shouldDiscard == true && mounted) {
      ref.read(taskDraftProvider.notifier).state = TaskDraft.empty();
      context.pop();
    }
  }

  void _continue() {
    final category = ref.read(taskDraftProvider).category;
    setState(() {
      _categoryError = category == null ? TaskPostingStrings.categoryRequiredError : null;
    });
    if (category == null) return;
    context.push(Routes.postTaskTypeLocation);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final category = ref.watch(taskDraftProvider).category;
    final cats = categories.isNotEmpty ? categories : fallbackCategories;

    return OnboardingScaffold(
      progress: const OnboardingProgress(step: 1, totalSteps: 7),
      mascotState: PhoWaYokeState.thinking,
      mascotMessage: TaskPostingStrings.categoryTitle,
      title: TaskPostingStrings.categoryTitle,
      onBack: _handleBack,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _inputController,
                  onChanged: _onInputChanged,
                  style: theme.textTheme.bodyLarge,
                  decoration: InputDecoration(
                    hintText: TaskPostingStrings.aiInputHint,
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
                semanticPrompt: TaskPostingStrings.aiInputHint,
                mockTranscript: "ရေယိုနေတယ်",
                onResult: (v) {
                  _inputController.text = v;
                  _onInputChanged(v);
                },
              ),
            ],
          ),
          if (_aiSuggestion != null) ...[
            const SizedBox(height: AppSpacing.lg),
            OnboardingSelectionCard(
              emoji: "🤖",
              label: "${TaskPostingStrings.aiSuggestionPrefix}$_aiSuggestion",
              selected: category == _aiSuggestion,
              semanticLabel: "${TaskPostingStrings.aiSuggestionPrefix}$_aiSuggestion",
              onTap: _confirmAiSuggestion,
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: [
              const Expanded(child: Divider(color: AppColors.onboardingDivider)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Text(TaskPostingStrings.orDivider,
                    style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
              ),
              const Expanded(child: Divider(color: AppColors.onboardingDivider)),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: Text(TaskPostingStrings.manualCategoryPrompt,
                    style: theme.textTheme.titleMedium),
              ),
              ReadAloudButton(textToRead: TaskPostingStrings.manualCategoryPrompt),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: cats.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: AppSpacing.md,
              crossAxisSpacing: AppSpacing.md,
              childAspectRatio: 0.72,
            ),
            itemBuilder: (context, i) {
              final c = cats[i];
              final skills = categoryToSkills[c.name] ?? const [];
              final skill = skills.isEmpty ? null : skills.first;
              return ServiceCategoryCard(
                emoji: c.icon,
                label: c.burmese,
                selected: skill != null && category == skill,
                onTap: skill == null ? () {} : () => _selectCategory(skill),
              );
            },
          ),
          if (_categoryError != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(_categoryError!,
                style: theme.textTheme.bodySmall?.copyWith(color: AppColors.error)),
          ],
        ],
      ),
      bottomBar: TaskPostingBottomBar(onContinue: _continue),
    );
  }
}
