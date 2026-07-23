import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_strings.dart';
import '../../core/data/demo_data.dart';
import '../../core/routing/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/demo_card.dart';
import '../profile/data/profile_repository.dart';
import '../profile/data/profile_repository_impl.dart';
import '../worker/task_execution_state.dart';
import 'widgets/category_section.dart';
import 'widgets/checkin_confirmation_card.dart';

// ============================================================================
// ACCOUNT NAME — backend-connected (`GET /api/profile/`), screen-local per
// CLAUDE.md's Riverpod convention. First frame never blocks on the network:
// the header falls back to [AppStrings.homeDemoClientName] until this loads
// (or if the request fails), same pattern as the profile screens' loading
// state.
// ============================================================================

class _HomeNameState {
  final bool loading;
  final String? name;
  const _HomeNameState({this.loading = true, this.name});
}

class _HomeNameNotifier extends StateNotifier<_HomeNameState> {
  final ProfileRepository _repo;
  _HomeNameNotifier(this._repo) : super(const _HomeNameState()) {
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await _repo.getProfile();
      state = _HomeNameState(loading: false, name: data.name);
    } catch (_) {
      state = const _HomeNameState(loading: false);
    }
  }
}

final _homeNameProvider =
    StateNotifierProvider.autoDispose<_HomeNameNotifier, _HomeNameState>(
  (ref) => _HomeNameNotifier(ProfileRepositoryImpl()),
);

/// Customer landing screen — a clean local-service marketplace dashboard.
///
/// Layout (top to bottom):
///   1. Header   — greeting, logo, notification bell
///   2. Actions  — Post a Task | Find Workers (two balanced action cards)
///   3. Categories — scrollable category grid with live search
///   4. Recommended Workers — top 3 workers from demo_data
///   5. AI Helper — small optional card, not the main hero
class CustomerHomeScreen extends StatelessWidget {
  const CustomerHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cats = categories.isNotEmpty ? categories : fallbackCategories;
    // Top-rated, available-first workers for the recommendations strip.
    final recommended = [...workers]..sort((a, b) {
        if (a.isAvailableNow != b.isAvailableNow) {
          return a.isAvailableNow ? -1 : 1;
        }
        return b.rating.compareTo(a.rating);
      });
    final top = recommended.take(4).toList();

    return Scaffold(
      backgroundColor: AppColors.lightBg,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── Gradient hero header ────────────────────────────────────────
            SliverToBoxAdapter(child: _HeroHeader()),

            // ── Action cards ────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
                child: Row(
                  children: [
                    Expanded(
                      child: _ActionCard(
                        label: AppStrings.homePostTaskAction,
                        subtitle: AppStrings.homePostTaskSubtitle,
                        icon: Icons.edit_note_rounded,
                        filled: true,
                        onTap: () => context.push(Routes.aiTaskPosting),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: _ActionCard(
                        label: AppStrings.homeFindWorkerAction,
                        subtitle: AppStrings.homeFindWorkerSubtitle,
                        icon: Icons.people_alt_rounded,
                        filled: false,
                        onTap: () => context.push(Routes.workerList),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Popular Categories ───────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: CategorySection(
                  categories: cats,
                  onCategoryTap: (c) {
                    final skills = categoryToSkills[c.name] ?? const [];
                    context.push(skills.isEmpty
                        ? Routes.workerList
                        : '${Routes.workerList}?skill=${skills.first}');
                  },
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),

            // ── Recommended Workers ─────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: _SectionHeader(
                  title: AppStrings.homeRecommendedTitle,
                  subtitle: AppStrings.homeRecommendedSubtitle,
                  onSeeAll: () => context.push(Routes.workerList),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 220,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  itemCount: top.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(width: AppSpacing.md),
                  itemBuilder: (context, i) => _WorkerPreviewCard(
                    worker: top[i],
                    onTap: () =>
                        context.push('${Routes.workerProfile}/${top[i].id}'),
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),

            // ── AI Helper card (small, secondary) ───────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: _AiHelperCard(
                  onTap: () => context.push('${Routes.chatbot}?role=client'),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxxl)),
          ],
        ),
      ),
    );
  }
}

// ── Header ──────────────────────────────────────────────────────────────────

class _HeroHeader extends ConsumerWidget {
  const _HeroHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final accountName =
        ref.watch(_homeNameProvider).name ?? AppStrings.homeDemoClientName;
    final activeBooking =
        bookings.where((b) => b.status == 'Active').firstOrNull;
    final execution = activeBooking == null
        ? null
        : executionFor(ref.watch(taskExecutionProvider), activeBooking.id);
    final needsClientAction =
        execution?.status == ExecutionStatus.waitingCheckinConfirm ||
            execution?.status == ExecutionStatus.waitingCheckoutConfirm;

