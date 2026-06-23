import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/mascot/mascot_state.dart';
import '../../core/widgets/mascot/pho_wa_yoke.dart';

/// Stub for the bottom nav's "Profile" tab — reserves the destination until
/// the client's own profile screen is built in a future slice.
class ProfilePlaceholderScreen extends StatelessWidget {
  const ProfilePlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.profileTabLabel)),
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
