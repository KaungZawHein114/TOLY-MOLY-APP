import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_strings.dart';
import '../../core/data/demo_data.dart';
import '../../core/routing/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/large_button.dart';
import '../profile/data/profile_repository.dart';
import '../profile/data/profile_repository_impl.dart';
import 'widgets/job_card.dart';
import 'widgets/job_filter_bar.dart';
import 'widgets/job_search_bar.dart';

// ============================================================================
// LOCAL UI STATE (Riverpod), declared in this screen file.
// ============================================================================

// ── Account name — backend-connected (`GET /api/profile/`). First frame
// never blocks on the network: the header falls back to just the generic
// greeting until this loads (or if the request fails). Same pattern as the
// customer Home screen's [_HomeNameNotifier]. ──

class _WorkerNameState {
  final bool loading;
  final String? name;
  const _WorkerNameState({this.loading = true, this.name});
}

class _WorkerNameNotifier extends StateNotifier<_WorkerNameState> {
  final ProfileRepository _repo;
  _WorkerNameNotifier(this._repo) : super(const _WorkerNameState()) {
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await _repo.getProfile();
      state = _WorkerNameState(loading: false, name: data.name);
    } catch (_) {
      state = const _WorkerNameState(loading: false);
    }
  }
}

final _workerNameProvider = StateNotifierProvider.autoDispose<_WorkerNameNotifier, _WorkerNameState>(
  (ref) => _WorkerNameNotifier(ProfileRepositoryImpl()),
);

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

/// Shared focus node for the job-search field, so the chatbot's "Find a Task"
/// action can focus it after navigating here (best-effort; no-op when the
/// field isn't on screen, e.g. the worker hasn't checked in yet).
final FocusNode jobSearchFocusNode = FocusNode();
final townshipFilterProvider = StateProvider<String?>((ref) => null);
final urgentOnlyJobsProvider = StateProvider<bool>((ref) => false);
final jobSortProvider = StateProvider<_JobSort>((ref) => _JobSort.recommended);
final jobsStateProvider = StateProvider<List<Job>>((ref) => jobs);
final workerInterestsProvider = StateProvider<List<WorkerInterest>>((ref) => []);

// Additive Job Board filters (Category/Distance/Budget) — local UI-only
// state, same pattern as the filters above; they narrow within whatever the
// worker-skill/tier eligibility check below already allows through, they
// never bypass it.
final jobCategoryFilterProvider = StateProvider<String?>((ref) => null);
final jobDistanceFilterKmProvider = StateProvider<double?>((ref) => null);
final jobBudgetFilterProvider = StateProvider<_BudgetFilter>((ref) => _BudgetFilter.any);

enum _JobSort { recommended, nearest, highestBudget, newest, urgentFirst }

enum _BudgetFilter { any, under20k, between20k50k, above50k }

extension on _BudgetFilter {
  bool matches(int budgetMmk) {
    switch (this) {
      case _BudgetFilter.any:
        return true;
      case _BudgetFilter.under20k:
        return budgetMmk < 20000;
      case _BudgetFilter.between20k50k:
        return budgetMmk >= 20000 && budgetMmk <= 50000;
      case _BudgetFilter.above50k:
        return budgetMmk > 50000;
    }
  }

  String get label {
    switch (this) {
      case _BudgetFilter.any:
        return AppStrings.jobBoardBudgetAny;
      case _BudgetFilter.under20k:
        return AppStrings.jobBoardBudgetUnder20k;
      case _BudgetFilter.between20k50k:
        return AppStrings.jobBoardBudget20to50k;
      case _BudgetFilter.above50k:
        return AppStrings.jobBoardBudgetAbove50k;
    }
  }
}

String _jobSortLabel(_JobSort sort) {
  switch (sort) {
    case _JobSort.recommended:
      return AppStrings.jobBoardSortRecommended;
    case _JobSort.nearest:
      return AppStrings.jobBoardSortNearest;
    case _JobSort.highestBudget:
      return AppStrings.jobBoardSortHighestBudget;
    case _JobSort.newest:
      return AppStrings.jobBoardSortNewest;
    case _JobSort.urgentFirst:
      return AppStrings.jobBoardSortUrgentFirst;
  }
}

const List<double> _distanceKmOptions = [2, 5, 10];

class WorkerDashboardScreen extends ConsumerStatefulWidget {
  const WorkerDashboardScreen({super.key});

  @override
  ConsumerState<WorkerDashboardScreen> createState() => _WorkerDashboardScreenState();
}