    return Container(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.lg),
      decoration: const BoxDecoration(
        color: AppColors.purple700,
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(AppRadius.xl),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Single row: logo + greeting/name + notification bell.
          Row(
            children: [
              Image.asset('assets/logo_circle.png', width: 40, height: 40),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      AppStrings.homeGreeting,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.onBrand.withValues(alpha: 0.85),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      accountName,
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
              _TaskConfirmationIconButton(
                hasPendingAction: needsClientAction,
                onTap: () => _showTaskConfirmationSheet(
                  context,
                  activeBooking: activeBooking,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Semantics(
                label: AppStrings.homeNotificationsEmpty,
                button: true,
                child: IconButton(
                  icon: const Icon(Icons.notifications_outlined,
                      color: AppColors.onBrand),
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(AppStrings.homeNotificationsEmpty)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          // Tagline chip
          IntrinsicWidth(
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md, vertical: AppSpacing.xs),
              decoration: BoxDecoration(
                color: AppColors.onBrand.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.place_outlined,
                      size: 14, color: AppColors.onBrand),
                  const SizedBox(width: AppSpacing.xs),
                  Flexible(
                    child: Text(
                      'ရန်ကုန် • အိမ်ဝန်ဆောင်မှုများ',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.onBrand,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showTaskConfirmationSheet(
    BuildContext context, {
    required Booking? activeBooking,
  }) {
    final dashboardContext = context;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: AppColors.lightSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (sheetContext) {
        final bottomInset = MediaQuery.of(sheetContext).viewInsets.bottom;
        return SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.lg + bottomInset,
            ),
            child: activeBooking == null
                ? const _NoActiveTaskSheet()
                : _TaskConfirmationSheetBody(
                    booking: activeBooking,
                    dashboardContext: dashboardContext,
                  ),
          ),
        );
      },
    );
  }
}

class _TaskConfirmationIconButton extends StatelessWidget {
  final bool hasPendingAction;
  final VoidCallback onTap;

  const _TaskConfirmationIconButton({
    required this.hasPendingAction,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final iconButton = IconButton(
      tooltip: 'Check-in / Check-out',
      icon: const Icon(Icons.fact_check_outlined, color: AppColors.onBrand),
      onPressed: onTap,
    );

    return Semantics(
      label: hasPendingAction
          ? 'Check-in / Check-out အတည်ပြုရန်ရှိသည်'
          : 'Check-in / Check-out demo',
      button: true,
      child: hasPendingAction
          ? Stack(
              clipBehavior: Clip.none,
              children: [
                iconButton,
                Positioned(
                  top: AppSpacing.sm,
                  right: AppSpacing.sm,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: AppColors.warning,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.purple700, width: 2),
                    ),
                  ),
                ),
              ],
            )
          : iconButton,
    );
  }
}

class _TaskConfirmationSheetBody extends ConsumerWidget {
  final Booking booking;
  final BuildContext dashboardContext;

  const _TaskConfirmationSheetBody({
    required this.booking,
    required this.dashboardContext,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final execution =
        executionFor(ref.watch(taskExecutionProvider), booking.id);

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _TaskSheetHeader(booking: booking),
          const SizedBox(height: AppSpacing.lg),
          switch (execution.status) {
            ExecutionStatus.waitingCheckinConfirm => CheckinConfirmationCard(
                workerName: booking.workerName,
                onAccept: () => _confirmCheckin(context, ref, booking.id),
                onReject: () => _rejectCheckin(context, ref, booking.id),
              ),
            ExecutionStatus.waitingCheckoutConfirm => CheckoutConfirmationCard(
                workerName: booking.workerName,
                onConfirm: () => _confirmCheckout(context, ref, booking.id),
                onReport: () => _reportCheckoutIssue(context, ref, booking.id),
              ),
            _ => _DemoTaskConfirmationControls(booking: booking),
          },
        ],
      ),
    );
  }

  void _confirmCheckin(BuildContext context, WidgetRef ref, int taskId) {
    final all = ref.read(taskExecutionProvider);
    final current = executionFor(all, taskId);
    ref.read(taskExecutionProvider.notifier).state = {
      ...all,
      taskId: current.copyWith(
        status: ExecutionStatus.inProgress,
        clientCheckinConfirmedAt: DateTime.now(),
      ),
    };
    Navigator.of(context).pop();
    _showDemoSnack(dashboardContext, 'ရောက်ရှိကြောင်း အတည်ပြုပြီးပါပြီ။');
  }

  void _rejectCheckin(BuildContext context, WidgetRef ref, int taskId) {
    final all = ref.read(taskExecutionProvider);
    final current = executionFor(all, taskId);
    ref.read(taskExecutionProvider.notifier).state = {
      ...all,
      taskId: current.copyWith(status: ExecutionStatus.arrivalDisputed),
    };
    Navigator.of(context).pop();
    _showDemoSnack(dashboardContext, 'မရောက်သေးကြောင်း မှတ်သားထားပါပြီ။');
  }

  void _confirmCheckout(BuildContext context, WidgetRef ref, int taskId) {
    final all = ref.read(taskExecutionProvider);
    final current = executionFor(all, taskId);
    ref.read(taskExecutionProvider.notifier).state = {
      ...all,
      taskId: current.copyWith(
        status: ExecutionStatus.completed,
        clientCheckoutConfirmedAt: DateTime.now(),
      ),
    };
    Navigator.of(context).pop();
    _showDemoSnack(dashboardContext, 'အလုပ်ပြီးဆုံးကြောင်း အတည်ပြုပြီးပါပြီ။');
  }

  void _reportCheckoutIssue(BuildContext context, WidgetRef ref, int taskId) {
    final all = ref.read(taskExecutionProvider);
    final current = executionFor(all, taskId);
    ref.read(taskExecutionProvider.notifier).state = {
      ...all,
      taskId: current.copyWith(status: ExecutionStatus.completionDisputed),
    };
    Navigator.of(context).pop();
    _showDemoSnack(dashboardContext, 'ပြဿနာရှိကြောင်း မှတ်သားထားပါပြီ။');
  }
}

class _TaskSheetHeader extends StatelessWidget {
  final Booking booking;

