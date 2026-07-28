import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/large_button.dart';
import '../../../core/widgets/mascot/mascot_message_card.dart';
import '../../../core/widgets/mascot/mascot_state.dart';
import '../activity_chat.dart';
import 'discussion_models.dart';
import 'discussion_state.dart';
import 'widgets/apprentice_request_card.dart';
import 'widgets/cost_proposal_card.dart';
import 'widgets/discussion_action_bar.dart';
import 'widgets/discussion_chat_bubble.dart';
import 'widgets/discussion_compose_sheets.dart';
import 'widgets/discussion_progress_card.dart';
import 'widgets/discussion_summary_card.dart';
import 'widgets/duration_card.dart';
import 'widgets/material_checklist_card.dart';
import 'widgets/photo_request_card.dart';
import 'widgets/schedule_proposal_card.dart';

// ---------------------------------------------------------------------------
// COLLABORATIVE AGREEMENT WORKSPACE
//
// This replaces the conversation-first discussion sheet. The shape of the page
// is the argument: decisions are structured cards with a status anyone can
// read at a glance, and chat is demoted to the small talk it always was.
//
// Neither side waits for a turn — both can raise a discussion point at any
// time, and both can answer whatever is open on them.
//
// Phase-1 safe: shared Riverpod StateProviders + synchronous mutations. The
// only `await`s are Flutter's own modal sheets/dialogs.
// ---------------------------------------------------------------------------

/// Opens the workspace. Kept as a modal sheet so every existing entry point
/// (chat list, activity list, booking card) keeps working unchanged.
void openDiscussionWorkspace(
  BuildContext context, {
  required ActivityRole role,
  required String counterpartName,
  required String counterpartEmoji,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.lightBg,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
    ),
    builder: (_) => DiscussionWorkspaceSheet(
      role: role,
      counterpartName: counterpartName,
      counterpartEmoji: counterpartEmoji,
    ),
  );
}

class DiscussionWorkspaceSheet extends ConsumerStatefulWidget {
  final ActivityRole role;
  final String counterpartName;
  final String counterpartEmoji;

  const DiscussionWorkspaceSheet({
    super.key,
    required this.role,
    required this.counterpartName,
    required this.counterpartEmoji,
  });

  @override
  ConsumerState<DiscussionWorkspaceSheet> createState() =>
      _DiscussionWorkspaceSheetState();
}

class _DiscussionWorkspaceSheetState extends ConsumerState<DiscussionWorkspaceSheet> {
  final ScrollController _scrollCtrl = ScrollController();
  final TextEditingController _textCtrl = TextEditingController();
  final FocusNode _chatFocus = FocusNode();
  final Map<String, GlobalKey> _itemKeys = {};

  /// The card that was just created, jumped to, or answered — ringed so the
  /// change is impossible to miss.
  String? _highlightId;

  @override
  void dispose() {
    _scrollCtrl.dispose();
    _textCtrl.dispose();
    _chatFocus.dispose();
    super.dispose();
  }

  GlobalKey _keyFor(String id) => _itemKeys.putIfAbsent(id, () => GlobalKey());

  ActivityRole get _role => widget.role;

  // ── navigation helpers ────────────────────────────────────────────────────

