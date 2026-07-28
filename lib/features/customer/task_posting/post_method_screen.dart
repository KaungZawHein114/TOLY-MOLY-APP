import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/task_posting_strings.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/mascot/mascot_state.dart';
import '../../../core/widgets/onboarding/onboarding_scaffold.dart';
import '../../../core/widgets/onboarding/onboarding_selection_card.dart';
import 'task_posting_models.dart';
import 'task_posting_state.dart';

/// The flow's entry screen: how does the client want to post? Voice hands over
/// to Pho Wa Yoke's conversation, Manual walks the three form steps. Both end
/// on the same summary screen, so the choice is only about input style.
///
/// Tapping a card navigates straight away (no Continue button) — picking the
/// method IS the action, and it keeps posting a task within three taps.
class PostMethodScreen extends ConsumerWidget {
  const PostMethodScreen({super.key});

  /// Every posting run starts from a clean draft. Editing an existing draft
  /// never comes through here — the summary's Edit links push the step routes
  /// directly.
  void _start(BuildContext context, WidgetRef ref, String route) {
    ref.read(taskDraftProvider.notifier).state = TaskDraft.empty();
    context.push(route);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return OnboardingScaffold(
      mascotState: PhoWaYokeState.happy,
      mascotMessage: TaskPostingStrings.methodMascotMessage,
      title: TaskPostingStrings.methodTitle,
      readAloudText: TaskPostingStrings.methodMascotMessage,
      onBack: () => context.pop(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OnboardingSelectionCard(
            emoji: "🎤",
            label: TaskPostingStrings.methodVoiceLabel,
            sublabel: TaskPostingStrings.methodVoiceSubtitle,
            semanticLabel:
                "${TaskPostingStrings.methodVoiceLabel}. ${TaskPostingStrings.methodVoiceSubtitle}",
            onTap: () => _start(context, ref, Routes.postTaskVoice),
          ),
          const SizedBox(height: AppSpacing.lg),
          OnboardingSelectionCard(
            emoji: "✍️",
            label: TaskPostingStrings.methodManualLabel,
            sublabel: TaskPostingStrings.methodManualSubtitle,
            semanticLabel:
                "${TaskPostingStrings.methodManualLabel}. ${TaskPostingStrings.methodManualSubtitle}",
            onTap: () => _start(context, ref, Routes.postTaskTitle),
          ),
        ],
      ),
      bottomBar: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline,
              size: AppSizes.iconSm, color: AppColors.textSecondary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(TaskPostingStrings.methodHelperNote,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: AppColors.textSecondary)),
          ),
        ],
      ),
    );
  }
}
