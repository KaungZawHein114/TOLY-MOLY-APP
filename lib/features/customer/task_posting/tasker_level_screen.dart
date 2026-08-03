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
import '../../../core/widgets/onboarding/onboarding_selection_card.dart';
import '../../onboarding/onboarding_models.dart';
import 'task_posting_bottom_bar.dart';
import 'task_posting_models.dart';
import 'task_posting_state.dart';

/// Manual step 4 of 5: Tasker Level. Only the trust tier is chosen here —
/// clients needing more than one worker create more tasks. Cards show friendly
/// labels; the literal "Tier N" mapping lives in the info sheet.
///
/// The level also sets the price: the budget is no longer typed by the client,
/// it is estimated by the AI from the category, the chosen level and urgency
/// (see [estimateTaskBudgetMmk]). Each card carries its own estimate so the
/// trade-off between level and price is visible before choosing.
///
/// SHARED convergence point for both posting methods: Manual reaches this
/// screen with no description yet and continues on to the Description step;
/// the AI Task Assistant conversation reaches it with the description
/// already collected, so continuing goes straight to Summary instead —
/// asking again would just repeat what the client already said in the chat.
class TaskerLevelScreen extends ConsumerStatefulWidget {
  const TaskerLevelScreen({super.key});

  @override
  ConsumerState<TaskerLevelScreen> createState() => _TaskerLevelScreenState();
}

class _TaskerLevelScreenState extends ConsumerState<TaskerLevelScreen> {
  String? _tierError;

  bool get _editMode =>
      GoRouterState.of(context).uri.queryParameters['edit'] == '1';

  /// The AI's estimate for [tier], given the draft's category and urgency.
  int _estimateFor(TaskDraft draft, WorkerTier tier) => estimateTaskBudgetMmk(
        category: draft.effectiveCategory,
        tierNumber: tier.number,
        urgent: draft.urgent,
      );

  /// Picking a level re-prices the task — the two are never out of sync.
  void _selectTier(WorkerTier tier) {
    final draft = ref.read(taskDraftProvider);
    ref.read(taskDraftProvider.notifier).state = draft.copyWith(
      workerTier: tier,
      budgetMmk: _estimateFor(draft, tier),
    );
    setState(() => _tierError = null);
  }

  void _showTierInfo() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(TaskPostingStrings.workerTierInfoSheetTitle,
                    style: theme.textTheme.titleMedium),
                const SizedBox(height: AppSpacing.md),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final tier in WorkerTier.values)
                          Padding(
                            padding:
                                const EdgeInsets.only(bottom: AppSpacing.md),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(tier.emoji,
                                    style: const TextStyle(fontSize: 20)),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text("Tier ${tier.number} · ${tier.label}",
                                          style: theme.textTheme.titleSmall
                                              ?.copyWith(
                                                  color: AppColors.brandPurple)),
                                      Text(tier.description,
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(
                                                  color:
                                                      AppColors.textSecondary)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text(TaskPostingStrings.workerTierInfoSheetClose),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _continue() {
    final draft = ref.read(taskDraftProvider);
    final tier = draft.workerTier;
    setState(() {
      _tierError =
          tier == null ? TaskPostingStrings.workerTierRequiredError : null;
    });
    if (tier == null) return;
    // Re-price on the way out too: urgency can have changed since the level
    // was picked (the summary's Edit links can revisit either step).
    ref.read(taskDraftProvider.notifier).state =
        draft.copyWith(budgetMmk: _estimateFor(draft, tier));
    if (_editMode) {
      context.pop();
    } else if (draft.description.trim().isNotEmpty) {
      // Reached from the AI Task Assistant conversation, which already
      // collected a description — asking again would repeat it. Manual
      // never has one yet at this point, so it always takes the other
      // branch below.
      context.push(Routes.postTaskReview);
    } else {
      context.push(Routes.postTaskDescription);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final draft = ref.watch(taskDraftProvider);

    return OnboardingScaffold(
      progress: const OnboardingProgress(step: 4, totalSteps: 5),
      mascotState: PhoWaYokeState.pointing,
      mascotMessage: TaskPostingStrings.workersTierTitle,
      title: TaskPostingStrings.workersTierTitle,
      onBack: () => context.pop(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _EstimatedBudgetCard(budgetMmk: draft.budgetMmk),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: Text(TaskPostingStrings.workerTierSectionTitle,
                    style: theme.textTheme.titleMedium),
              ),
              Semantics(
                label: TaskPostingStrings.workerTierInfoButton,
                button: true,
                child: Material(
                  color: AppColors.purple100,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: _showTierInfo,
                    child: const SizedBox(
                      width: 48,
                      height: 48,
                      child: Icon(Icons.info_outline,
                          color: AppColors.purple700, size: AppSizes.iconMd),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          for (final tier in WorkerTier.values) ...[
            OnboardingSelectionCard(
              emoji: tier.emoji,
              label: tier.label,
              sublabel: TaskPostingStrings.tierPriceSublabel(
                  formatBudgetMmk(_estimateFor(draft, tier))),
              semanticLabel: "${tier.label}. ${tier.description}. "
                  "${TaskPostingStrings.tierPriceSublabel(formatBudgetMmk(_estimateFor(draft, tier)))}",
              selected: draft.workerTier == tier,
              onTap: () => _selectTier(tier),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          if (_tierError != null)
            Text(_tierError!,
                style:
                    theme.textTheme.bodySmall?.copyWith(color: AppColors.error)),
          const SizedBox(height: AppSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline,
                  size: AppSizes.iconSm, color: AppColors.textSecondary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(TaskPostingStrings.estimatedBudgetNote,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: AppColors.textSecondary)),
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

/// The AI's price for the level currently selected. Indigo is the design
/// system's AI accent, so this reads as "the assistant decided this", not as an
/// input the client is expected to argue with.
class _EstimatedBudgetCard extends StatelessWidget {
  final int? budgetMmk;
  const _EstimatedBudgetCard({required this.budgetMmk});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final amount = budgetMmk;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.indigo100,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome,
                  size: AppSizes.iconSm, color: AppColors.indigo700),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(TaskPostingStrings.estimatedBudgetTitle,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(color: AppColors.indigo700)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          if (amount == null)
            Text(TaskPostingStrings.estimatedBudgetPlaceholder,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: AppColors.textSecondary))
          else ...[
            Text(formatBudgetMmk(amount),
                style: theme.textTheme.headlineSmall
                    ?.copyWith(color: AppColors.indigo700)),
            const SizedBox(height: AppSpacing.xxs),
            Text(TaskPostingStrings.estimatedByAi,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: AppColors.textSecondary)),
          ],
        ],
      ),
    );
  }
}
