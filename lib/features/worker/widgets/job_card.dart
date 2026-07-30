import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/data/demo_data.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../onboarding/onboarding_models.dart' show toBurmeseDigits;

/// Maps a job category name to a representative icon — purely cosmetic,
/// derived from the same category strings demo_data.dart already uses
/// elsewhere (never hardcodes a category list of its own).
IconData categoryIconFor(String category) {
  final c = category.toLowerCase();
  if (c.contains('plumb')) return Icons.plumbing;
  if (c.contains('electric')) return Icons.electrical_services;
  if (c.contains('clean')) return Icons.cleaning_services;
  if (c.contains('carpent')) return Icons.carpenter;
  if (c.contains('paint')) return Icons.format_paint;
  if (c.contains('ac') || c.contains('air')) return Icons.ac_unit;
  if (c.contains('garden')) return Icons.yard;
  if (c.contains('delivery')) return Icons.local_shipping;
  if (c.contains('tutor')) return Icons.school;
  if (c.contains('handyman') || c.contains('appliance')) return Icons.handyman;
  return Icons.work_outline;
}

/// "X minutes/hours/days ago" in Burmese, derived from [createdAt] — display
/// only, computed from the existing [Job.createdAt] field.
String relativeTimeFor(DateTime createdAt, {DateTime? now}) {
  final n = now ?? DateTime.now();
  final diff = n.difference(createdAt);
  if (diff.inMinutes < 1) return "ခုနက";
  if (diff.inMinutes < 60) {
    return "${toBurmeseDigits(diff.inMinutes)} မိနစ်အရင်";
  }
  if (diff.inHours < 24) return "${toBurmeseDigits(diff.inHours)} နာရီအရင်";
  return "${toBurmeseDigits(diff.inDays)} ရက်အရင်";
}

/// Highlighted estimated-budget readout — larger typography per the Job
/// Board redesign spec, still backed by [Job.aiSuggestedBudgetMmk].
class BudgetBadge extends StatelessWidget {
  final int budgetMmk;
  const BudgetBadge({super.key, required this.budgetMmk});

  @override
  Widget build(BuildContext context) {
    final taskerReceives = budgetMmk - (budgetMmk * 0.15).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _MoneyLine(
                label: 'Client posted',
                amount: budgetMmk,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _MoneyLine(
                label: 'Tasker gets',
                amount: taskerReceives,
                color: AppColors.purple700,
                emphasized: true,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MoneyLine extends StatelessWidget {
  final String label;
  final int amount;
  final Color color;
  final bool emphasized;

  const _MoneyLine({
    required this.label,
    required this.amount,
    required this.color,
    this.emphasized = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          '$amount ${AppStrings.currency}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: (emphasized
                  ? theme.textTheme.titleLarge
                  : theme.textTheme.titleMedium)
              ?.copyWith(color: color, fontWeight: FontWeight.w900),
        ),
      ],
    );
  }
}

/// Small placeholder tiles standing in for a job's attached photos/videos.
/// This demo data has no real files to render (Phase 1: no network images),
/// so each tile is just a soft, category-tinted icon box — enough to signal
/// "this task has attachments" without pretending to show a real photo.
/// Capped at 3 tiles even if [count] is higher.
class MediaCountStrip extends StatelessWidget {
  final int count;
  final String category;
  const MediaCountStrip({super.key, required this.count, required this.category});

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const SizedBox.shrink();
    final shown = count > 3 ? 3 : count;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm + 2),
      child: Row(
        children: [
          for (var i = 0; i < shown; i++)
            Padding(
              padding: EdgeInsets.only(right: i == shown - 1 ? 0 : AppSpacing.xs),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.purple100,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                alignment: Alignment.center,
                child: Icon(categoryIconFor(category),
                    color: AppColors.purple700, size: AppSizes.iconSm),
              ),
            ),
          if (count > 3) ...[
            const SizedBox(width: AppSpacing.xs),
            Text("+${count - 3}",
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppColors.textSecondary)),
          ],
        ],
      ),
    );
  }
}

/// Small colored pill for a job's urgency status. Reused wherever the
/// "Urgent" state needs to be flagged on a card.
class StatusBadge extends StatelessWidget {
  final bool urgent;
  const StatusBadge({super.key, required this.urgent});

