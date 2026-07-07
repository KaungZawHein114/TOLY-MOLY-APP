import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/agent/agent_session.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../activity/activity_chat.dart';
import 'activity_screen.dart';
import 'widgets/stale_post_nudge.dart';

// A representative "waiting" client post for the Task-Handling nudge (spec
// §4.4 Phase 1). The demo has no live open-post list with timestamps, so this
// stands in for one; its age is past [AgentThresholds.stalePostHours] so the
// gentle nudge shows. Swap for a real pending TaskPost when that list exists.
const Map<String, dynamic> _demoWaitingPost = {
  'category': 'Plumber',
  'township': 'လှိုင်',
  'budgetMmk': 12000,
  'urgent': false,
  'description': '',
};
const int _demoWaitingAgeHours = AgentThresholds.stalePostHours + 2;

/// Pending tab — shows only booking management (no chat list, no activity tabs).
/// Content is rendered by [ActivityBookingsView] from activity_screen.dart.
class PendingScreen extends ConsumerWidget {
  const PendingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              56,
              AppSpacing.xl,
              AppSpacing.xl,
            ),
            decoration: const BoxDecoration(
              color: AppColors.purple700,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(AppRadius.xl)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'ဘွတ်ကင်များ',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: AppColors.onBrand,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Semantics(
                  label: 'အသိပေးချက်များ',
                  button: true,
                  child: IconButton(
                    icon: const Icon(Icons.notifications_none_outlined,
                        color: AppColors.onBrand),
                    onPressed: () => showActivitySnack(
                        context, 'အသိပေးချက်အသစ်များ မရှိသေးပါ။'),
                  ),
                ),
              ],
            ),
          ),
          if (_demoWaitingAgeHours >= AgentThresholds.stalePostHours)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 0),
              child: StalePostNudge(
                task: _demoWaitingPost,
                ageHours: _demoWaitingAgeHours,
              ),
            ),
          const Expanded(child: ActivityBookingsView()),
        ],
      ),
    );
  }
}
