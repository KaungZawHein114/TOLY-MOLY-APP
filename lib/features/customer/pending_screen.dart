import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/agent/agent_session.dart';
import '../../core/data/demo_data.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../activity/activity_chat.dart';
import '../worker/task_execution_state.dart';
import 'activity_screen.dart';
import 'widgets/checkin_confirmation_card.dart';
import 'widgets/stale_post_nudge.dart';

// A representative "waiting" client post for the Task-Handling nudge (spec
// §4.4 Phase 1). The demo has no live open-post list with timestamps, so this
// stands in for one; its age is past [AgentThresholds.stalePostHours] so the
// gentle nudge shows. Swap for a real pending TaskPost when that list exists.
const Map<String, dynamic> _demoWaitingPost = {
  'category': 'Plumber',
  'township': 'လှိုင်',
  'budgetMmk': 12000,
  'urgent': false,
  'description': '',
};
const int _demoWaitingAgeHours = AgentThresholds.stalePostHours + 2;

/// Pending tab — shows booking management.
///
/// Pinned confirmation cards appear at the TOP of this tab whenever the
/// active booking's execution state requires the client to act:
///   • [ExecutionStatus.waitingCheckinConfirm] → [CheckinConfirmationCard]
///   • [ExecutionStatus.waitingCheckoutConfirm] → [CheckoutConfirmationCard]
///
/// Both cards write directly to [taskExecutionProvider], which the worker's
/// [TaskExecutionScreen] also reads — no network needed in Phase 1.
class PendingScreen extends ConsumerWidget {
  const PendingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    // Find the first "Active" demo booking that may need client action.
    final activeBooking = bookings.where((b) => b.status == 'Active').firstOrNull;
    final allExec = ref.watch(taskExecutionProvider);
    final execution =
        activeBooking != null ? executionFor(allExec, activeBooking.id) : null;

    final needsCheckinConfirm =
        execution?.status == ExecutionStatus.waitingCheckinConfirm;
    final needsCheckoutConfirm =
        execution?.status == ExecutionStatus.waitingCheckoutConfirm;

    return Scaffold(
      body: Column(
        children: [
          // ── Header ────────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              56,
              AppSpacing.xl,
              AppSpacing.xl,
            ),
            decoration: const BoxDecoration(
              color: AppColors.purple700,
              borderRadius:
                  BorderRadius.vertical(bottom: Radius.circular(AppRadius.xl)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'ဘွတ်ကင်များ',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: AppColors.onBrand,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Semantics(
                  label: 'အသိပေးချက်များ',
                  button: true,
                  child: IconButton(
                    icon: const Icon(Icons.notifications_none_outlined,
                        color: AppColors.onBrand),
                    onPressed: () => showActivitySnack(
                        context, 'အသိပေးချက်အသစ်များ မရှိသေးပါ။'),
                  ),
                ),
              ],
            ),
          ),

          // ── Scrollable body ───────────────────────────────────────────────
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.xxxl),
              children: [
                // ── Pinned check-in confirmation card ─────────────────────
                if (needsCheckinConfirm && activeBooking != null) ...[
                  CheckinConfirmationCard(
                    workerName: activeBooking.workerName,
                    onAccept: () => _clientConfirmCheckin(ref, activeBooking.id),
                    onReject: () => _clientRejectCheckin(ref, activeBooking.id),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],

                // ── Pinned check-out confirmation card ────────────────────
                if (needsCheckoutConfirm && activeBooking != null) ...[
                  CheckoutConfirmationCard(
                    workerName: activeBooking.workerName,
                    onConfirm: () =>
                        _clientConfirmCheckout(ref, activeBooking.id),
                    onReport: () =>
                        _clientReportIssue(ref, activeBooking.id, context),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],

                // ── Stale-post nudge ──────────────────────────────────────
                if (_demoWaitingAgeHours >= AgentThresholds.stalePostHours) ...[
                  StalePostNudge(
                    task: _demoWaitingPost,
                    ageHours: _demoWaitingAgeHours,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],

                // ── Booking list ──────────────────────────────────────────
                const ActivityBookingsView(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── State mutation helpers (client side) ──────────────────────────────────

  void _clientConfirmCheckin(WidgetRef ref, int taskId) {
    final all = ref.read(taskExecutionProvider);
    final current = executionFor(all, taskId);
    final updated = current.copyWith(
      status: ExecutionStatus.inProgress,
      clientCheckinConfirmedAt: DateTime.now(),
    );
    ref.read(taskExecutionProvider.notifier).state = {...all, taskId: updated};
  }

  void _clientRejectCheckin(WidgetRef ref, int taskId) {
    final all = ref.read(taskExecutionProvider);
    final current = executionFor(all, taskId);
    final updated = current.copyWith(status: ExecutionStatus.arrivalDisputed);
    ref.read(taskExecutionProvider.notifier).state = {...all, taskId: updated};
  }

  void _clientConfirmCheckout(WidgetRef ref, int taskId) {
    final all = ref.read(taskExecutionProvider);
    final current = executionFor(all, taskId);
    final updated = current.copyWith(
      status: ExecutionStatus.completed,
      clientCheckoutConfirmedAt: DateTime.now(),
    );
    ref.read(taskExecutionProvider.notifier).state = {...all, taskId: updated};
  }

  void _clientReportIssue(WidgetRef ref, int taskId, BuildContext context) {
    final all = ref.read(taskExecutionProvider);
    final current = executionFor(all, taskId);
    final updated =
        current.copyWith(status: ExecutionStatus.completionDisputed);
    ref.read(taskExecutionProvider.notifier).state = {...all, taskId: updated};
    showActivitySnack(context, 'ပြဿနာ တိုင်ကြားမှုကို မှတ်တမ်းတင်ပြီးပါပြီ။ Support ဆက်သွယ်ပေးပါမည်။');
  }
}
