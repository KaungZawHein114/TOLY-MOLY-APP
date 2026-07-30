import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/mascot/mascot_state.dart';
import '../../../../core/widgets/mascot/pho_wa_yoke.dart';

/// A one-line Pho Wa Yoke strip above the conversation.
///
/// He is here to say what this page is *for*, not to report progress — and he
/// takes a single line so the conversation keeps the screen. The task details
/// button lives beside him instead of a permanent summary card.
class MascotGuide extends StatelessWidget {
  final String message;
  final VoidCallback onViewTask;
  final VoidCallback onDismiss;

  const MascotGuide({
    super.key,
    required this.message,
    required this.onViewTask,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.sm, AppSpacing.sm, AppSpacing.sm),
      decoration: BoxDecoration(
        gradient: AppColors.guidanceSurfaceGradient,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const PhoWaYoke(state: PhoWaYokeState.happy, size: 44),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  message,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.brandPurple,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded,
                    size: AppSizes.iconSm, color: AppColors.purple500),
                tooltip: 'ဖျောက်ရန်',
                onPressed: onDismiss,
              ),
            ],
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: onViewTask,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.purple700,
                minimumSize: const Size(0, 44),
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              ),
              icon: const Icon(Icons.assignment_outlined, size: AppSizes.iconSm),
              label: const Text('အလုပ် အသေးစိတ် ကြည့်ရန်'),
            ),
          ),
        ],
      ),
    );
  }
}

/// What replaces the guide once it is dismissed: a single quiet chip, so the
/// task details are always one tap away without ever costing a headline.
class TaskDetailsChip extends StatelessWidget {
  final VoidCallback onTap;

  const TaskDetailsChip({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Align(
      alignment: Alignment.center,
      child: Semantics(
        button: true,
        label: 'အလုပ် အသေးစိတ် ကြည့်ရန်',
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 40),
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.blue100,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.assignment_outlined,
                    size: AppSizes.iconSm, color: AppColors.purple700),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  'အလုပ် အသေးစိတ်',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.purple700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