  @override
  Widget build(BuildContext context) {
    if (!urgent) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm, vertical: AppSpacing.xxs),
      decoration: BoxDecoration(
        color: AppColors.orange.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        "⚡ အရေးပေါ်",
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodySmall
            ?.copyWith(color: AppColors.orange, fontWeight: FontWeight.w700),
      ),
    );
  }
}

/// Bottom action row: compact primary ("Accept Job") + secondary ("View
/// Details") buttons — sized for a card footer, not full-bleed like
/// [LargeButton]. Scales slightly on tap for tactile feedback.
class JobActionButtons extends StatefulWidget {
  final bool accepted;
  final VoidCallback onAccept;
  final VoidCallback onViewDetails;

  const JobActionButtons({
    super.key,
    required this.accepted,
    required this.onAccept,
    required this.onViewDetails,
  });

  @override
  State<JobActionButtons> createState() => _JobActionButtonsState();
}

class _JobActionButtonsState extends State<JobActionButtons> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: widget.onViewDetails,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(44),
              side: const BorderSide(color: AppColors.purple700),
            ),
            child: Text(AppStrings.dashboardViewDetailsCta,
                maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Listener(
            onPointerDown:
                widget.accepted ? null : (_) => setState(() => _pressed = true),
            onPointerUp: (_) => setState(() => _pressed = false),
            onPointerCancel: (_) => setState(() => _pressed = false),
            child: AnimatedScale(
              scale: _pressed ? 0.96 : 1.0,
              duration: AppMotion.fast,
              curve: AppMotion.press,
              child: FilledButton(
                onPressed: widget.accepted
                    ? null
                    : () {
                        HapticFeedback.selectionClick();
                        widget.onAccept();
                      },
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(44),
                  backgroundColor:
                      widget.accepted ? AppColors.success : AppColors.purple700,
                ),
                child: Text(
                  widget.accepted
                      ? AppStrings.dashboardInterestReceived
                      : AppStrings.dashboardInterestedCta,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// A single Job Board listing: category icon + title + urgent badge, a
/// 2-line description, location/distance/posted-time row, the required-tier
/// requirement, a highlighted budget readout, and the accept/details
/// actions. Pure presentation — all data comes from [Job]; tapping is
/// delegated to the caller.
class JobCard extends StatelessWidget {
  final Job job;
  final VoidCallback onAccept;
  final VoidCallback onViewDetails;

  const JobCard({
    super.key,
    required this.job,
    required this.onAccept,
    required this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accepted = job.status == AppStrings.dashboardInterestReceived;
    final radius = BorderRadius.circular(AppRadius.lg);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowMd,
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.purple100,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  alignment: Alignment.center,
                  child: Icon(categoryIconFor(job.category),
                      color: AppColors.purple700, size: AppSizes.iconMd),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(job.category,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium),
                ),
                if (job.isUrgent) ...[
                  const SizedBox(width: AppSpacing.xs),
                  Flexible(child: StatusBadge(urgent: job.isUrgent)),
                ],
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(job.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium),
            const SizedBox(height: AppSpacing.sm + 2),
            MediaCountStrip(count: job.photoCount, category: job.category),
            Row(
              children: [
                Icon(Icons.location_on, size: 14, color: theme.hintColor),
                const SizedBox(width: AppSpacing.xxs),
                Flexible(
                  child: Text(
                      "${job.township} • ${job.distanceMiles.toStringAsFixed(1)} km",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.hintColor)),
                ),
                const SizedBox(width: AppSpacing.sm),
                Icon(Icons.schedule, size: 14, color: theme.hintColor),
                const SizedBox(width: AppSpacing.xxs),
                Flexible(
                  child: Text(relativeTimeFor(job.createdAt),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.hintColor)),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                Icon(Icons.verified_user_outlined,
                    size: 14, color: theme.hintColor),
                const SizedBox(width: AppSpacing.xxs),
                Flexible(
                  child: Text(
                      "${AppStrings.dashboardRequiredTierPrefix}${trustBadgeFor(job.requiredTier)}",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.hintColor)),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Divider(height: 1),
            ),
            BudgetBadge(budgetMmk: job.aiSuggestedBudgetMmk),
            const SizedBox(height: AppSpacing.md),
            JobActionButtons(
              accepted: accepted,
              onAccept: onAccept,
              onViewDetails: onViewDetails,
            ),
          ],
        ),
      ),
    );
  }
}
