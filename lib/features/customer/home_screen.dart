import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/data/demo_data.dart';
import '../../core/routing/app_router.dart';
import '../../core/widgets/demo_card.dart';
import '../../core/widgets/skill_tile.dart';

/// Customer landing: category grid (10) + nearby workers (top 5).
/// All data is the const list from demo_data.dart — renders on first frame.
class CustomerHomeScreen extends StatelessWidget {
  const CustomerHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Fail-safe: fall back to hardcoded constants if a list is ever empty.
    final cats = categories.isNotEmpty ? categories : fallbackCategories;
    final all = workers.isNotEmpty ? workers : fallbackWorkers;
    final nearby = (List<Worker>.from(all)
          ..sort((a, b) => a.distanceMiles.compareTo(b.distanceMiles)))
        .take(5)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.appName),
        leading: IconButton(
          icon: const Icon(Icons.swap_horiz),
          tooltip: "Switch role",
          onPressed: () => context.go(Routes.role),
        ),
        actions: [
          IconButton(
            icon: const Text("💬", style: TextStyle(fontSize: 20)),
            tooltip: "Assistant",
            onPressed: () => context.go(Routes.chatbot),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          _Greeting(theme: theme),
          const SizedBox(height: 16),
          _SearchBar(onTap: () => context.go(Routes.workerList)),
          const SizedBox(height: 22),
          Text(AppStrings.categories,
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: cats.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.82,
            ),
            itemBuilder: (context, i) {
              final c = cats[i];
              return SkillTile(
                emoji: c.icon,
                label: c.name,
                sublabel: c.burmese,
                onTap: () {
                  final skill = (categoryToSkills[c.name] ?? const []).isNotEmpty
                      ? categoryToSkills[c.name]!.first
                      : null;
                  context.go(skill == null
                      ? Routes.workerList
                      : '${Routes.workerList}?skill=$skill');
                },
              );
            },
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(AppStrings.nearbyWorkers,
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w800)),
              TextButton(
                onPressed: () => context.go(Routes.workerList),
                child: const Text("See all"),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ...nearby.map(
            (w) => WorkerCard(
              worker: w,
              onTap: () => context.go('${Routes.workerProfile}/${w.id}'),
            ),
          ),
        ],
      ),
    );
  }
}

class _Greeting extends StatelessWidget {
  final ThemeData theme;
  const _Greeting({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Mingalaba 👋",
            style: theme.textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w900)),
        const SizedBox(height: 2),
        Text("What do you need done today?",
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor)),
      ],
    );
  }
}

class _SearchBar extends StatelessWidget {
  final VoidCallback onTap;
  const _SearchBar({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.cardColor,
      borderRadius: BorderRadius.circular(14),
      elevation: 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(Icons.search, color: theme.hintColor),
              const SizedBox(width: 10),
              Text("Search plumbers, cleaners…",
                  style: TextStyle(color: theme.hintColor, fontSize: 15)),
              const Spacer(),
              const Icon(Icons.tune, color: AppColors.teal),
            ],
          ),
        ),
      ),
    );
  }
}