class _WorkerDashboardScreenState extends ConsumerState<WorkerDashboardScreen> {
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey _filterBarKey = GlobalKey();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _scrollToFilters() {
    final ctx = _filterBarKey.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(ctx, duration: AppMotion.medium, curve: AppMotion.enter);
    }
  }

  void _showJobDetails(Job job) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return Padding(
          padding: EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.lg + MediaQuery.of(ctx).viewPadding.bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(categoryIconFor(job.category), color: AppColors.purple700),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(job.category,
                        maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.titleLarge),
                  ),
                  StatusBadge(urgent: job.isUrgent),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(job.description, style: theme.textTheme.bodyMedium),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: theme.hintColor),
                  const SizedBox(width: AppSpacing.xxs),
                  Text("${job.township} • ${job.distanceMiles.toStringAsFixed(1)} km",
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor)),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  Icon(Icons.verified_user_outlined, size: 16, color: theme.hintColor),
                  const SizedBox(width: AppSpacing.xxs),
                  Text("${AppStrings.dashboardRequiredTierPrefix}${trustBadgeFor(job.requiredTier)}",
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor)),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              BudgetBadge(budgetMmk: job.aiSuggestedBudgetMmk),
              const SizedBox(height: AppSpacing.lg),
              LargeButton(
                label: AppStrings.dashboardMessageClientCta,
                icon: Icons.chat_bubble_outline,
                filled: false,
                outlineColor: AppColors.purple700,
                onTap: () {
                  Navigator.of(ctx).pop();
                  context.push(Routes.chatbot);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final attendance = ref.watch(attendanceProvider);
    final query = ref.watch(jobSearchProvider);
    final townshipFilter = ref.watch(townshipFilterProvider);
    final urgentOnly = ref.watch(urgentOnlyJobsProvider);
    final sort = ref.watch(jobSortProvider);
    final categoryFilter = ref.watch(jobCategoryFilterProvider);
    final distanceKmFilter = ref.watch(jobDistanceFilterKmProvider);
    final budgetFilter = ref.watch(jobBudgetFilterProvider);
    final allJobsState = ref.watch(jobsStateProvider);
    final worker = loggedInWorker;

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

    // Category options are derived from whatever is already eligible above —
    // this never widens the worker-skill/tier gate, it only ever narrows it.
    final categoryOptions = <String>{for (final j in eligible) j.category}.toList()..sort();

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
    if (categoryFilter != null) {
      eligible = eligible.where((j) => j.category == categoryFilter).toList();
    }
    if (distanceKmFilter != null) {
      final milesCap = distanceKmFilter / 1.609;
      eligible = eligible.where((j) => j.distanceMiles <= milesCap).toList();
    }
    eligible = eligible.where((j) => budgetFilter.matches(j.aiSuggestedBudgetMmk)).toList();

    switch (sort) {
      case _JobSort.recommended:
        eligible.sort((a, b) {
          if (a.isUrgent != b.isUrgent) return a.isUrgent ? -1 : 1;
          return a.distanceMiles.compareTo(b.distanceMiles);
        });
        break;
      case _JobSort.nearest:
        eligible.sort((a, b) => a.distanceMiles.compareTo(b.distanceMiles));
        break;
      case _JobSort.highestBudget:
        eligible.sort((a, b) => b.aiSuggestedBudgetMmk.compareTo(a.aiSuggestedBudgetMmk));
        break;
      case _JobSort.newest:
        eligible.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case _JobSort.urgentFirst:
        eligible.sort((a, b) {
          if (a.isUrgent != b.isUrgent) return a.isUrgent ? -1 : 1;
          return b.createdAt.compareTo(a.createdAt);
        });
        break;
    }

    final monthlyIncome = _monthlyIncome(DateTime.now());
    final completedJobsCount = bookings.where((b) => b.status == "Completed").length;

    // The Digital Task Check-In card only appears when there's a confirmed
    // on-site task — "Active" is this app's closest existing analog to
    // task.status == confirmed (there's no separate task-status field yet).
    final activeBookings = bookings.where((b) => b.status == "Active").toList();
    final todaysTask = activeBookings.isEmpty ? null : activeBookings.first;

    final activeChips = <Widget>[
      if (categoryFilter != null)
        ActiveFilterChip(
          label: categoryFilter,
          onRemove: () => ref.read(jobCategoryFilterProvider.notifier).state = null,
        ),
      if (distanceKmFilter != null)
        ActiveFilterChip(
          label: "${distanceKmFilter.toStringAsFixed(0)} km",
          onRemove: () => ref.read(jobDistanceFilterKmProvider.notifier).state = null,
        ),
      if (budgetFilter != _BudgetFilter.any)
        ActiveFilterChip(
          label: budgetFilter.label,
          onRemove: () => ref.read(jobBudgetFilterProvider.notifier).state = _BudgetFilter.any,
        ),
      if (townshipFilter != null)
        ActiveFilterChip(
          label: townshipFilter,
          onRemove: () => ref.read(townshipFilterProvider.notifier).state = null,
        ),
      if (urgentOnly)
        ActiveFilterChip(
          label: AppStrings.jobBoardUrgentOnlyChip,
          onRemove: () => ref.read(urgentOnlyJobsProvider.notifier).state = false,
        ),
    ];

    void clearAllFilters() {
      ref.read(jobCategoryFilterProvider.notifier).state = null;
      ref.read(jobDistanceFilterKmProvider.notifier).state = null;
      ref.read(jobBudgetFilterProvider.notifier).state = _BudgetFilter.any;
      ref.read(townshipFilterProvider.notifier).state = null;
      ref.read(urgentOnlyJobsProvider.notifier).state = false;
    }

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            _WorkerHomeHeader(
              onSwitchRole: () => context.go(Routes.onboardingWelcome),
            ),
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
                    unit: "အလုပ်",
                    label: AppStrings.dashboardCompletedJobs,
                    gradient: AppColors.orangeGradient,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxl),
            Text(AppStrings.jobBoardTitle, style: theme.textTheme.titleLarge),
            const SizedBox(height: AppSpacing.sm),
            if (!attendance.isCheckedIn)
              _CheckInHint(message: AppStrings.dashboardCheckInToSeeJobs)
            else ...[
              JobSearchBar(
                controller: _searchController,
                focusNode: jobSearchFocusNode,
                onChanged: (v) => ref.read(jobSearchProvider.notifier).state = v,
                onFilterTap: _scrollToFilters,
              ),
              const SizedBox(height: AppSpacing.md),
              Container(
                key: _filterBarKey,
                child: JobFilterBar(
                  dropdowns: [
                    FilterDropdown<String?>(
                      semanticLabel: AppStrings.jobBoardCategoryLabel,
                      displayText: categoryFilter ?? AppStrings.jobBoardCategoryAll,
                      isActive: categoryFilter != null,
                      options: [
                        FilterOption(value: null, label: AppStrings.jobBoardCategoryAll),
                        for (final c in categoryOptions) FilterOption(value: c, label: c),
                      ],
                      onSelected: (v) => ref.read(jobCategoryFilterProvider.notifier).state = v,
                    ),
                    FilterDropdown<double?>(
                      semanticLabel: AppStrings.jobBoardDistanceLabel,
                      displayText: distanceKmFilter == null
                          ? AppStrings.jobBoardDistanceNearby
                          : "${distanceKmFilter.toStringAsFixed(0)} km",
                      isActive: distanceKmFilter != null,
                      options: [
                        FilterOption(value: null, label: AppStrings.jobBoardDistanceNearby),
                        for (final km in _distanceKmOptions)
                          FilterOption(value: km, label: "${km.toStringAsFixed(0)} km"),
                      ],
                      onSelected: (v) => ref.read(jobDistanceFilterKmProvider.notifier).state = v,
                    ),
                    FilterDropdown<_JobSort>(
                      semanticLabel: AppStrings.jobBoardSortLabel,
                      displayText: _jobSortLabel(sort),
                      isActive: sort != _JobSort.recommended,
                      options: [
                        for (final s in _JobSort.values) FilterOption(value: s, label: _jobSortLabel(s)),
                      ],
                      onSelected: (v) => ref.read(jobSortProvider.notifier).state = v,
                    ),
                    FilterDropdown<_BudgetFilter>(
                      semanticLabel: AppStrings.jobBoardBudgetLabel,
                      displayText: budgetFilter.label,
                      isActive: budgetFilter != _BudgetFilter.any,
                      options: [
                        for (final b in _BudgetFilter.values) FilterOption(value: b, label: b.label),
                      ],
                      onSelected: (v) => ref.read(jobBudgetFilterProvider.notifier).state = v,
                    ),
                    FilterDropdown<String?>(
                      semanticLabel: AppStrings.jobBoardTownshipLabel,
                      displayText: townshipFilter ?? AppStrings.jobBoardTownshipLabel,
                      isActive: townshipFilter != null,
                      options: [
                        FilterOption(value: null, label: "${AppStrings.jobBoardCategoryAll} ${AppStrings.jobBoardTownshipLabel}"),
                        for (final t in _townships) FilterOption(value: t, label: t),
                      ],
                      onSelected: (v) => ref.read(townshipFilterProvider.notifier).state = v,
                    ),
                    FilterToggleChip(
                      label: AppStrings.jobBoardUrgentOnlyChip,
                      selected: urgentOnly,
                      onTap: () => ref.read(urgentOnlyJobsProvider.notifier).state = !urgentOnly,
                    ),
                  ],
                  activeFilterChips: activeChips,
                  onClearAll: activeChips.isEmpty ? null : clearAllFilters,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              if (eligible.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                  child: Center(
                    child: Text(AppStrings.dashboardNoJobsFound,
                        style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor)),
                  ),
                )
              else
                ...List.generate(eligible.length, (i) {
                  final j = eligible[i];
                  return TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: AppMotion.medium,
                    curve: AppMotion.enter,
                    builder: (context, t, child) => Opacity(
                      opacity: t,
                      child: Transform.translate(offset: Offset(0, (1 - t) * 12), child: child),
                    ),
                    child: JobCard(
                      job: j,
                      onAccept: () {
                        ref.read(jobsStateProvider.notifier).state = [
                          for (final job in ref.read(jobsStateProvider))
                            if (job.id == j.id) job.copyWith(status: AppStrings.dashboardInterestReceived) else job,
                        ];
                        ref.read(workerInterestsProvider.notifier).state = [
                          ...ref.read(workerInterestsProvider),
                          WorkerInterest(workerId: worker.id, jobId: j.id, createdAt: DateTime.now()),
                        ];
                      },
                      onViewDetails: () => _showJobDetails(j),
                    ),
                  );
                }),
            ],
          ],
        ),
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

