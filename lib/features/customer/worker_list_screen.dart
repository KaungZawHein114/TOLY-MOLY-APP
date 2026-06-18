import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/data/demo_data.dart';
import '../../core/routing/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/demo_card.dart';

enum WorkerSort { distance, rating, priceLow }

// LOCAL UI STATE (Riverpod) — declared in this screen file, not a shared file.
final workerSortProvider =
    StateProvider<WorkerSort>((ref) => WorkerSort.distance);
final availableOnlyProvider = StateProvider<bool>((ref) => false);

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

    // Fail-safe source list.
    final source = workers.isNotEmpty ? workers : fallbackWorkers;

    // Distinct skills for the filter chips — derived from data, not hardcoded.
    final skills = <String>{for (final w in source) w.skill}.toList()..sort();

    // Apply filters.
    var list = source.where((w) {
      if (_skill != null && w.skill != _skill) return false;
      if (availableOnly && !w.isAvailableNow) return false;
      return true;
    }).toList();

    // Apply sort.
    switch (sort) {
      case WorkerSort.distance:
        list.sort((a, b) => a.distanceMiles.compareTo(b.distanceMiles));
        break;
      case WorkerSort.rating:
        list.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case WorkerSort.priceLow:
        list.sort((a, b) => a.hourlyRateMmk.compareTo(b.hourlyRateMmk));
        break;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_skill ?? "All Workers"),
        actions: [
          IconButton(
            icon: const Text("💬", style: TextStyle(fontSize: 20)),
            onPressed: () => context.push(Routes.chatbot),
          ),
        ],
      ),
      body: Column(
        children: [
          // Skill filter chips
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
          // Sort + availability row
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg, vertical: AppSpacing.xs + 2),
            child: Row(
              children: [
                Icon(Icons.sort, size: 18, color: theme.hintColor),
                const SizedBox(width: AppSpacing.xs + 2),
                DropdownButton<WorkerSort>(
                  value: sort,
                  underline: const SizedBox.shrink(),
                  onChanged: (v) {
                    if (v != null) {
                      ref.read(workerSortProvider.notifier).state = v;
                    }
                  },
                  items: const [
                    DropdownMenuItem(
                        value: WorkerSort.distance, child: Text("Nearest")),
                    DropdownMenuItem(
                        value: WorkerSort.rating, child: Text("Top rated")),
                    DropdownMenuItem(
                        value: WorkerSort.priceLow,
                        child: Text("Lowest price")),
                  ],
                ),
                const Spacer(),
                const Text("Available now"),
                Switch(
                  value: availableOnly,
                  activeColor: AppColors.teal,
                  onChanged: (v) =>
                      ref.read(availableOnlyProvider.notifier).state = v,
                ),
              ],
            ),
          ),
          Expanded(
            child: list.isEmpty
                ? _EmptyState(onReset: () {
                    setState(() => _skill = null);
                    ref.read(availableOnlyProvider.notifier).state = false;
                  })
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.md,
                        AppSpacing.xs, AppSpacing.md, AppSpacing.xxl),
                    itemCount: list.length,
                    itemBuilder: (context, i) => WorkerCard(
                      worker: list[i],
                      onTap: () => context
                          .push('${Routes.workerProfile}/${list[i].id}'),
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
  const _Chip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.sm),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: AppColors.teal,
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
          const Text("No workers match these filters"),
          const SizedBox(height: AppSpacing.sm),
          TextButton(onPressed: onReset, child: const Text("Reset filters")),
        ],
      ),
    );
  }
}
