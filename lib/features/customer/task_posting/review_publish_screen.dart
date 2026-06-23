import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/task_posting_strings.dart';
import '../../../core/data/demo_data.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/large_button.dart';
import '../../../core/widgets/mascot/mascot_state.dart';
import '../../../core/widgets/mascot/pho_wa_yoke.dart';
import '../../../core/widgets/onboarding/onboarding_scaffold.dart';
import '../../onboarding/onboarding_models.dart';
import '../customer_home_shell.dart';
import 'task_posting_bottom_bar.dart';
import 'task_posting_models.dart';
import 'task_posting_state.dart';

/// Step 7 of 7: Review & Publish. Each summary row's "Edit" link pushes back
/// to the screen that owns that field — the shared draft provider means the
/// target screen pre-fills from the same data, no separate edit-mode needed.
class ReviewPublishScreen extends ConsumerWidget {
  const ReviewPublishScreen({super.key});

  String _formatDate(DateTime? date) {
    if (date == null) return "-";
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  String _formatLocation(TaskDraft draft) {
    if (draft.taskType == TaskType.remote) return TaskPostingStrings.remoteLocationValue;
    if (draft.township.isEmpty && draft.address.isEmpty) return "-";
    return "${draft.township} ${draft.address}".trim();
  }

  void _publish(BuildContext context, WidgetRef ref) {
    final draft = ref.read(taskDraftProvider);
    final task = TaskPost(
      id: DateTime.now().millisecondsSinceEpoch,
      category: draft.category ?? "",
      taskType: draft.taskType ?? TaskType.onSite,
      township: draft.township,
      address: draft.address,
      date: draft.date ?? DateTime.now(),
      timeSlot: draft.timeSlot ?? "",
      urgent: draft.urgent,
      workersNeeded: draft.workersNeeded,
      workerTier: draft.workerTier ?? WorkerTier.basic,
      description: draft.description,
      budgetMmk: draft.resolvedBudgetMmk ?? 0,
      createdAt: DateTime.now(),
    );
    ref.read(postedTasksProvider.notifier).state = [
      ...ref.read(postedTasksProvider),
      task,
    ];
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _SuccessModal(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(taskDraftProvider);

    return OnboardingScaffold(
      progress: const OnboardingProgress(step: 7, totalSteps: 7),
      mascotState: PhoWaYokeState.pointing,
      mascotMessage: TaskPostingStrings.reviewTitle,
      title: TaskPostingStrings.reviewTitle,
      onBack: () => context.pop(),
      body: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.blue100,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SummaryRow(
              label: TaskPostingStrings.reviewCategoryLabel,
              value: draft.category ?? "-",
              onEdit: () => context.push(Routes.postTask),
            ),
            _SummaryRow(
              label: TaskPostingStrings.reviewLocationLabel,
              value: _formatLocation(draft),
              onEdit: () => context.push(Routes.postTaskTypeLocation),
            ),
            _SummaryRow(
              label: TaskPostingStrings.reviewDateLabel,
              value: _formatDate(draft.date),
              onEdit: () => context.push(Routes.postTaskDateTime),
            ),
            _SummaryRow(
              label: TaskPostingStrings.reviewTimeLabel,
              value: draft.timeSlot ?? "-",
              onEdit: () => context.push(Routes.postTaskDateTime),
            ),
            _SummaryRow(
              label: TaskPostingStrings.reviewWorkersLabel,
              value: "${draft.workersNeeded}",
              onEdit: () => context.push(Routes.postTaskWorkersTier),
            ),
            _SummaryRow(
              label: TaskPostingStrings.reviewTierLabel,
              value: draft.workerTier?.label ?? "-",
              onEdit: () => context.push(Routes.postTaskWorkersTier),
            ),
            _SummaryRow(
              label: TaskPostingStrings.reviewBudgetLabel,
              value: "${draft.resolvedBudgetMmk ?? 0} ${TaskPostingStrings.budgetCurrency}",
              onEdit: () => context.push(Routes.postTaskBudget),
            ),
            _SummaryRow(
              label: TaskPostingStrings.reviewDescriptionLabel,
              value: draft.description.isEmpty ? "-" : draft.description,
              onEdit: () => context.push(Routes.postTaskDescription),
              isLast: true,
            ),
          ],
        ),
      ),
      bottomBar: TaskPostingBottomBar(
        onPrevious: () => context.pop(),
        onContinue: () => _publish(context, ref),
        celebratory: true,
        continueLabel: TaskPostingStrings.publishButton,
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onEdit;
  final bool isLast;

  const _SummaryRow({
    required this.label,
    required this.value,
    required this.onEdit,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: AppSpacing.xxs),
                Text(value, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          TextButton(onPressed: onEdit, child: const Text(TaskPostingStrings.editLink)),
        ],
      ),
    );
  }
}

class _SuccessModal extends ConsumerWidget {
  const _SuccessModal();

  void _goHome(BuildContext context, WidgetRef ref, {required bool toActivity}) {
    ref.read(taskDraftProvider.notifier).state = TaskDraft.empty();
    if (toActivity) {
      ref.read(customerTabIndexProvider.notifier).state = 1;
    } else {
      ref.read(customerTabIndexProvider.notifier).state = 0;
    }
    Navigator.of(context).pop(); // close the dialog
    context.go(Routes.customerHome);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl)),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const PhoWaYoke(state: PhoWaYokeState.success, size: 120),
            const SizedBox(height: AppSpacing.lg),
            Text("🎉 ${TaskPostingStrings.successTitle}",
                textAlign: TextAlign.center, style: theme.textTheme.headlineSmall),
            const SizedBox(height: AppSpacing.sm),
            Text(
              TaskPostingStrings.successMessage,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
            ),
            const SizedBox(height: AppSpacing.xl),
            LargeButton(
              label: TaskPostingStrings.successGoToActivity,
              gradient: AppColors.purpleGradient,
              onTap: () => _goHome(context, ref, toActivity: true),
            ),
            const SizedBox(height: AppSpacing.md),
            LargeButton(
              label: TaskPostingStrings.successGoHome,
              filled: false,
              outlineColor: AppColors.purple700,
              onTap: () => _goHome(context, ref, toActivity: false),
            ),
          ],
        ),
      ),
    );
  }
}
