import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/task_posting_strings.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/mascot/mascot_state.dart';
import '../../../core/widgets/onboarding/onboarding_scaffold.dart';
import '../../../core/widgets/onboarding/speech_to_text_button.dart';
import '../../onboarding/onboarding_models.dart';
import 'task_posting_bottom_bar.dart';
import 'task_posting_state.dart';

/// Manual step 5 of 5: Description — the last step before the shared Summary.
/// The client types it, or speaks it via the same demo voice input used
/// everywhere else in this flow (fake listening state, simulated transcript,
/// no speech API). There is no AI rewrite here — whatever the client provides
/// is exactly what is saved. Also the summary screen's edit target for the
/// description row for tasks that came from either posting method.
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

  bool get _editMode =>
      GoRouterState.of(context).uri.queryParameters['edit'] == '1';

  void _continue() {
    final description = _controller.text.trim();
    setState(() {
      _error = description.isEmpty ? TaskPostingStrings.descriptionRequiredError : null;
    });
    if (description.isEmpty) return;
    ref.read(taskDraftProvider.notifier).state =
        ref.read(taskDraftProvider).copyWith(description: description);
    if (_editMode) {
      context.pop();
    } else {
      context.push(Routes.postTaskReview);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return OnboardingScaffold(
      progress: const OnboardingProgress(step: 5, totalSteps: 5),
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
        ],
      ),
      bottomBar: TaskPostingBottomBar(
        onPrevious: _editMode ? null : () => context.pop(),
        onContinue: _continue,
        continueLabel: _editMode
            ? TaskPostingStrings.saveButton
            : TaskPostingStrings.continueButton,
        continueIcon: _editMode ? Icons.check : Icons.arrow_forward,
      ),
    );
  }
}
