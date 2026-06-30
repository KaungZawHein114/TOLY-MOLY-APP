import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../constants/onboarding_strings.dart';
import '../../theme/app_colors.dart';

/// Mock speech-to-text control. Synchronous and offline: tapping immediately
/// hands back a canned transcript instead of recording real audio.
class SpeechToTextButton extends StatelessWidget {
  final String semanticPrompt;
  final ValueChanged<String> onResult;
  final String mockTranscript;
  final bool large;

  // Smaller footprint to sit inline next to a single field's label, next to
  // ReadAloudButton's matching `compact` size — see basic_info_screen.dart.
  final bool compact;

  const SpeechToTextButton({
    super.key,
    required this.semanticPrompt,
    required this.onResult,
    required this.mockTranscript,
    this.large = false,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final dimension = large ? 88.0 : (compact ? 44.0 : 56.0);
    return Tooltip(
      message: semanticPrompt,
      child: Semantics(
        label: semanticPrompt,
        button: true,
        child: Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () {
              HapticFeedback.mediumImpact();
              onResult(mockTranscript);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(OnboardingStrings.mockVoiceCapturedMessage),
                  backgroundColor: AppColors.purple700,
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            child: Container(
              width: dimension,
              height: dimension,
              decoration: const BoxDecoration(
                gradient: AppColors.purpleGradient,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(Icons.mic_rounded,
                  color: AppColors.onBrand, size: large ? 40 : (compact ? 20 : 24)),
            ),
          ),
        ),
      ),
    );
  }
}
