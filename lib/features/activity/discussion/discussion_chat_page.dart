import 'package:flutter/material.dart';
// For ScrollCacheExtent, which material.dart does not re-export.
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../activity_chat.dart';
import 'discussion_models.dart';
import 'discussion_state.dart';
import 'widgets/chat_bubble.dart';
import 'widgets/expandable_question_menu.dart';
import 'widgets/mascot_guide.dart';
import 'widgets/question_bubble.dart';
import 'widgets/task_detail_sheet.dart';

// ---------------------------------------------------------------------------
// CONVERSATION — one page, two states of the same task.
//
// [ConversationMode.discussion] settles the details before payment;
// [ConversationMode.progress] takes over once the client has paid and the
// tasker is on the way. Same page, same bubbles, same menu — the mode only
// picks which timeline, which suggested questions, and which bar sits under
// the chat. Both roles read the same timeline and see it from their own side.
//
// Two people chatting, with the app quietly helping: the tasker's questions
// arrive as normal bubbles you can answer with one tap, and the client picks
// questions from a list instead of composing them. Everything that matters is
// still recorded — it just doesn't look like paperwork.
//
// Phase-1 safe: shared StateProviders, synchronous scripted replies, and the
// only `await`s are Flutter's own sheets.
// ---------------------------------------------------------------------------

/// Opens the pre-payment discussion. Kept as a modal sheet so every existing
/// entry point (Sar To Myar list, activity list, booking card) works unchanged.
void openDiscussionChatPage(
  BuildContext context, {
  required ActivityRole role,
  required String counterpartName,
  required String counterpartEmoji,
}) =>
    _openConversation(
      context,
      role: role,
      counterpartName: counterpartName,
      counterpartEmoji: counterpartEmoji,
      mode: ConversationMode.discussion,
    );

/// Opens the post-payment conversation for a task that is already agreed.
/// [fixedTask] is the job this thread belongs to when it isn't the live one.
void openProgressChatPage(
  BuildContext context, {
  required ActivityRole role,
  required String counterpartName,
  required String counterpartEmoji,
  DiscussionTask? fixedTask,
}) =>
    _openConversation(
      context,
      role: role,
      counterpartName: counterpartName,
      counterpartEmoji: counterpartEmoji,
      mode: ConversationMode.progress,
      fixedTask: fixedTask,
    );

void _openConversation(
  BuildContext context, {
  required ActivityRole role,
  required String counterpartName,
  required String counterpartEmoji,
  required ConversationMode mode,
  DiscussionTask? fixedTask,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.lightBg,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
    ),
    builder: (_) => DiscussionChatPage(
      role: role,
      counterpartName: counterpartName,
      counterpartEmoji: counterpartEmoji,
      mode: mode,
      fixedTask: fixedTask,
    ),
  );
}

class DiscussionChatPage extends ConsumerStatefulWidget {
  final ActivityRole role;
  final String counterpartName;
  final String counterpartEmoji;
  final ConversationMode mode;

  /// Non-null when this thread is about a task other than the live one.
  final DiscussionTask? fixedTask;

  const DiscussionChatPage({
    super.key,
    required this.role,
    required this.counterpartName,
    required this.counterpartEmoji,
    this.mode = ConversationMode.discussion,
    this.fixedTask,
  });

  @override
  ConsumerState<DiscussionChatPage> createState() => _DiscussionChatPageState();
}

class _DiscussionChatPageState extends ConsumerState<DiscussionChatPage> {
  final ScrollController _scrollCtrl = ScrollController();
  final TextEditingController _textCtrl = TextEditingController();
  final Map<String, GlobalKey> _messageKeys = {};
  bool _guideVisible = true;

  ActivityRole get _role => widget.role;
  ActivityRole get _them => counterpartOf(widget.role);
  bool get _isProgress => widget.mode == ConversationMode.progress;
  MessagesProvider get _messages => messagesProviderFor(widget.mode);

  @override
  void initState() {
    super.initState();
    _scrollToEnd();
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    _textCtrl.dispose();
    super.dispose();
  }

