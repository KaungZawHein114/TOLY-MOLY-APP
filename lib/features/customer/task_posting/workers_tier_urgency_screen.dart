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
import '../../../core/widgets/onboarding/read_aloud_button.dart';
import '../../onboarding/onboarding_models.dart';
import 'task_posting_bottom_bar.dart';
import 'task_posting_models.dart';
import 'task_posting_state.dart';

/// Step 4 of 7: Tasker Tier Selection. Only the trust tier is chosen here —
/// clients needing more than one worker create more tasks. Cards show friendly
/// labels; the literal "Tier N" mapping lives in the info sheet.
class WorkersTierUrgencyScreen extends ConsumerStatefulWidget {
  const WorkersTierUrgencyScreen({super.key});

  @override
  ConsumerState<WorkersTierUrgencyScreen> createState() =>
      _WorkersTierUrgencyScreenState();
}

class _WorkersTierUrgencyScreenState
    extends ConsumerState<WorkersTierUrgencyScreen> {
  String? _tierError;

  bool get _editMode =>
      GoRouterState.of(context).uri.queryParameters['edit'] == '1';

  void _selectTier(WorkerTier tier) {
    ref.read(taskDraftProvider.notifier).state =
        ref.read(taskDraftProvider).copyWith(workerTier: tier);
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
    final tier = ref.read(taskDraftProvider).workerTier;
    setState(() {
      _tierError =
          tier == null ? TaskPostingStrings.workerTierRequiredError : null;
    });
    if (tier == null) return;
    if (_editMode) {
      context.pop();
    } else {
      context.push(Routes.postTaskDescription);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final draft = ref.watch(taskDraftProvider);

    return OnboardingScaffold(
      progress: const OnboardingProgress(step: 4, totalSteps: 7),
      mascotState: PhoWaYokeState.pointing,
      mascotMessage: TaskPostingStrings.workersTierTitle,
      title: TaskPostingStrings.workersTierTitle,
      onBack: () => context.pop(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(TaskPostingStrings.workerTierSectionTitle,
                    style: theme.textTheme.titleMedium),
              ),
              ReadAloudButton(
                  textToRead: TaskPostingStrings.workerTierSectionTitle),
              const SizedBox(width: AppSpacing.xs),
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
              sublabel: tier.description,
              selected: draft.workerTier == tier,
              onTap: () => _selectTier(tier),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          if (_tierError != null)
            Text(_tierError!,
                style:
                    theme.textTheme.bodySmall?.copyWith(color: AppColors.error)),
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
