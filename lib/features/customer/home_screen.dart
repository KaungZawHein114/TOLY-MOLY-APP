import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_strings.dart';
import '../../core/data/demo_data.dart';
import '../../core/routing/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/demo_card.dart';
import '../../core/widgets/modern_service_card.dart';
import '../profile/data/profile_repository.dart';
import '../profile/data/profile_repository_impl.dart';
import 'widgets/category_section.dart';

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
                        onTap: () => context.push(Routes.postTask),
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

            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),

            // ── App guide entry ────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: _HowToUseAppCard(
                  onTap: () => context.push(Routes.clientGuide),
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
                height: 240,
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
        ],
      ),
    );
  }
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
    final cardBackground =
        widget.filled ? AppColors.purple700 : AppColors.blue500;
    final titleColor = widget.filled ? AppColors.onBrand : AppColors.textPrimary;
    final subtitleColor =
        widget.filled ? AppColors.onBrandMuted : AppColors.textSecondary;
    final iconBackground =
        widget.filled ? AppColors.blue500 : AppColors.workIconSurface;
    final iconColor = AppColors.purple700;

    return AnimatedScale(
      scale: _pressed ? 0.95 : 1.0,
      duration: AppMotion.fast,
      curve: AppMotion.press,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) => setState(() => _pressed = false),
        child: ModernServiceCard(
          onTap: widget.onTap,
          backgroundColor: cardBackground,
          borderColor: widget.filled
              ? Colors.transparent
              : AppColors.blue500.withValues(alpha: 0.55),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 110),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ModernIconBox(
                  icon: widget.icon,
                  color: iconColor,
                  backgroundColor: iconBackground,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  widget.label,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: titleColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  widget.subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: subtitleColor,
                    height: 1.35,
                  ),
                ),
              ],
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

// ── App Guide Entry Card ─────────────────────────────────────

class _HowToUseAppCard extends StatelessWidget {
  final VoidCallback onTap;

  const _HowToUseAppCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ModernServiceCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      backgroundColor: AppColors.blue500,
      borderColor: AppColors.blue500.withValues(alpha: 0.55),
      onTap: onTap,
      child: Row(
        children: [
          const ModernIconBox(icon: Icons.menu_book_rounded),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ဒီ App ကို ဘယ်လိုသုံးမလဲ?',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  'အလုပ်တင်ခြင်း၊ worker ရှာခြင်း၊ booking နှင့် check-in/out အသုံးပြုနည်းများ',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          const Icon(Icons.arrow_forward_rounded,
              color: AppColors.purple700, size: 22),
        ],
      ),
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
    return AnimatedScale(
      scale: _pressed ? 0.96 : 1.0,
      duration: AppMotion.fast,
      curve: AppMotion.press,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) => setState(() => _pressed = false),
        child: SizedBox(
          width: 160,
          child: ModernServiceCard(
            onTap: widget.onTap,
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.purple100,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    color: AppColors.purple700,
                    size: AppSizes.iconLg,
                  ),
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
    return ModernServiceCard(
      onTap: onTap,
      backgroundColor: AppColors.blue500,
      borderColor: AppColors.blue500.withValues(alpha: 0.55),
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.workIconSurface,
              borderRadius: BorderRadius.circular(AppRadius.md + 2),
              border: Border.all(
                color: AppColors.purple700.withValues(alpha: 0.08),
              ),
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/img.png',
                width: 34,
                height: 34,
                fit: BoxFit.cover,
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
          const Icon(Icons.chevron_right_rounded, color: AppColors.purple700),
        ],
      ),
    );
  }
}
