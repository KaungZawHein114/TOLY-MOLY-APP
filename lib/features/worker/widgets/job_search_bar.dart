import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/constants/onboarding_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

/// Large rounded Job Board search field with trailing voice-search and
/// filter affordances. Voice search reuses the app's existing offline mock
/// dictation pattern (see [SpeechToTextButton]) — tapping it hands back a
/// canned transcript instead of recording real audio, same as everywhere
/// else voice input appears in this Phase 1 build.
class JobSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback? onFilterTap;

  const JobSearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
    this.focusNode,
    this.onFilterTap,
  });

  // Offline mock dictation — same convention as [SpeechToTextButton]
  // elsewhere in the app: tapping hands back a canned transcript instead of
  // recording real audio.
  static const String _mockTranscript = "ရေပိုက် ပြင်ဆင်ခြင်း";

  void _useVoiceSearch(BuildContext context) {
    HapticFeedback.mediumImpact();
    controller.text = _mockTranscript;
    onChanged(_mockTranscript);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(OnboardingStrings.mockVoiceCapturedMessage),
        backgroundColor: AppColors.purple700,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowMd,
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: AppStrings.jobBoardSearchHint,
          prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Semantics(
                label: AppStrings.jobBoardVoiceSearchLabel,
                button: true,
                child: IconButton(
                  icon: const Icon(Icons.mic_none, color: AppColors.purple700),
                  onPressed: () => _useVoiceSearch(context),
                ),
              ),
              Semantics(
                label: AppStrings.jobBoardFilterLabel,
                button: true,
                child: IconButton(
                  icon: const Icon(Icons.tune, color: AppColors.purple700),
                  onPressed: onFilterTap,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
            ],
          ),
          filled: true,
          fillColor: theme.cardColor,
          contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            borderSide: const BorderSide(color: AppColors.onboardingDivider),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            borderSide: const BorderSide(color: AppColors.onboardingDivider),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            borderSide: const BorderSide(color: AppColors.purple700, width: 2),
          ),
        ),
      ),
    );
  }
}
