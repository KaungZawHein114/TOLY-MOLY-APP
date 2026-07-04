import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../activity/activity_chat.dart';
import 'activity_screen.dart';

/// Chat tab — shows only the conversation list (no bookings, no activity tabs).
/// Content is rendered by [ActivityMessagesView] from activity_screen.dart.
class ChatScreen extends ConsumerWidget {
  const ChatScreen({super.key});

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
                  'စကားပြောမှုများ',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: AppColors.onBrand,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Stack(
                  children: [
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
                    Positioned(
                      top: AppSpacing.sm,
                      right: AppSpacing.sm,
                      child: Container(
                        width: AppSpacing.sm,
                        height: AppSpacing.sm,
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                          border:
                              Border.all(color: AppColors.purple700, width: AppSpacing.xxs),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Expanded(child: ActivityMessagesView()),
        ],
      ),
    );
  }
}
