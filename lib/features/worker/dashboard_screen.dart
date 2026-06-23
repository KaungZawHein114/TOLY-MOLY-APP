import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_strings.dart';
import '../../core/data/demo_data.dart';
import '../../core/routing/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/demo_card.dart';
import '../../core/widgets/large_button.dart';

// ============================================================================
// LOCAL UI STATE (Riverpod), declared in this screen file.
// ============================================================================

class AttendanceStatus {
  final bool isCheckedIn;
  final DateTime? checkInTime;
  final DateTime? checkOutTime;

  const AttendanceStatus({this.isCheckedIn = false, this.checkInTime, this.checkOutTime});

  AttendanceStatus checkIn() =>
      AttendanceStatus(isCheckedIn: true, checkInTime: DateTime.now(), checkOutTime: null);

  AttendanceStatus checkOut() =>
      AttendanceStatus(isCheckedIn: false, checkInTime: checkInTime, checkOutTime: DateTime.now());
}

final attendanceProvider = StateProvider<AttendanceStatus>((ref) => const AttendanceStatus());
final jobSearchProvider = StateProvider<String>((ref) => "");
final townshipFilterProvider = StateProvider<String?>((ref) => null);
final urgentOnlyJobsProvider = StateProvider<bool>((ref) => false);
final jobViewProvider = StateProvider<_JobView>((ref) => _JobView.nearby);
final jobsStateProvider = StateProvider<List<Job>>((ref) => jobs);
final workerInterestsProvider = StateProvider<List<WorkerInterest>>((ref) => []);

enum _JobView { nearby, all }

class WorkerDashboardScreen extends ConsumerWidget {
  const WorkerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final attendance = ref.watch(attendanceProvider);
    final query = ref.watch(jobSearchProvider);
    final townshipFilter = ref.watch(townshipFilterProvider);
    final urgentOnly = ref.watch(urgentOnlyJobsProvider);
    final view = ref.watch(jobViewProvider);
    final allJobsState = ref.watch(jobsStateProvider);
    final worker = loggedInWorker;

    // Pending requests = the demo bookings that are not yet completed.
    final pending = bookings.where((b) => b.status == "Pending" || b.status == "Active").toList();

    // Worker only sees jobs that match their skill and tier. A job this
    // worker has already expressed interest in stays visible (with the
    // button swapped to a disabled "Interest Received" state) rather than
    // disappearing — status only gates whether *other* workers would still
    // see it as open, not this worker's own view of their own action.
    var eligible = allJobsState.where((j) {
      if (j.category != worker.skill) return false;
      if (worker.currentTier < j.requiredTier) return false;
      return true;
    }).toList();

    if (query.trim().isNotEmpty) {
      final q = query.trim();
      eligible = eligible
          .where((j) => j.category.contains(q) || j.description.contains(q))
          .toList();
    }
    if (townshipFilter != null) {
      eligible = eligible.where((j) => j.township == townshipFilter).toList();
    }
    if (urgentOnly) {
      eligible = eligible.where((j) => j.isUrgent).toList();
    }

    switch (view) {
      case _JobView.nearby:
        eligible.sort((a, b) => a.distanceMiles.compareTo(b.distanceMiles));
        break;
      case _JobView.all:
        eligible.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
    }

    final monthlyIncome = _monthlyIncome(DateTime.now());
    final completedJobsCount = bookings.where((b) => b.status == "Completed").length;

