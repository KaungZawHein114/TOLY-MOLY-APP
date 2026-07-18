import 'package:flutter/material.dart';

import '../../../features/auth/audio/auth_audio_button.dart';
import '../../constants/onboarding_strings.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';

/// The redesigned Terms step: rules as five icon + one-line rows that can be
/// recognized at a glance (recognition over recall), a listen control, and
/// the full legal text tucked behind "အပြည့်အစုံ ဖတ်မည်" (progressive
/// disclosure). Agreement itself is the screen's single big CTA, owned by
/// the caller — this panel only presents.
class RulesSummaryPanel extends StatefulWidget {
  /// Full rules text, shown when the user expands and read by the TTS/audio
  /// listen control.
  final String fullRulesText;

  /// AUTH-ONLY pre-recorded clip key; null falls back to nothing (auth
  /// screens never use TTS).
  final String? audioKey;

  const RulesSummaryPanel({
    super.key,
    required this.fullRulesText,
    this.audioKey,
  });

  @override
  State<RulesSummaryPanel> createState() => _RulesSummaryPanelState();
}

class _RulesSummaryPanelState extends State<RulesSummaryPanel> {
  bool _expanded = false;

  static const List<(IconData, String)> _summaryRows = [
    (Icons.fact_check_outlined, OnboardingStrings.rulesSummaryHonesty),
    (Icons.schedule_outlined, OnboardingStrings.rulesSummaryPunctual),
    (Icons.handshake_outlined, OnboardingStrings.rulesSummaryRespect),
    (Icons.shield_outlined, OnboardingStrings.rulesSummarySafety),
    (Icons.gpp_maybe_outlined, OnboardingStrings.rulesSummarySuspension),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(OnboardingStrings.rulesSummaryIntro,
                  style: theme.textTheme.titleMedium),
            ),
            if (widget.audioKey != null)
              AuthAudioButton(
                audioKey: widget.audioKey!,
                semanticLabel: OnboardingStrings.rulesTitle,
                compact: true,
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Container(
          decoration: BoxDecoration(
            color: AppColors.blue100,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.blue300),
          ),
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
          child: Column(
            children: [
              for (final (icon, text) in _summaryRows)
                Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: AppColors.onBrand,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon,
                            size: AppSizes.iconMd,
                            color: AppColors.indigo700),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(
                          text,
                          style: theme.textTheme.bodyLarge
                              ?.copyWith(height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        // Full legal text on demand — never forced on the user up front.
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => setState(() => _expanded = !_expanded),
            icon: Icon(
              _expanded ? Icons.expand_less : Icons.expand_more,
              size: AppSizes.iconMd,
            ),
            label: Text(_expanded
                ? OnboardingStrings.rulesHideFull
                : OnboardingStrings.rulesReadFull),
            style: TextButton.styleFrom(
              minimumSize: const Size(0, 48),
              foregroundColor: AppColors.purple700,
            ),
          ),
        ),
        AnimatedSize(
          duration: AppMotion.medium,
          curve: AppMotion.enter,
          alignment: Alignment.topCenter,
          child: !_expanded
              ? const SizedBox(width: double.infinity)
              : Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: AppColors.lightSurface,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: AppColors.onboardingDivider),
                  ),
                  child: Text(
                    widget.fullRulesText,
                    style:
                        theme.textTheme.bodyLarge?.copyWith(height: 1.7),
                  ),
                ),
        ),
      ],
    );
  }
}
