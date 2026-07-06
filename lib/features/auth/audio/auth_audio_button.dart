import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/onboarding_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import 'auth_audio_controller.dart';
import 'auth_audio_map.dart';

/// Speaker button for the AUTH (onboarding) flow that plays a pre-recorded
/// clip from `recordings/auth/` instead of using the device TTS engine.
///
/// It is a visual twin of `ReadAloudButton` (same size, compact variant, pulse
/// on tap, and playing-state color swap) so the two can stand in for each other
/// without any layout change — auth screens use this, the rest of the app keeps
/// `ReadAloudButton`.
///
/// Behaviour:
/// - Tap to play; tap again (while playing) to stop.
/// - Only one auth clip is ever audible — starting one stops any other, via
///   the shared [AuthAudioController].
/// - Shows a stop icon + highlight while its own clip is playing.
/// - If [audioKey] has no recording in [authAudioMap], the button renders
///   nothing (an empty box) — no dead control, no TTS fallback.
class AuthAudioButton extends StatefulWidget {
  /// A key from [AuthAudioKeys]; resolved to a file through [authAudioMap].
  final String audioKey;

  /// Optional label spoken by screen readers instead of the generic one (e.g.
  /// the field label the button sits next to).
  final String? semanticLabel;

  /// Smaller footprint (44px) to sit inline next to a single field's label,
  /// matching `ReadAloudButton(compact: true)`.
  final bool compact;

  const AuthAudioButton({
    super.key,
    required this.audioKey,
    this.semanticLabel,
    this.compact = false,
  });

  @override
  State<AuthAudioButton> createState() => _AuthAudioButtonState();
}

class _AuthAudioButtonState extends State<AuthAudioButton>
    with SingleTickerProviderStateMixin {
  final AuthAudioController _controller = AuthAudioController.instance;

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
    _controller.toggle(widget.audioKey);
  }

  @override
  Widget build(BuildContext context) {
    // No recording for this key yet → show nothing rather than a dead button.
    if (!authAudioHasKey(widget.audioKey)) return const SizedBox.shrink();

    final dimension = widget.compact ? 44.0 : 56.0;
    final iconSize = widget.compact ? AppSizes.iconMd : AppSizes.iconLg;
    final semantics = widget.semanticLabel == null
        ? OnboardingStrings.readAloudButton
        : '${OnboardingStrings.readAloudButton}: ${widget.semanticLabel}';

    // Rebuild the icon/highlight whenever shared playback state changes.
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final isPlaying = _controller.isPlaying(widget.audioKey);
        return Tooltip(
          message: OnboardingStrings.readAloudButton,
          child: Semantics(
            label: semantics,
            button: true,
            child: Material(
              color: isPlaying ? AppColors.indigo100 : AppColors.purple100,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: _handleTap,
                child: AnimatedBuilder(
                  animation: _scale,
                  builder: (context, child) =>
                      Transform.scale(scale: _scale.value, child: child),
                  child: SizedBox(
                    width: dimension,
                    height: dimension,
                    child: Icon(
                      isPlaying ? Icons.stop_rounded : Icons.volume_up_rounded,
                      color: isPlaying ? AppColors.indigo700 : AppColors.purple700,
                      size: iconSize,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
