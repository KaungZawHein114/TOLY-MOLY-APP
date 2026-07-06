import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../features/auth/audio/auth_audio_button.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import 'read_aloud_button.dart';

/// Scrollable rules summary with a read-aloud control and a required
/// agreement checkbox. The user cannot proceed until [agreed] is true —
/// enforced by the caller disabling its own continue button.
class RulesAgreementPanel extends StatelessWidget {
  final String rulesText;
  final String agreementLabel;
  final bool agreed;
  final ValueChanged<bool> onChanged;
  final String? errorText;

  /// AUTH-ONLY: when set, the read-aloud control plays this pre-recorded clip
  /// (a key from `AuthAudioKeys`) instead of speaking [rulesText] via TTS.
  final String? audioKey;

  const RulesAgreementPanel({
    super.key,
    required this.rulesText,
    required this.agreementLabel,
    required this.agreed,
    required this.onChanged,
    this.errorText,
    this.audioKey,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.centerRight,
          // AUTH: pre-recorded clip; otherwise the live TTS read-aloud button.
          child: audioKey != null
              ? AuthAudioButton(audioKey: audioKey!)
              : ReadAloudButton(textToRead: rulesText),
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          height: 220,
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.blue100,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.onboardingDivider),
          ),
          child: SingleChildScrollView(
            child: Text(rulesText, style: theme.textTheme.bodyMedium?.copyWith(height: 1.6)),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.md),
            onTap: () {
              HapticFeedback.selectionClick();
              onChanged(!agreed);
            },
            child: AnimatedContainer(
              // State-indication, not decoration — keep it quick so
              // confirming agreement feels instant rather than slow.
              duration: AppMotion.fast,
              curve: AppMotion.press,
              constraints: const BoxConstraints(minHeight: 56),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              decoration: BoxDecoration(
                color: agreed ? AppColors.purple100 : AppColors.lightSurface,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: agreed ? AppColors.purple700 : AppColors.onboardingDivider,
                  width: agreed ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Checkbox(
                    value: agreed,
                    activeColor: AppColors.purple700,
                    onChanged: (v) => onChanged(v ?? false),
                  ),
                  Expanded(
                    child: Text(agreementLabel, style: theme.textTheme.bodyMedium),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(errorText!, style: theme.textTheme.bodySmall?.copyWith(color: AppColors.error)),
        ],
      ],
    );
  }
}
