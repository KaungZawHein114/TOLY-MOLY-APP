import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../../../core/theme/app_colors.dart';

/// Real microphone recording (unlike core/widgets/onboarding/
/// speech_to_text_button.dart, which is a Phase-1 mock that returns a
/// canned transcript). Records to a temp .m4a file and hands the raw bytes
/// to [onRecorded] once the user taps again to stop.
class VoiceRecordButton extends StatefulWidget {
  final ValueChanged<List<int>> onRecorded;
  final bool large;

  const VoiceRecordButton({super.key, required this.onRecorded, this.large = false});

  @override
  State<VoiceRecordButton> createState() => _VoiceRecordButtonState();
}

class _VoiceRecordButtonState extends State<VoiceRecordButton> {
  final AudioRecorder _recorder = AudioRecorder();
  bool _isRecording = false;
  bool _isProcessing = false;

  @override
  void dispose() {
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_isProcessing) return;
    if (_isRecording) {
      await _stop();
    } else {
      await _start();
    }
  }

  Future<void> _start() async {
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Microphone permission is required to record.")),
      );
      return;
    }
    final tempDir = await getTemporaryDirectory();
    final path = "${tempDir.path}/task_voice_${DateTime.now().millisecondsSinceEpoch}.m4a";
    await _recorder.start(const RecordConfig(encoder: AudioEncoder.aacLc), path: path);
    if (!mounted) return;
    setState(() => _isRecording = true);
  }

  Future<void> _stop() async {
    setState(() {
      _isRecording = false;
      _isProcessing = true;
    });
    final path = await _recorder.stop();
    if (path != null) {
      final bytes = await File(path).readAsBytes();
      widget.onRecorded(bytes);
    }
    if (mounted) setState(() => _isProcessing = false);
  }

  @override
  Widget build(BuildContext context) {
    final dimension = widget.large ? 88.0 : 56.0;
    final label = _isRecording ? "Stop recording" : "Record voice message";
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
            onTap: _isProcessing ? null : _toggle,
            child: Container(
              width: dimension,
              height: dimension,
              decoration: BoxDecoration(
                gradient: _isRecording ? null : AppColors.purpleGradient,
                color: _isRecording ? AppColors.error : null,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: _isProcessing
                  ? SizedBox(
                      width: dimension * 0.4,
                      height: dimension * 0.4,
                      child: const CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.onBrand),
                    )
                  : Icon(
                      _isRecording ? Icons.stop_rounded : Icons.mic_rounded,
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
