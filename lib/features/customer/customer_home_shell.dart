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
import 'activity_screen.dart';
import 'client_profile_screen.dart';
import 'client_rewards_screen.dart';
import 'home_screen.dart';

// Which bottom-nav tab is active. Public because the task-posting flow's
// success modal may switch tabs after publishing.
final customerTabIndexProvider = StateProvider<int>((ref) => 0);

/// Bottom-nav shell for the customer flow: Home / Jobs / Activity / Rewards / Account.
///
/// Each tab maps 1-to-1 to a dedicated screen — no shared screens, no
/// content duplication between tabs:
///   0 → Home     (CustomerHomeScreen)
///   1 → Jobs     (ActivityScreen — discussion + check-in / check-out)
///   2 → Activity (ActivityOverviewScreen — ongoing / pending / history)
///   3 → Rewards  (ClientRewardsScreen — VIP & coupons, client only)
///   4 → Account  (ClientProfileScreen)
class CustomerHomeShell extends ConsumerWidget {
  const CustomerHomeShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(customerTabIndexProvider);

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
      // button so safety is one tap away while a task is in progress. Placed on
      // the shell (not a nested screen) so it can never be hidden.
      floatingActionButton: switch (index) {
        0 => AgentFab(onTap: () => context.push('${Routes.chatbot}?role=client')),
        1 => FloatingActionButton.extended(
            heroTag: 'client-sos',
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
          CustomerHomeScreen(), // 0 — Home
          ActivityScreen(), // 1 — Jobs
          ActivityOverviewScreen(
            role: ActivityOverviewRole.client,
          ), // 2 — Activity
          ClientRewardsScreen(), // 3 — Rewards (VIP & coupons)
          ClientProfileScreen(), // 4 — Account
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) =>
            ref.read(customerTabIndexProvider.notifier).state = i,
        backgroundColor: AppColors.lightSurface,
        indicatorColor: AppColors.purple100,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: AppStrings.homeTabLabel,
          ),
          NavigationDestination(
            icon: Icon(Icons.work_outline),
            selectedIcon: Icon(Icons.work),
            label: AppStrings.jobsTabLabel,
          ),
          NavigationDestination(
            icon: Icon(Icons.assignment_outlined),
            selectedIcon: Icon(Icons.assignment_rounded),
            label: AppStrings.activityTabLabel,
          ),
          NavigationDestination(
            icon: Icon(Icons.card_giftcard_outlined),
            selectedIcon: Icon(Icons.card_giftcard_rounded),
            label: AppStrings.rewardsTabLabel,
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: AppStrings.profileTabLabel,
          ),
        ],
      ),
    );
  }
}
