import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import 'activity_placeholder_screen.dart';
import 'home_screen.dart';
import 'profile_placeholder_screen.dart';

// Which bottom-nav tab is active. Public (not file-private) because the
// task-posting flow's success modal switches to the Activity tab after
// publishing — still feature-local in spirit (one provider, one concern),
// just not restricted to this file the way other screens' local state is.
final customerTabIndexProvider = StateProvider<int>((ref) => 0);

/// Bottom-nav shell for the customer flow: Home / Activity / Profile.
/// Tabs are local state (IndexedStack), not separate GoRouter routes — the
/// global back-button handler and ShellRoute are untouched by this; pushed
/// screens (worker list/profile, booking, post-task) still navigate via
/// context.push as before, on top of whichever tab is active.
class CustomerHomeShell extends ConsumerWidget {
  const CustomerHomeShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(customerTabIndexProvider);
    return Scaffold(
      body: IndexedStack(
        index: index,
        children: const [
          CustomerHomeScreen(),
          ActivityPlaceholderScreen(),
          ProfilePlaceholderScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: index,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.purple700,
        unselectedItemColor: AppColors.textSecondary,
        backgroundColor: AppColors.lightSurface,
        onTap: (i) => ref.read(customerTabIndexProvider.notifier).state = i,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: AppStrings.homeTabLabel,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment_outlined),
            activeIcon: Icon(Icons.assignment),
            label: AppStrings.activityTabLabel,
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
