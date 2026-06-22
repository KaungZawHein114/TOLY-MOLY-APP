import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_strings.dart';
import '../../core/data/demo_data.dart';
import '../../core/routing/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/demo_card.dart';
import '../../core/widgets/skill_tile.dart';

/// Customer landing: category grid + nearby workers.
/// Fully data-driven — the grid and list size themselves to the demo_data
/// lists, so adding categories/workers later needs no screen changes.
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
          onPressed: () => context.go(Routes.onboardingWelcome),
        ),
        actions: [
          IconButton(
            icon: const Text("💬", style: TextStyle(fontSize: 20)),
            tooltip: "Assistant",
            onPressed: () => context.push(Routes.chatbot),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, AppSpacing.xs, AppSpacing.lg, AppSpacing.xxl),
        children: [
          _Greeting(theme: theme),
          const SizedBox(height: AppSpacing.lg),
          _SearchBar(onTap: () => context.push(Routes.workerList)),
          const SizedBox(height: AppSpacing.xl + 2),
          Text(AppStrings.categories, style: theme.textTheme.titleLarge),
          const SizedBox(height: AppSpacing.md),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: cats.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: AppSpacing.md,
              crossAxisSpacing: AppSpacing.md,
              childAspectRatio: 0.82,
            ),
            itemBuilder: (context, i) {
              final c = cats[i];
              return SkillTile(
                emoji: c.icon,
                label: c.name,
                sublabel: c.burmese,
                onTap: () {
                  final skills = categoryToSkills[c.name] ?? const [];
                  context.push(skills.isEmpty
                      ? Routes.workerList
                      : '${Routes.workerList}?skill=${skills.first}');
                },
              );
            },
          ),
          const SizedBox(height: AppSpacing.xxl),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(AppStrings.nearbyWorkers,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleLarge),
              ),
              TextButton(
                onPressed: () => context.push(Routes.workerList),
                child: const Text("See all"),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          ...nearby.map(
            (w) => WorkerCard(
              worker: w,
              onTap: () => context.push('${Routes.workerProfile}/${w.id}'),
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
        Text("Mingalaba 👋", style: theme.textTheme.headlineSmall),
        const SizedBox(height: AppSpacing.xxs),
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
      borderRadius: BorderRadius.circular(AppRadius.md),
      elevation: 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg, vertical: AppSpacing.md + 2),
          child: Row(
            children: [
              Icon(Icons.search, color: theme.hintColor),
              const SizedBox(width: AppSpacing.sm + 2),
              Expanded(
                child: Text("Search plumbers, cleaners…",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.hintColor, fontSize: 15)),
              ),
              const SizedBox(width: AppSpacing.sm),
              const Icon(Icons.tune, color: AppColors.teal),
            ],
          ),
        ),
      ),
    );
  }
}
