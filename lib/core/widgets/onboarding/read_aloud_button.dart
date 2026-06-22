import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../constants/onboarding_strings.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';

/// Mock read-aloud control. TTS is not wired up in the offline MVP — tapping
/// gives haptic + visual confirmation so the affordance is still demonstrable.
/// A brief one-shot pulse on tap stands in for "speaking" feedback.
class ReadAloudButton extends StatefulWidget {
  final String textToRead;

  const ReadAloudButton({super.key, required this.textToRead});

  @override
  State<ReadAloudButton> createState() => _ReadAloudButtonState();
}

class _ReadAloudButtonState extends State<ReadAloudButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController = AnimationController(
    vsync: this,
    duration: AppMotion.fast,
  )..addStatusListener((status) {
      if (status == AnimationStatus.completed) _pulseController.reverse();
    });

  late final Animation<double> _scale = Tween<double>(begin: 1.0, end: 1.15)
      .animate(CurvedAnimation(parent: _pulseController, curve: AppMotion.enter));

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _handleTap() {
    HapticFeedback.lightImpact();
    _pulseController.forward(from: 0);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "${OnboardingStrings.mockReadingAloudMessage} ${widget.textToRead}",
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: AppColors.purple700,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: OnboardingStrings.readAloudButton,
      child: Semantics(
        label: "${OnboardingStrings.readAloudButton}: ${widget.textToRead}",
        button: true,
        child: Material(
          color: AppColors.purple100,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: _handleTap,
            child: AnimatedBuilder(
              animation: _scale,
              builder: (context, child) =>
                  Transform.scale(scale: _scale.value, child: child),
              child: const SizedBox(
                width: 56,
                height: 56,
                child: Icon(Icons.volume_up_rounded,
                    color: AppColors.purple700, size: AppSizes.iconLg),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