  /// The list is reversed, so "the newest message" always sits at offset 0 —
  /// no chasing an estimated maxScrollExtent that grows as bubbles build.
  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollCtrl.hasClients) return;
      _scrollCtrl.animateTo(
        _scrollCtrl.position.minScrollExtent,
        duration: AppMotion.medium,
        curve: AppMotion.enter,
      );
    });
  }

  GlobalKey _keyFor(String id) => _messageKeys.putIfAbsent(id, () => GlobalKey());

  void _openTaskDetails() => showTaskDetailSheet(context, fixedTask: widget.fixedTask);

  /// Jumps to the oldest question still waiting on me. Once the conversation
  /// grows, an unanswered question scrolls out of sight — the reminder above
  /// the composer is what brings the user back to it.
  void _jumpToOldestOpen() {
    final messages = ref.read(_messages);
    final open = messages.where((m) => m.isMyTurn(_role));
    if (open.isEmpty) return;
    final ctx = _messageKeys[open.first.id]?.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      alignment: 0.2,
      duration: AppMotion.medium,
      curve: AppMotion.enter,
    );
  }

  // ── answering a question in the chat ──────────────────────────────────────

  void _answer(DiscussionMessage question, bool positive) {
    final topic = question.topic;
    if (topic == null) return;
    final script = answerScriptFor(topic, positive: positive);

    markAnswered(ref, _messages, question.id);
    addMessages(ref, _messages, [
      DiscussionMessage(
        id: newMessageId('answer'),
        author: _role,
        text: script.mine,
        photos: script.photos,
      ),
      DiscussionMessage(
        id: newMessageId('reply'),
        author: _them,
        text: script.theirs,
      ),
    ]);
    _applyTaskChange(script);
    _scrollToEnd();
  }

  /// Demo-only: play the counterpart's answer to a question I asked, so a
  /// single-device walkthrough never stalls waiting for someone who isn't here.
  void _demoAnswer(DiscussionMessage question) {
    final topic = question.topic;
    if (topic == null) return;
    final script = answerScriptFor(topic, positive: true);

    markAnswered(ref, _messages, question.id);
    addMessages(ref, _messages, [
      DiscussionMessage(
        id: newMessageId('answer'),
        author: _them,
        text: script.mine,
        photos: script.photos,
      ),
      DiscussionMessage(
        id: newMessageId('reply'),
        author: _role,
        text: script.theirs,
      ),
    ]);
    _applyTaskChange(script);
    _scrollToEnd();
  }

  /// An accepted arrival time rewrites the one shared task, so the booking
  /// card and the escrow summary can never show a stale time.
  void _applyTaskChange(AnswerScript script) {
    final newTime = script.newTimeSlot;
    if (newTime == null) return;
    final notifier = ref.read(discussionTaskProvider.notifier);
    notifier.state = notifier.state.copyWith(timeSlot: newTime);
    addMessage(
      ref,
      _messages,
      DiscussionMessage(
        id: newMessageId('system'),
        kind: MessageKind.system,
        text: '✅ ရောက်ချိန်ကို $newTime သို့ ပြောင်းလိုက်ပါပြီ',
      ),
    );
  }

  // ── asking a question ─────────────────────────────────────────────────────

  void _ask(SuggestedQuestion question) {
    addMessage(
      ref,
      _messages,
      DiscussionMessage(
        id: newMessageId('ask'),
        author: _role,
        kind: MessageKind.question,
        topic: question.topic,
        answerStyle: question.answerStyle,
        text: question.text,
        // Questions with a scripted reply are answered the moment they land.
        answered: question.reply != null,
      ),
    );
    final reply = question.reply;
    if (reply != null) {
      addMessage(
        ref,
        _messages,
        DiscussionMessage(
          id: newMessageId('reply'),
          author: _them,
          text: reply,
        ),
      );
    }
    // "On the way" is a status, not just a sentence: sending it moves the
    // strip both sides are reading.
    final status = question.setsStatus;
    if (status != null) {
      ref.read(arrivalStatusProvider.notifier).state = status;
    }
    _scrollToEnd();
  }

  void _sendFreeText() {
    final text = _textCtrl.text.trim();
    if (text.isEmpty) return;

    final blockReason = aiBlockReason(text);
    if (blockReason != null) {
      addMessage(
        ref,
        _messages,
        DiscussionMessage(
          id: newMessageId('blocked'),
          kind: MessageKind.warning,
          text: '🚫 AI က ဤစာတိုကို ပိတ်ပင်လိုက်ပါသည် — $blockReason ပါဝင်နေပါသည်။ '
              'သင့်လုံခြုံရေးအတွက် ဆက်သွယ်ရေးနှင့် ငွေပေးချေမှုအားလုံးကို အက်ပ်အတွင်းသာ ပြုလုပ်ပါ။',
        ),
      );
      showActivitySnack(context, 'AI က မသင့်လျော်သော စာတိုကို ပိတ်ပင်လိုက်ပါသည်။');
      _scrollToEnd();
      return;
    }

    addMessages(ref, _messages, [
      DiscussionMessage(id: newMessageId('me'), author: _role, text: text),
      DiscussionMessage(
        id: newMessageId('ack'),
        author: _them,
        text: 'ဟုတ်ကဲ့၊ မှတ်သားလိုက်ပါပြီ ခင်ဗျာ။',
      ),
    ]);
    _textCtrl.clear();
    _scrollToEnd();
  }

  // ── ready to proceed ──────────────────────────────────────────────────────

  void _setReady(ActivityRole role) {
    final ready = {...ref.read(discussionReadyProvider), role};
    ref.read(discussionReadyProvider.notifier).state = ready;
    addMessage(
      ref,
      _messages,
      DiscussionMessage(
        id: newMessageId('ready'),
        kind: MessageKind.system,
        text: '${roleLabel(role)} က အလုပ်အသေးစိတ်ကို အတည်ပြုလိုက်ပါပြီ ✓',
      ),
    );
    if (ready.length == 2) {
      ref.read(taskPhaseProvider.notifier).state = TaskPhase.confirmed;
      addMessage(
        ref,
        _messages,
        DiscussionMessage(
          id: newMessageId('done'),
          kind: MessageKind.system,
          text: 'ဆွေးနွေးမှု ပြီးဆုံးပါပြီ ✓ — နှစ်ဦးစလုံး သဘောတူပါသည်။',
        ),
      );
    }
    _scrollToEnd();
  }

  // ── build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(_messages);
    final phase = ref.watch(taskPhaseProvider);
    final ready = ref.watch(discussionReadyProvider);
    final arrival = ref.watch(arrivalStatusProvider);

    final bothAgreed = phase != TaskPhase.discussing;
    final iAmReady = ready.contains(_role) || bothAgreed;
    final theyAreReady = ready.contains(_them) || bothAgreed;
    final myOpenQuestions = openQuestionsFor(messages, _role);

    final asked = askedTopics(messages);
    final available = [
      for (final q in questionsFor(_role, widget.mode))
        if (!asked.contains(q.topic)) q,
    ];

    // At large accessibility text scales the guide costs more screen than it
    // gives, so it steps aside for the one-line chip and the conversation
    // keeps the space.
    final textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
    final showGuide = _guideVisible && textScale <= 1.3;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: FractionallySizedBox(
        heightFactor: 0.94,
        child: Column(
          children: [
            _ChatHeader(
              name: widget.counterpartName,
              emoji: widget.counterpartEmoji,
              subtitle: _isProgress
                  ? 'ငွေပေးချေပြီး · လာရန် စောင့်ဆဲ'
                  : switch (phase) {
                      TaskPhase.discussing => 'ဆွေးနွေးနေဆဲ',
                      TaskPhase.confirmed => 'သဘောတူပြီး · ငွေပေးချေရန်',
                      TaskPhase.marked => 'ငွေပေးချေပြီး',
                    },
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
              child: showGuide
                  ? MascotGuide(
                      message: _isProgress
                          ? 'သဘောတူပြီးပါပြီ။ ဒီနေရာမှာ ရောက်ချိန်နဲ့ အခြေအနေတွေကို အသိပေးနိုင်ပါတယ်။'
                          : 'ဒီနေရာမှာ အလုပ်မစခင် လိုအပ်တာတွေကို နှစ်ဖက် ညှိနိုင်ပါတယ်။',
                      onViewTask: _openTaskDetails,
                      onDismiss: () => setState(() => _guideVisible = false),
                    )
                  : TaskDetailsChip(onTap: _openTaskDetails),
            ),
            Expanded(
              child: ListView.builder(
                key: const Key('discussionMessageList'),
                controller: _scrollCtrl,
                reverse: true,
                // Keeps older bubbles built so "jump to the question above"
                // always has somewhere to jump to. A discussion is short.
                scrollCacheExtent: const ScrollCacheExtent.pixels(2000),
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.md),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final message = messages[messages.length - 1 - index];
                  return KeyedSubtree(
                    key: _keyFor(message.id),
                    child: message.kind != MessageKind.question
                        ? ChatBubble(message: message, viewerRole: _role)
                        : QuestionBubble(
                            message: message,
                            viewerRole: _role,
                            onAnswer: (positive) => _answer(message, positive),
                            onDemoAnswer:
                                message.isOpenQuestion && !message.isMyTurn(_role)
                                    ? () => _demoAnswer(message)
                                    : null,
                          ),
                  );
                },
              ),
            ),
            // The bottom half is a fixed child of this Column, so it must
            // never claim more than its share: past that it scrolls internally
            // instead of overflowing the sheet at large text scales.
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.5,
              ),
              child: SingleChildScrollView(
                reverse: true,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_isProgress)
                      _StatusStrip(
                        status: arrival,
                        role: _role,
                        counterpartName: widget.counterpartName,
                      )
                    else
                      _ReadyBar(
                        role: _role,
                        phase: phase,
                        iAmReady: iAmReady,
                        theyAreReady: theyAreReady,
                        bothAgreed: bothAgreed,
                        myOpenQuestions: myOpenQuestions,
                        onJumpToOpen: _jumpToOldestOpen,
                        onReady: () => _setReady(_role),
                        onSimulateCounterpart: () => _setReady(_them),
                        onPay: () => openEscrowPage(context),
                      ),
                    _Composer(
                      role: _role,
                      mode: widget.mode,
                      questions: available,
                      showAskMenu: _isProgress || !bothAgreed,
                      textCtrl: _textCtrl,
                      onAsk: _ask,
                      onSend: _sendFreeText,
                      onVoice: () => showActivitySnack(
                          context, 'အသံဖြင့် စာရိုက်ခြင်းကို မကြာမီ ထည့်သွင်းပါမည်။'),
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

// ---------------------------------------------------------------------------
// Chrome
// ---------------------------------------------------------------------------

class _ChatHeader extends StatelessWidget {
  final String name;
  final String emoji;
  final String subtitle;

  const _ChatHeader({
    required this.name,
    required this.emoji,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.sm, AppSpacing.sm, AppSpacing.sm, AppSpacing.sm),
      decoration: const BoxDecoration(
        color: AppColors.purple700,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      child: Column(
        children: [
          Container(
            width: AppSpacing.xl * 2,
            height: AppSpacing.xxs,
            margin: const EdgeInsets.only(bottom: AppSpacing.xs),
            decoration: BoxDecoration(
              color: AppColors.onBrandMuted,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: AppColors.onBrand),
                tooltip: 'နောက်သို့',
                onPressed: () => Navigator.of(context).pop(),
              ),
              CircleAvatar(
                backgroundColor: AppColors.onBrand,
                child: Text(emoji, style: theme.textTheme.titleMedium),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: AppColors.onBrand,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: AppColors.onBrandMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The single exit from the discussion, and the only thing that ever sits
/// between the conversation and the composer. It shows up as one line, and
/// only says the one thing that is true right now.
class _ReadyBar extends StatelessWidget {
  final ActivityRole role;
  final TaskPhase phase;
  final bool iAmReady;
  final bool theyAreReady;
  final bool bothAgreed;
  final int myOpenQuestions;
  final VoidCallback onJumpToOpen;
  final VoidCallback onReady;
  final VoidCallback onSimulateCounterpart;
  final VoidCallback onPay;

  const _ReadyBar({
    required this.role,
    required this.phase,
    required this.iAmReady,
    required this.theyAreReady,
    required this.bothAgreed,
    required this.myOpenQuestions,
    required this.onJumpToOpen,
    required this.onReady,
    required this.onSimulateCounterpart,
    required this.onPay,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isClient = role == ActivityRole.client;
    final paid = phase == TaskPhase.marked;

    Widget shell(Widget child, {Color? color}) => Container(
          width: double.infinity,
          margin:
              const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.sm),
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: color ?? AppColors.blue100,
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: child,
        );

    Widget note(IconData icon, String text, Color color, {Widget? trailing}) => Row(
          children: [
            const SizedBox(width: AppSpacing.xs),
            Icon(icon, size: AppSizes.iconMd, color: color),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                text,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: color, fontWeight: FontWeight.w600),
              ),
            ),
            if (trailing != null) trailing,
          ],
        );

    if (paid) {
      return shell(
        note(Icons.verified_rounded, 'ငွေပေးချေပြီးပါပြီ ✓', AppColors.tealDark),
        color: AppColors.success.withValues(alpha: 0.12),
      );
    }

    if (bothAgreed) {
      if (!isClient) {
        return shell(note(Icons.hourglass_top_rounded, 'အလုပ်ရှင်က ငွေပေးချေနေပါသည်',
            AppColors.purple700));
      }
      return Container(
        margin: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.sm),
        child: FilledButton.icon(
          onPressed: onPay,
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(56),
            backgroundColor: AppColors.purple700,
            foregroundColor: AppColors.onBrand,
          ),
          icon: const Icon(Icons.lock_outline),
          label: const Text('Escrow ဖြင့် ငွေပေးချေရန်'),
        ),
      );
    }

    if (iAmReady) {
      return shell(
        note(
          Icons.hourglass_top_rounded,
          '${roleLabel(counterpartOf(role))} အတည်ပြုရန် စောင့်နေသည်',
          AppColors.purple700,
          trailing: TextButton(
            onPressed: onSimulateCounterpart,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.indigo700,
              minimumSize: const Size(0, 44),
            ),
            child: const Text('သရုပ်ပြ'),
          ),
        ),
      );
    }

    if (myOpenQuestions > 0) {
      // Tappable: the question it points at may have scrolled away.
      return Semantics(
        button: true,
        label: 'ဖြေရန်ကျန်သော မေးခွန်းသို့ သွားရန်',
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          onTap: onJumpToOpen,
          child: shell(
            note(
              Icons.arrow_upward_rounded,
              'အပေါ်က မေးခွန်း $myOpenQuestions ခုကို အရင် ဖြေပေးပါ',
              AppColors.orangeDark,
            ),
            color: AppColors.warning.withValues(alpha: 0.14),
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.sm),
      child: FilledButton.icon(
        onPressed: onReady,
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(56),
          backgroundColor: AppColors.tealDark,
          foregroundColor: AppColors.onBrand,
        ),
        icon: const Icon(Icons.check_circle_outline),
        label: const Text('အဆင်သင့် ဖြစ်ပါပြီ'),
      ),
    );
  }
}

/// The progress conversation's one-line state, worded for whoever is reading
/// it. Nothing to negotiate here — this bar answers "where is he?" and
/// "does she know I'm coming?" without either side having to ask.
class _StatusStrip extends StatelessWidget {
  final ArrivalStatus status;
  final ActivityRole role;
  final String counterpartName;

  const _StatusStrip({
    required this.status,
    required this.role,
    required this.counterpartName,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final arrived = status == ArrivalStatus.arrived;
    final color = arrived ? AppColors.tealDark : AppColors.purple700;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: arrived ? AppColors.success.withValues(alpha: 0.12) : AppColors.blue100,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        children: [
          Icon(arrivalStatusIcon(status), size: AppSizes.iconMd, color: color),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              arrivalStatusText(status, role, counterpartName),
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: color, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  final ActivityRole role;
  final ConversationMode mode;
  final List<SuggestedQuestion> questions;
  final bool showAskMenu;
  final TextEditingController textCtrl;
  final ValueChanged<SuggestedQuestion> onAsk;
  final VoidCallback onSend;
  final VoidCallback onVoice;

  const _Composer({
    required this.role,
    required this.mode,
    required this.questions,
    required this.showAskMenu,
    required this.textCtrl,
    required this.onAsk,
    required this.onSend,
    required this.onVoice,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isClient = role == ActivityRole.client;
    // The tasker's progress list is status updates, not questions, so the pill
    // says what tapping it actually does.
    final askLabel = isClient
        ? 'ဝန်ဆောင်မှုပေးသူကို မေးရန်'
        : mode == ConversationMode.progress
            ? 'အခြေအနေ အသိပေးရန်'
            : 'အလုပ်ရှင်ကို မေးရန်';

    return Container(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.lightSurface,
        border: const Border(top: BorderSide(color: AppColors.onboardingDivider)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowSm,
            blurRadius: AppSpacing.md,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showAskMenu) ...[
            ExpandableQuestionMenu(
              label: askLabel,
              sheetTitle: askLabel,
              questions: questions,
              onSelected: onAsk,
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: textCtrl,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => onSend(),
                  minLines: 1,
                  maxLines: 3,
                  style: theme.textTheme.bodyLarge,
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: 'စာရိုက်ရန်...',
                    filled: true,
                    fillColor: AppColors.lightBg,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md, vertical: AppSpacing.md),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Semantics(
                button: true,
                label: 'အသံဖြင့် ပြောရန်',
                child: IconButton(
                  icon: const Icon(Icons.mic_none_rounded, color: AppColors.purple700),
                  tooltip: 'အသံဖြင့် ပြောရန်',
                  onPressed: onVoice,
                ),
              ),
              Container(
                decoration: const BoxDecoration(
                    color: AppColors.purple700, shape: BoxShape.circle),
                child: IconButton(
                  icon: const Icon(Icons.send_rounded, color: AppColors.onBrand),
                  tooltip: 'ပို့ရန်',
                  onPressed: onSend,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              const Icon(Icons.shield_outlined,
                  size: AppSizes.iconSm, color: AppColors.indigo500),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  'စာတိုများကို AI ဖြင့် စစ်ဆေးပါသည်။ ငွေပေးချေမှုကို အက်ပ်ထဲမှာသာ ပြုလုပ်ပါ။',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: AppColors.textSecondary, fontSize: 11),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
