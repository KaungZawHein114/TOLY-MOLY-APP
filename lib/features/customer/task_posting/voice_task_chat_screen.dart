import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/task_posting_strings.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/ai_service.dart';
import '../../../core/widgets/mascot/mascot_state.dart';
import '../../../core/widgets/mascot/pho_wa_yoke.dart';
import 'task_media_picker.dart';
import 'task_posting_models.dart';
import 'task_posting_state.dart';

/// AI Task Assistant — the conversational half of the posting flow. A real,
/// multi-turn AI conversation (`AiService.taskAssistant`, backed by
/// `backend/apps/tasks`' `POST /api/tasks/ai/analyze`), with a local
/// fallback engine that takes over seamlessly if the backend is ever
/// unreachable — see `ai_mock.dart`'s `taskAssistantFallbackTurn`. This is a
/// SEPARATE agent from the floating App Assistant; it never shares a prompt,
/// endpoint, or client with it.
///
/// Stages: Collecting (one question at a time) → Confirming (Yes/No chips
/// on a natural-language recap) → Media (optional, existing
/// [TaskMediaPicker]) → hand off to the existing, unmodified Summary screen.
/// Every collected field lands in the same [taskDraftProvider] the manual
/// steps write to, so Summary is the identical screen either method reaches.
///
/// The mic is demo-only by design (not a placeholder for later real speech
/// input): tapping it always hands back one fixed canned line, which then
/// flows into the exact same pipeline as typed text — text is the one real,
/// dynamic input surface here.
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

enum _Stage { collecting, confirming, media, handoff }

// Demo pacing — long enough to read as deliberate, short enough not to stall.
const _kListeningDuration = Duration(milliseconds: 1400);
const _kWrapUpDuration = Duration(milliseconds: 1300);

class _VoiceTaskChatScreenState extends ConsumerState<VoiceTaskChatScreen> {
  final List<_Turn> _turns = [];
  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();
  final List<Timer> _timers = [];

  _Stage _stage = _Stage.collecting;
  bool _listening = false;
  bool _thinking = false;
  bool _handoffStarted = false;

  /// The running merged-fields map — same shape the backend/fallback both
  /// use: {category, title, description, township, address, date, time,
  /// urgency, category_fields}.
  Map<String, dynamic> _fields = {};

  /// Turns already sent to the backend/fallback, oldest first — NOT
  /// including the opening greeting (a fixed UI line, not something either
  /// side needs echoed back for context).
  final List<Map<String, String>> _history = [];

  int _questionsAsked = 0;

  /// Sticky once the backend fails once — no per-turn retries for the rest
  /// of this conversation (design doc §10: flapping between live and
  /// fallback mid-conversation would read as inconsistent, worse than just
  /// staying local).
  bool _usingFallback = false;

