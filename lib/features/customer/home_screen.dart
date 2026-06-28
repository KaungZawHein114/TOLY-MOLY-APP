import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_strings.dart';
import '../../core/data/demo_data.dart';
import '../../core/routing/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/large_button.dart';
import '../../core/widgets/onboarding/staggered_entrance.dart';
import 'widgets/category_section.dart';

/// Customer landing (Home tab of [CustomerHomeShell]): greeting/logo/bell
/// header, two quick-action buttons, and a browse-services category grid.
/// Fully data-driven — the grid sizes itself to demo_data's category list,
/// so adding categories later needs no screen changes.
class CustomerHomeScreen extends StatelessWidget {
  const CustomerHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Fail-safe: fall back to hardcoded constants if the list is ever empty.
    final cats = categories.isNotEmpty ? categories : fallbackCategories;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xxl),
          children: [
            const _HomeHeader(),
            const SizedBox(height: AppSpacing.lg),
            StaggeredEntrance(
              children: [
                LargeButton(
                  label: AppStrings.homePostTaskAction,
                  icon: Icons.add_circle_outline,
                  gradient: AppColors.purpleGradient,
                  onTap: () => context.push(Routes.postTask),
                ),
                const SizedBox(height: AppSpacing.md),
                LargeButton(
                  label: AppStrings.homeFindWorkerAction,
                  icon: Icons.search,
                  filled: false,
                  outlineColor: AppColors.purple700,
                  onTap: () => context.push(Routes.workerList),
                ),
                const SizedBox(height: AppSpacing.xl),
                CategorySection(
                  categories: cats,
                  onCategoryTap: (c) {
                    final skills = categoryToSkills[c.name] ?? const [];
                    context.push(skills.isEmpty
                        ? Routes.workerList
                        : '${Routes.workerList}?skill=${skills.first}');
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppStrings.homeGreeting, style: theme.textTheme.headlineSmall),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                AppStrings.homeDemoClientName,
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
              ),
            ],
          ),
        ),
        Image.asset("assets/logo_circle.png", width: 36, height: 36),
        const SizedBox(width: AppSpacing.md),
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
