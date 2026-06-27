import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../../constants/onboarding_strings.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';

/// Real read-aloud control using the device Text-To-Speech engine.
///
/// Note: Burmese voice support depends on the user's device TTS engine and
/// installed language packs. If Burmese is not installed on the phone, the
/// button may not speak Burmese correctly until the user installs/enables it.
class ReadAloudButton extends StatefulWidget {
  final String textToRead;

  // Smaller footprint for tight grid cells (e.g. category cards). The tap
  // target is kept at 44px for compact places already used in the app.
  final bool compact;

  const ReadAloudButton({
    super.key,
    required this.textToRead,
    this.compact = false,
  });

  @override
  State<ReadAloudButton> createState() => _ReadAloudButtonState();
}

class _ReadAloudButtonState extends State<ReadAloudButton>
    with SingleTickerProviderStateMixin {
  final FlutterTts _flutterTts = FlutterTts();

  bool _isSpeaking = false;
  bool _isConfigured = false;

  late final AnimationController _pulseController = AnimationController(
    vsync: this,
    duration: AppMotion.fast,
  )..addStatusListener((status) {
    if (status == AnimationStatus.completed) _pulseController.reverse();
  });

  late final Animation<double> _scale = Tween<double>(begin: 1.0, end: 1.15)
      .animate(CurvedAnimation(parent: _pulseController, curve: AppMotion.enter));

  Future<void> _configureTts() async {
    if (_isConfigured) return;

    await _flutterTts.awaitSpeakCompletion(true);
    await _flutterTts.setLanguage('my-MM');
    await _flutterTts.setSpeechRate(0.55);
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setVolume(1.0);

    _flutterTts.setStartHandler(() {
      if (mounted) setState(() => _isSpeaking = true);
    });

    _flutterTts.setCompletionHandler(() {
      if (mounted) setState(() => _isSpeaking = false);
    });

    _flutterTts.setCancelHandler(() {
      if (mounted) setState(() => _isSpeaking = false);
    });

    _flutterTts.setErrorHandler((_) {
      if (mounted) setState(() => _isSpeaking = false);
    });

    _isConfigured = true;
  }

  Future<void> _handleTap() async {
    final text = widget.textToRead.trim();
    if (text.isEmpty) return;

    HapticFeedback.lightImpact();
    _pulseController.forward(from: 0);

    try {
      if (_isSpeaking) {
        await _flutterTts.stop();
        if (mounted) setState(() => _isSpeaking = false);
        return;
      }

      await _configureTts();
      await _flutterTts.speak(text);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSpeaking = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('အသံဖတ်ပြရန် မအောင်မြင်ပါ။ ဖုန်း၏ Text-to-Speech setting ကို စစ်ပါ။'),
          backgroundColor: AppColors.error,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  void dispose() {
    _flutterTts.stop();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dimension = widget.compact ? 44.0 : 56.0;
    final iconSize = widget.compact ? AppSizes.iconMd : AppSizes.iconLg;

    return Tooltip(
      message: OnboardingStrings.readAloudButton,
      child: Semantics(
        label: '${OnboardingStrings.readAloudButton}: ${widget.textToRead}',
        button: true,
        child: Material(
          color: _isSpeaking ? AppColors.indigo100 : AppColors.purple100,
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
                  _isSpeaking ? Icons.stop_rounded : Icons.volume_up_rounded,
                  color: _isSpeaking ? AppColors.indigo700 : AppColors.purple700,
                  size: iconSize,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
