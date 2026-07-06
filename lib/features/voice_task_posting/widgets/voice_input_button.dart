import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../../../core/theme/app_colors.dart';

/// Large, on-device speech-to-text button for the voice task flow.
///
/// Separate from ai_task_posting's VoiceRecordButton (which hard-forces
/// Burmese): this one defaults to ENGLISH for the current testing phase, but
/// the locale is a parameter, so switching the whole flow to Burmese later is
/// a one-line change at the call site — no rewrite here.
///
/// Recognized words stream back live via [onPartialResult] as the user speaks,
/// and the final transcript via [onFinalResult] once they stop.
class VoiceInputButton extends StatefulWidget {
  final ValueChanged<String> onPartialResult;
  final ValueChanged<String> onFinalResult;

  /// Preferred spoken-language candidates, in the form device engines report
  /// them. The first one actually installed on the phone wins; if none match,
  /// the device's default recognizer locale is used.
  final List<String> localeCandidates;
  final bool large;

  const VoiceInputButton({
    super.key,
    required this.onPartialResult,
    required this.onFinalResult,
    this.localeCandidates = const ['en_US', 'en-US', 'en_GB', 'en-GB', 'en'],
    this.large = true,
  });

  @override
  State<VoiceInputButton> createState() => _VoiceInputButtonState();
}

class _VoiceInputButtonState extends State<VoiceInputButton> {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  bool _busy = false; // a start/stop op is in flight (drives the spinner)
  bool _available = false; // initialize() has succeeded at least once
  String? _resolvedLocaleId;

  @override
  void dispose() {
    _speech.cancel();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_busy) return;

    // Already recording -> stop.
    if (_speech.isListening) {
      try {
        await _speech.stop();
      } catch (_) {}
      if (mounted) setState(() => _isListening = false);
      return;
    }

    setState(() => _busy = true);
    var started = false;
    try {
      // Initialize once (retry until it works). EVERY await here is bounded by
      // a timeout so a stalled speech service can't freeze the button — an
      // un-bounded call was what left the spinner (and the whole button)
      // stuck earlier. The first initialize() also pops the mic permission.
      if (!_available) {
        _available = await _speech
            .initialize(onStatus: _onStatus, onError: _onError)
            .timeout(const Duration(seconds: 10), onTimeout: () => false);
      }
      if (!mounted) return;
      if (!_available) {
        _showSnack('မိုက်ကို ဖွင့်၍မရပါ။ မိုက်ခွင့်ပြုချက်ပေးထားပြီး ထပ်နှိပ်ကြည့်ပါ။');
        return;
      }

      // Resolve the preferred language once; null = device default recognizer.
      _resolvedLocaleId ??= await _resolveLocaleId()
          .timeout(const Duration(seconds: 5), onTimeout: () => null);

      // Flip to the red "listening" state and clear the spinner BEFORE awaiting
      // listen() — capturing can run for many seconds (words stream in via
      // onResult), and the button must stay tappable to stop. onStatus flips
      // back to the mic icon when the recognizer stops on its own.
      started = true;
      if (mounted) {
        setState(() {
          _busy = false;
          _isListening = true;
        });
      }

      await _speech.listen(
        onResult: (result) {
          if (result.finalResult) {
            widget.onFinalResult(result.recognizedWords);
          } else {
            widget.onPartialResult(result.recognizedWords);
          }
        },
        listenOptions: stt.SpeechListenOptions(
          localeId: _resolvedLocaleId,
          partialResults: true,
          cancelOnError: true,
          listenFor: const Duration(seconds: 30),
          pauseFor: const Duration(seconds: 5),
        ),
      );
    } catch (e) {
      if (mounted) setState(() => _isListening = false);
      _showSnack('အသံဖမ်းယူ၍ မရပါ — $e');
    } finally {
      // If we bailed before listening started, make sure the spinner clears.
      if (mounted && !started) setState(() => _busy = false);
    }
  }

  // Keep the icon in sync with the recognizer's REAL state — it stops on its
  // own after a pause, and the mic icon (not the red stop) should reflect that
  // without the user having to tap again.
  void _onStatus(String status) {
    if (mounted) setState(() => _isListening = _speech.isListening);
  }

  void _onError(SpeechRecognitionError error) {
    if (!mounted) return;
    setState(() => _isListening = false);
    // Only surface real (permanent) failures — e.g. the chosen language pack
    // isn't installed. Transient "no match"/timeout errors are normal and
    // shouldn't nag the user.
    if (error.permanent) {
      _showSnack('အသံအသိအမှတ်ပြုမှု အခက်အခဲ — ${error.errorMsg}');
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<String?> _resolveLocaleId() async {
    final available = await _speech.locales();
    for (final candidate in widget.localeCandidates) {
      for (final locale in available) {
        if (locale.localeId.toLowerCase() == candidate.toLowerCase()) {
          return locale.localeId;
        }
      }
    }
    // Fall back to any English-named locale before giving up on a preference.
    for (final locale in available) {
      if (locale.name.toLowerCase().contains('english')) {
        return locale.localeId;
      }
    }
    return null; // device default recognizer locale
  }

  @override
  Widget build(BuildContext context) {
    final dimension = widget.large ? 96.0 : 56.0;
    final label = _isListening ? 'ရပ်ရန်' : 'ပြောရန် နှိပ်ပါ';
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
            // Never disabled: _toggle guards its own re-entry, so the button
            // can't get stuck un-tappable the way an `onTap: null` gate could.
            onTap: _toggle,
            child: Container(
              width: dimension,
              height: dimension,
              decoration: BoxDecoration(
                gradient: _isListening ? null : AppColors.purpleGradient,
                color: _isListening ? AppColors.error : null,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: _busy
                  ? SizedBox(
                      width: dimension * 0.35,
                      height: dimension * 0.35,
                      child: const CircularProgressIndicator(
                          strokeWidth: 2.5, color: AppColors.onBrand),
                    )
                  : Icon(
                      _isListening ? Icons.stop_rounded : Icons.mic_rounded,
                      color: AppColors.onBrand,
                      size: widget.large ? 44 : 24,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
