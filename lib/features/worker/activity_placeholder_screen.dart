import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/mascot/mascot_state.dart';
import '../../core/widgets/mascot/pho_wa_yoke.dart';

/// Stub for the worker bottom nav's "လုပ်ဆောင်ချက်များ" tab — reserves the
/// destination until job-interest/booking history tracking is built.
class WorkerActivityPlaceholderScreen extends StatelessWidget {
  const WorkerActivityPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.activityTabLabel)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const PhoWaYoke(state: PhoWaYokeState.idle, size: 120),
              const SizedBox(height: AppSpacing.lg),
              Text(AppStrings.comingSoonTitle, style: theme.textTheme.headlineSmall),
              const SizedBox(height: AppSpacing.sm),
              Text(
                AppStrings.comingSoonMessage,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
