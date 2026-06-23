import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import 'activity_placeholder_screen.dart';
import 'dashboard_screen.dart';
import 'profile_placeholder_screen.dart';

/// Which bottom-nav tab is active — local state, mirrors CustomerHomeShell.
final workerTabIndexProvider = StateProvider<int>((ref) => 0);

/// Bottom-nav shell for the worker flow: ပင်မ / လုပ်ဆောင်ချက်များ / ပရိုဖိုင်.
class WorkerHomeShell extends ConsumerWidget {
  const WorkerHomeShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(workerTabIndexProvider);
    return Scaffold(
      body: IndexedStack(
        index: index,
        children: const [
          WorkerDashboardScreen(),
          WorkerActivityPlaceholderScreen(),
          WorkerProfilePlaceholderScreen(),
        ],
      ),
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
