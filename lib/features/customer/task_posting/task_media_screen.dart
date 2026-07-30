import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/task_posting_strings.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/widgets/mascot/mascot_state.dart';
import '../../../core/widgets/onboarding/onboarding_scaffold.dart';
import '../../onboarding/onboarding_models.dart';
import 'task_media_picker.dart';
import 'task_posting_bottom_bar.dart';
import 'task_posting_state.dart';

/// Manual step 2 of 5: attach up to 3 photos/videos. Entirely optional — the
/// primary button reads "Skip" while nothing is attached and "Continue" once
/// something is, but both do exactly the same thing: move on with whatever
/// [TaskDraft.media] currently holds. There is no validation error on this
/// screen, unlike every other manual step.
class TaskMediaScreen extends ConsumerWidget {
  const TaskMediaScreen({super.key});

  bool _editMode(BuildContext context) =>
      GoRouterState.of(context).uri.queryParameters['edit'] == '1';

  void _continue(BuildContext context) {
    if (_editMode(context)) {
      context.pop();
    } else {
      context.push(Routes.postTaskWhenWhere);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(taskDraftProvider);
    final editMode = _editMode(context);

    return OnboardingScaffold(
      progress: const OnboardingProgress(step: 2, totalSteps: 5),
      mascotState: PhoWaYokeState.pointing,
      mascotMessage: TaskPostingStrings.mediaStepMascotMessage,
      title: TaskPostingStrings.mediaStepTitle,
      onBack: () => context.pop(),
      body: TaskMediaPicker(
        items: draft.media,
        onChanged: (next) => ref.read(taskDraftProvider.notifier).state =
            draft.copyWith(media: next),
      ),
      bottomBar: TaskPostingBottomBar(
        onPrevious: editMode ? null : () => context.pop(),
        onContinue: () => _continue(context),
        continueLabel: editMode
            ? TaskPostingStrings.saveButton
            : (draft.media.isEmpty
                ? TaskPostingStrings.mediaSkipButton
                : TaskPostingStrings.continueButton),
        continueIcon: editMode ? Icons.check : Icons.arrow_forward,
      ),
    );
  }
}
