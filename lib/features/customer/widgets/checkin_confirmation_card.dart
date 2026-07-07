import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

/// Pinned card shown on the client's Pending tab when the worker has checked
/// in and is waiting for the client to confirm arrival.
///
/// [workerName] is shown inline in the card body.
/// [onAccept] → advances execution to [ExecutionStatus.inProgress].
/// [onReject] → advances to [ExecutionStatus.arrivalDisputed].
class CheckinConfirmationCard extends StatelessWidget {
  final String workerName;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const CheckinConfirmationCard({
    super.key,
    required this.workerName,
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return _ConfirmationCard(
      icon: Icons.location_on_rounded,
      iconColor: AppColors.indigo700,
      surfaceColor: AppColors.indigo100,
      borderColor: AppColors.indigo500,
      title: AppStrings.checkinCardTitle,
      body: "$workerName ${AppStrings.checkinCardBody}",
      primaryLabel: AppStrings.checkinAcceptCta,
      primaryColor: AppColors.indigo700,
      secondaryLabel: AppStrings.checkinRejectCta,
      onPrimary: onAccept,
      onSecondary: onReject,
    );
  }
}

/// Pinned card shown when the worker has checked out and is waiting for the
/// client to confirm job completion.
///
/// [workerName] is shown inline in the card body.
/// [onConfirm] → advances execution to [ExecutionStatus.completed].
/// [onReport]  → advances to [ExecutionStatus.completionDisputed].
class CheckoutConfirmationCard extends StatelessWidget {
  final String workerName;
  final VoidCallback onConfirm;
  final VoidCallback onReport;

  const CheckoutConfirmationCard({
    super.key,
    required this.workerName,
    required this.onConfirm,
    required this.onReport,
  });

  @override
  Widget build(BuildContext context) {
    return _ConfirmationCard(
      icon: Icons.task_alt_rounded,
      iconColor: AppColors.success,
      surfaceColor: AppColors.success.withValues(alpha: 0.08),
      borderColor: AppColors.success.withValues(alpha: 0.35),
      title: AppStrings.checkoutCardTitle,
      body: "$workerName ${AppStrings.checkoutCardBody}",
      primaryLabel: AppStrings.checkoutConfirmCta,
      primaryColor: AppColors.success,
      secondaryLabel: AppStrings.checkoutReportCta,
      onPrimary: onConfirm,
      onSecondary: onReport,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared card shell — not exported; only the two typed variants above are.
// ─────────────────────────────────────────────────────────────────────────────

class _ConfirmationCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color surfaceColor;
  final Color borderColor;
  final String title;
  final String body;
  final String primaryLabel;
  final Color primaryColor;
  final String secondaryLabel;
  final VoidCallback onPrimary;
  final VoidCallback onSecondary;

  const _ConfirmationCard({
    required this.icon,
    required this.iconColor,
    required this.surfaceColor,
    required this.borderColor,
    required this.title,
    required this.body,
    required this.primaryLabel,
    required this.primaryColor,
    required this.secondaryLabel,
    required this.onPrimary,
    required this.onSecondary,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: iconColor.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row
          Row(
            children: [
              Icon(icon, color: iconColor, size: 22),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: iconColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // Body
          Text(
            body,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: Semantics(
                  button: true,
                  label: primaryLabel,
                  child: FilledButton(
                    onPressed: onPrimary,
                    style: FilledButton.styleFrom(
                      backgroundColor: primaryColor,
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                    ),
                    child: Text(
                      primaryLabel,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: AppColors.onBrand,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Semantics(
                  button: true,
                  label: secondaryLabel,
                  child: OutlinedButton(
                    onPressed: onSecondary,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: iconColor.withValues(alpha: 0.5)),
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                    ),
                    child: Text(
                      secondaryLabel,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: iconColor,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
