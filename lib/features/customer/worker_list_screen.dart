import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/agent/agent_session.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/task_posting_strings.dart';
import '../../core/data/demo_data.dart';
import '../../core/routing/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/demo_card.dart';
import '../../core/widgets/mascot/mascot_state.dart';
import '../../core/widgets/mascot/pho_wa_yoke.dart';
import 'task_posting/task_posting_models.dart' show WorkerTier, WorkerTierInfo;
import 'widgets/tasker_shortlist_sheet.dart';
import 'widgets/worker_filter_bar.dart';

/// Sort options. [recommended] is the MVP Matching Score formula (trust 40% +
/// rating 30% + distance 20% + completion 10%) and is the default; picking
/// any other option overrides it, per the spec's "Sorting Logic" section.
enum WorkerSort { recommended, distance, rating, tier, completedTasks }

const List<String> _townships = ["လှိုင်", "ကမာရွတ်", "မရမ်းကုန်း", "အင်းစိန်"];
const List<double> _ratingTiers = [4.0, 4.5, 4.8];

// LOCAL UI STATE (Riverpod) — declared in this screen file, not a shared file.
final workerSortProvider =
    StateProvider<WorkerSort>((ref) => WorkerSort.recommended);
final availableOnlyProvider = StateProvider<bool>((ref) => false);
final trustFilterProvider = StateProvider<WorkerTier?>((ref) => null);
final ratingFilterProvider = StateProvider<double?>((ref) => null);
final townshipFilterProvider = StateProvider<String?>((ref) => null);

double _matchingScore(Worker w) {
  final trustScore = w.currentTier / 7 * 100;
  final ratingScore = w.rating / 5 * 100;
  final distanceScore = (100 - w.distanceMiles * 1.609 * 10).clamp(0, 100);
  final completionScore = (w.completedTasks / 2).clamp(0, 100);
  return trustScore * 0.4 +
      ratingScore * 0.3 +
      distanceScore * 0.2 +
      completionScore * 0.1;
}

String _sortLabel(WorkerSort sort) {
  switch (sort) {
    case WorkerSort.recommended:
      return "Recommended";
    case WorkerSort.distance:
      return AppStrings.exploreSortNearest;
    case WorkerSort.rating:
      return AppStrings.exploreSortTopRated;
    case WorkerSort.tier:
      return AppStrings.exploreSortTrustTier;
    case WorkerSort.completedTasks:
      return AppStrings.exploreSortMostCompleted;
  }
}

class WorkerListScreen extends ConsumerStatefulWidget {
  final String? initialSkill;
  const WorkerListScreen({super.key, this.initialSkill});

  @override
  ConsumerState<WorkerListScreen> createState() => _WorkerListScreenState();
}

class _WorkerListScreenState extends ConsumerState<WorkerListScreen> {
  // Local field, seeded synchronously from the route param (no async).
  late String? _skill = widget.initialSkill;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _clearAllFilters() {
    setState(() => _skill = null);
    ref.read(availableOnlyProvider.notifier).state = false;
    ref.read(trustFilterProvider.notifier).state = null;
    ref.read(ratingFilterProvider.notifier).state = null;
    ref.read(townshipFilterProvider.notifier).state = null;
  }

