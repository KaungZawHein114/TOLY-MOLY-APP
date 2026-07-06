import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_strings.dart';
import '../../core/routing/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/chatbot_fab.dart';
import '../rewards/rewards_screen.dart';
import 'activity_placeholder_screen.dart';
import 'dashboard_screen.dart';
import 'tasker_profile_screen.dart';

/// Which bottom-nav tab is active — local state, mirrors CustomerHomeShell.
final workerTabIndexProvider = StateProvider<int>((ref) => 0);

/// Bottom-nav shell for the WORKER flow only.
///
/// This 5-tab structure (Home / Jobs / Pending / Rewards / Profile) and the
/// Rewards & Gamification screen are STRICTLY worker-side. The Employer/Client
/// experience lives in CustomerHomeShell, which keeps its own 4-tab
/// NavigationBar and must NOT gain this tab set.
///
///   0 → Home     (WorkerDashboardScreen — the job board lives here)
///   1 → Jobs     (ActivityScreen — the worker's job activity + bookings)
///   2 → Pending  (interim placeholder — no dedicated worker screen yet)
///   3 → Rewards  (RewardsScreen — gamification, worker only)
///   4 → Profile  (TaskerProfileScreen)
class WorkerHomeShell extends ConsumerWidget {
  const WorkerHomeShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(workerTabIndexProvider);
    return Scaffold(
      // Floating AI assistant — only on the Home tab.
      floatingActionButton: index == 0
          ? ChatbotFab(onTap: () => context.push('${Routes.chatbot}?role=tasker'))
          : null,
      body: IndexedStack(
        index: index,
        children: const [
          WorkerDashboardScreen(), // 0 — Home
          ActivityScreen(),        // 1 — Jobs
          _PendingPlaceholder(),   // 2 — Pending (interim)
          RewardsScreen(),         // 3 — Rewards
          TaskerProfileScreen(),   // 4 — Profile
        ],
      ),
      // 5 items → type MUST be fixed so the bar inherits our theme colors
      // instead of falling back to the shifting animation.
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: index,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.purple700,
        unselectedItemColor: AppColors.textSecondary,
        backgroundColor: AppColors.lightSurface,
        onTap: (i) => ref.read(workerTabIndexProvider.notifier).state = i,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: AppStrings.homeTabLabel,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.work_outline),
            activeIcon: Icon(Icons.work),
            label: AppStrings.jobsTabLabel,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.pending_actions_outlined),
            activeIcon: Icon(Icons.pending_actions),
            label: AppStrings.pendingTabLabel,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.star_border),
            activeIcon: Icon(Icons.star),
            label: AppStrings.rewardsTabLabel,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: AppStrings.profileTabLabel,
          ),
        ],
      ),
    );
  }
}

/// Interim placeholder for the worker "Pending" tab until a dedicated screen
/// exists. Kept intentionally minimal and theme-driven so it can be swapped
/// for the real screen without touching the shell wiring above.
class _PendingPlaceholder extends StatelessWidget {
  const _PendingPlaceholder();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.pending_actions_outlined,
                  size: 48,
                  color: AppColors.purple500,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  AppStrings.comingSoonTitle,
                  style: theme.textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  AppStrings.comingSoonMessage,
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
