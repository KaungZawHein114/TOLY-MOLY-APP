import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/task_posting_strings.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/ai_mock.dart';
import '../../../core/widgets/mascot/mascot_state.dart';
import '../../../core/widgets/mascot/pho_wa_yoke.dart';
import '../../../core/widgets/onboarding/read_aloud_button.dart';
import 'task_posting_models.dart';
import 'task_posting_state.dart';

/// Voice posting — the conversational half of the flow. Pho Wa Yoke walks the
/// scripted questions in [taskVoiceScript]; the client answers by speaking
/// (mock mic), tapping a quick reply, or typing. Every answer lands in the same
/// [taskDraftProvider] the manual steps write to, so the summary screen at the
/// end is the identical screen either flow arrives at.
///
/// DEMO ONLY: there is no speech engine and no model here. The mic is a timed
/// animation that hands back the current question's canned transcript, and the
/// "thinking" pauses are [Timer]s — see `ai_mock.dart` for the script and the
/// keyword extraction behind it.
class VoiceTaskChatScreen extends ConsumerStatefulWidget {
  const VoiceTaskChatScreen({super.key});

  @override
  ConsumerState<VoiceTaskChatScreen> createState() =>
      _VoiceTaskChatScreenState();
}

/// One rendered line of the conversation.
class _Turn {
  final bool fromAi;
  final String text;
  const _Turn.ai(this.text) : fromAi = true;
  const _Turn.user(this.text) : fromAi = false;
}

// Demo pacing — long enough to read as deliberate, short enough not to stall.
const _kListeningDuration = Duration(milliseconds: 1400);
const _kThinkingDuration = Duration(milliseconds: 900);
const _kWrapUpDuration = Duration(milliseconds: 1300);

class _VoiceTaskChatScreenState extends ConsumerState<VoiceTaskChatScreen> {
  final List<_Turn> _turns = [];
  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();
  final List<Timer> _timers = [];

