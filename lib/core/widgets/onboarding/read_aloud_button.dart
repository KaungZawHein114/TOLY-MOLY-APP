import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../constants/onboarding_strings.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';

/// Mock read-aloud control. TTS is not wired up in the offline MVP — tapping
/// gives haptic + visual confirmation so the affordance is still demonstrable.
class ReadAloudButton extends StatelessWidget {
  final String textToRead;

  const ReadAloudButton({super.key, required this.textToRead});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: OnboardingStrings.readAloudButton,
      child: Semantics(
        label: "${OnboardingStrings.readAloudButton}: $textToRead",
        button: true,
        child: Material(
          color: AppColors.purple100,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () {
              HapticFeedback.lightImpact();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    "${OnboardingStrings.mockReadingAloudMessage} $textToRead",
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  backgroundColor: AppColors.purple700,
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            child: const SizedBox(
              width: 56,
              height: 56,
              child: Icon(Icons.volume_up_rounded,
                  color: AppColors.purple700, size: AppSizes.iconLg),
            ),
          ),
        ),
      ),
    );
  }
}