  @override
  void initState() {
    super.initState();
    _turns.add(const _Turn.ai(TaskPostingStrings.taskAssistantGreeting));
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

  bool get _busy => _listening || _thinking || _handoffStarted;

  /// Mock mic: pulse for a beat, then "hear" the one fixed demo line —
  /// see the class doc comment for why this is deliberately not real STT.
  void _startListening() {
    if (_busy || _stage != _Stage.collecting) return;
    HapticFeedback.mediumImpact();
    setState(() => _listening = true);
    _after(_kListeningDuration, () {
      setState(() => _listening = false);
      _submit(TaskPostingStrings.taskAssistantMicTranscript);
    });
  }

  Future<void> _submit(String answer) async {
    final text = answer.trim();
    if (text.isEmpty || _busy || _stage != _Stage.collecting) return;

    _input.clear();
    setState(() {
      _turns.add(_Turn.user(text));
      _thinking = true;
    });
    _scrollToBottom();

    final questionNumber = _questionsAsked;
    _questionsAsked++;

    final reply = _usingFallback
        ? await AiService.taskAssistantOffline(
            message: text,
            knownFields: _fields,
            questionsAsked: questionNumber,
          )
        : await AiService.taskAssistant(
            message: text,
            history: _history,
            knownFields: _fields,
            questionsAsked: questionNumber,
          );
    if (!mounted) return;

    if (!_usingFallback && reply.source == AiSource.demo) {
      _usingFallback = true; // sticky — see class field doc comment
    }
    _history
      ..add({'role': 'user', 'content': text})
      ..add({'role': 'assistant', 'content': reply.reply});
    _fields = reply.fields;
    _applyFieldsToDraft(_fields);

    setState(() {
      _thinking = false;
      _turns.add(_Turn.ai(reply.reply));
      _stage = reply.ready ? _Stage.confirming : _Stage.collecting;
    });
    _scrollToBottom();
  }

  /// Maps the assistant's merged fields onto the shared [TaskDraft]. Budget
  /// and tasker level are deliberately never touched here — those stay a
  /// separate step after this conversation, same as the locked design.
  void _applyFieldsToDraft(Map<String, dynamic> fields) {
    final notifier = ref.read(taskDraftProvider.notifier);
    final draft = ref.read(taskDraftProvider);

    DateTime? date;
    final rawDate = fields['date'] as String?;
    if (rawDate != null && rawDate != 'flexible') {
      date = DateTime.tryParse(rawDate);
    }
    final rawTime = fields['time'] as String?;

    final categoryFields =
        (fields['category_fields'] as Map?)?.cast<String, dynamic>() ??
            const {};
    final detail = categoryFields['detail'] as String?;
    var description = fields['description'] as String?;
    if (detail != null &&
        detail.trim().isNotEmpty &&
        (description == null || !description.contains(detail))) {
      description = (description == null || description.isEmpty)
          ? detail
          : '$description $detail';
    }

    notifier.state = draft.copyWith(
      category: fields['category'] as String?,
      title: fields['title'] as String?,
      description: description,
      taskType: TaskType.onSite,
      township: fields['township'] as String?,
      address: fields['address'] as String?,
      date: date,
      timeSlot: rawTime,
      urgent: fields['urgency'] == 'URGENT'
          ? true
          : (fields['urgency'] == 'NORMAL' ? false : null),
    );
  }

  /// "Yes, that's right" — move on to the optional media step.
  void _confirmYes() {
    if (_busy || _stage != _Stage.confirming) return;
    setState(() {
      _turns.add(const _Turn.ai(TaskPostingStrings.taskAssistantMediaPrompt));
      _stage = _Stage.media;
    });
    _scrollToBottom();
  }

  /// "No, let me change something" — drop back into Collecting; the user's
  /// next message is sent as a correction through the same pipeline.
  void _confirmNo() {
    if (_busy || _stage != _Stage.confirming) return;
    setState(() {
      _turns.add(const _Turn.user(TaskPostingStrings.taskAssistantConfirmNo));
      _turns.add(const _Turn.ai(TaskPostingStrings.taskAssistantConfirmNoPrompt));
      _stage = _Stage.collecting;
    });
    _scrollToBottom();
  }

  /// Media step done (Skip or Continue both call this) — hand off to Summary.
  void _finishMedia() {
    if (_handoffStarted) return;
    setState(() {
      _handoffStarted = true;
      _turns.add(const _Turn.ai(TaskPostingStrings.taskAssistantWrapUpMessage));
      _stage = _Stage.handoff;
    });
    _scrollToBottom();
    _after(_kWrapUpDuration, () => context.push(Routes.postTaskReview));
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
        ..add(const _Turn.ai(TaskPostingStrings.taskAssistantGreeting));
      _fields = {};
      _history.clear();
      _questionsAsked = 0;
      _usingFallback = false;
      _stage = _Stage.collecting;
      _listening = false;
      _thinking = false;
      _handoffStarted = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final media = ref.watch(taskDraftProvider.select((d) => d.media));

    return Scaffold(
      backgroundColor: AppColors.lightBg,
      appBar: AppBar(
        title: const Text(TaskPostingStrings.voiceChatTitle),
        actions: [
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
            if (_stage == _Stage.confirming && !_busy)
              _QuickReplies(
                replies: const [
                  TaskPostingStrings.taskAssistantConfirmYes,
                  TaskPostingStrings.taskAssistantConfirmNo,
                ],
                onTap: (reply) => reply == TaskPostingStrings.taskAssistantConfirmYes
                    ? _confirmYes()
                    : _confirmNo(),
              ),
            if (_stage == _Stage.media) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.sm),
                child: TaskMediaPicker(
                  items: media,
                  onChanged: (next) => ref.read(taskDraftProvider.notifier).state =
                      ref.read(taskDraftProvider).copyWith(media: next),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.md),
                child: FilledButton(
                  onPressed: _busy ? null : _finishMedia,
                  child: Text(media.isEmpty
                      ? TaskPostingStrings.mediaSkipButton
                      : TaskPostingStrings.taskAssistantMediaContinue),
                ),
              ),
            ],
            if (_stage == _Stage.collecting)
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