  void _focusItem(String id) {
    setState(() => _highlightId = id);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _itemKeys[id]?.currentContext;
      if (ctx == null) return;
      Scrollable.ensureVisible(
        ctx,
        alignment: 0.1,
        duration: AppMotion.medium,
        curve: AppMotion.enter,
      );
    });
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollCtrl.hasClients) return;
      _scrollCtrl.animateTo(
        _scrollCtrl.position.maxScrollExtent,
        duration: AppMotion.medium,
        curve: AppMotion.enter,
      );
    });
  }

  // ── creating discussion cards ─────────────────────────────────────────────

  Future<void> _onAction(DiscussionActionSpec spec) async {
    final type = spec.type;

    // "Ask a question" is deliberately not a card — it drops you into chat.
    if (type == null) {
      _scrollToEnd();
      _chatFocus.requestFocus();
      return;
    }

    // Smart behaviour: never two cards for the same decision.
    final existing = openItemOfType(ref.read(discussionItemsProvider), type);
    if (existing != null) {
      showActivitySnack(
        context,
        '${type.label} ဆွေးနွေးမှု ရှိပြီးသားပါ။ ရှိပြီးသား ကတ်ကို ပြပေးပါမည်။',
      );
      _focusItem(existing.id);
      return;
    }

    final item = await _composeItem(type);
    if (item == null || !mounted) return;

    addDiscussionItem(ref, item);
    addDiscussionMessage(
      ref,
      DiscussionMessage(
        text: '📋 ဆွေးနွေးကတ် အသစ် — ${item.type.label}',
        kind: DiscussionMsgKind.system,
      ),
    );
    _focusItem(item.id);
  }

  Future<DiscussionItem?> _composeItem(DiscussionItemType type) async {
    final isTasker = _role == ActivityRole.tasker;
    final task = ref.read(discussionTaskProvider);

    DiscussionItem base({
      required String title,
      required String description,
      DiscussionStatus status = DiscussionStatus.pending,
      Map<String, Object?> data = const {},
    }) {
      return DiscussionItem(
        id: newDiscussionId(type),
        type: type,
        creatorRole: _role,
        title: title,
        description: description,
        status: status,
        data: data,
      );
    }

    switch (type) {
      case DiscussionItemType.photoRequest:
        return base(
          title: isTasker ? 'ပျက်စီးမှု ဓာတ်ပုံ ပို့ပေးပါ' : 'ဓာတ်ပုံ ထပ်တောင်းဆိုချက်',
          description: isTasker
              ? 'ပျက်စီးနေတဲ့ နေရာကို ဓာတ်ပုံ ရိုက်ပို့ပေးပါ။ ကြိုတင် ပြင်ဆင်ထားနိုင်အောင်ပါ။'
              : 'အလုပ်နဲ့ ပတ်သက်ပြီး ဓာတ်ပုံလေး ပြပေးနိုင်မလား။',
        );

      case DiscussionItemType.durationRequest:
        if (!isTasker) {
          return base(
            title: 'ဘယ်လောက်ကြာမလဲ',
            description: 'ဒီအလုပ်က ဘယ်လောက်ကြာနိုင်မလဲ ခန့်မှန်းပေးပါ။',
          );
        }
        final duration = await showDurationComposer(context);
        if (duration == null) return null;
        return base(
          title: 'ခန့်မှန်း ကြာမြင့်ချိန်',
          description: 'ဒီအလုပ်အတွက် ကျွန်တော် ခန့်မှန်းထားတဲ့ အချိန်ပါ။',
          status: DiscussionStatus.answered,
          data: {'duration': duration},
        );

      case DiscussionItemType.materialChecklist:
        final materials = await showMaterialsComposer(context);
        if (materials == null) return null;
        return base(
          title: 'လိုအပ်သော ပစ္စည်းများ',
          description: 'ဒီပစ္စည်းတွေထဲက ဘယ်ဟာတွေ အိမ်မှာ ရှိပြီးသားလဲ ခြစ်ပေးပါ။',
          data: {'materials': materials, 'have': const <String>[]},
        );

      case DiscussionItemType.apprenticeRequest:
        final reason = await showApprenticeComposer(context);
        if (reason == null) return null;
        return base(
          title: 'လက်ထောက် ခေါ်ဆောင်ခွင့်',
          description: reason,
        );

      case DiscussionItemType.extraCostProposal:
        if (!isTasker) {
          return base(
            title: 'ထပ်ဆောင်း ကုန်ကျစရိတ် ရှိနိုင်လား',
            description: 'နောက်ထပ် ကုန်ကျစရိတ် ဖြစ်နိုင်တာ ရှိရင် ကြိုပြောပေးပါ။',
          );
        }
        final cost = await showCostComposer(context);
        if (cost == null) return null;
        return base(
          title: 'ဖြစ်နိုင်သော ကုန်ကျစရိတ်',
          description: 'အောက်ပါ အခြေအနေမျိုး ဖြစ်လာရင် စရိတ် ထပ်ကုန်နိုင်ပါတယ်။',
          data: cost,
        );

      case DiscussionItemType.scheduleProposal:
        final slot = await showScheduleComposer(
          context,
          currentDate: task.date,
          currentTime: task.timeSlot,
        );
        if (slot == null) return null;
        return base(
          title: 'ချိန်းဆိုချိန် ပြောင်းလဲရန်',
          description: isTasker
              ? 'အောက်က အချိန်အသစ်ဆို ကျွန်တော့်အတွက် ပိုအဆင်ပြေပါတယ်။'
              : 'အောက်က အချိန်အသစ်ဆို ကျွန်တော့်အတွက် ပိုအဆင်ပြေပါတယ်။',
          data: slot,
        );
    }
  }

  // ── answering discussion cards ────────────────────────────────────────────

  void _onUpdate(DiscussionItem item) {
    updateDiscussionItem(ref, item);
    setState(() => _highlightId = item.id);

    // An accepted schedule rewrites the one shared task, so the booking card
    // and the escrow summary can never show a stale time.
    if (item.type == DiscussionItemType.scheduleProposal &&
        item.status == DiscussionStatus.accepted) {
      final notifier = ref.read(discussionTaskProvider.notifier);
      notifier.state = notifier.state.copyWith(date: item.toDate, timeSlot: item.toTime);
      addDiscussionMessage(
        ref,
        DiscussionMessage(
          text: '✅ Task အချက်အလက် ပြင်ဆင်ပြီး — ${item.toDate} · ${item.toTime}',
          kind: DiscussionMsgKind.system,
        ),
      );
      return;
    }

    if (item.status == DiscussionStatus.needsClarification) {
      addDiscussionMessage(
        ref,
        const DiscussionMessage(
          text: 'ဖြစ်နိုင်သော ကုန်ကျစရိတ်ကို ထပ်မံ ဆွေးနွေးရန် တောင်းဆိုထားပါသည်။',
          kind: DiscussionMsgKind.system,
        ),
      );
    }
  }

  /// Demo-only: plays the counterpart's scripted answer so a single-device
  /// walkthrough never dead-ends on a card that is waiting for the other side.
  void _demoAnswer(DiscussionItem item) {
    final answered = demoAnswerFor(item);
    updateDiscussionItem(ref, answered);
    addDiscussionMessage(
      ref,
      DiscussionMessage(
        text: demoAnswerNote(item),
        authorRole: counterpartOf(_role),
      ),
    );
    if (answered.type == DiscussionItemType.scheduleProposal &&
        answered.status == DiscussionStatus.accepted) {
      final notifier = ref.read(discussionTaskProvider.notifier);
      notifier.state =
          notifier.state.copyWith(date: answered.toDate, timeSlot: answered.toTime);
    }
    setState(() => _highlightId = item.id);
  }

  Future<void> _fillCost(DiscussionItem item) async {
    final cost = await showCostComposer(context);
    if (cost == null || !mounted) return;
    _onUpdate(item.withData(cost));
  }

  // ── casual chat ───────────────────────────────────────────────────────────

  void _sendChat() {
    final text = _textCtrl.text.trim();
    if (text.isEmpty) return;

    final blockReason = aiBlockReason(text);
    if (blockReason != null) {
      addDiscussionMessage(
        ref,
        DiscussionMessage(
          text: '🚫 AI က ဤစာတိုကို ပိတ်ပင်လိုက်ပါသည် — $blockReason ပါဝင်နေပါသည်။ '
              'သင့်လုံခြုံရေးအတွက် ဆက်သွယ်ရေးနှင့် ငွေပေးချေမှုအားလုံးကို အက်ပ်အတွင်းသာ ပြုလုပ်ပါ။',
          kind: DiscussionMsgKind.warning,
        ),
      );
      showActivitySnack(context, 'AI က မသင့်လျော်သော စာတိုကို ပိတ်ပင်လိုက်ပါသည်။');
      _scrollToEnd();
      return;
    }

    addDiscussionMessage(
      ref,
      DiscussionMessage(text: text, authorRole: _role),
    );
    _textCtrl.clear();
    _scrollToEnd();
  }

  // ── ready to proceed ──────────────────────────────────────────────────────

  Future<void> _markReady() async {
    final items = ref.read(discussionItemsProvider);
    final pending = items.where((i) => i.status.isPending).length;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('အလုပ်အသေးစိတ် အဆင်သင့် ဖြစ်ပြီလား။'),
        content: Text(
          pending == 0
              ? 'ဆွေးနွေးစရာ အားလုံး ပြီးဆုံးပါပြီ။ နှစ်ဦးစလုံး အတည်ပြုမှသာ '
                  'Escrow ငွေပေးချေမှုသို့ ဆက်သွားပါမည်။'
              : 'ဖြေဆိုရန် ကျန်နေသေးတဲ့ ကတ် $pending ခု ရှိပါသေးတယ်။ '
                  'အဲဒါတွေကို မဖြေဘဲ ဆက်သွားချင်ပါသလား။',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('ဆက်ဆွေးနွေးမည်'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('အဆင်သင့် ဖြစ်ပါပြီ'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    _setReady(_role);
  }

  void _setReady(ActivityRole role) {
    final ready = {...ref.read(discussionReadyProvider), role};
    ref.read(discussionReadyProvider.notifier).state = ready;
    addDiscussionMessage(
      ref,
      DiscussionMessage(
        text: '${roleLabel(role)} က အလုပ်အသေးစိတ်ကို အတည်ပြုလိုက်ပါပြီ။',
        kind: DiscussionMsgKind.system,
      ),
    );
    if (ready.length == 2) {
      ref.read(taskPhaseProvider.notifier).state = TaskPhase.confirmed;
      addDiscussionMessage(
        ref,
        const DiscussionMessage(
          text: 'နှစ်ဦးစလုံး အလုပ်အသေးစိတ်ကို သဘောတူပြီးပါပြီ။',
          kind: DiscussionMsgKind.system,
        ),
      );
    }
    _scrollToEnd();
  }

  void _continueDiscussion() {
    ref.read(discussionReadyProvider.notifier).state = const <ActivityRole>{};
    ref.read(taskPhaseProvider.notifier).state = TaskPhase.discussing;
    addDiscussionMessage(
      ref,
      const DiscussionMessage(
        text: 'ဆွေးနွေးမှုကို ပြန်လည် ဖွင့်လိုက်ပါသည်။',
        kind: DiscussionMsgKind.system,
      ),
    );
  }

  // ── build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
    final items = ref.watch(discussionItemsProvider);
    final chat = ref.watch(discussionChatProvider);
    final phase = ref.watch(taskPhaseProvider);
    final ready = ref.watch(discussionReadyProvider);

    final bothAgreed = phase != TaskPhase.discussing;
    final iAmReady = ready.contains(_role) || bothAgreed;
    final myTurnCount = items.where((i) => i.isMyTurn(_role)).length;

    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets),
      child: FractionallySizedBox(
        heightFactor: 0.94,
        child: Column(
          children: [
            _WorkspaceHeader(
              name: widget.counterpartName,
              emoji: widget.counterpartEmoji,
              settledCount: settledTopicCount(items),
              totalCount: kDiscussionChecklist.length,
            ),
            Expanded(
              // Deliberately not a lazy ListView: "that discussion already
              // exists" jumps to a card through its GlobalKey, which only
              // resolves once the card has been laid out. A workspace holds a
              // handful of cards, so building them all is cheap and makes the
              // jump reliable wherever the card sits.
              child: SingleChildScrollView(
                key: const Key('discussionWorkspaceList'),
                controller: _scrollCtrl,
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DiscussionSummaryCard(viewerRole: _role),
                    const SizedBox(height: AppSpacing.md),
                    DiscussionProgressCard(
                      items: items,
                      onOpenItem: (item) => _focusItem(item.id),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    MascotMessageCard(
                      state: myTurnCount > 0
                          ? PhoWaYokeState.pointing
                          : bothAgreed
                              ? PhoWaYokeState.success
                              : PhoWaYokeState.idle,
                      mascotSize: 64,
                      message: _guidanceMessage(
                        myTurnCount: myTurnCount,
                        items: items,
                        bothAgreed: bothAgreed,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _SectionHeader(
                      icon: Icons.fact_check_outlined,
                      title: 'ဆွေးနွေးမှု ကတ်များ',
                      trailing: myTurnCount > 0 ? 'သင် ဖြေရန် $myTurnCount ခု' : null,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    if (items.isEmpty)
                      const _EmptyCards()
                    else
                      for (final item in _orderedItems(items))
                        KeyedSubtree(
                          key: _keyFor(item.id),
                          child: _buildCard(item),
                        ),
                    if (iAmReady) ...[
                      const SizedBox(height: AppSpacing.sm),
                      _ReadyCard(
                        role: _role,
                        phase: phase,
                        bothAgreed: bothAgreed,
                        onSimulateCounterpart: () => _setReady(counterpartOf(_role)),
                        onContinue: _continueDiscussion,
                        onPay: () => openEscrowPage(context),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.xl),
                    _SectionHeader(
                      icon: Icons.chat_bubble_outline,
                      title: 'ရိုးရိုး စကားပြော',
                      subtitle: 'နှုတ်ဆက်ခြင်း၊ ရှင်းလင်းမေးမြန်းခြင်းအတွက်သာ။ '
                          'အရေးကြီးသော သဘောတူညီချက်များကို ကတ်များဖြင့် မှတ်တမ်းတင်ပါ။',
                    ),
                    const SizedBox(height: AppSpacing.md),
                    for (final message in chat)
                      DiscussionChatBubble(message: message, viewerRole: _role),
                  ],
                ),
              ),
            ),
            DiscussionActionBar(
              viewerRole: _role,
              items: items,
              showActions: !bothAgreed,
              onAction: _onAction,
              textCtrl: _textCtrl,
              chatFocus: _chatFocus,
              onSend: _sendChat,
              onVoice: () => showActivitySnack(
                  context, 'အသံဖြင့် စာရိုက်ခြင်းကို မကြာမီ ထည့်သွင်းပါမည်။'),
              onReady: iAmReady ? null : _markReady,
              readyLabel: 'အဆင်သင့် ဖြစ်ပါပြီ',
            ),
          ],
        ),
      ),
    );
  }

  String _guidanceMessage({
    required int myTurnCount,
    required List<DiscussionItem> items,
    required bool bothAgreed,
  }) {
    if (bothAgreed) {
      return 'နှစ်ဦးစလုံး သဘောတူပြီးပါပြီ။ ကျေးဇူးတင်ပါတယ်နော်။';
    }
    if (myTurnCount > 0) {
      return 'သင် ဖြေပေးရမယ့် ကတ် $myTurnCount ခု ရှိပါတယ်။ တစ်ခုချင်းစီ ဖြေပေးပါနော်။';
    }
    if (items.any((i) => i.status.isPending)) {
      return 'တစ်ဖက်လူရဲ့ အဖြေကို စောင့်နေပါတယ်။ ခဏလေး စောင့်ပေးပါနော်။';
    }
    return 'အားလုံး ညှိပြီးပါပြီ။ အဆင်ပြေရင် "အဆင်သင့် ဖြစ်ပါပြီ" ကို နှိပ်ပါ။';
  }

  /// What needs *you* floats to the top; settled cards sink. Order inside each
  /// group stays chronological (List.sort isn't stable, so index is the
  /// tie-breaker).
  List<DiscussionItem> _orderedItems(List<DiscussionItem> items) {
    int bucket(DiscussionItem item) {
      if (!item.status.isPending) return 2;
      return item.isMyTurn(_role) ? 0 : 1;
    }

    final indexOf = {
      for (var i = 0; i < items.length; i++) items[i].id: i,
    };
    return [...items]..sort((a, b) {
        final byBucket = bucket(a).compareTo(bucket(b));
        if (byBucket != 0) return byBucket;
        return indexOf[a.id]!.compareTo(indexOf[b.id]!);
      });
  }

  Widget _buildCard(DiscussionItem item) {
    final highlighted = _highlightId == item.id;
    final waitingOnThem = item.awaitingRole != null && item.awaitingRole != _role;
    final onDemoAnswer = waitingOnThem ? () => _demoAnswer(item) : null;

    switch (item.type) {
      case DiscussionItemType.photoRequest:
        return PhotoRequestCard(
          item: item,
          viewerRole: _role,
          highlighted: highlighted,
          onUpdate: _onUpdate,
          onDemoAnswer: onDemoAnswer,
        );
      case DiscussionItemType.materialChecklist:
        return MaterialChecklistCard(
          // Rebuild the local tick state whenever the shared item changes.
          key: ValueKey('${item.id}-${item.status}'),
          item: item,
          viewerRole: _role,
          highlighted: highlighted,
          onUpdate: _onUpdate,
          onDemoAnswer: onDemoAnswer,
        );
      case DiscussionItemType.durationRequest:
        return DurationCard(
          item: item,
          viewerRole: _role,
          highlighted: highlighted,
          onUpdate: _onUpdate,
          onDemoAnswer: onDemoAnswer,
        );
      case DiscussionItemType.apprenticeRequest:
        return ApprenticeRequestCard(
          item: item,
          viewerRole: _role,
          highlighted: highlighted,
          onUpdate: _onUpdate,
          onDemoAnswer: onDemoAnswer,
        );
      case DiscussionItemType.extraCostProposal:
        return CostProposalCard(
          item: item,
          viewerRole: _role,
          highlighted: highlighted,
          onUpdate: _onUpdate,
          onFill: () => _fillCost(item),
          onDemoAnswer: onDemoAnswer,
        );
      case DiscussionItemType.scheduleProposal:
        return ScheduleProposalCard(
          item: item,
          viewerRole: _role,
          highlighted: highlighted,
          onUpdate: _onUpdate,
          onDemoAnswer: onDemoAnswer,
        );
    }
  }
}

// ---------------------------------------------------------------------------
// Chrome
// ---------------------------------------------------------------------------

class _WorkspaceHeader extends StatelessWidget {
  final String name;
  final String emoji;
  final int settledCount;
  final int totalCount;

  const _WorkspaceHeader({
    required this.name,
    required this.emoji,
    required this.settledCount,
    required this.totalCount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.md),
      decoration: const BoxDecoration(
        color: AppColors.purple700,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      child: Column(
        children: [
          Container(
            width: AppSpacing.xl * 2,
            height: AppSpacing.xxs,
            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.onBrandMuted,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.close, color: AppColors.onBrand),
                tooltip: 'ပိတ်ရန်',
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
                      'သဘောတူညီချက် ဆွေးနွေးခန်း · $settledCount/$totalCount ပြီးပြီ',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: AppColors.onBrandMuted),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.volume_up_outlined, color: AppColors.onBrand),
                tooltip: 'ဖတ်ပြရန်',
                onPressed: () =>
                    showActivitySnack(context, 'စာသားများကို အသံဖြင့် ဖတ်ပြပါမည်။'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? trailing;

  const _SectionHeader({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: AppSizes.iconMd, color: AppColors.purple700),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            if (trailing != null)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm, vertical: AppSpacing.xxs),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  trailing!,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.orangeDark,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            subtitle!,
            style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ],
    );
  }
}

class _EmptyCards extends StatelessWidget {
  const _EmptyCards();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.lightSurface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        children: [
          const Icon(Icons.fact_check_outlined,
              size: AppSizes.iconLg, color: AppColors.purple300),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'ဆွေးနွေးစရာ မရှိသေးပါ',
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'အောက်က ခလုတ်လေးတွေထဲက တစ်ခုကို နှိပ်ပြီး စတင်ဆွေးနွေးနိုင်ပါတယ်။',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

/// Replaces the old "End Discussion". Ending a conversation is a strange thing
/// to ask someone to do; confirming that the details are settled is not.
class _ReadyCard extends StatelessWidget {
  final ActivityRole role;
  final TaskPhase phase;
  final bool bothAgreed;
  final VoidCallback onSimulateCounterpart;
  final VoidCallback onContinue;
  final VoidCallback onPay;

  const _ReadyCard({
    required this.role,
    required this.phase,
    required this.bothAgreed,
    required this.onSimulateCounterpart,
    required this.onContinue,
    required this.onPay,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isClient = role == ActivityRole.client;
    final paid = phase == TaskPhase.marked;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: bothAgreed ? AppColors.purple100 : AppColors.blue100,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        children: [
          Icon(
            paid
                ? Icons.task_alt
                : bothAgreed
                    ? Icons.handshake_outlined
                    : Icons.hourglass_top_rounded,
            color: AppColors.purple700,
            size: AppSizes.iconLg,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            paid
                ? 'အလုပ် လက်ခံပြီးပါပြီ'
                : bothAgreed
                    ? 'နှစ်ဦးစလုံး သဘောတူပြီးပါပြီ'
                    : 'တစ်ဖက်လူ၏ အတည်ပြုချက်ကို စောင့်နေသည်',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.purple700,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            paid
                ? 'Escrow ငွေ လုံခြုံစွာ ထိန်းသိမ်းပြီးပါပြီ။'
                : bothAgreed
                    ? isClient
                        ? 'အလုပ်အသေးစိတ်အားလုံး သဘောတူပြီးပါပြီ။ Escrow ဖြင့် ငွေပေးချေပါ။'
                        : 'အလုပ်ရှင်က Escrow ငွေပေးချေမှု ပြုလုပ်နေပါသည်။'
                    : 'သင်ဘက်က အတည်ပြုပြီးပါပြီ။ တစ်ဖက်လူ အတည်ပြုပြီးမှ ငွေပေးချေမှုသို့ ဆက်သွားပါမည်။',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
          if (!bothAgreed) ...[
            const SizedBox(height: AppSpacing.md),
            OutlinedButton.icon(
              onPressed: onSimulateCounterpart,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                foregroundColor: AppColors.indigo700,
                side: const BorderSide(color: AppColors.indigo500),
              ),
              icon: const Icon(Icons.play_circle_outline, size: AppSizes.iconSm),
              label: const Text('သရုပ်ပြ — တစ်ဖက်လူ အတည်ပြုသည်'),
            ),
          ],
          if (bothAgreed && !paid) ...[
            const SizedBox(height: AppSpacing.md),
            if (isClient)
              LargeButton(
                label: 'Escrow ဖြင့် ငွေပေးချေရန်',
                icon: Icons.lock_outline,
                gradient: AppColors.purpleGradient,
                onTap: onPay,
              ),
            const SizedBox(height: AppSpacing.sm),
            TextButton.icon(
              onPressed: onContinue,
              style: TextButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                foregroundColor: AppColors.purple700,
              ),
              icon: const Icon(Icons.forum_outlined, size: AppSizes.iconSm),
              label: const Text('ဆက်လက် ဆွေးနွေးမည်'),
            ),
          ],
        ],
      ),
    );
  }
}
