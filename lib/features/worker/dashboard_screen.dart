import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_strings.dart';
import '../../core/data/demo_data.dart';
import '../../core/routing/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/large_button.dart';
import '../../core/widgets/modern_service_card.dart';
import '../profile/data/profile_repository.dart';
import '../profile/data/profile_repository_impl.dart';
import 'notifications/notification_service.dart';
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

final _workerNameProvider =
    StateNotifierProvider.autoDispose<_WorkerNameNotifier, _WorkerNameState>(
  (ref) => _WorkerNameNotifier(ProfileRepositoryImpl()),
);

final jobSearchProvider = StateProvider<String>((ref) => "");

/// Shared focus node for the job-search field, so the chatbot's "Find a Task"
/// action can focus it after navigating here (best-effort; no-op when the
/// field isn't on screen, e.g. the worker hasn't checked in yet).
final FocusNode jobSearchFocusNode = FocusNode();
final townshipFilterProvider = StateProvider<String?>((ref) => null);
final urgentOnlyJobsProvider = StateProvider<bool>((ref) => false);
final jobSortProvider = StateProvider<_JobSort>((ref) => _JobSort.recommended);
final jobsStateProvider = StateProvider<List<Job>>((ref) => jobs);
final workerInterestsProvider =
    StateProvider<List<WorkerInterest>>((ref) => []);