    // The Digital Task Check-In card only appears when there's a confirmed
    // on-site task — "Active" is this app's closest existing analog to
    // task.status == confirmed (there's no separate task-status field yet).
    final activeBookings = bookings.where((b) => b.status == "Active").toList();
    final todaysTask = activeBookings.isEmpty ? null : activeBookings.first;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Worker Dashboard"),
        leading: IconButton(
          icon: const Icon(Icons.swap_horiz),
          tooltip: "Switch role",
          onPressed: () => context.go(Routes.onboardingWelcome),
        ),
        actions: [
          Semantics(
            label: AppStrings.homeNotificationsEmpty,
            button: true,
            child: IconButton(
              icon: const Icon(Icons.notifications_outlined),
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(AppStrings.homeNotificationsEmpty)),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _WorkerIdentityCard(worker: worker),
          const SizedBox(height: AppSpacing.lg),
          _AttendanceCard(
            attendance: attendance,
            onCheckIn: () => ref.read(attendanceProvider.notifier).state = attendance.checkIn(),
            onCheckOut: () => ref.read(attendanceProvider.notifier).state = attendance.checkOut(),
          ),
          if (todaysTask != null) ...[
            const SizedBox(height: AppSpacing.lg),
            _DigitalCheckInCard(booking: todaysTask),
          ],
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  emoji: "💰",
                  value: monthlyIncome.toString(),
                  unit: AppStrings.currency,
                  label: AppStrings.dashboardMonthlyIncome,
                  gradient: AppColors.purpleGradient,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _StatCard(
                  emoji: "✅",
                  value: "$completedJobsCount",
                  unit: "jobs",
                  label: AppStrings.dashboardCompletedJobs,
                  gradient: AppColors.orangeGradient,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xxl),
          Text("Job Board", style: theme.textTheme.titleLarge),
          const SizedBox(height: AppSpacing.sm),
          if (!attendance.isCheckedIn)
            _CheckInHint(message: AppStrings.dashboardCheckInToSeeJobs)
          else ...[
            TextField(
              onChanged: (v) => ref.read(jobSearchProvider.notifier).state = v,
              decoration: InputDecoration(
                hintText: AppStrings.dashboardJobSearchHint,
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: AppColors.blue100,
                contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm + 2),
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _Chip(
                    label: "All",
                    selected: townshipFilter == null,
                    onTap: () => ref.read(townshipFilterProvider.notifier).state = null,
                  ),
                  for (final t in _townships)
                    _Chip(
                      label: t,
                      selected: townshipFilter == t,
                      onTap: () => ref.read(townshipFilterProvider.notifier).state =
                          townshipFilter == t ? null : t,
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xs + 2),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: [
                ChoiceChip(
                  label: Text(AppStrings.dashboardNearbyJobs),
                  selected: view == _JobView.nearby,
                  onSelected: (_) => ref.read(jobViewProvider.notifier).state = _JobView.nearby,
                  selectedColor: AppColors.purple700,
                  labelStyle: TextStyle(
                      color: view == _JobView.nearby ? AppColors.onBrand : null,
                      fontWeight: FontWeight.w600),
                ),
                ChoiceChip(
                  label: Text(AppStrings.dashboardAllJobs),
                  selected: view == _JobView.all,
                  onSelected: (_) => ref.read(jobViewProvider.notifier).state = _JobView.all,
                  selectedColor: AppColors.purple700,
                  labelStyle: TextStyle(
                      color: view == _JobView.all ? AppColors.onBrand : null,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs + 2),
            Row(
              children: [
                Flexible(
                  child: Text(AppStrings.dashboardUrgentOnly,
                      style: theme.textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ),
                Switch(
                  value: urgentOnly,
                  activeThumbColor: AppColors.purple700,
                  onChanged: (v) => ref.read(urgentOnlyJobsProvider.notifier).state = v,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            if (eligible.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                child: Center(
                  child: Text(AppStrings.dashboardNoJobsFound,
                      style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor)),
                ),
              )
            else
              ...eligible.map((j) => _JobCard(
                    job: j,
                    onInterested: () {
                      ref.read(jobsStateProvider.notifier).state = [
                        for (final job in ref.read(jobsStateProvider))
                          if (job.id == j.id) job.copyWith(status: AppStrings.dashboardInterestReceived) else job,
                      ];
                      ref.read(workerInterestsProvider.notifier).state = [
                        ...ref.read(workerInterestsProvider),
                        WorkerInterest(workerId: worker.id, jobId: j.id, createdAt: DateTime.now()),
                      ];
                    },
                    onMessageClient: () => context.push(Routes.chatbot),
                  )),
          ],
          const SizedBox(height: AppSpacing.xxl),
          Text(AppStrings.pendingRequests, style: theme.textTheme.titleLarge),
          const SizedBox(height: AppSpacing.sm),
          if (!attendance.isCheckedIn)
            const _OfflineHint()
          else
            ...pending.map((b) => _RequestCard(booking: b)),
        ],
      ),
    );
  }

  int _monthlyIncome(DateTime now) {
    return bookings
        .where((b) {
          if (b.status != "Completed") return false;
          final d = DateTime.tryParse(b.date);
          return d != null && d.year == now.year && d.month == now.month;
        })
        .fold(0, (sum, b) => sum + b.totalMmk);
  }
}

const List<String> _townships = ["လှိုင်", "ကမာရွတ်", "မရမ်းကုန်း", "အင်းစိန်"];

class _WorkerIdentityCard extends StatelessWidget {
  final Worker worker;
  const _WorkerIdentityCard({required this.worker});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(color: AppColors.purple100, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Text(worker.emoji, style: const TextStyle(fontSize: 28)),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(worker.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.titleMedium),
                const SizedBox(height: AppSpacing.xxs),
                TrustBadgePill(tier: worker.currentTier),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AttendanceCard extends StatelessWidget {
  final AttendanceStatus attendance;
  final VoidCallback onCheckIn;
  final VoidCallback onCheckOut;
  const _AttendanceCard({
    required this.attendance,
    required this.onCheckIn,
    required this.onCheckOut,
  });

  String _time(DateTime d) => "${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}";

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final checkedIn = attendance.isCheckedIn;
    String? subtitle;
    if (checkedIn && attendance.checkInTime != null) {
      subtitle = "${AppStrings.dashboardCheckedInSince} ${_time(attendance.checkInTime!)}";
    } else if (!checkedIn && attendance.checkInTime != null && attendance.checkOutTime != null) {
      final hours = attendance.checkOutTime!.difference(attendance.checkInTime!).inMinutes / 60;
      subtitle = "${AppStrings.dashboardHoursToday}: ${hours.toStringAsFixed(1)}h";
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg + 2, vertical: AppSpacing.md + 2),
      decoration: BoxDecoration(
        gradient: checkedIn ? AppColors.purpleGradient : null,
        color: checkedIn ? null : theme.cardColor,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: checkedIn ? null : Border.all(color: theme.dividerColor),
        boxShadow: checkedIn
            ? [
                BoxShadow(
                  color: AppColors.purple700.withValues(alpha: 0.35),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                checkedIn ? Icons.flash_on : Icons.flash_off,
                color: checkedIn ? AppColors.onBrand : theme.hintColor,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.availableForBookings,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: checkedIn ? AppColors.onBrand : theme.textTheme.bodyLarge?.color,
                      ),
                    ),
                    if (subtitle != null)
                      Text(subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: checkedIn ? AppColors.onBrandMuted : theme.hintColor)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: checkedIn ? AppColors.onBrand : AppColors.purple700,
              foregroundColor: checkedIn ? AppColors.purple700 : AppColors.onBrand,
            ),
            onPressed: checkedIn ? onCheckOut : onCheckIn,
            child: Text(checkedIn ? AppStrings.dashboardCheckOut : AppStrings.dashboardCheckIn),
          ),
        ],
      ),
    );
  }
}

/// Digital Task Check-In preview — distinct from [_AttendanceCard] (general
/// "available for new bookings" status). This is about a single confirmed,
/// on-site task's execution stages (leaving/arrived/completed); "Start
/// Process" pushes to the dedicated [TaskExecutionScreen].
class _DigitalCheckInCard extends StatelessWidget {
  final Booking booking;
  const _DigitalCheckInCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppStrings.executionSectionTitle,
              maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Icon(Icons.assignment_outlined, size: 18, color: theme.hintColor),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  "${AppStrings.executionTodaysTask}: ${booking.skill} • ${booking.timeSlot} • ${booking.township}",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          LargeButton(
            label: AppStrings.executionStartProcess,
            icon: Icons.play_arrow,
            filled: false,
            outlineColor: AppColors.purple700,
            onTap: () => context.push('${Routes.taskExecution}/${booking.id}'),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String emoji;
  final String value;
  final String unit;
  final String label;
  final Gradient gradient;
  const _StatCard({
    required this.emoji,
    required this.value,
    required this.unit,
    required this.label,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: gradient.colors.first.withValues(alpha: 0.3),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 26)),
          const SizedBox(height: AppSpacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: Text(value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.headlineSmall?.copyWith(color: AppColors.onBrand, fontSize: 24)),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(unit, style: theme.textTheme.bodySmall?.copyWith(color: AppColors.onBrandMuted)),
            ],
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(color: AppColors.onBrandMuted)),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _Chip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.sm),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: AppColors.purple700,
        labelStyle: theme.textTheme.bodyMedium
            ?.copyWith(color: selected ? AppColors.onBrand : null, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _JobCard extends StatelessWidget {
  final Job job;
  final VoidCallback onInterested;
  final VoidCallback onMessageClient;
  const _JobCard({required this.job, required this.onInterested, required this.onMessageClient});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final interested = job.status == AppStrings.dashboardInterestReceived;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs + 2),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md + 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(job.category,
                      maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.titleMedium),
                ),
                if (job.isUrgent) ...[
                  const SizedBox(width: AppSpacing.xs),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xxs),
                    decoration: BoxDecoration(
                      color: AppColors.orange.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Text("⚡ Urgent",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: AppColors.orange, fontWeight: FontWeight.w700)),
                  ),
                ],
              ],
            ),
            const SizedBox(height: AppSpacing.xxs),
            Text(job.description,
                maxLines: 2, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodyMedium),
            const SizedBox(height: AppSpacing.xs + 2),
            Row(
              children: [
                Icon(Icons.location_on, size: 14, color: theme.hintColor),
                const SizedBox(width: AppSpacing.xxs),
                Flexible(
                  child: Text("${job.township} • ${job.distanceMiles.toStringAsFixed(1)} mi",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor)),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text("${AppStrings.dashboardRequiredTierPrefix}${trustBadgeFor(job.requiredTier)}",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor)),
            const SizedBox(height: AppSpacing.sm + 2),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppStrings.dashboardAiEstimatedBudget,
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor)),
                Text("${job.aiSuggestedBudgetMmk} MMK",
                    style: theme.textTheme.titleMedium
                        ?.copyWith(color: AppColors.purple700, fontWeight: FontWeight.w900)),
              ],
            ),
            const SizedBox(height: AppSpacing.sm + 2),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onMessageClient,
                    child: Text(AppStrings.dashboardMessageClientCta,
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                        backgroundColor: interested ? AppColors.success : AppColors.purple700),
                    onPressed: interested ? null : onInterested,
                    child: Text(
                      interested ? AppStrings.dashboardInterestReceived : AppStrings.dashboardInterestedCta,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  final Booking booking;
  const _RequestCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs + 2),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md + 2),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.orange.withValues(alpha: 0.15),
                  child: const Text("🧑"),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(booking.customerName,
                          maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.titleMedium),
                      Text("${booking.skill} • ${booking.date}",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor)),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                StatusBadge(status: booking.status),
              ],
            ),
            const SizedBox(height: AppSpacing.sm + 2),
            Text("${booking.totalMmk} MMK",
                style: theme.textTheme.titleMedium?.copyWith(color: AppColors.orange, fontWeight: FontWeight.w900)),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _toast(context, "Declined"),
                    child: const Text("Decline", maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: AppColors.purple700),
                    onPressed: () => _toast(context, "Accepted ✓"),
                    child: const Text("Accept", maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _toast(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 1)),
    );
  }
}

class _CheckInHint extends StatelessWidget {
  final String message;
  const _CheckInHint({required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        children: [
          const Text("📋", style: TextStyle(fontSize: 36)),
          const SizedBox(height: AppSpacing.sm),
          Text(message, textAlign: TextAlign.center, style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor)),
        ],
      ),
    );
  }
}

class _OfflineHint extends StatelessWidget {
  const _OfflineHint();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        children: [
          const Text("😴", style: TextStyle(fontSize: 36)),
          const SizedBox(height: AppSpacing.sm),
          Text("Turn on \"Available for bookings\" to see requests",
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor)),
        ],
      ),
    );
  }
}
