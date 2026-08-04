import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_strings.dart';
import '../../core/routing/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/chatbot_fab.dart';
import '../../core/widgets/global_push_banner.dart';
import '../safety/emergency_bottom_sheet.dart';
import '../activity/activity_overview_screen.dart';
import '../rewards/rewards_screen.dart';
import 'activity_placeholder_screen.dart';
import 'dashboard_screen.dart';
import 'notifications/money_received_toast.dart';
import 'notifications/notification_service.dart';
import 'tasker_profile_screen.dart';

/// Which bottom-nav tab is active — local state, mirrors CustomerHomeShell.
final workerTabIndexProvider = StateProvider<int>((ref) => 0);

/// Bottom-nav shell for the WORKER flow only.
///
/// This 5-tab structure (Home / Jobs / Activity / Rewards / Profile) and the
/// Rewards & Gamification screen are STRICTLY worker-side. The Employer/Client
/// experience lives in CustomerHomeShell, which keeps its own 4-tab
/// NavigationBar and must NOT gain this tab set.
///
///   0 → Home     (WorkerDashboardScreen — the job board lives here)
///   1 → Jobs     (ActivityScreen — discussion + check-in / check-out)
///   2 → Activity (ActivityOverviewScreen — ongoing / pending / history)
///   3 → Rewards  (RewardsScreen — gamification, worker only)
///   4 → Profile  (TaskerProfileScreen)
class WorkerHomeShell extends ConsumerWidget {
  const WorkerHomeShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(workerTabIndexProvider);

    // Show the "Money Received" top toast whenever a checkout clears — works
    // from any worker screen since the shell stays mounted beneath pushed
    // routes (wallet, task execution, …). Fires once per event thanks to the
    // monotonic ToastSignal.seq.
    ref.listen(notificationProvider.select((s) => s.toast), (prev, next) {
      if (next != null && next != prev) {
        showMoneyReceivedToast(context, next.amount);
      }
    });

    // Generalized push notifications (reward redemptions, etc.)
    ref.listen(notificationProvider.select((s) => s.push), (prev, next) {
      if (next != null && next != prev) {
        showGlobalPushBanner(
          context,
          title: next.title,
          body: next.body,
          emoji: next.emoji,
        );
      }
    });

    // Generalized push notifications (reward redemptions, etc.)
    ref.listen(notificationProvider.select((s) => s.push), (prev, next) {
      if (next != null && next != prev) {
        showGlobalPushBanner(
          context,
          title: next.title,
          body: next.body,
          emoji: next.emoji,
        );
      }
    });

    return Scaffold(
      // Home → AI assistant. Jobs tab (messages + check-in/out) → red SOS
      // button so safety is one tap away while a task is in progress.
      floatingActionButton: switch (index) {
        0 => AgentFab(onTap: () => context.push('${Routes.chatbot}?role=tasker')),
        1 => FloatingActionButton.extended(
            heroTag: 'worker-sos',
            backgroundColor: AppColors.error,
            foregroundColor: AppColors.onBrand,
            icon: const Icon(Icons.shield),
            label: const Text(
              'SOS',
              style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1),
            ),
            onPressed: () =>
                showEmergencyBottomSheet(context, location: 'လက်ရှိတည်နေရာ'),
          ),
        _ => null,
      },
      body: IndexedStack(
        index: index,
        children: const [
          WorkerDashboardScreen(), // 0 — Home
          ActivityScreen(), // 1 — Jobs
          ActivityOverviewScreen(
            role: ActivityOverviewRole.tasker,
          ), // 2 — Activity
          RewardsScreen(), // 3 — Rewards
          TaskerProfileScreen(), // 4 — Profile
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
            icon: Icon(Icons.assignment_outlined),
            activeIcon: Icon(Icons.assignment),
            label: AppStrings.activityTabLabel,
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
