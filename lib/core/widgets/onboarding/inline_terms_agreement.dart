import 'package:flutter/material.dart';

import '../../constants/onboarding_strings.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import 'rules_summary_panel.dart';

/// Compact, reusable Terms & Conditions agreement, designed to sit right above
/// a signup/login primary button — replacing the old standalone Terms page.
///
/// Layout: [Checkbox] + agreement text + a "View Details" affordance. Tapping
/// the details text (or chevron) opens a scrollable sheet with the full terms
/// (reusing [RulesSummaryPanel]); its "Accept & Close" button ticks the box.
///
/// State is owned by the caller (so it can gate its submit button and persist
/// the choice on the signup draft) — this widget only presents and reports.
class InlineTermsAgreement extends StatelessWidget {
  final bool accepted;
  final ValueChanged<bool> onChanged;

  /// Full legal text shown in the details sheet.
  final String fullRulesText;

  /// Optional AUTH-ONLY listen-clip key, forwarded to [RulesSummaryPanel].
  final String? audioKey;

  /// When non-null, a warning is shown (e.g. the user tried to submit without
  /// agreeing). Cleared by the caller once the box is ticked.
  final String? errorText;

  const InlineTermsAgreement({
    super.key,
    required this.accepted,
    required this.onChanged,
    required this.fullRulesText,
    this.audioKey,
    this.errorText,
  });

  Future<void> _openDetails(BuildContext context) async {
    final accept = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (ctx) => _TermsDetailsSheet(
        fullRulesText: fullRulesText,
        audioKey: audioKey,
      ),
    );
    // "Accept & Close" returns true → tick the box for the caller.
    if (accept == true) onChanged(true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasError = errorText != null;
    final borderColor = hasError ? AppColors.error : AppColors.onboardingDivider;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              Checkbox(
                value: accepted,
                onChanged: (v) => onChanged(v ?? false),
                activeColor: AppColors.purple700,
                materialTapTargetSize: MaterialTapTargetSize.padded,
              ),
              // Tapping the label also toggles — bigger, friendlier target.
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onChanged(!accepted),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                    child: Text(
                      OnboardingStrings.termsInlineAgree,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              // View-details affordance → full terms sheet.
              TextButton(
                onPressed: () => _openDetails(context),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.purple700,
                  minimumSize: const Size(0, 48),
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        OnboardingStrings.termsViewDetails,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.purple700,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const Icon(Icons.chevron_right, size: AppSizes.iconMd, color: AppColors.purple700),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
            ],
          ),
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs, left: AppSpacing.sm),
            child: Row(
              children: [
                const Icon(Icons.error_outline, size: AppSizes.iconSm, color: AppColors.error),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    errorText!,
                    style: theme.textTheme.bodySmall?.copyWith(color: AppColors.error),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// The details bottom sheet: full terms (via [RulesSummaryPanel]) + an
/// "Accept & Close" button that pops `true`.
class _TermsDetailsSheet extends StatelessWidget {
  final String fullRulesText;
  final String? audioKey;
  const _TermsDetailsSheet({required this.fullRulesText, this.audioKey});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (ctx, controller) => Column(
        children: [
          const SizedBox(height: AppSpacing.sm),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.dividerColor,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                const Icon(Icons.gavel_outlined, color: AppColors.purple700),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(OnboardingStrings.rulesTitle, style: theme.textTheme.titleLarge),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              controller: controller,
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              child: RulesSummaryPanel(
                fullRulesText: fullRulesText,
                audioKey: audioKey,
              ),
            ),
          ),
          // Accept & Close — the caller ticks the box on `true`.
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.purple700,
                    foregroundColor: AppColors.onBrand,
                    minimumSize: const Size(0, AppSizes.buttonHeight),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                  icon: const Icon(Icons.check_circle_outline),
                  label: Text(OnboardingStrings.termsAcceptClose),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
