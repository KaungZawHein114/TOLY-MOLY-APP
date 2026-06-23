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

/// Step 4 of 7: Workers Needed + Trust Level + Urgency. Tier labels are
/// always the friendly Burmese names/descriptions — no tier numbers appear
/// anywhere in this UI.
class WorkersTierUrgencyScreen extends ConsumerStatefulWidget {
  const WorkersTierUrgencyScreen({super.key});

  @override
  ConsumerState<WorkersTierUrgencyScreen> createState() => _WorkersTierUrgencyScreenState();
}

class _WorkersTierUrgencyScreenState extends ConsumerState<WorkersTierUrgencyScreen> {
  static const int _minWorkers = 1;
  static const int _maxWorkers = 10;

  String? _tierError;

  void _setWorkers(int delta) {
    final draft = ref.read(taskDraftProvider);
    final next = (draft.workersNeeded + delta).clamp(_minWorkers, _maxWorkers);
    ref.read(taskDraftProvider.notifier).state = draft.copyWith(workersNeeded: next);
  }

  void _selectTier(WorkerTier tier) {
    ref.read(taskDraftProvider.notifier).state =
        ref.read(taskDraftProvider).copyWith(workerTier: tier);
    setState(() => _tierError = null);
  }

  void _continue() {
    final tier = ref.read(taskDraftProvider).workerTier;
    setState(() {
      _tierError = tier == null ? TaskPostingStrings.workerTierRequiredError : null;
    });
    if (tier == null) return;
    context.push(Routes.postTaskDescription);
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
          Text(TaskPostingStrings.workersNeededLabel, style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _StepperButton(
                icon: Icons.remove,
                onTap: draft.workersNeeded > _minWorkers ? () => _setWorkers(-1) : null,
              ),
              SizedBox(
                width: 64,
                child: Text(
                  "${draft.workersNeeded}",
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall,
                ),
              ),
              _StepperButton(
                icon: Icons.add,
                onTap: draft.workersNeeded < _maxWorkers ? () => _setWorkers(1) : null,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: [
              Expanded(
                child: Text(TaskPostingStrings.workerTierSectionTitle,
                    style: theme.textTheme.titleMedium),
              ),
              ReadAloudButton(textToRead: TaskPostingStrings.workerTierSectionTitle),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          OnboardingSelectionCard(
            emoji: "🧰",
            label: TaskPostingStrings.workerTierBasicLabel,
            sublabel: TaskPostingStrings.workerTierBasicDescription,
            selected: draft.workerTier == WorkerTier.basic,
            onTap: () => _selectTier(WorkerTier.basic),
          ),
          const SizedBox(height: AppSpacing.md),
          OnboardingSelectionCard(
            emoji: "🛡️",
            label: TaskPostingStrings.workerTierTrustedLabel,
            sublabel: TaskPostingStrings.workerTierTrustedDescription,
            selected: draft.workerTier == WorkerTier.trusted,
            onTap: () => _selectTier(WorkerTier.trusted),
          ),
          const SizedBox(height: AppSpacing.md),
          OnboardingSelectionCard(
            emoji: "🎓",
            label: TaskPostingStrings.workerTierExpertLabel,
            sublabel: TaskPostingStrings.workerTierExpertDescription,
            selected: draft.workerTier == WorkerTier.expert,
            onTap: () => _selectTier(WorkerTier.expert),
          ),
          if (_tierError != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(_tierError!, style: theme.textTheme.bodySmall?.copyWith(color: AppColors.error)),
          ],
        ],
      ),
      bottomBar: TaskPostingBottomBar(
        onPrevious: () => context.pop(),
        onContinue: _continue,
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _StepperButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Material(
      color: enabled ? AppColors.purple100 : AppColors.onboardingDivider,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 48,
          height: 48,
          child: Icon(icon, color: enabled ? AppColors.purple700 : AppColors.textSecondary),
        ),
      ),
    );
  }
}
