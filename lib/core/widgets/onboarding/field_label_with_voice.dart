import 'package:flutter/material.dart';

import '../../theme/app_spacing.dart';
import 'read_aloud_button.dart';
import 'speech_to_text_button.dart';

/// A field's label plus its own listen and speak controls — used instead of
/// one read-aloud/speak pair for the whole screen, so a user who can't read
/// or write can act on each field independently.
class FieldLabelWithVoice extends StatelessWidget {
  final String label;
  final String readAloudText;
  final String? mockTranscript;
  final ValueChanged<String>? onSpeechResult;

  // Password and other sensitive fields skip the speak control — dictating
  // a password out loud defeats the point of it being hidden.
  bool get _showSpeech => mockTranscript != null && onSpeechResult != null;

  const FieldLabelWithVoice({
    super.key,
    required this.label,
    required this.readAloudText,
    this.mockTranscript,
    this.onSpeechResult,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(child: Text(label, style: theme.textTheme.titleMedium)),
        ReadAloudButton(textToRead: readAloudText, compact: true),
        if (_showSpeech) ...[
          const SizedBox(width: AppSpacing.sm),
          SpeechToTextButton(
            semanticPrompt: label,
            mockTranscript: mockTranscript!,
            onResult: onSpeechResult!,
            compact: true,
          ),
        ],
      ],
    );
  }
}
