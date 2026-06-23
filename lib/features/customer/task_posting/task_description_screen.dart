import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/task_posting_strings.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/ai_mock.dart';
import '../../../core/widgets/large_button.dart';
import '../../../core/widgets/mascot/mascot_state.dart';
import '../../../core/widgets/onboarding/onboarding_scaffold.dart';
import '../../../core/widgets/onboarding/speech_to_text_button.dart';
import '../../onboarding/onboarding_models.dart';
import 'task_posting_bottom_bar.dart';
import 'task_posting_state.dart';

/// Step 5 of 7: Task Description. "AI က ရေးပေးမည်" replaces the field's
/// content with a generated description; the result stays editable.
class TaskDescriptionScreen extends ConsumerStatefulWidget {
  const TaskDescriptionScreen({super.key});

  @override
  ConsumerState<TaskDescriptionScreen> createState() => _TaskDescriptionScreenState();
}

class _TaskDescriptionScreenState extends ConsumerState<TaskDescriptionScreen> {
  late final TextEditingController _controller;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: ref.read(taskDraftProvider).description);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _generateWithAi() {
    final draft = ref.read(taskDraftProvider);
    final generated = generateTaskDescription(draft.category ?? "", _controller.text);
    setState(() => _controller.text = generated);
  }

  void _continue() {
    final description = _controller.text.trim();
    setState(() {
      _error = description.isEmpty ? TaskPostingStrings.descriptionRequiredError : null;
    });
    if (description.isEmpty) return;
    ref.read(taskDraftProvider.notifier).state =
        ref.read(taskDraftProvider).copyWith(description: description);
    context.push(Routes.postTaskBudget);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return OnboardingScaffold(
      progress: const OnboardingProgress(step: 5, totalSteps: 7),
      mascotState: PhoWaYokeState.pointing,
      mascotMessage: TaskPostingStrings.descriptionTitle,
      title: TaskPostingStrings.descriptionTitle,
      onBack: () => context.pop(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  maxLines: 5,
                  style: theme.textTheme.bodyLarge,
                  decoration: InputDecoration(
                    hintText: TaskPostingStrings.descriptionPlaceholder,
                    errorText: _error,
                    filled: true,
                    fillColor: AppColors.blue100,
                    contentPadding: const EdgeInsets.all(AppSpacing.lg),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              SpeechToTextButton(
                semanticPrompt: TaskPostingStrings.descriptionPlaceholder,
                mockTranscript: "ရေယိုနေတယ်",
                onResult: (v) => setState(() => _controller.text = v),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          LargeButton(
            label: TaskPostingStrings.aiWriteButton,
            icon: Icons.auto_awesome,
            filled: false,
            outlineColor: AppColors.purple700,
            onTap: _generateWithAi,
          ),
        ],
      ),
      bottomBar: TaskPostingBottomBar(
        onPrevious: () => context.pop(),
        onContinue: _continue,
      ),
    );
  }
}
