import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../activity_chat.dart';

/// The task summary, on demand only.
///
/// It used to sit permanently at the top of the discussion and cost a third of
/// the screen. Nobody re-reads it every message — so it lives one tap away and
/// closes again, leaving the conversation in charge.
void showTaskDetailSheet(BuildContext context, {DiscussionTask? fixedTask}) {
  showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    backgroundColor: AppColors.lightSurface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
    ),
    builder: (_) => TaskDetailSheet(fixedTask: fixedTask),
  );
}

class TaskDetailSheet extends ConsumerWidget {
  /// A thread about a different job passes its own task; the live discussion
  /// leaves this null and watches the shared one, so an accepted time change
  /// shows up here immediately.
  final DiscussionTask? fixedTask;

  const TaskDetailSheet({super.key, this.fixedTask});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final DiscussionTask task = fixedTask ?? ref.watch(discussionTaskProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: AppSpacing.huge,
                height: AppSpacing.xxs,
                margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.onboardingDivider,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    task.skillLabel,
                    style:
                        theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                if (task.isUrgent)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm, vertical: AppSpacing.xxs),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.bolt_rounded,
                            size: AppSizes.iconSm, color: AppColors.orangeDark),
                        const SizedBox(width: AppSpacing.xxs),
                        Text(
                          'အမြန်လိုအပ်',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppColors.orangeDark,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            _DetailRow(
              icon: Icons.place_outlined,
              label: 'နေရာ',
              value: task.location,
            ),
            _DetailRow(
              icon: Icons.event_outlined,
              label: 'ရက်စွဲ / အချိန်',
              value: '${task.date} · ${task.timeSlot}',
            ),
            _DetailRow(
              icon: Icons.payments_outlined,
              label: 'သဘောတူဈေး',
              value: formatMmk(task.budgetMmk),
              emphasize: true,
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                backgroundColor: AppColors.purple700,
                foregroundColor: AppColors.onBrand,
              ),
              child: const Text('ပိတ်မည်'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool emphasize;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: AppSizes.iconMd, color: AppColors.purple700),
          const SizedBox(width: AppSpacing.md),
          Flexible(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: (emphasize ? theme.textTheme.titleMedium : theme.textTheme.bodyLarge)
                  ?.copyWith(
                fontWeight: FontWeight.bold,
                color: emphasize ? AppColors.purple700 : AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
