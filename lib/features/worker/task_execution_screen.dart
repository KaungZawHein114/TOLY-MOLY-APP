import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_strings.dart';
import '../../core/data/demo_data.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/large_button.dart';
import 'task_execution_state.dart';
import 'widgets/task_handling_cards.dart';

/// Digital Task Check-In: Leaving For Task -> Arrived & Started -> Task
/// Completed -> (client confirmation, out of scope — no client-side screen
/// exists for this flow yet). On-site only, per the spec; this app has no
/// remote-booking concept, so every [Booking] qualifies.
class TaskExecutionScreen extends ConsumerWidget {
  final Booking booking;
  const TaskExecutionScreen({super.key, required this.booking});

  void _advance(BuildContext context, WidgetRef ref, ExecutionStatus next) {
    final all = ref.read(taskExecutionProvider);
    final current = executionFor(all, booking.id);
    final now = DateTime.now();
    final updated = current.copyWith(
      status: next,
      leaveTime: next == ExecutionStatus.leavingForTask ? now : null,
      arrivalTime: next == ExecutionStatus.started ? now : null,
      completionTime: next == ExecutionStatus.completed ? now : null,
    );
    ref.read(taskExecutionProvider.notifier).state = {...all, booking.id: updated};

    final notice = switch (next) {
      ExecutionStatus.leavingForTask =>
        "${booking.workerName} သည် သင့်အလုပ်နေရာသို့ ထွက်ခွာနေပါပြီ",
      ExecutionStatus.started => "${booking.workerName} သည် ရောက်ရှိပြီး အလုပ်စတင်နေပါပြီ",
      ExecutionStatus.completed => "အလုပ်ပြီးစီးပါပြီ — ကျေးဇူးပြု၍ အတည်ပြုပေးပါ",
      ExecutionStatus.pending => "",
    };
    if (notice.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(notice), duration: const Duration(seconds: 2)),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final all = ref.watch(taskExecutionProvider);
    final execution = executionFor(all, booking.id);
    final isCompleted = execution.status == ExecutionStatus.completed;
    final task = bookingTaskMap(booking);

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.executionPageTitle)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _TaskSummaryCard(booking: booking),
          const SizedBox(height: AppSpacing.xl),
          _Timeline(execution: execution),
          const SizedBox(height: AppSpacing.xl),
          _CurrentAction(
            execution: execution,
            onLeaving: () => _advance(context, ref, ExecutionStatus.leavingForTask),
            onStarted: () => _advance(context, ref, ExecutionStatus.started),
            onCompleted: () => _advance(context, ref, ExecutionStatus.completed),
          ),
          // Task-Handling mode (tasker, spec §4.8): brief + gentle reminder
          // before/during the job; the completion summary + suggested tier after.
          // Kept BELOW the primary action so the action stays reachable.
          if (!isCompleted) ...[
            const SizedBox(height: AppSpacing.xl),
            TaskerBriefCard(task: task),
            const SizedBox(height: AppSpacing.md),
            TaskerReminderBanner(timeSlot: booking.timeSlot),
          ],
          if (isCompleted) ...[
            const SizedBox(height: AppSpacing.xl),
            // Demo timing: completed within its window (onTime). No client rating
            // captured yet, so the tier engine (rules) would use its own signals.
            CompletionSummaryCard(task: task, timing: const {'onTime': true}),
          ],
        ],
      ),
    );
  }
}

class _TaskSummaryCard extends StatelessWidget {
  final Booking booking;
  const _TaskSummaryCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: AppColors.purpleGradient,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppStrings.executionTodaysTask,
              style: theme.textTheme.bodySmall?.copyWith(color: AppColors.onBrandMuted)),
          const SizedBox(height: AppSpacing.xs),
          Text(booking.skill,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.headlineSmall?.copyWith(color: AppColors.onBrand, fontSize: 22)),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Icon(Icons.access_time, size: 16, color: AppColors.onBrandMuted),
              const SizedBox(width: AppSpacing.xs),
              Flexible(
                child: Text(booking.timeSlot,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.onBrand)),
              ),
              const SizedBox(width: AppSpacing.md),
              Icon(Icons.location_on, size: 16, color: AppColors.onBrandMuted),
              const SizedBox(width: AppSpacing.xs),
              Flexible(
                child: Text(booking.township,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.onBrand)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Timeline extends StatelessWidget {
  final TaskExecution execution;
  const _Timeline({required this.execution});

  String? _time(DateTime? d) {
    if (d == null) return null;
    return "${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rows = [
      (AppStrings.executionLeaveLabel, _time(execution.leaveTime)),
      (AppStrings.executionArrivalLabel, _time(execution.arrivalTime)),
      (AppStrings.executionCompletionLabel, _time(execution.completionTime)),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(AppStrings.executionTimelineTitle, style: theme.textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        for (final row in rows)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
            child: Row(
              children: [
                Icon(
                  row.$2 != null ? Icons.check_circle : Icons.radio_button_unchecked,
                  size: 18,
                  color: row.$2 != null ? AppColors.success : Theme.of(context).hintColor,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(row.$1,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: row.$2 != null ? null : theme.hintColor,
                      )),
                ),
                if (row.$2 != null)
                  Text(row.$2!, style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor)),
              ],
            ),
          ),
      ],
    );
  }
}

class _CurrentAction extends StatelessWidget {
  final TaskExecution execution;
  final VoidCallback onLeaving;
  final VoidCallback onStarted;
  final VoidCallback onCompleted;
  const _CurrentAction({
    required this.execution,
    required this.onLeaving,
    required this.onStarted,
    required this.onCompleted,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    switch (execution.status) {
      case ExecutionStatus.pending:
        return LargeButton(
          label: AppStrings.executionLeavingCta,
          gradient: AppColors.purpleGradient,
          onTap: onLeaving,
        );
      case ExecutionStatus.leavingForTask:
        return LargeButton(
          label: AppStrings.executionStartedCta,
          gradient: AppColors.purpleGradient,
          onTap: onStarted,
        );
      case ExecutionStatus.started:
        return LargeButton(
          label: AppStrings.executionCompletedCta,
          gradient: AppColors.purpleGradient,
          onTap: onCompleted,
        );
      case ExecutionStatus.completed:
        return Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: Row(
            children: [
              const Icon(Icons.hourglass_top, color: AppColors.success),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  AppStrings.executionWaitingClientConfirmation,
                  style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.success),
                ),
              ),
            ],
          ),
        );
    }
  }
}
