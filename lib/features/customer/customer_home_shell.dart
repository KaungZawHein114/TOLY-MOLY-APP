import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_strings.dart';
import '../../core/routing/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/chatbot_fab.dart';
import 'chat_screen.dart';
import 'client_profile_screen.dart';
import 'home_screen.dart';
import 'pending_screen.dart';

// Which bottom-nav tab is active. Public because the task-posting flow's
// success modal may switch tabs after publishing.
final customerTabIndexProvider = StateProvider<int>((ref) => 0);

/// Bottom-nav shell for the customer flow: Home / Chat / Pending / Account.
///
/// Each tab maps 1-to-1 to a dedicated screen — no shared screens, no
/// content duplication between tabs:
///   0 → Home     (CustomerHomeScreen)
///   1 → Chat     (ChatScreen — conversations only)
///   2 → Pending  (PendingScreen — bookings only)
///   3 → Account  (ClientProfileScreen)
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
        index: index,
        children: const [
          CustomerHomeScreen(),  // 0 — Home
          ChatScreen(),          // 1 — Chat (conversations only)
          PendingScreen(),       // 2 — Pending (bookings only)
          ClientProfileScreen(), // 3 — Account
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