  // Tasker-Finding mode (spec §4.3): hand the CURRENTLY filtered list to
  // Pho Wa Yoke as candidates. The agent ranks + explains (LLM or offline
  // fallback), the user picks one, and we open that tasker's profile — a
  // prepare-and-confirm step, never an auto-selection.
  Future<void> _openAiShortlist(List<Worker> candidates) async {
    if (candidates.isEmpty) return;
    ref.read(agentModeProvider.notifier).state = AgentMode.taskerFinding;
    ref.read(agentSessionProvider.notifier).state = AgentSession.active;

    final township = ref.read(townshipFilterProvider);
    final task = <String, dynamic>{
      'category': _skill ?? '',
      if (township != null) 'township': township,
      'urgent': false,
    };

    final pickedId = await showTaskerShortlist(
      context,
      task: task,
      candidates: candidates,
    );
    if (!mounted || pickedId == null) return;
    context.push('${Routes.workerProfile}/$pickedId');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sort = ref.watch(workerSortProvider);
    final availableOnly = ref.watch(availableOnlyProvider);
    final trustFilter = ref.watch(trustFilterProvider);
    final ratingFilter = ref.watch(ratingFilterProvider);
    final townshipFilter = ref.watch(townshipFilterProvider);

    // Fail-safe source list.
    final source = workers.isNotEmpty ? workers : fallbackWorkers;

    // Distinct skills for the category dropdown — derived from data, not hardcoded.
    final skills = <String>{for (final w in source) w.skill}.toList()..sort();

    final query = _searchQuery.trim().toLowerCase();

    // Apply filters.
    var list = source.where((w) {
      if (_skill != null && w.skill != _skill) return false;
      if (availableOnly && !w.isAvailableNow) return false;
      // Trust filter is a minimum tier — picking "Tier N" shows tier N and up
      // (with 7 tiers, exact-match would leave most selections empty).
      if (trustFilter != null && w.currentTier < trustFilter.number) {
        return false;
      }
      if (ratingFilter != null && w.rating < ratingFilter) return false;
      if (townshipFilter != null && w.township != townshipFilter) return false;
      if (query.isNotEmpty &&
          !w.name.toLowerCase().contains(query) &&
          !w.skill.toLowerCase().contains(query)) {
        return false;
      }
      return true;
    }).toList();

    // Apply sort — `recommended` is the default Matching Score ranking;
    // any other choice overrides it.
    switch (sort) {
      case WorkerSort.recommended:
        list.sort((a, b) => _matchingScore(b).compareTo(_matchingScore(a)));
        break;
      case WorkerSort.distance:
        list.sort((a, b) => a.distanceMiles.compareTo(b.distanceMiles));
        break;
      case WorkerSort.rating:
        list.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case WorkerSort.tier:
        list.sort((a, b) => b.currentTier.compareTo(a.currentTier));
        break;
      case WorkerSort.completedTasks:
        list.sort((a, b) => b.completedTasks.compareTo(a.completedTasks));
        break;
    }

    final activeChips = <Widget>[
      if (_skill != null)
        ActiveFilterChip(label: _skill!, onRemove: () => setState(() => _skill = null)),
      if (trustFilter != null)
        ActiveFilterChip(
          label: trustFilter.label,
          onRemove: () => ref.read(trustFilterProvider.notifier).state = null,
        ),
      if (availableOnly)
        ActiveFilterChip(
          label: AppStrings.exploreAvailableNow,
          onRemove: () => ref.read(availableOnlyProvider.notifier).state = false,
        ),
      if (ratingFilter != null)
        ActiveFilterChip(
          label: "$ratingFilter+",
          onRemove: () => ref.read(ratingFilterProvider.notifier).state = null,
        ),
      if (townshipFilter != null)
        ActiveFilterChip(
          label: townshipFilter,
          onRemove: () => ref.read(townshipFilterProvider.notifier).state = null,
        ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(_skill ?? AppStrings.exploreAllWorkers),
        actions: [
          Semantics(
            label: "ချက်တင်",
            button: true,
            child: IconButton(
              icon: const Icon(Icons.chat_bubble_outline),
              onPressed: () => context.push(Routes.chatbot),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.md),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _searchQuery = v),
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: AppStrings.exploreSearchHint,
                prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                suffixIcon: _searchQuery.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close, color: AppColors.textSecondary),
                        onPressed: () => setState(() {
                          _searchController.clear();
                          _searchQuery = '';
                        }),
                      ),
                filled: true,
                fillColor: theme.cardColor,
                contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  borderSide: const BorderSide(color: AppColors.onboardingDivider),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  borderSide: const BorderSide(color: AppColors.onboardingDivider),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  borderSide: const BorderSide(color: AppColors.purple700, width: 2),
                ),
              ),
            ),
          ),
          WorkerFilterBar(
            dropdowns: [
              FilterDropdown<String?>(
                semanticLabel: AppStrings.exploreFilterCategory,
                displayText: _skill ?? AppStrings.exploreAllCategories,
                isActive: _skill != null,
                options: [
                  FilterOption(value: null, label: AppStrings.exploreAllCategories),
                  for (final s in skills) FilterOption(value: s, label: s),
                ],
                onSelected: (v) => setState(() => _skill = v),
              ),
              FilterDropdown<WorkerTier?>(
                semanticLabel: AppStrings.exploreFilterTrustLevel,
                displayText: trustFilter?.label ?? AppStrings.exploreFilterTrustLevel,
                isActive: trustFilter != null,
                options: [
                  FilterOption(value: null, label: "All ${AppStrings.exploreFilterTrustLevel}"),
                  for (final tier in WorkerTier.values)
                    FilterOption(value: tier, label: tier.label),
                ],
                onSelected: (v) => ref.read(trustFilterProvider.notifier).state = v,
              ),
              FilterDropdown<WorkerSort>(
                semanticLabel: AppStrings.exploreFilterSort,
                displayText: _sortLabel(sort),
                isActive: sort != WorkerSort.recommended,
                options: [
                  for (final s in WorkerSort.values) FilterOption(value: s, label: _sortLabel(s)),
                ],
                onSelected: (v) => ref.read(workerSortProvider.notifier).state = v,
              ),
              FilterDropdown<bool>(
                semanticLabel: AppStrings.exploreFilterAvailability,
                displayText:
                    availableOnly ? AppStrings.exploreAvailableNow : AppStrings.exploreFilterAvailability,
                isActive: availableOnly,
                options: [
                  FilterOption(value: false, label: AppStrings.exploreAllWorkersOption),
                  FilterOption(value: true, label: AppStrings.exploreAvailableNow),
                ],
                onSelected: (v) => ref.read(availableOnlyProvider.notifier).state = v,
              ),
              FilterDropdown<double?>(
                semanticLabel: AppStrings.exploreFilterRating,
                displayText: ratingFilter == null
                    ? AppStrings.exploreFilterRating
                    : "$ratingFilter+",
                isActive: ratingFilter != null,
                options: [
                  FilterOption(value: null, label: "All ${AppStrings.exploreFilterRating}"),
                  for (final r in _ratingTiers) FilterOption(value: r, label: "$r+"),
                ],
                onSelected: (v) => ref.read(ratingFilterProvider.notifier).state = v,
              ),
              FilterDropdown<String?>(
                semanticLabel: AppStrings.exploreFilterTownship,
                displayText: townshipFilter ?? AppStrings.exploreFilterTownship,
                isActive: townshipFilter != null,
                options: [
                  FilterOption(value: null, label: "All ${AppStrings.exploreFilterTownship}"),
                  for (final t in _townships) FilterOption(value: t, label: t),
                ],
                onSelected: (v) => ref.read(townshipFilterProvider.notifier).state = v,
              ),
            ],
            activeFilterChips: activeChips,
            onClearAll: activeChips.isEmpty ? null : _clearAllFilters,
          ),
          if (list.isNotEmpty)
            _AiMatchBanner(onTap: () => _openAiShortlist(list)),
          Expanded(
            child: list.isEmpty
                ? _EmptyState(onReset: _clearAllFilters)
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.lg,
                        AppSpacing.xs, AppSpacing.lg, AppSpacing.xxl),
                    itemCount: list.length,
                    itemBuilder: (context, i) => WorkerCard(
                      worker: list[i],
                      onTap: () =>
                          context.push('${Routes.workerProfile}/${list[i].id}'),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

/// Indigo (AI-accent) CTA that launches the Tasker-Finding shortlist. Sits
/// above the manual list so both the manual browse and the AI shortcut are
/// always one tap away.
class _AiMatchBanner extends StatelessWidget {
  final VoidCallback onTap;
  const _AiMatchBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final radius = BorderRadius.circular(AppRadius.lg);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.xs, AppSpacing.lg, AppSpacing.sm),
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: Ink(
            decoration: BoxDecoration(
              gradient: AppColors.indigoGradient,
              borderRadius: radius,
              boxShadow: [
                BoxShadow(
                  color: AppColors.indigo700.withValues(alpha: 0.3),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  const PhoWaYoke(
                      state: PhoWaYokeState.thinking, size: 44, decorative: true),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          TaskPostingStrings.matchCtaTitle,
                          style: theme.textTheme.titleSmall
                              ?.copyWith(color: AppColors.onBrand),
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          TaskPostingStrings.matchCtaSubtitle,
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: AppColors.onBrandMuted),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.auto_awesome, color: AppColors.onBrand),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onReset;
  const _EmptyState({required this.onReset});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("🔍", style: TextStyle(fontSize: 40)),
          const SizedBox(height: AppSpacing.sm),
          Text(AppStrings.exploreNoResults),
          const SizedBox(height: AppSpacing.sm),
          TextButton(
              onPressed: onReset, child: Text(AppStrings.exploreResetFilters)),
        ],
      ),
    );
  }
}