/// Worker Home header: TOLY MOLY logo + greeting at the top-left (replacing
/// the old "Worker Dashboard" AppBar title), with the switch-role and
/// notification actions on the right — same shape as the customer Home
/// header, just mirrored.
class _WorkerHomeHeader extends ConsumerWidget {
  final VoidCallback onSwitchRole;
  const _WorkerHomeHeader({required this.onSwitchRole});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final name = ref.watch(_workerNameProvider).name;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Image.asset("assets/logo_circle.png", width: 40, height: 40),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (name != null)
                Text(
                  AppStrings.workerHomeGreeting,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                ),
              Text(
                name ?? AppStrings.workerHomeGreeting,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
        Semantics(
          label: "အခန်းကဏ္ဍ ပြောင်းမည်",
          button: true,
          child: IconButton(
            icon: const Icon(Icons.swap_horiz, color: AppColors.purple700),
            tooltip: "အခန်းကဏ္ဍ ပြောင်းမည်",
            onPressed: onSwitchRole,
          ),
        ),
        Semantics(
          label: AppStrings.homeNotificationsEmpty,
          button: true,
          child: IconButton(
            icon: const Icon(Icons.notifications_outlined, color: AppColors.purple700),
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(AppStrings.homeNotificationsEmpty)),
            ),
          ),
        ),
      ],
    );
  }
}

const List<String> _townships = ["လှိုင်", "ကမာရွတ်", "မရမ်းကုန်း", "အင်းစိန်"];

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
    final radius = BorderRadius.circular(AppRadius.lg);

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowMd,
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: AppColors.purpleGradient,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.qr_code_scanner, color: AppColors.onBrand, size: AppSizes.iconMd),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    AppStrings.executionSectionTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xxs),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Text(
                      AppStrings.executionLiveBadge,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: AppColors.success, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.purple100.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${AppStrings.executionTodaysTask} • ${booking.skill}",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 14, color: theme.hintColor),
                      const SizedBox(width: AppSpacing.xxs),
                      Flexible(
                        child: Text(booking.timeSlot,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor)),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Icon(Icons.location_on, size: 14, color: theme.hintColor),
                      const SizedBox(width: AppSpacing.xxs),
                      Flexible(
                        child: Text(booking.township,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            LargeButton(
              label: AppStrings.executionStartProcess,
              icon: Icons.play_circle_fill,
              gradient: AppColors.purpleGradient,
              onTap: () => context.push('${Routes.taskExecution}/${booking.id}'),
            ),
          ],
        ),
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

