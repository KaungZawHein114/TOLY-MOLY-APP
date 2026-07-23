import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_strings.dart';
import '../../core/data/demo_data.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/large_button.dart';
import 'task_execution_state.dart';
import 'widgets/task_handling_cards.dart';

/// Digital Task Check-In / Check-Out screen (worker side).
///
/// Full lifecycle:
///   pending → leavingForTask → waitingCheckinConfirm
///     → inProgress (after client accepts) | arrivalDisputed (client rejects)
///   inProgress → waitingCheckoutConfirm
///     → completed (client confirms) | completionDisputed (client reports issue)
///
/// The client-side confirmation cards live in PendingScreen, which reads the
/// same [taskExecutionProvider] — no network needed in Phase 1 demo.
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
      checkinTime: next == ExecutionStatus.waitingCheckinConfirm ? now : null,
      checkoutTime: next == ExecutionStatus.waitingCheckoutConfirm ? now : null,
    );
    ref.read(taskExecutionProvider.notifier).state = {
      ...all,
      booking.id: updated
    };
    _autoAdvanceDemoConfirmation(context, ref, next);

    final notice = switch (next) {
      ExecutionStatus.leavingForTask =>
        "${booking.workerName} သည် သင့်အလုပ်နေရာသို့ ထွက်ခွာနေပါပြီ",
      ExecutionStatus.waitingCheckinConfirm =>
        "Check-In ပြုလုပ်ပြီးပါပြီ — Client အတည်ပြုချက် စောင့်ပါ",
      ExecutionStatus.waitingCheckoutConfirm =>
        "Check-Out ပြုလုပ်ပြီးပါပြီ — Client အတည်ပြုချက် စောင့်ပါ",
      _ => "",
    };
    if (notice.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(notice), duration: const Duration(seconds: 2)),
      );
    }
  }

  void _autoAdvanceDemoConfirmation(
    BuildContext context,
    WidgetRef ref,
    ExecutionStatus waitingStatus,
  ) {
    final nextStatus = switch (waitingStatus) {
      ExecutionStatus.waitingCheckinConfirm => ExecutionStatus.inProgress,
      ExecutionStatus.waitingCheckoutConfirm => ExecutionStatus.completed,
      _ => null,
    };
    if (nextStatus == null) return;

    Timer(const Duration(seconds: 2), () {
      if (!context.mounted) return;
      final all = ref.read(taskExecutionProvider);
      final current = executionFor(all, booking.id);
      if (current.status != waitingStatus) return;

      final now = DateTime.now();
      ref.read(taskExecutionProvider.notifier).state = {
        ...all,
        booking.id: current.copyWith(
          status: nextStatus,
          clientCheckinConfirmedAt:
              waitingStatus == ExecutionStatus.waitingCheckinConfirm
                  ? now
                  : null,
          clientCheckoutConfirmedAt:
              waitingStatus == ExecutionStatus.waitingCheckoutConfirm
                  ? now
                  : null,
        ),
      };
    });
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final all = ref.watch(taskExecutionProvider);
    final execution = executionFor(all, booking.id);
    final isTerminal = execution.status == ExecutionStatus.completed ||
        execution.status == ExecutionStatus.completionDisputed;
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
            onLeaving: () =>
                _advance(context, ref, ExecutionStatus.leavingForTask),
            onCheckin: () =>
                _advance(context, ref, ExecutionStatus.waitingCheckinConfirm),
            onCheckout: () =>
                _advance(context, ref, ExecutionStatus.waitingCheckoutConfirm),
          ),
          if (!isTerminal &&
              execution.status != ExecutionStatus.waitingCheckinConfirm &&
              execution.status != ExecutionStatus.waitingCheckoutConfirm &&
              execution.status != ExecutionStatus.arrivalDisputed) ...[
            const SizedBox(height: AppSpacing.xl),
            TaskerBriefCard(task: task),
            const SizedBox(height: AppSpacing.md),
            TaskerReminderBanner(timeSlot: booking.timeSlot),
          ],
          if (execution.status == ExecutionStatus.completed) ...[
            const SizedBox(height: AppSpacing.xl),
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
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: AppColors.onBrandMuted)),
          const SizedBox(height: AppSpacing.xs),
          Text(booking.skill,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.headlineSmall
                  ?.copyWith(color: AppColors.onBrand, fontSize: 22)),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Icon(Icons.access_time, size: 16, color: AppColors.onBrandMuted),
              const SizedBox(width: AppSpacing.xs),
              Flexible(
                child: Text(booking.timeSlot,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: AppColors.onBrand)),
              ),
              const SizedBox(width: AppSpacing.md),
              Icon(Icons.location_on, size: 16, color: AppColors.onBrandMuted),
              const SizedBox(width: AppSpacing.xs),
              Flexible(
                child: Text(booking.township,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: AppColors.onBrand)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Timeline — shows every milestone with time if recorded
// ─────────────────────────────────────────────────────────────────────────────

class _Timeline extends StatelessWidget {
  final TaskExecution execution;
  const _Timeline({required this.execution});

  String? _fmt(DateTime? d) => d == null
      ? null
      : "${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}";

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rows = [
      (AppStrings.executionLeaveLabel, _fmt(execution.leaveTime)),
      (AppStrings.executionCheckinLabel, _fmt(execution.checkinTime)),
      (
        AppStrings.executionClientConfirmedCheckinLabel,
        _fmt(execution.clientCheckinConfirmedAt)
      ),
      (AppStrings.executionCheckoutLabel, _fmt(execution.checkoutTime)),
      (
        AppStrings.executionClientConfirmedCheckoutLabel,
        _fmt(execution.clientCheckoutConfirmedAt)
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(AppStrings.executionTimelineTitle,
            style: theme.textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        for (final row in rows)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
            child: Row(
              children: [
                Icon(
                  row.$2 != null
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  size: 18,
                  color: row.$2 != null
                      ? AppColors.success
                      : Theme.of(context).hintColor,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    row.$1,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: row.$2 != null ? null : theme.hintColor,
                    ),
                  ),
                ),
                if (row.$2 != null)
                  Text(row.$2!,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.hintColor)),
              ],
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Current action — the primary CTA card that changes with each state
// ─────────────────────────────────────────────────────────────────────────────

class _CurrentAction extends StatelessWidget {
  final TaskExecution execution;
  final VoidCallback onLeaving;
  final VoidCallback onCheckin;
  final VoidCallback onCheckout;

  const _CurrentAction({
    required this.execution,
    required this.onLeaving,
    required this.onCheckin,
    required this.onCheckout,
  });

  @override
  Widget build(BuildContext context) {
    return switch (execution.status) {
      // ── Step 0: haven't left yet ─────────────────────────────────────────
      ExecutionStatus.pending => LargeButton(
          label: AppStrings.executionLeavingCta,
          gradient: AppColors.purpleGradient,
          onTap: onLeaving,
        ),

      // ── Step 1: on the way ───────────────────────────────────────────────
      ExecutionStatus.leavingForTask => LargeButton(
          label: AppStrings.executionCheckinCta,
          gradient: AppColors.purpleGradient,
          onTap: onCheckin,
        ),

      // ── Step 2a: checked in, waiting for client ──────────────────────────
      ExecutionStatus.waitingCheckinConfirm => _StatusBanner(
          icon: Icons.hourglass_top,
          color: AppColors.indigo700,
          message: AppStrings.executionCheckinWaiting,
        ),

      // ── Step 2b: client rejected arrival ────────────────────────────────
      ExecutionStatus.arrivalDisputed => _StatusBanner(
          icon: Icons.warning_amber_rounded,
          color: AppColors.warning,
          message: AppStrings.executionArrivalDisputedMsg,
        ),

      // ── Step 3: client confirmed, work in progress ───────────────────────
      ExecutionStatus.inProgress => LargeButton(
          label: AppStrings.executionCheckoutCta,
          gradient: AppColors.purpleGradient,
          onTap: onCheckout,
        ),

      // ── Step 4a: checked out, waiting for client ─────────────────────────
      ExecutionStatus.waitingCheckoutConfirm => _StatusBanner(
          icon: Icons.hourglass_top,
          color: AppColors.indigo700,
          message: AppStrings.executionCheckoutWaiting,
        ),

      // ── Step 4b: client reported issue ───────────────────────────────────
      ExecutionStatus.completionDisputed => _StatusBanner(
          icon: Icons.report_problem_outlined,
          color: AppColors.error,
          message: AppStrings.executionCompletionDisputedMsg,
        ),

      // ── Terminal: job completed ───────────────────────────────────────────
      ExecutionStatus.completed => _StatusBanner(
          icon: Icons.celebration_outlined,
          color: AppColors.success,
          message: AppStrings.executionCompletedMsg,
        ),
    };
  }
}

class _StatusBanner extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String message;
  const _StatusBanner({
    required this.icon,
    required this.color,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: color, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
