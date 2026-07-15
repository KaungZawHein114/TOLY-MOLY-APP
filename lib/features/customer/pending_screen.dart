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
      // CustomScrollView + SliverFillRemaining(hasScrollBody: true) instead of
      // a plain Column: at large text scale, the header plus any pinned cards
      // can exceed the viewport height on their own — a Column would overflow
      // outright, but this lets the whole screen scroll instead while still
      // giving ActivityBookingsView's own internal Expanded a real bound
      // (at least the remaining viewport) to lay out against.
      body: CustomScrollView(
        slivers: [
          // ── Header ────────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
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
                children: [
                  Expanded(
                    child: Text(
                      'ဘွတ်ကင်များ',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: AppColors.onBrand,
                        fontWeight: FontWeight.bold,
                      ),
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
          ),

          // ── Pinned cards — fixed above the list, genuinely "pinned" ────────
          // (previously these lived inside the same ListView as the booking
          // list below, which meant they scrolled away with it despite the
          // name; it also handed ActivityBookingsView's internal Expanded an
          // unbounded height, since a bare ListView child has no height
          // limit — that's what caused the layout overflow.)
          if (needsCheckinConfirm && activeBooking != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 0),
                child: CheckinConfirmationCard(
                  workerName: activeBooking.workerName,
                  onAccept: () => _clientConfirmCheckin(ref, activeBooking.id),
                  onReject: () => _clientRejectCheckin(ref, activeBooking.id),
                ),
              ),
            ),
          if (needsCheckoutConfirm && activeBooking != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 0),
                child: CheckoutConfirmationCard(
                  workerName: activeBooking.workerName,
                  onConfirm: () => _clientConfirmCheckout(ref, activeBooking.id),
                  onReport: () =>
                      _clientReportIssue(ref, activeBooking.id, context),
                ),
              ),
            ),
          if (_demoWaitingAgeHours >= AgentThresholds.stalePostHours)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 0),
                child: StalePostNudge(
                  task: _demoWaitingPost,
                  ageHours: _demoWaitingAgeHours,
                ),
              ),
            ),

          // ── Booking list — same widget ActivityScreen embeds; here it gets
          // at least the remaining viewport height, growing further (with the
          // whole screen scrolling) if its own content needs more. ──
          const SliverFillRemaining(
            hasScrollBody: true,
            child: ActivityBookingsView(),
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
