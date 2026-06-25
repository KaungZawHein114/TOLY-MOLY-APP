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

/// Step 1 of 7: Task Title + Category Selection. The user names the task in
/// the title field (free text — AI detects a category from it) or picks a
/// category card directly. "Other" reveals a free-text "specify category" box.
class AiCategoryScreen extends ConsumerStatefulWidget {
  const AiCategoryScreen({super.key});

  @override
  ConsumerState<AiCategoryScreen> createState() => _AiCategoryScreenState();
}

class _AiCategoryScreenState extends ConsumerState<AiCategoryScreen> {
  final TextEditingController _titleController = TextEditingController();
  late final TextEditingController _customCategoryController;
  String? _aiSuggestion;
  String? _categoryError;
  String? _customCategoryError;

  @override
  void initState() {
    super.initState();
    final draft = ref.read(taskDraftProvider);
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

  void _onTitleChanged(String text) {
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

    ref.read(taskDraftProvider.notifier).state =
        ref.read(taskDraftProvider).copyWith(customCategory: customCategory);

    if (_editMode) {
      context.pop();
    } else {
      context.push(Routes.postTaskTypeLocation);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final category = ref.watch(taskDraftProvider).category;
    final cats = categories.isNotEmpty ? categories : fallbackCategories;
    final isOther = category == kOtherCategory;

    return OnboardingScaffold(
      progress: const OnboardingProgress(step: 1, totalSteps: 7),
      mascotState: PhoWaYokeState.thinking,
      mascotMessage: TaskPostingStrings.categoryTitle,
      title: TaskPostingStrings.categoryTitle,
      onBack: _handleBack,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Task title ──────────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: Text(TaskPostingStrings.taskTitleLabel,
                    style: theme.textTheme.titleMedium),
              ),
              ReadAloudButton(textToRead: TaskPostingStrings.taskTitleLabel),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _titleController,
                  onChanged: _onTitleChanged,
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
                onResult: (v) {
                  _titleController.text = v;
                  _onTitleChanged(v);
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
              semanticLabel:
                  "${TaskPostingStrings.aiSuggestionPrefix}$_aiSuggestion",
              onTap: _confirmAiSuggestion,
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: [
              const Expanded(child: Divider(color: AppColors.onboardingDivider)),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Text(TaskPostingStrings.orDivider,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: AppColors.textSecondary)),
              ),
              const Expanded(child: Divider(color: AppColors.onboardingDivider)),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          // ── Choose category: ONE voice control + one read-aloud control ──
          Row(
            children: [
              Expanded(
                child: Text(TaskPostingStrings.manualCategoryPrompt,
                    style: theme.textTheme.titleMedium),
              ),
              ReadAloudButton(textToRead: TaskPostingStrings.manualCategoryPrompt),
              const SizedBox(width: AppSpacing.xs),
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
                  showListen: false,
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
                showListen: false,
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
