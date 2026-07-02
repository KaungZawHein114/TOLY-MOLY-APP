import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../../../core/theme/app_colors.dart';

/// On-device speech recognition (the OS's Google speech service on Android)
/// instead of recording audio and uploading it to the backend's Whisper
/// endpoint. Recognized words are streamed back live via [onPartialResult]
/// as the user speaks, and the final transcript via [onFinalResult] once
/// they stop — the caller shows that text directly as the chat message.
class VoiceRecordButton extends StatefulWidget {
  final ValueChanged<String> onPartialResult;
  final ValueChanged<String> onFinalResult;
  final bool large;

  const VoiceRecordButton({
    super.key,
    required this.onPartialResult,
    required this.onFinalResult,
    this.large = false,
  });

  @override
  State<VoiceRecordButton> createState() => _VoiceRecordButtonState();
}

// Candidate locale ids for Burmese, in the form the device's speech engine
// reports them — varies by OS/vendor, so we try a few known spellings
// rather than assume one.
const _burmeseLocaleCandidates = ["my_MM", "my-MM", "my_MY", "my-MY", "my"];

class _VoiceRecordButtonState extends State<VoiceRecordButton> {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  bool _isInitializing = false;
  String? _burmeseLocaleId;

  @override
  void dispose() {
    _speech.stop();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_isInitializing) return;
    if (_isListening) {
      await _speech.stop();
      if (mounted) setState(() => _isListening = false);
      return;
    }

    setState(() => _isInitializing = true);
    final available = await _speech.initialize(
      onStatus: (status) {
        if (status == "done" || status == "notListening") {
          if (mounted) setState(() => _isListening = false);
        }
      },
      onError: (_) {
        if (mounted) setState(() => _isListening = false);
      },
    );
    if (!mounted) return;
    setState(() => _isInitializing = false);

    if (!available) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Speech recognition isn't available on this device.")),
      );
      return;
    }

    _burmeseLocaleId ??= await _resolveBurmeseLocaleId();
    if (_burmeseLocaleId == null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "ဖုန်း၏ အသံအသိအမှတ်ပြုစနစ်တွင် မြန်မာဘာသာ မပါရှိပါ။ "
            "Settings > System > Languages တွင် မြန်မာဘာသာ ထည့်ပေးပါ။",
          ),
        ),
      );
    }

    setState(() => _isListening = true);
    await _speech.listen(
      onResult: (result) {
        if (result.finalResult) {
          widget.onFinalResult(result.recognizedWords);
        } else {
          widget.onPartialResult(result.recognizedWords);
        }
      },
      listenOptions: stt.SpeechListenOptions(localeId: _burmeseLocaleId),
    );
  }

  Future<String?> _resolveBurmeseLocaleId() async {
    final available = await _speech.locales();
    for (final candidate in _burmeseLocaleCandidates) {
      for (final locale in available) {
        if (locale.localeId.toLowerCase() == candidate.toLowerCase()) {
          return locale.localeId;
        }
      }
    }
    // Some engines report a Burmese-script display name with a non-obvious
    // localeId — fall back to matching on that instead of giving up.
    for (final locale in available) {
      if (locale.name.contains("Burmese") || locale.name.contains("မြန်မာ")) {
        return locale.localeId;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final dimension = widget.large ? 88.0 : 56.0;
    final label = _isListening ? "Stop listening" : "Speak your message";
    return Tooltip(
      message: label,
      child: Semantics(
        label: label,
        button: true,
        child: Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: _isInitializing ? null : _toggle,
            child: Container(
              width: dimension,
              height: dimension,
              decoration: BoxDecoration(
                gradient: _isListening ? null : AppColors.purpleGradient,
                color: _isListening ? AppColors.error : null,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: _isInitializing
                  ? SizedBox(
                      width: dimension * 0.4,
                      height: dimension * 0.4,
                      child: const CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.onBrand),
                    )
                  : Icon(
                      _isListening ? Icons.stop_rounded : Icons.mic_rounded,
                      color: AppColors.onBrand,
                      size: widget.large ? 40 : 24,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