// Additive Job Board filters (Category/Distance/Budget), local UI-only state.
final jobCategoryFilterProvider = StateProvider<String?>((ref) => null);
final jobDistanceFilterKmProvider = StateProvider<double?>((ref) => null);
final jobBudgetFilterProvider =
    StateProvider<_BudgetFilter>((ref) => _BudgetFilter.any);

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
  ConsumerState<WorkerDashboardScreen> createState() =>
      _WorkerDashboardScreenState();
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
      Scrollable.ensureVisible(ctx,
          duration: AppMotion.medium, curve: AppMotion.enter);
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
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg + MediaQuery.of(ctx).viewPadding.bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(workIconForLabel(job.category),
                      color: AppColors.purple700),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(job.category,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleLarge),
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
                  Text(
                      "${job.township} • ${job.distanceMiles.toStringAsFixed(1)} km",
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.hintColor)),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  Icon(Icons.verified_user_outlined,
                      size: 16, color: theme.hintColor),
                  const SizedBox(width: AppSpacing.xxs),
                  Text(
                      "${AppStrings.dashboardRequiredTierPrefix}${trustBadgeFor(job.requiredTier)}",
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.hintColor)),
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
    final query = ref.watch(jobSearchProvider);
    final townshipFilter = ref.watch(townshipFilterProvider);
    final urgentOnly = ref.watch(urgentOnlyJobsProvider);
    final sort = ref.watch(jobSortProvider);
    final categoryFilter = ref.watch(jobCategoryFilterProvider);
    final distanceKmFilter = ref.watch(jobDistanceFilterKmProvider);
    final budgetFilter = ref.watch(jobBudgetFilterProvider);
    final allJobsState = ref.watch(jobsStateProvider);
    final worker = loggedInWorker;

    // Demo job board: show mixed work categories so the tasker home page does
    // not look locked to one skill in the offline MVP.
    var eligible = allJobsState.toList();

    // Category options are derived from the visible demo job pool.
    final categoryOptions =
        <String>{for (final j in eligible) j.category}.toList()..sort();

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
    eligible = eligible
        .where((j) => budgetFilter.matches(j.aiSuggestedBudgetMmk))
        .toList();

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
        eligible.sort(
            (a, b) => b.aiSuggestedBudgetMmk.compareTo(a.aiSuggestedBudgetMmk));
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
    final completedJobsCount =
        bookings.where((b) => b.status == "Completed").length;

    final activeChips = <Widget>[
      if (categoryFilter != null)
        ActiveFilterChip(
          label: categoryFilter,
          onRemove: () =>
              ref.read(jobCategoryFilterProvider.notifier).state = null,
        ),
      if (distanceKmFilter != null)
        ActiveFilterChip(
          label: "${distanceKmFilter.toStringAsFixed(0)} km",
          onRemove: () =>
              ref.read(jobDistanceFilterKmProvider.notifier).state = null,
        ),
      if (budgetFilter != _BudgetFilter.any)
        ActiveFilterChip(
          label: budgetFilter.label,
          onRemove: () => ref.read(jobBudgetFilterProvider.notifier).state =
              _BudgetFilter.any,
        ),
      if (townshipFilter != null)
        ActiveFilterChip(
          label: townshipFilter,
          onRemove: () =>
              ref.read(townshipFilterProvider.notifier).state = null,
        ),
      if (urgentOnly)
        ActiveFilterChip(
          label: AppStrings.jobBoardUrgentOnlyChip,
          onRemove: () =>
              ref.read(urgentOnlyJobsProvider.notifier).state = false,
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
          padding: EdgeInsets.zero,
          children: [
            const _WorkerHomeHeader(),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          icon: Icons.account_balance_wallet_outlined,
                          iconColor: AppColors.purple700,
                          iconBackground: AppColors.blue500,
                          cardBackground: AppColors.purple700,
                          valueColor: AppColors.onBrand,
                          labelColor: AppColors.onBrandMuted,
                          value: monthlyIncome.toString(),
                          unit: AppStrings.currency,
                          label: AppStrings.dashboardMonthlyIncome,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: _StatCard(
                          icon: Icons.task_alt_rounded,
                          iconColor: AppColors.purple700,
                          iconBackground: AppColors.workIconSurface,
                          cardBackground: AppColors.blue500,
                          valueColor: AppColors.textPrimary,
                          labelColor: AppColors.textSecondary,
                          value: "$completedJobsCount",
                          unit: "အလုပ်",
                          label: AppStrings.dashboardCompletedJobs,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  Text(AppStrings.jobBoardTitle,
                      style: theme.textTheme.titleLarge),
                  const SizedBox(height: AppSpacing.sm),
                  JobSearchBar(
                    controller: _searchController,
                    focusNode: jobSearchFocusNode,
                    onChanged: (v) =>
                        ref.read(jobSearchProvider.notifier).state = v,
                    onFilterTap: _scrollToFilters,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    key: _filterBarKey,
                    child: JobFilterBar(
                      dropdowns: [
                        FilterDropdown<String?>(
                          semanticLabel: AppStrings.jobBoardCategoryLabel,
                          displayText:
                              categoryFilter ?? AppStrings.jobBoardCategoryAll,
                          isActive: categoryFilter != null,
                          options: [
                            FilterOption(
                                value: null,
                                label: AppStrings.jobBoardCategoryAll),
                            for (final c in categoryOptions)
                              FilterOption(value: c, label: c),
                          ],
                          onSelected: (v) => ref
                              .read(jobCategoryFilterProvider.notifier)
                              .state = v,
                        ),
                        FilterDropdown<double?>(
                          semanticLabel: AppStrings.jobBoardDistanceLabel,
                          displayText: distanceKmFilter == null
                              ? AppStrings.jobBoardDistanceNearby
                              : "${distanceKmFilter.toStringAsFixed(0)} km",
                          isActive: distanceKmFilter != null,
                          options: [
                            FilterOption(
                                value: null,
                                label: AppStrings.jobBoardDistanceNearby),
                            for (final km in _distanceKmOptions)
                              FilterOption(
                                  value: km,
                                  label: "${km.toStringAsFixed(0)} km"),
                          ],
                          onSelected: (v) => ref
                              .read(jobDistanceFilterKmProvider.notifier)
                              .state = v,
                        ),
                        FilterDropdown<_JobSort>(
                          semanticLabel: AppStrings.jobBoardSortLabel,
                          displayText: _jobSortLabel(sort),
                          isActive: sort != _JobSort.recommended,
                          options: [
                            for (final s in _JobSort.values)
                              FilterOption(value: s, label: _jobSortLabel(s)),
                          ],
                          onSelected: (v) =>
                              ref.read(jobSortProvider.notifier).state = v,
                        ),
                        FilterDropdown<_BudgetFilter>(
                          semanticLabel: AppStrings.jobBoardBudgetLabel,
                          displayText: budgetFilter.label,
                          isActive: budgetFilter != _BudgetFilter.any,
                          options: [
                            for (final b in _BudgetFilter.values)
                              FilterOption(value: b, label: b.label),
                          ],
                          onSelected: (v) => ref
                              .read(jobBudgetFilterProvider.notifier)
                              .state = v,
                        ),
                        FilterDropdown<String?>(
                          semanticLabel: AppStrings.jobBoardTownshipLabel,
                          displayText: townshipFilter ??
                              AppStrings.jobBoardTownshipLabel,
                          isActive: townshipFilter != null,
                          options: [
                            FilterOption(
                                value: null,
                                label:
                                    "${AppStrings.jobBoardCategoryAll} ${AppStrings.jobBoardTownshipLabel}"),
                            for (final t in _townships)
                              FilterOption(value: t, label: t),
                          ],
                          onSelected: (v) => ref
                              .read(townshipFilterProvider.notifier)
                              .state = v,
                        ),
                        FilterToggleChip(
                          label: AppStrings.jobBoardUrgentOnlyChip,
                          selected: urgentOnly,
                          onTap: () => ref
                              .read(urgentOnlyJobsProvider.notifier)
                              .state = !urgentOnly,
                        ),
                      ],
                      activeFilterChips: activeChips,
                      onClearAll: activeChips.isEmpty ? null : clearAllFilters,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (eligible.isEmpty)
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                      child: Center(
                        child: Text(AppStrings.dashboardNoJobsFound,
                            style: theme.textTheme.bodyMedium
                                ?.copyWith(color: theme.hintColor)),
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
                          child: Transform.translate(
                              offset: Offset(0, (1 - t) * 12), child: child),
                        ),
                        child: JobCard(
                          job: j,
                          onAccept: () {
                            ref.read(jobsStateProvider.notifier).state = [
                              for (final job in ref.read(jobsStateProvider))
                                if (job.id == j.id)
                                  job.copyWith(
                                      status: AppStrings
                                          .dashboardInterestReceived)
                                else
                                  job,
                            ];
                            ref.read(workerInterestsProvider.notifier).state = [
                              ...ref.read(workerInterestsProvider),
                              WorkerInterest(
                                  workerId: worker.id,
                                  jobId: j.id,
                                  createdAt: DateTime.now()),
                            ];
                          },
                          onViewDetails: () => _showJobDetails(j),
                        ),
                      );
                    }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _monthlyIncome(DateTime now) {
    return bookings.where((b) {
      if (b.status != "Completed") return false;
      final d = DateTime.tryParse(b.date);
      return d != null && d.year == now.year && d.month == now.month;
    }).fold(0, (sum, b) => sum + b.totalMmk);
  }
}

/// Worker Home header: TOLY MOLY logo + greeting at the top-left with
/// notification actions on the right.
class _WorkerHomeHeader extends ConsumerWidget {
  const _WorkerHomeHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final name = ref.watch(_workerNameProvider).name;
    return Container(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.lg),
      decoration: const BoxDecoration(
        color: AppColors.purple700,
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(AppRadius.xl),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Image.asset("assets/logo_circle.png", width: 40, height: 40),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  AppStrings.workerHomeGreeting,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.onBrand.withValues(alpha: 0.85),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  name ?? AppStrings.workerHomeGreeting,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: AppColors.onBrand,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const _NotificationBell(
            iconColor: AppColors.onBrand,
            badgeBorderColor: AppColors.purple700,
          ),
        ],
      ),
    );
  }
}

