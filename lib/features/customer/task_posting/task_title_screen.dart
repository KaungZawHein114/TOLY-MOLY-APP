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
import '../../../core/widgets/onboarding/speech_to_text_button.dart';
import '../../../core/widgets/service_category_card.dart';
import '../../onboarding/onboarding_models.dart';
import 'task_posting_bottom_bar.dart';
import 'task_posting_models.dart';
import 'task_posting_state.dart';

/// Manual step 1 of 5: Task Title + Category. The user names the task in the
/// title field (free text) and picks a category card directly, or speaks it
/// (the voice quick-pick maps to a category through the same offline keyword
/// matcher the rest of the app uses — no AI suggestion step, no loading
/// state). "Other" reveals a free-text "specify category" box.
///
/// Also serves as the summary screen's "Title"/"Category" edit target, for
/// tasks that came from either posting method.
class TaskTitleScreen extends ConsumerStatefulWidget {
  const TaskTitleScreen({super.key});

  @override
  ConsumerState<TaskTitleScreen> createState() => _TaskTitleScreenState();
}

class _TaskTitleScreenState extends ConsumerState<TaskTitleScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _customCategoryController;
  String? _categoryError;
  String? _customCategoryError;

  @override
  void initState() {
    super.initState();
    final draft = ref.read(taskDraftProvider);
    _titleController = TextEditingController(text: draft.title);
    _customCategoryController =
        TextEditingController(text: draft.customCategory);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _customCategoryController.dispose();
    super.dispose();
  }

  bool get _editMode =>
      GoRouterState.of(context).uri.queryParameters['edit'] == '1';

  void _selectCategory(String skill) {
    ref.read(taskDraftProvider.notifier).state =
        ref.read(taskDraftProvider).copyWith(category: skill);
    setState(() => _categoryError = null);
  }

  void _selectOther() {
    ref.read(taskDraftProvider.notifier).state =
        ref.read(taskDraftProvider).copyWith(category: kOtherCategory);
    setState(() => _categoryError = null);
  }

  void _pickByVoice(String spoken) {
    final skill = categorizeJob(spoken);
    _selectCategory(skill);
  }

  Future<void> _handleBack() async {
    if (_editMode) {
      context.pop();
      return;
    }
    final draft = ref.read(taskDraftProvider);
    final isDirty =
        draft.category != null || _titleController.text.trim().isNotEmpty;
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
    final isOther = category == kOtherCategory;
    final customCategory = _customCategoryController.text.trim();
    setState(() {
      _categoryError =
          category == null ? TaskPostingStrings.categoryRequiredError : null;
      _customCategoryError = (isOther && customCategory.isEmpty)
          ? TaskPostingStrings.specifyCategoryRequiredError
          : null;
    });
    if (_categoryError != null || _customCategoryError != null) return;

    ref.read(taskDraftProvider.notifier).state = ref.read(taskDraftProvider).copyWith(
          title: _titleController.text.trim(),
          customCategory: customCategory,
        );

    if (_editMode) {
      context.pop();
    } else {
      context.push(Routes.postTaskMedia);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final category = ref.watch(taskDraftProvider).category;
    final cats = categories.isNotEmpty ? categories : fallbackCategories;
    final isOther = category == kOtherCategory;

    return OnboardingScaffold(
      progress: const OnboardingProgress(step: 1, totalSteps: 5),
      mascotState: PhoWaYokeState.thinking,
      mascotMessage: TaskPostingStrings.categoryTitle,
      title: TaskPostingStrings.categoryTitle,
      onBack: _handleBack,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Task title ──────────────────────────────────────────────────
          Text(TaskPostingStrings.taskTitleLabel,
              style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _titleController,
                  textInputAction: TextInputAction.done,
                  style: theme.textTheme.bodyLarge,
                  decoration: InputDecoration(
                    hintText: TaskPostingStrings.taskTitleHint,
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              SpeechToTextButton(
                semanticPrompt: TaskPostingStrings.taskTitleHint,
                mockTranscript: "ပန်ကာ တပ်ဆင်ရန်",
                onResult: (v) => _titleController.text = v,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          // ── Choose category: label + voice control ──────────────────────
          Row(
            children: [
              Expanded(
                child: Text(TaskPostingStrings.manualCategoryPrompt,
                    style: theme.textTheme.titleMedium),
              ),
              SpeechToTextButton(
                semanticPrompt: TaskPostingStrings.categoryVoicePrompt,
                mockTranscript: "သန့်ရှင်းရေး",
                onResult: _pickByVoice,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: cats.length + 1, // + the "Other" card
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: AppSpacing.md,
              crossAxisSpacing: AppSpacing.md,
              childAspectRatio: 0.72,
            ),
            itemBuilder: (context, i) {
              if (i == cats.length) {
                return ServiceCategoryCard(
                  emoji: "➕",
                  label: TaskPostingStrings.otherCategoryLabel,
                  selected: isOther,
                  onTap: _selectOther,
                );
              }
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
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: AppColors.error)),
          ],
          // ── "Other" → specify category (text + voice) ───────────────────
          if (isOther) ...[
            const SizedBox(height: AppSpacing.lg),
            Text(TaskPostingStrings.specifyCategoryLabel,
                style: theme.textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _customCategoryController,
                    style: theme.textTheme.bodyLarge,
                    onChanged: (_) {
                      if (_customCategoryError != null) {
                        setState(() => _customCategoryError = null);
                      }
                    },
                    decoration: InputDecoration(
                      hintText: TaskPostingStrings.specifyCategoryHint,
                      errorText: _customCategoryError,
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                SpeechToTextButton(
                  semanticPrompt: TaskPostingStrings.specifyCategoryLabel,
                  mockTranscript: "အိမ်ပြောင်းရွှေ့ခြင်း",
                  onResult: (v) =>
                      setState(() => _customCategoryController.text = v),
                ),
              ],
            ),
          ],
        ],
      ),
      bottomBar: TaskPostingBottomBar(
        onContinue: _continue,
        continueLabel: _editMode
            ? TaskPostingStrings.saveButton
            : TaskPostingStrings.continueButton,
        continueIcon: _editMode ? Icons.check : Icons.arrow_forward,
      ),
    );
  }
}