  const _TaskSheetHeader({required this.booking});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.purple100,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: const Icon(
            Icons.engineering_outlined,
            color: AppColors.purple700,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                booking.workerName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                '${booking.skill} • ${booking.date} • ${booking.timeSlot}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DemoTaskConfirmationControls extends ConsumerWidget {
  final Booking booking;

  const _DemoTaskConfirmationControls({required this.booking});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.blue100,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.blue300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Demo အတွက် စမ်းသပ်ရန်',
            style: theme.textTheme.titleMedium?.copyWith(
              color: AppColors.indigo700,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Backend မရှိသေးလို့ worker ဘက်က check-in / check-out လုပ်သလို ဒီနေရာကနေ စမ်းနိုင်ပါတယ်။',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          FilledButton.icon(
            onPressed: () => _simulate(
              ref,
              status: ExecutionStatus.waitingCheckinConfirm,
              checkin: true,
            ),
            icon: const Icon(Icons.location_on_rounded),
            label: const Text('Worker check-in စမ်းမည်'),
          ),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton.icon(
            onPressed: () => _simulate(
              ref,
              status: ExecutionStatus.waitingCheckoutConfirm,
              checkout: true,
            ),
            icon: const Icon(Icons.task_alt_rounded),
            label: const Text('Worker check-out စမ်းမည်'),
          ),
        ],
      ),
    );
  }

  void _simulate(
    WidgetRef ref, {
    required ExecutionStatus status,
    bool checkin = false,
    bool checkout = false,
  }) {
    final now = DateTime.now();
    final all = ref.read(taskExecutionProvider);
    final current = executionFor(all, booking.id);
    ref.read(taskExecutionProvider.notifier).state = {
      ...all,
      booking.id: current.copyWith(
        status: status,
        checkinTime: checkin ? now : null,
        checkoutTime: checkout ? now : null,
      ),
    };
  }
}

class _NoActiveTaskSheet extends StatelessWidget {
  const _NoActiveTaskSheet();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.assignment_outlined,
            size: 48,
            color: AppColors.purple300,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'လက်ရှိ active booking မရှိသေးပါ',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Demo booking ရှိလာတဲ့အခါ check-in / check-out အတည်ပြုချက်ကို ဒီနေရာကနေ ကြည့်နိုင်ပါမယ်။',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

void _showDemoSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

// ── Action Cards ─────────────────────────────────────────────────────────────

class _ActionCard extends StatefulWidget {
  final String label;
  final String subtitle;
  final IconData icon;
  final bool filled;
  final VoidCallback onTap;

  const _ActionCard({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.filled,
    required this.onTap,
  });

  @override
  State<_ActionCard> createState() => _ActionCardState();
}

class _ActionCardState extends State<_ActionCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final radius = BorderRadius.circular(AppRadius.lg);