/// Bell icon with an unread badge that reflects [notificationProvider]. Tapping
/// opens the notification history and marks everything read (clearing the
/// badge).
class _NotificationBell extends ConsumerWidget {
  final Color iconColor;
  final Color badgeBorderColor;

  const _NotificationBell({
    this.iconColor = AppColors.purple700,
    this.badgeBorderColor = AppColors.lightSurface,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(notificationProvider.select((s) => s.unreadCount));
    return Semantics(
      label: unread > 0
          ? "$unread ${AppStrings.homeNotificationsEmpty}"
          : AppStrings.homeNotificationsEmpty,
      button: true,
      child: IconButton(
        tooltip: AppStrings.homeNotificationsEmpty,
        onPressed: () => _showNotificationsSheet(context, ref),
        icon: Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(Icons.notifications_outlined, color: iconColor),
            if (unread > 0)
              Positioned(
                right: -3,
                top: -3,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  constraints:
                      const BoxConstraints(minWidth: 16, minHeight: 16),
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    shape: BoxShape.circle,
                    border: Border.all(color: badgeBorderColor, width: 1.5),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    unread > 9 ? '9+' : '$unread',
                    style: const TextStyle(
                      color: AppColors.onBrand,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      height: 1,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

void _showNotificationsSheet(BuildContext context, WidgetRef ref) {
  final items = ref.read(notificationProvider).items;
  // Opening the sheet counts as "seen" → clear the badge.
  ref.read(notificationProvider.notifier).markAllRead();

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).cardColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
    ),
    builder: (ctx) {
      final theme = Theme.of(ctx);
      return DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (ctx, controller) => Column(
          children: [
            const SizedBox(height: AppSpacing.sm),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.dividerColor,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  const Icon(Icons.notifications_active_outlined,
                      color: AppColors.purple700),
                  const SizedBox(width: AppSpacing.sm),
                  Text(AppStrings.homeNotificationsEmpty,
                      style: theme.textTheme.titleLarge),
                ],
              ),
            ),
            Expanded(
              child: items.isEmpty
                  ? Center(
                      child: Text(
                        AppStrings.homeNotificationsEmpty,
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: theme.hintColor),
                      ),
                    )
                  : ListView.separated(
                      controller: controller,
                      padding: const EdgeInsets.fromLTRB(
                          AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xxl),
                      itemCount: items.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (ctx, i) =>
                          _NotificationTile(item: items[i]),
                    ),
            ),
          ],
        ),
      );
    },
  );
}