  /// Index into [taskVoiceScript]; equal to its length once every question has
  /// been answered.
  int _step = 0;
  bool _listening = false;
  bool _thinking = false;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    // Open with the first question so the screen is never an empty chat.
    _turns.add(_Turn.ai(taskVoiceScript.first.question));
  }

  @override
  void dispose() {
    for (final t in _timers) {
      t.cancel();
    }
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _after(Duration delay, VoidCallback action) {
    late Timer timer;
    timer = Timer(delay, () {
      _timers.remove(timer);
      if (mounted) action();
    });
    _timers.add(timer);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: AppMotion.medium,
        curve: Curves.easeOut,
      );
    });
  }

  bool get _busy => _listening || _thinking || _finished;

  VoiceTaskQuestion? get _current =>
      _step < taskVoiceScript.length ? taskVoiceScript[_step] : null;

  /// Mock mic: pulse for a beat, then "hear" this question's canned transcript.
  void _startListening() {
    final question = _current;
    if (_busy || question == null) return;
    HapticFeedback.mediumImpact();
    setState(() => _listening = true);
    _after(_kListeningDuration, () {
      setState(() => _listening = false);
      _submit(question.micTranscript);
    });
  }

  void _submit(String answer) {
    final text = answer.trim();
    final question = _current;
    if (text.isEmpty || question == null || _thinking || _finished) return;

    _input.clear();
    setState(() {
      _turns.add(_Turn.user(text));
      _thinking = true;
    });
    _scrollToBottom();

    _apply(question.field, text);

    // A short "thinking" beat, then either the next question or the hand-off.
    _after(_kThinkingDuration, () {
      final next = _step + 1;
      setState(() {
        _thinking = false;
        _step = next;
        if (next < taskVoiceScript.length) {
          _turns.add(_Turn.ai(taskVoiceScript[next].question));
        } else {
          _finished = true;
          _turns.add(const _Turn.ai(voiceTaskWrapUpMessage));
        }
      });
      _scrollToBottom();
      if (_finished) {
        _after(_kWrapUpDuration, () => context.push(Routes.postTaskReview));
      }
    });
  }

  /// Folds one answer into the shared draft. Extraction lives in `ai_mock.dart`
  /// — this only maps the primitives it returns onto [TaskDraft].
  void _apply(VoiceTaskField field, String answer) {
    final notifier = ref.read(taskDraftProvider.notifier);
    final draft = ref.read(taskDraftProvider);
    switch (field) {
      case VoiceTaskField.need:
        final need = voiceTaskNeed(answer);
        notifier.state = draft.copyWith(
          category: need.category,
          title: need.title,
          description: need.description,
        );
      case VoiceTaskField.place:
        final place = voiceTaskPlace(answer);
        notifier.state = draft.copyWith(
          taskType: TaskType.onSite,
          township: place.township,
          address: place.address,
        );
      case VoiceTaskField.schedule:
        final when = voiceTaskSchedule(answer);
        notifier.state =
            draft.copyWith(date: when.date, timeSlot: when.timeSlot);
      case VoiceTaskField.urgency:
        notifier.state = draft.copyWith(urgent: voiceTaskUrgent(answer));
      case VoiceTaskField.tier:
        final tierNumber = voiceTaskTierNumber(answer);
        final updated = draft.copyWith(
          workerTier: WorkerTier.values[tierNumber - 1],
        );
        notifier.state = updated.copyWith(
          budgetMmk: estimateTaskBudgetMmk(
            category: updated.effectiveCategory,
            tierNumber: tierNumber,
            urgent: updated.urgent,
          ),
        );
    }
  }

  /// Start the conversation over — the draft is rebuilt from scratch, so a
  /// misheard answer never needs to be lived with.
  void _restart() {
    for (final t in _timers) {
      t.cancel();
    }
    _timers.clear();
    ref.read(taskDraftProvider.notifier).state = TaskDraft.empty();
    _input.clear();
    setState(() {
      _turns
        ..clear()
        ..add(_Turn.ai(taskVoiceScript.first.question));
      _step = 0;
      _listening = false;
      _thinking = false;
      _finished = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final question = _current;
    final lastAiLine =
        _turns.lastWhere((t) => t.fromAi, orElse: () => const _Turn.ai("")).text;

    return Scaffold(
      backgroundColor: AppColors.lightBg,
      appBar: AppBar(
        title: const Text(TaskPostingStrings.voiceChatTitle),
        actions: [
          ReadAloudButton(textToRead: lastAiLine),
          IconButton(
            onPressed: _restart,
            tooltip: TaskPostingStrings.voiceChatRestart,
            icon: const Icon(Icons.refresh),
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scroll,
                padding: const EdgeInsets.all(AppSpacing.lg),
                itemCount: _turns.length + (_thinking ? 1 : 0),
                itemBuilder: (context, i) {
                  if (i == _turns.length) return const _TypingBubble();
                  return _ChatBubble(turn: _turns[i]);
                },
              ),
            ),
            if (_listening) const _ListeningBanner(),
            // Quick replies keep the demo keyboard-free and give low-literacy
            // users recognition instead of recall.
            if (question != null && !_busy)
              _QuickReplies(
                replies: question.quickReplies,
                onTap: _submit,
              ),
            _InputBar(
              controller: _input,
              enabled: !_busy,
              listening: _listening,
              onMic: _startListening,
              onSend: () => _submit(_input.text),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Text(
                TaskPostingStrings.voiceChatDemoNote,
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One conversation line. Pho Wa Yoke fronts every AI line so the guidance
/// always has a face attached to it.
class _ChatBubble extends StatelessWidget {
  final _Turn turn;
  const _ChatBubble({required this.turn});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bubble = Container(
      constraints:
          BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm + 2),
      decoration: BoxDecoration(
        color: turn.fromAi ? AppColors.blue300 : AppColors.purple700,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Text(
        turn.text,
        style: theme.textTheme.bodyLarge?.copyWith(
          color: turn.fromAi ? AppColors.textPrimary : AppColors.onBrand,
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        mainAxisAlignment:
            turn.fromAi ? MainAxisAlignment.start : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (turn.fromAi) ...[
            const ExcludeSemantics(
              child: PhoWaYoke(state: PhoWaYokeState.happy, size: 40),
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
          Flexible(child: bubble),
        ],
      ),
    );
  }
}

/// The "AI is typing" placeholder — three dots fading in sequence.
class _TypingBubble extends StatefulWidget {
  const _TypingBubble();

  @override
  State<_TypingBubble> createState() => _TypingBubbleState();
}

class _TypingBubbleState extends State<_TypingBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Each dot runs the same fade a third of a cycle behind the one before it.
  double _dotOpacity(int index) {
    final phase = (_controller.value + index / 3) % 1.0;
    final ramp = phase < 0.5 ? phase * 2 : (1 - phase) * 2;
    return 0.35 + 0.65 * ramp;
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: TaskPostingStrings.aiThinking,
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.md),
        child: Row(
          children: [
            const ExcludeSemantics(
              child: PhoWaYoke(state: PhoWaYokeState.thinking, size: 40),
            ),
            const SizedBox(width: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md, vertical: AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.blue300,
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) => Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var i = 0; i < 3; i++)
                      Padding(
                        padding: EdgeInsets.only(right: i == 2 ? 0 : 4),
                        child: Opacity(
                          opacity: _dotOpacity(i),
                          child: const _Dot(),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: const BoxDecoration(
        color: AppColors.indigo700,
        shape: BoxShape.circle,
      ),
    );
  }
}

/// Tappable canned answers for the current question.
class _QuickReplies extends StatelessWidget {
  final List<String> replies;
  final ValueChanged<String> onTap;

  const _QuickReplies({required this.replies, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Align(
      alignment: Alignment.centerLeft,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Row(
          children: [
            for (final reply in replies)
              Padding(
                padding: const EdgeInsets.only(right: AppSpacing.sm),
                child: ActionChip(
                  label: Text(reply, style: theme.textTheme.bodyMedium),
                  backgroundColor: AppColors.indigo100,
                  side: const BorderSide(color: AppColors.indigo100),
                  onPressed: () => onTap(reply),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Shown while the mock mic is "listening" so the pause reads as deliberate.
class _ListeningBanner extends StatelessWidget {
  const _ListeningBanner();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      liveRegion: true,
      label: TaskPostingStrings.voiceChatListening,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.purple100,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.graphic_eq,
                color: AppColors.purple700, size: AppSizes.iconSm),
            const SizedBox(width: AppSpacing.sm),
            Text(TaskPostingStrings.voiceChatListening,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: AppColors.brandPurple)),
          ],
        ),
      ),
    );
  }
}

/// Type-or-speak input row. Both routes feed the same [onSend]/[onMic] pair,
/// so speaking and typing are genuinely the same conversation.
class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;
  final bool listening;
  final VoidCallback onMic;
  final VoidCallback onSend;

  const _InputBar({
    required this.controller,
    required this.enabled,
    required this.listening,
    required this.onMic,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              enabled: enabled,
              style: theme.textTheme.bodyLarge,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSend(),
              decoration: InputDecoration(
                hintText: TaskPostingStrings.voiceChatInputHint,
                filled: true,
                fillColor: AppColors.lightSurface,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          _MicButton(listening: listening, onTap: onMic),
          const SizedBox(width: AppSpacing.xs),
          Semantics(
            label: TaskPostingStrings.voiceChatSendLabel,
            button: true,
            child: IconButton(
              onPressed: enabled ? onSend : null,
              iconSize: AppSizes.iconMd,
              style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
              icon: const Icon(Icons.send_rounded, color: AppColors.purple700),
            ),
          ),
        ],
      ),
    );
  }
}

/// Mock microphone. Matches [SpeechToTextButton]'s look but adds the pulsing
/// "listening" ring the demo needs — nothing is recorded either way.
class _MicButton extends StatefulWidget {
  final bool listening;
  final VoidCallback onTap;

  const _MicButton({required this.listening, required this.onTap});

  @override
  State<_MicButton> createState() => _MicButtonState();
}

class _MicButtonState extends State<_MicButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  @override
  void initState() {
    super.initState();
    if (widget.listening) _pulse.repeat();
  }

  @override
  void didUpdateWidget(covariant _MicButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.listening && !_pulse.isAnimating) {
      _pulse.repeat();
    } else if (!widget.listening && _pulse.isAnimating) {
      _pulse
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: TaskPostingStrings.voiceChatMicPrompt,
      button: true,
      child: Tooltip(
        message: TaskPostingStrings.voiceChatMicPrompt,
        child: SizedBox(
          width: 56,
          height: 56,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Expanding ring — the visual stand-in for "I'm hearing you".
              AnimatedBuilder(
                animation: _pulse,
                builder: (context, _) {
                  if (!widget.listening) return const SizedBox.shrink();
                  return Container(
                    width: 40 + 16 * _pulse.value,
                    height: 40 + 16 * _pulse.value,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.purple700
                          .withValues(alpha: 0.30 * (1 - _pulse.value)),
                    ),
                  );
                },
              ),
              Material(
                color: Colors.transparent,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: widget.onTap,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      gradient: AppColors.purpleGradient,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      widget.listening ? Icons.graphic_eq : Icons.mic_rounded,
                      color: AppColors.onBrand,
                      size: AppSizes.iconMd,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
