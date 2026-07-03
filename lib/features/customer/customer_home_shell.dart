import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_strings.dart';
import '../../core/routing/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/chatbot_fab.dart';
import 'client_profile_screen.dart';
import 'home_screen.dart';
import '../customer/activity_screen.dart';

// Which bottom-nav tab is active. Public because the task-posting flow's
// success modal switches to the Activity tab (index 2) after publishing.
final customerTabIndexProvider = StateProvider<int>((ref) => 0);

/// Bottom-nav shell for the customer flow: Home / Chat / Pending / Account.
///
/// Tab indices:
///   0 → Home
///   1 → Chat      (ActivityScreen with Messages sub-tab pre-selected)
///   2 → Pending   (ActivityScreen with Bookings sub-tab pre-selected)
///   3 → Account
///
/// Chat and Pending share a single ActivityScreen instance. Tapping either
/// tab simply switches activityTabProvider's sub-tab (0 = Messages,
/// 1 = Bookings) so state is preserved between taps.
class CustomerHomeShell extends ConsumerWidget {
  const CustomerHomeShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(customerTabIndexProvider);

    return Scaffold(
      // Floating AI assistant — only on the Home tab.
      floatingActionButton: index == 0
          ? ChatbotFab(onTap: () => context.push('${Routes.chatbot}?role=client'))
          : null,
      body: IndexedStack(
        index: index == 2 ? 1 : index == 3 ? 2 : index,
        children: const [
          CustomerHomeScreen(),  // 0 → Home
          ActivityScreen(),      // 1 → Chat  /  2 → Pending (same widget, sub-tab differs)
          ClientProfileScreen(), // 3 → Account
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) {
          // When switching to Chat (1) or Pending (2), also update
          // ActivityScreen's internal sub-tab so the right content shows.
          if (i == 1) ref.read(activityTabProvider.notifier).state = 0;
          if (i == 2) ref.read(activityTabProvider.notifier).state = 1;
          ref.read(customerTabIndexProvider.notifier).state = i;
        },
        backgroundColor: AppColors.lightSurface,
        indicatorColor: AppColors.purple100,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: AppStrings.homeTabLabel,
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline_rounded),
            selectedIcon: Icon(Icons.chat_bubble_rounded),
            label: AppStrings.chatTabLabel,
          ),
          NavigationDestination(
            icon: Icon(Icons.pending_actions_outlined),
            selectedIcon: Icon(Icons.pending_actions_rounded),
            label: AppStrings.pendingTabLabel,
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