class _NotificationTile extends StatelessWidget {
  final AppNotification item;
  const _NotificationTile({required this.item});

  String _time(DateTime d) =>
      "${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}";

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ModernServiceCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ModernIconBox(icon: Icons.account_balance_wallet_outlined),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                    Text(_time(item.timestamp),
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: theme.hintColor)),
                  ],
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(item.body,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.hintColor)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

const List<String> _townships = ["လှိုင်", "ကမာရွတ်", "မရမ်းကုန်း", "အင်းစိန်"];

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final Color cardBackground;
  final Color valueColor;
  final Color labelColor;
  final String value;
  final String unit;
  final String label;
  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.cardBackground,
    required this.valueColor,
    required this.labelColor,
    required this.value,
    required this.unit,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ModernServiceCard(
      backgroundColor: cardBackground,
      borderColor: cardBackground == AppColors.purple700
          ? Colors.transparent
          : AppColors.blue500.withValues(alpha: 0.55),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ModernIconBox(
            icon: icon,
            color: iconColor,
            backgroundColor: iconBackground,
            borderColor: iconBackground == AppColors.purple700
                ? Colors.transparent
                : AppColors.purple700.withValues(alpha: 0.08),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: Text(value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.headlineSmall
                        ?.copyWith(color: valueColor, fontSize: 24)),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(unit,
                  style: theme.textTheme.bodySmall?.copyWith(
                      color: labelColor, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(color: labelColor)),
        ],
      ),
    );
  }
}
