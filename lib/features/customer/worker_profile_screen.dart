import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_strings.dart';
import '../../core/data/demo_data.dart';
import '../../core/routing/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/demo_card.dart';
import '../../core/widgets/large_button.dart';
import 'task_posting/task_posting_models.dart';
import 'task_posting/task_posting_state.dart';

/// Worker profile. The router guarantees a non-null Worker; if anything is off
/// it passes the hardcoded fallbackWorker, so this screen always renders.
class WorkerProfileScreen extends ConsumerWidget {
  final Worker worker;
  const WorkerProfileScreen({super.key, required this.worker});

  /// "Schedule Worker" starts a fresh task-posting draft with this worker's
  /// category + tier already filled in, then jumps straight to the Location
  /// step — the category-pick and tier-pick steps are skipped entirely since
  /// they're no longer a choice (the client picked this exact worker).
  void _scheduleWorker(BuildContext context, WidgetRef ref) {
    ref.read(taskDraftProvider.notifier).state = TaskDraft(
      category: worker.skill,
      workerTier: WorkerTier.values[worker.currentTier.clamp(1, 7) - 1],
      presetWorkerId: worker.id,
    );
    context.push(Routes.postTaskTypeLocation);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: AppColors.purple700,
            foregroundColor: AppColors.onBrand,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(gradient: AppColors.purpleGradient),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: AppSpacing.xxxl - 2),
                      Container(
                        width: AppSizes.avatarLarge,
                        height: AppSizes.avatarLarge,
                        decoration: const BoxDecoration(
                          color: AppColors.onBrand,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(worker.emoji,
                            style: const TextStyle(fontSize: 48)),
                      ),
                      const SizedBox(height: AppSpacing.sm + 2),
                      Text(
                        worker.name,
                        style: theme.textTheme.headlineSmall
                            ?.copyWith(color: AppColors.onBrand, fontSize: 24),
                      ),
                      Text(
                        worker.skill,
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: AppColors.onBrandMuted),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      TrustBadgePill(tier: worker.currentTier),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Row(
                  children: [
                    _Stat(
                      icon: Icons.star,
                      iconColor: AppColors.star,
                      value: worker.rating.toString(),
                      label: "${worker.reviews} reviews",
                    ),
                    _Stat(
                      icon: Icons.location_on,
                      iconColor: AppColors.purple700,
                      value: "${(worker.distanceMiles * 1.609).toStringAsFixed(1)} km",
                      label: "away",
                    ),
                    _Stat(
                      icon: Icons.assignment_turned_in,
                      iconColor: AppColors.success,
                      value: "${worker.completedTasks}",
                      label: AppStrings.tasksCompletedSuffix,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                _AvailabilityBanner(available: worker.isAvailableNow),
                const SizedBox(height: AppSpacing.xl),
                Text("အကြောင်း", style: theme.textTheme.titleMedium),
                const SizedBox(height: AppSpacing.xs + 2),
                Text(worker.bio, style: theme.textTheme.bodyMedium),
                const SizedBox(height: AppSpacing.xxl + 4),
                LargeButton(
                  label: AppStrings.scheduleWorkerCta,
                  icon: Icons.calendar_month,
                  gradient: AppColors.purpleGradient,
                  onTap: () => _scheduleWorker(context, ref),
                ),
                const SizedBox(height: AppSpacing.md),
                LargeButton(
                  label: "အကူအညီ မေးမည်",
                  icon: Icons.chat_bubble_outline,
                  filled: false,
                  onTap: () => context.push(Routes.chatbot),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;
  const _Stat({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: AppSizes.iconLg - 2),
          const SizedBox(height: AppSpacing.xs),
          Text(value, style: theme.textTheme.titleMedium),
          Text(label,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.hintColor)),
        ],
      ),
    );
  }
}

class _AvailabilityBanner extends StatelessWidget {
  final bool available;
  const _AvailabilityBanner({required this.available});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = available ? AppColors.success : AppColors.orange;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md + 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.md - 2),
      ),
      child: Row(
        children: [
          Icon(available ? Icons.check_circle : Icons.schedule, color: color),
          const SizedBox(width: AppSpacing.sm + 2),
          Text(
            available ? AppStrings.availableNowLabel : AppStrings.availableLaterLabel,
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: color, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

