import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/task_posting_strings.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/ai_mock.dart';
import '../../../core/widgets/mascot/mascot_state.dart';
import '../../../core/widgets/onboarding/onboarding_scaffold.dart';
import '../../onboarding/onboarding_models.dart';
import 'task_posting_bottom_bar.dart';
import 'task_posting_models.dart';
import 'task_posting_state.dart';

/// Step 6 of 7: Budget Suggestion. The price is set by the platform's
/// supply/demand model — the client cannot override it here; negotiation
/// happens with the matched worker via chat later (a future feature). This
/// screen is read-only: it computes the suggestion once (deterministic —
/// same draft inputs always reproduce the same numbers) and just explains it.
class BudgetScreen extends ConsumerWidget {
  const BudgetScreen({super.key});

  void _computeSuggestionIfNeeded(BuildContext context, WidgetRef ref) {
    final draft = ref.read(taskDraftProvider);
    if (draft.suggestedBudgetLowMmk != null) return;
    // Riverpod disallows modifying a provider during the widget tree's
    // build phase — defer to right after this frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      final current = ref.read(taskDraftProvider);
      if (current.suggestedBudgetLowMmk != null) return;
      final suggestion = suggestBudget(
        current.category ?? "",
        current.urgent,
        current.workerTier ?? WorkerTier.basic,
        current.workersNeeded,
      );
      ref.read(taskDraftProvider.notifier).state = current.copyWith(
        suggestedBudgetLowMmk: suggestion.low,
        suggestedBudgetHighMmk: suggestion.high,
        marketPercent: suggestion.marketPercent,
      );
    });
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final draft = ref.watch(taskDraftProvider);
    _computeSuggestionIfNeeded(context, ref);

    return OnboardingScaffold(
      progress: const OnboardingProgress(step: 6, totalSteps: 7),
      mascotState: PhoWaYokeState.thinking,
      mascotMessage: TaskPostingStrings.budgetTitle,
      title: TaskPostingStrings.budgetTitle,
      onBack: () => context.pop(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              gradient: AppColors.guidanceSurfaceGradient,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(TaskPostingStrings.budgetAnalysisTitle,
                    style: theme.textTheme.titleMedium?.copyWith(color: AppColors.brandPurple)),
                const SizedBox(height: AppSpacing.sm),
                Text(TaskPostingStrings.budgetSuggestedLabel,
                    style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.brandPurple)),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  "${draft.suggestedBudgetLowMmk ?? 0} - ${draft.suggestedBudgetHighMmk ?? 0} ${TaskPostingStrings.budgetCurrency}",
                  style: theme.textTheme.headlineSmall?.copyWith(color: AppColors.brandPurple),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  "${TaskPostingStrings.budgetMarketInsightPrefix}${draft.marketPercent ?? 0}${TaskPostingStrings.budgetMarketInsightSuffix}",
                  style: theme.textTheme.bodySmall?.copyWith(color: AppColors.brandPurple),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            TaskPostingStrings.budgetAutoSetNote,
            style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
      bottomBar: TaskPostingBottomBar(
        onPrevious: () => context.pop(),
        onContinue: () => context.push(Routes.postTaskReview),
      ),
    );
  }
}
