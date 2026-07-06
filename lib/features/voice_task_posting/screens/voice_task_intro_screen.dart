import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/large_button.dart';
import '../../../core/widgets/mascot/mascot_message_card.dart';
import '../../../core/widgets/mascot/mascot_state.dart';
import '../../../core/widgets/onboarding/read_aloud_button.dart';
import '../data/voice_task_api.dart';
import '../voice_task_state.dart';
import '../widgets/voice_input_button.dart';

// Burmese-first guidance kept local to the feature (mirrors ai_task_posting,
// which also holds its screen copy inline rather than in the shared strings).
const _kAppBarTitle = 'အသံဖြင့် အလုပ်တင်ရန်';
const _kPrompt =
    'ဘာအကူအညီ လိုအပ်ပါသလဲ။ အောက်ကမိုက်ခလုတ်ကို နှိပ်ပြီး သင်လိုချင်တာကို ပြောပြပါ။';
const _kAnalyzingMsg = 'ခဏလေး စောင့်ပါနော်… သင်ပြောခဲ့တာတွေကို စီစစ်နေပါတယ်။';
const _kMicHelper = 'မိုက်ကို နှိပ်ပြီး ပြောပါ (ယခု အင်္ဂလိပ်ဘာသာဖြင့် စမ်းသပ်နေသည်)';
const _kTranscriptLabel = 'သင်ပြောခဲ့သော စကား';
const _kTranscriptHint =
    'ဥပမာ — "My kitchen sink is leaking, I need a plumber tomorrow morning, budget around 15000 kyat"';
const _kAnalyzeLabel = 'AI ဖြင့် ဆက်လုပ်မည်';
const _kAnalyzingLabel = 'စီစစ်နေသည်…';
const _kEmptyError = 'ကျေးဇူးပြု၍ အရင်ဆုံး သင်လိုချင်တာကို ပြောပြပါ။';

/// Step 1 of the voice task flow: the client dictates (or types) what they
/// need in one go. The mic streams live text into the field; "Analyze" sends
/// the whole thing to the backend for one-shot AI extraction, then hands off
/// to the review screen. No back-and-forth questions — that's the whole point.
class VoiceTaskIntroScreen extends ConsumerStatefulWidget {
  const VoiceTaskIntroScreen({super.key});

  @override
  ConsumerState<VoiceTaskIntroScreen> createState() =>
      _VoiceTaskIntroScreenState();
}

class _VoiceTaskIntroScreenState extends ConsumerState<VoiceTaskIntroScreen> {
  final TextEditingController _transcript = TextEditingController();
  bool _isAnalyzing = false;
  String? _error;

  @override
  void dispose() {
    _transcript.dispose();
    super.dispose();
  }

  // Keep the caret at the end so live speech reads naturally as it streams in.
  void _setTranscript(String words) {
    setState(() {
      _transcript.value = TextEditingValue(
        text: words,
        selection: TextSelection.collapsed(offset: words.length),
      );
    });
  }

  void _onFinal(String words) {
    if (words.trim().isEmpty) return;
    _setTranscript(words);
  }

  Future<void> _analyze() async {
    if (_isAnalyzing) return;
    final text = _transcript.text.trim();
    if (text.isEmpty) {
      setState(() => _error = _kEmptyError);
      return;
    }
    setState(() {
      _isAnalyzing = true;
      _error = null;
    });
    try {
      final result = await ref.read(voiceTaskApiProvider).extract(text);
      ref.read(voiceDraftProvider.notifier).state = result;
      if (!mounted) return;
      context.push(Routes.voiceTaskReview);
    } on VoiceTaskFailure catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text(_kAppBarTitle),
        actions: [
          ReadAloudButton(textToRead: _isAnalyzing ? _kAnalyzingMsg : _kPrompt),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  MascotMessageCard(
                    state: _isAnalyzing
                        ? PhoWaYokeState.thinking
                        : PhoWaYokeState.pointing,
                    message: _isAnalyzing ? _kAnalyzingMsg : _kPrompt,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Center(
                    child: VoiceInputButton(
                      onPartialResult: _setTranscript,
                      onFinalResult: _onFinal,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Center(
                    child: Text(
                      _kMicHelper,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: AppColors.textSecondary),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text(_kTranscriptLabel, style: theme.textTheme.titleMedium),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: _transcript,
                    minLines: 3,
                    maxLines: 6,
                    enabled: !_isAnalyzing,
                    style: theme.textTheme.bodyLarge,
                    decoration: InputDecoration(
                      hintText: _kTranscriptHint,
                      filled: true,
                      fillColor: AppColors.blue100,
                      contentPadding: const EdgeInsets.all(AppSpacing.lg),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    Text(_error!, style: const TextStyle(color: AppColors.error)),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: LargeButton(
                label: _isAnalyzing ? _kAnalyzingLabel : _kAnalyzeLabel,
                icon: _isAnalyzing ? null : Icons.auto_awesome,
                gradient: AppColors.purpleGradient,
                onTap: _analyze,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