    final bgColor =
        widget.filled ? AppColors.purple700 : AppColors.lightSurface;
    final fgColor = widget.filled ? AppColors.onBrand : AppColors.purple700;
    final iconBg = widget.filled
        ? AppColors.onBrand.withValues(alpha: 0.18)
        : AppColors.purple100;

    return AnimatedScale(
      scale: _pressed ? 0.95 : 1.0,
      duration: AppMotion.fast,
      curve: AppMotion.press,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) => setState(() => _pressed = false),
        child: Material(
          color: bgColor,
          borderRadius: radius,
          elevation: widget.filled ? 4 : 1,
          shadowColor: widget.filled
              ? AppColors.purple700.withValues(alpha: 0.35)
              : AppColors.shadowSm,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: radius,
            child: Container(
              constraints: const BoxConstraints(minHeight: 110),
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: widget.filled
                  ? null
                  : BoxDecoration(
                      borderRadius: radius,
                      border: Border.all(
                          color: AppColors.purple700.withValues(alpha: 0.25),
                          width: 1.5),
                    ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: iconBg,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Icon(widget.icon, color: fgColor, size: 22),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    widget.label,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: fgColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    widget.subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: fgColor.withValues(alpha: 0.75),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Section Header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback? onSeeAll;

  const _SectionHeader({
    required this.title,
    required this.subtitle,
    this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        if (onSeeAll != null)
          TextButton(
            onPressed: onSeeAll,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
              minimumSize: const Size(0, 36),
            ),
            child: Text(
              AppStrings.homeSeeAll,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.purple700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }
}

// ── Worker Preview Card (horizontal scroll) ───────────────────────────────────

class _WorkerPreviewCard extends StatefulWidget {
  final Worker worker;
  final VoidCallback onTap;

  const _WorkerPreviewCard({required this.worker, required this.onTap});

  @override
  State<_WorkerPreviewCard> createState() => _WorkerPreviewCardState();
}

class _WorkerPreviewCardState extends State<_WorkerPreviewCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final w = widget.worker;
    final distanceKm = (w.distanceMiles * 1.609).toStringAsFixed(1);
    final radius = BorderRadius.circular(AppRadius.lg);

    return AnimatedScale(
      scale: _pressed ? 0.96 : 1.0,
      duration: AppMotion.fast,
      curve: AppMotion.press,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) => setState(() => _pressed = false),
        child: Container(
          width: 160,
          decoration: BoxDecoration(
            color: AppColors.lightSurface,
            borderRadius: radius,
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowMd,
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: radius,
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: widget.onTap,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar + availability dot
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: AppColors.purple100,
                          child: Text(w.emoji,
                              style: const TextStyle(fontSize: 24)),
                        ),
                        if (w.isAvailableNow)
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              width: 14,
                              height: 14,
                              decoration: BoxDecoration(
                                color: AppColors.success,
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: AppColors.lightSurface, width: 2),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      w.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      w.skill,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    // Rating row
                    Row(
                      children: [
                        const Icon(Icons.star_rounded,
                            size: 13, color: AppColors.star),
                        const SizedBox(width: 2),
                        Text(
                          w.rating.toStringAsFixed(1),
                          style: theme.textTheme.bodySmall
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Flexible(
                          child: Text(
                            '(${w.reviews})',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: AppColors.textSecondary),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    // Distance + verified
                    Row(
                      children: [
                        const Icon(Icons.location_on,
                            size: 12, color: AppColors.textSecondary),
                        const SizedBox(width: 2),
                        Flexible(
                          child: Text(
                            '$distanceKm km',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: AppColors.textSecondary),
                          ),
                        ),
                        if (w.isVerified) ...[
                          const SizedBox(width: AppSpacing.xs),
                          const Icon(Icons.verified,
                              size: 13, color: AppColors.success),
                        ],
                      ],
                    ),
                    const Spacer(),
                    // Trust badge
                    TrustBadgePill(tier: w.currentTier),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── AI Helper Card (small, secondary) ────────────────────────────────────────

class _AiHelperCard extends StatelessWidget {
  final VoidCallback onTap;

  const _AiHelperCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: AppColors.indigo100,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg, vertical: AppSpacing.md),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.indigo500.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/img.png',
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.smart_toy_outlined,
                      color: AppColors.indigo700,
                      size: 22,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.homeAiHelperTitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.indigo700,
                      ),
                    ),
                    Text(
                      AppStrings.homeAiHelperSubtitle,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: AppColors.indigo500),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.indigo700),
            ],
          ),
        ),
      ),
    );
  }
}
