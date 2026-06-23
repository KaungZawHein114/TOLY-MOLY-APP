import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_strings.dart';
import '../../core/data/demo_data.dart';
import '../../core/routing/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/demo_card.dart';
import 'task_posting/task_posting_models.dart' show WorkerTier, WorkerTierLabel;

/// Sort options. [recommended] is the MVP Matching Score formula (trust 40% +
/// rating 30% + distance 20% + completion 10%) and is the default; picking
/// any other option overrides it, per the spec's "Sorting Logic" section.
enum WorkerSort { recommended, distance, rating, tier, completedTasks }

const List<String> _townships = ["လှိုင်", "ကမာရွတ်", "မရမ်းကုန်း", "အင်းစိန်"];

// LOCAL UI STATE (Riverpod) — declared in this screen file, not a shared file.
final workerSortProvider = StateProvider<WorkerSort>((ref) => WorkerSort.recommended);
final availableOnlyProvider = StateProvider<bool>((ref) => false);
final trustFilterProvider = StateProvider<WorkerTier?>((ref) => null);
final ratingFilterProvider = StateProvider<double?>((ref) => null);
final townshipFilterProvider = StateProvider<String?>((ref) => null);

double _matchingScore(Worker w) {
  final trustScore = w.currentTier / 7 * 100;
  final ratingScore = w.rating / 5 * 100;
  final distanceScore = (100 - w.distanceMiles * 1.609 * 10).clamp(0, 100);
  final completionScore = (w.completedTasks / 2).clamp(0, 100);
  return trustScore * 0.4 + ratingScore * 0.3 + distanceScore * 0.2 + completionScore * 0.1;
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

    // Distinct skills for the filter chips — derived from data, not hardcoded.
    final skills = <String>{for (final w in source) w.skill}.toList()..sort();

    // Apply filters.
    var list = source.where((w) {
      if (_skill != null && w.skill != _skill) return false;
      if (availableOnly && !w.isAvailableNow) return false;
      if (trustFilter != null && tierBucketFor(w.currentTier) != trustFilter) return false;
      if (ratingFilter != null && w.rating < ratingFilter) return false;
      if (townshipFilter != null && w.township != townshipFilter) return false;
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

    return Scaffold(
      appBar: AppBar(
        title: Text(_skill ?? AppStrings.exploreAllWorkers),
        actions: [
          IconButton(
            icon: const Text("💬", style: TextStyle(fontSize: 20)),
            onPressed: () => context.push(Routes.chatbot),
          ),
        ],
      ),
      body: Column(
        children: [
          // Category filter chips
          SizedBox(
            height: 46,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              children: [
                _Chip(
                  label: "All",
                  selected: _skill == null,
                  onTap: () => setState(() => _skill = null),
                ),
                ...skills.map((s) => _Chip(
                      label: s,
                      selected: _skill == s,
                      onTap: () => setState(() => _skill = s),
                    )),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          // Trust level filter chips
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              children: [
                _Chip(
                  label: "All ${AppStrings.exploreFilterTrustLevel}",
                  selected: trustFilter == null,
                  onTap: () => ref.read(trustFilterProvider.notifier).state = null,
                ),
                for (final tier in WorkerTier.values)
                  _Chip(
                    label: tier.label,
                    selected: trustFilter == tier,
                    onTap: () => ref.read(trustFilterProvider.notifier).state = tier,
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          // Rating + township filter chips
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              children: [
                for (final r in [4.0, 4.5, 4.8])
                  _Chip(
                    label: "$r+",
                    selected: ratingFilter == r,
                    onTap: () => ref.read(ratingFilterProvider.notifier).state =
                        ratingFilter == r ? null : r,
                  ),
                const SizedBox(width: AppSpacing.sm),
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
          // Sort + availability row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs + 2),
            child: Row(
              children: [
                Icon(Icons.sort, size: 18, color: theme.hintColor),
                const SizedBox(width: AppSpacing.xs + 2),
                DropdownButton<WorkerSort>(
                  value: sort,
                  underline: const SizedBox.shrink(),
                  onChanged: (v) {
                    if (v != null) ref.read(workerSortProvider.notifier).state = v;
                  },
                  items: [
                    const DropdownMenuItem(value: WorkerSort.recommended, child: Text("Recommended")),
                    DropdownMenuItem(value: WorkerSort.distance, child: Text(AppStrings.exploreSortNearest)),
                    DropdownMenuItem(value: WorkerSort.rating, child: Text(AppStrings.exploreSortTopRated)),
                    DropdownMenuItem(value: WorkerSort.tier, child: Text(AppStrings.exploreSortTrustTier)),
                    DropdownMenuItem(
                        value: WorkerSort.completedTasks, child: Text(AppStrings.exploreSortMostCompleted)),
                  ],
                ),
                const Spacer(),
                Text(AppStrings.exploreAvailableNow),
                Switch(
                  value: availableOnly,
                  activeColor: AppColors.purple700,
                  onChanged: (v) => ref.read(availableOnlyProvider.notifier).state = v,
                ),
              ],
            ),
          ),
          Expanded(
            child: list.isEmpty
                ? _EmptyState(onReset: () {
                    setState(() => _skill = null);
                    ref.read(availableOnlyProvider.notifier).state = false;
                    ref.read(trustFilterProvider.notifier).state = null;
                    ref.read(ratingFilterProvider.notifier).state = null;
                    ref.read(townshipFilterProvider.notifier).state = null;
                  })
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(
                        AppSpacing.md, AppSpacing.xs, AppSpacing.md, AppSpacing.xxl),
                    itemCount: list.length,
                    itemBuilder: (context, i) => WorkerCard(
                      worker: list[i],
                      onTap: () => context.push('${Routes.workerProfile}/${list[i].id}'),
                    ),
                  ),
          ),
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
        labelStyle: theme.textTheme.bodyMedium?.copyWith(
          color: selected ? AppColors.onBrand : null,
          fontWeight: FontWeight.w600,
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
          TextButton(onPressed: onReset, child: Text(AppStrings.exploreResetFilters)),
        ],
      ),
    );
  }
}
