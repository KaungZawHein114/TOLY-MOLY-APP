import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/large_button.dart';

// ---------------------------------------------------------------------------
// SHARED ACTIVITY CHAT ENGINE (demo)
//
// The whole Activity demo centers on ONE task that flows through its real
// lifecycle and stays consistent on every surface:
//
//   Discussion (Phase 2)  →  End Discussion  →  Escrow  →  Task Marked (Phase 3)
//
// A single [DiscussionTask] + [taskPhaseProvider] are the one source of truth.
// An accepted budget / time / date / location change rewrites that task, so the
// new value replaces the old one in the discussion summary, the booking card,
// the task-progress chat, and the escrow page — never a stale value left behind.
//
// Phase-1 safe: no backend, no async business logic — every counterpart reply
// is a synchronous scripted string.
// ---------------------------------------------------------------------------

/// Who is using the surface. Flips the scripts so the same engine serves the
/// client page (client asks, tasker answers) and the tasker page (tasker asks,
/// client answers).
enum ActivityRole { client, tasker }

/// Lifecycle of the single demo task.
enum TaskPhase { discussing, confirmed, marked }

// Demo identities for the one lifecycle task (Chat 1 → booking → escrow).
const String kDiscussionTaskerName = 'ကိုအောင် (လျှပ်စစ်)';
const String kDiscussionClientName = 'ဒေါ်ခင် (အိမ်ရှင်)';
// A separate, already-in-progress task used only by the standalone Chat 2 tile.
const String kProgressTaskerName = 'ကိုမင်း (ရေပိုက်)';
const String kProgressClientName = 'ကိုဇော် (အိမ်ရှင်)';
const String kTaskerEmoji = '👨‍🔧';
const String kClientEmoji = '🧑';

void showActivitySnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

String formatMmk(int mmk) {
  final s = mmk.toString();
  final buf = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
    buf.write(s[i]);
  }
  return '${buf.toString()} ကျပ်';
}

// ---------------------------------------------------------------------------
// Shared, live task details (single source of truth for the demo).
// ---------------------------------------------------------------------------

@immutable
class DiscussionTask {
  final String skillLabel;
  final int budgetMmk;
  final String date;
  final String timeSlot;
  final String location;

  const DiscussionTask({
    required this.skillLabel,
    required this.budgetMmk,
    required this.date,
    required this.timeSlot,
    required this.location,
  });

  DiscussionTask copyWith({
    int? budgetMmk,
    String? date,
    String? timeSlot,
    String? location,
  }) {
    return DiscussionTask(
      skillLabel: skillLabel,
      budgetMmk: budgetMmk ?? this.budgetMmk,
      date: date ?? this.date,
      timeSlot: timeSlot ?? this.timeSlot,
      location: location ?? this.location,
    );
  }
}

/// The one lifecycle task, shared by the discussion chat, the booking card,
/// the progress chat, and the escrow page.
final discussionTaskProvider = StateProvider<DiscussionTask>(
  (ref) => const DiscussionTask(
    skillLabel: 'လျှပ်စစ်ပြုပြင်ခြင်း',
    budgetMmk: 45000,
    date: 'ဇွန် ၂၈ ရက်',
    timeSlot: 'နေ့လည် ၂:၀၀',
    location: 'ကမာရွတ်မြို့နယ်',
  ),
);

/// Drives the whole flow: discussing → confirmed (both ended) → marked (escrow paid).
final taskPhaseProvider = StateProvider<TaskPhase>((ref) => TaskPhase.discussing);

/// The fixed, already-confirmed task behind the standalone Chat 2 tile (a
/// different job from the lifecycle task, so it has its own static details).
const DiscussionTask kProgressDemoTask = DiscussionTask(
  skillLabel: 'ရေပိုက်ပြုပြင်ခြင်း',
  budgetMmk: 38000,
  date: 'ဇွန် ၂၈ ရက်',
  timeSlot: 'နံနက် ၁၀:၀၀',
  location: 'ကမာရွတ်မြို့နယ်',
);

// ---------------------------------------------------------------------------
// Chat data model
// ---------------------------------------------------------------------------

enum BubbleKind { them, me, system, warning }

class ChatLine {
  final String text;
  final String time;
  final BubbleKind kind;

  const ChatLine({required this.text, required this.time, this.kind = BubbleKind.them});
}

/// What an accepted quick reply changes about the task, if anything.
enum ReplyAction { none, budget, time, date, location }

class QuickReply {
  final String label; // shown on the button + sent as my bubble
  final String reply; // counterpart's scripted answer
  final ReplyAction action;

  const QuickReply(this.label, this.reply, {this.action = ReplyAction.none});
}

/// A pending accept/reject proposal rendered inline in the transcript.
class _Proposal {
  final ReplyAction action;
  final String title;
  final String valueText;
  final String acceptedSummary; // system bubble text after accepting
  final DiscussionTask Function(DiscussionTask) apply;

  const _Proposal({
    required this.action,
    required this.title,
    required this.valueText,
    required this.acceptedSummary,
    required this.apply,
  });
}

_Proposal? _proposalFor(ReplyAction action, DiscussionTask task) {
  switch (action) {
    case ReplyAction.budget:
      const proposed = 52000;
      return _Proposal(
        action: action,
        title: 'အဆိုပြု ဈေးနှုန်း',
        valueText: '${formatMmk(proposed)}  (50,000 – 55,000)',
        acceptedSummary: 'သဘောတူဈေး — ${formatMmk(proposed)}',
        apply: (t) => t.copyWith(budgetMmk: proposed),
      );
    case ReplyAction.time:
      const proposed = 'ညနေ ၄:၀၀';
      return _Proposal(
        action: action,
        title: 'အဆိုပြု အချိန်',
        valueText: proposed,
        acceptedSummary: 'အချိန်အသစ် — $proposed',
        apply: (t) => t.copyWith(timeSlot: proposed),
      );
    case ReplyAction.date:
      const proposed = 'ဇွန် ၂၉ ရက်';
      return _Proposal(
        action: action,
        title: 'အဆိုပြု ရက်စွဲ',
        valueText: proposed,
        acceptedSummary: 'ရက်စွဲအသစ် — $proposed',
        apply: (t) => t.copyWith(date: proposed),
      );
    case ReplyAction.location:
      const proposed = 'လှိုင်မြို့နယ်';
      return _Proposal(
        action: action,
        title: 'အဆိုပြု နေရာ',
        valueText: proposed,
        acceptedSummary: 'နေရာအသစ် — $proposed',
        apply: (t) => t.copyWith(location: proposed),
      );
    case ReplyAction.none:
      return null;
  }
}

// ---------------------------------------------------------------------------
// Scripts — short, natural, each answer follows from its question.
// ---------------------------------------------------------------------------

/// Discussion quick replies — the CLIENT asks, the tasker answers.
const List<QuickReply> clientDiscussionReplies = [
  QuickReply('ဒီအလုပ်က ဘယ်လောက်ကြာနိုင်မလဲ။',
      'ပျက်စီးမှုပေါ်မူတည်ပြီး ၁ နာရီခွဲကနေ ၂ နာရီလောက် ကြာနိုင်ပါတယ်။'),
  QuickReply('ဘာပစ္စည်းတွေ ကြိုဝယ်ထားပေးရမလဲ။',
      'ဘာမှ ကြိုဝယ်စရာ မလိုပါဘူး။ လိုတဲ့ပစ္စည်းတွေ ကျွန်တော် ယူလာပါမယ်။'),
  QuickReply('ကိရိယာတွေ ကိုယ်တိုင် ယူလာမှာလား။',
      'ဟုတ်ကဲ့၊ ကိရိယာအစုံ ကျွန်တော့်ဆီမှာ ရှိပါတယ်။'),
  QuickReply('တင်ထားတဲ့ ဈေးနဲ့ အဆင်ပြေရဲ့လား။',
      'ဒီအလုပ်အတွက်တော့ နည်းနည်းလေး လျှော့နေပါတယ်ခင်ဗျာ။ ဒီဈေးဆို ဘယ်လိုလဲ။',
      action: ReplyAction.budget),
  QuickReply('ချိန်းထားတဲ့ အချိန် ပြောင်းလို့ ရမလား။',
      'ရပါတယ်။ အောက်က အချိန်ဆို ကျွန်တော့်အတွက် အဆင်ပြေပါတယ်။', action: ReplyAction.time),
  QuickReply('နေရာ ပြောင်းဖို့ ဖြစ်နိုင်မလား။',
      'ရပါတယ်။ နေရာအသစ်ကို အတည်ပြုပေးပါ။', action: ReplyAction.location),
  QuickReply('မလာခင် ကျွန်တော် ဘာပြင်ဆင်ထားရမလဲ။',
      'အလုပ်လုပ်မယ့်နေရာ ရှင်းထားပေးရင် ရပါပြီ။ ကျန်တာ ကျွန်တော် တာဝန်ယူပါမယ်။'),
  QuickReply('မနက်ဖြန်ဆို ရမလား။',
      'ရပါတယ်။ နောက်တစ်ရက်ဆို ပိုတောင် အဆင်ပြေပါတယ်။', action: ReplyAction.date),
  QuickReply('သင်တစ်ယောက်တည်းနဲ့ လုံလောက်မလား။',
      'ဒီအလုပ်က တစ်ယောက်တည်းနဲ့ ရပါတယ်။ လိုအပ်ရင် လူထပ်ခေါ်ပါ့မယ်။'),
  QuickReply('ဘယ်လို လုပ်မယ်ဆိုတာ အကြမ်းဖျင်း ပြောပြပေးပါ။',
      'အရင်ဆုံး ချို့ယွင်းချက်ကို စစ်မယ်၊ ပြီးရင် ပြုပြင်ပြီး သင့်ရှေ့မှာ စမ်းသပ်ပြပါမယ်။'),
  QuickReply('မစခင် ဓာတ်ပုံ လိုသေးလား။',
      'လက်ရှိအခြေအနေ ဓာတ်ပုံ နှစ်ပုံလောက် ပို့ပေးနိုင်ရင် ကောင်းပါတယ်။'),
  QuickReply('အလုပ်ပြီးရင် အာမခံ ပါသလား။',
      'ဟုတ်ကဲ့၊ ပြုပြင်ပြီး ၇ ရက်အတွင်း ပြန်ပျက်ရင် အခမဲ့ ပြင်ပေးပါတယ်။'),
  QuickReply('ဒါဆို အဆင်ပြေပါပြီ။ ထပ်လိုတာ ရှိသေးလား။',
      'ဘာမှ ထပ်မလိုတော့ပါ။ ချိန်းထားတဲ့အတိုင်း တွေ့ကြမယ်နော်။'),
];

/// Discussion quick replies — the TASKER asks, the client answers.
const List<QuickReply> taskerDiscussionReplies = [
  QuickReply('ဈေးနှုန်းကို နည်းနည်း ညှိပေးလို့ ရမလား။',
      'အလုပ်အရည်အသွေး သေချာရင် ဒီလောက်တော့ တိုးပေးနိုင်ပါတယ်။', action: ReplyAction.budget),
  QuickReply('မလာခင် ကျွန်တော် သိထားသင့်တာ ရှိလား။',
      'အိမ်ထဲ ခွေးရှိလို့ ကြိုပြောထားတာပါ။ စိတ်ချရပါတယ်။'),
  QuickReply('ကိရိယာ သင့်ဘက်က ပြင်ဆင်ထားဖို့ လိုလား။',
      'မလိုပါဘူး။ ကိရိယာတွေ သင်ယူလာမယ်လို့ ထင်ထားတာပါ။'),
  QuickReply('ပြဿနာနေရာ ဓာတ်ပုံ ထပ်ပို့ပေးနိုင်မလား။',
      'ရပါတယ်၊ ခုပဲ ဓာတ်ပုံ ပို့လိုက်ပါမယ်။'),
  QuickReply('ချိန်းချိန် ပြောင်းဖို့ အဆင်ပြေမလား။',
      'ရပါတယ်၊ အောက်က အချိန်ဆို အိမ်မှာ ရှိပါတယ်။', action: ReplyAction.time),
  QuickReply('တွေ့မယ့်နေရာ ပြောင်းလို့ ရမလား။',
      'ရပါတယ်၊ နေရာအသစ်ကို အတည်ပြုပေးပါ။', action: ReplyAction.location),
  QuickReply('ဒီနေ့မရရင် နောက်တစ်ရက် ရွှေ့လို့ ရမလား။',
      'ရပါတယ်၊ နောက်တစ်ရက်ဆို ပိုအဆင်ပြေပါတယ်။', action: ReplyAction.date),
  QuickReply('ကားရပ်စရာ နေရာ ရှိရဲ့လား။', 'အိမ်ရှေ့မှာ ရပ်လို့ ရပါတယ်။'),
  QuickReply('အိမ်မှာ လူ ရှိမှာ သေချာလား။', 'ဟုတ်ကဲ့၊ ကျွန်တော် ကိုယ်တိုင် စောင့်နေပါမယ်။'),
  QuickReply('ချိန်းချိန်ထက် စောရင် ဝင်လို့ ရမလား။', 'ရပါတယ်၊ စောရင် ပိုကောင်းတာပေါ့။'),
  QuickReply('လက်ထောက် တစ်ယောက် ပါလာရင် ရမလား။', 'ရပါတယ်၊ ကိစ္စ မရှိပါဘူး။'),
];

/// Task-progress quick replies — the TASKER sends an update, the client acks.
const List<QuickReply> taskerProgressReplies = [
  QuickReply('ယခုပဲ ထွက်လာပါပြီ။', 'ဟုတ်ကဲ့၊ စောင့်နေပါမယ်။'),
  QuickReply('လမ်းမှာ ၁၅ မိနစ်လောက် အကွာမှာ ရှိပါတယ်။', 'ရပါတယ်၊ သတိနဲ့ လာပါ။'),
  QuickReply('အိမ်ရှေ့ ရောက်ပါပြီ။', 'ဂိတ် ဖွင့်ပေးထားပါတယ်၊ ဝင်လာပါ။'),
  QuickReply('အလုပ် စတင်လိုက်ပါပြီ။', 'ကျေးဇူးတင်ပါတယ်၊ အဆင်ပြေပါစေ။'),
  QuickReply('နီးပါး ပြီးပါပြီ၊ နောက်ဆုံး စစ်ဆေးနေပါတယ်။', 'ကောင်းပါပြီ၊ ဖြည်းဖြည်းမှန်မှန် လုပ်ပါ။'),
  QuickReply('အလုပ် ပြီးဆုံးပါပြီ။ စစ်ဆေးကြည့်ပေးပါ။',
      'အဆင်ပြေပါတယ်၊ ကျေးဇူးတင်ပါတယ်။ Escrow ငွေ ထုတ်ပေးလိုက်ပါမယ်။'),
  QuickReply('ဒီနေ့ နည်းနည်း နောက်ကျနိုင်လို့ ကြိုအကြောင်းကြားပါတယ်။', 'ရပါတယ်၊ ဖြည်းဖြည်း လာပါ။'),
  QuickReply('လိပ်စာ ရှာမတွေ့သေးလို့ တည်နေရာ ပြန်ပို့ပေးပါ။', 'ခုပဲ တည်နေရာ ပြန်ပို့လိုက်ပါပြီ။'),
];

/// Task-progress quick replies — the CLIENT acks, the tasker confirms.
const List<QuickReply> clientProgressReplies = [
  QuickReply('ရပါပြီ၊ စောင့်နေပါမယ်။', 'ဟုတ်ကဲ့ ခင်ဗျာ။'),
  QuickReply('ကျေးဇူးတင်ပါတယ်။', 'ရပါတယ် ခင်ဗျာ။'),
  QuickReply('ဖြည်းဖြည်း လာပါ။', 'ဟုတ်ကဲ့၊ သတိထားလာပါမယ်။'),
  QuickReply('ခဏ စောင့်ပေးပါ။', 'ရပါတယ်၊ စောင့်ပေးပါမယ်။'),
  QuickReply('ဂိတ် ဖွင့်ပေးထားပါတယ်။', 'ကျေးဇူးတင်ပါတယ်၊ ဝင်လာပါမယ်။'),
  QuickReply('နားလည်ပါပြီ။', 'ဟုတ်ကဲ့ ခင်ဗျာ။'),
];

// ---------------------------------------------------------------------------
// AI free-text screening (client-side demo only).
// ---------------------------------------------------------------------------

/// Returns a human reason if the message should be blocked, else null.
String? aiBlockReason(String text) {
  final normalized = text.replaceAll(RegExp(r'[\s\-]'), '');
  // Phone numbers (Myanmar 09… or any 7+ digit run).
  if (RegExp(r'09\d{6,}').hasMatch(normalized) || RegExp(r'\d{7,}').hasMatch(normalized)) {
    return 'ဖုန်းနံပါတ်';
  }
  // Social media handles / off-platform messaging apps.
  if (RegExp(r'@\w+').hasMatch(text) ||
      RegExp(r'(facebook|messenger|viber|telegram|whatsapp|tiktok|instagram|\big\b|\bfb\b|wechat|line)',
              caseSensitive: false)
          .hasMatch(text)) {
    return 'ပြင်ပ ဆက်သွယ်ရေး အကောင့်';
  }
  // Requests to pay outside the platform.
  if (RegExp(r'(kpay|kbz|wave|ayapay|aya pay|အပြင်ကနေ|ပြင်ပ.*ငွေ|ငွေ.*လွှဲ|ဘဏ်.*လွှဲ|cash)',
          caseSensitive: false)
      .hasMatch(text)) {
    return 'အက်ပ်ပြင်ပ ငွေပေးချေမှု';
  }
  return null;
}

// ---------------------------------------------------------------------------
// Public openers
// ---------------------------------------------------------------------------

void openDiscussionChat(
  BuildContext context, {
  required ActivityRole role,
  required String counterpartName,
  required String counterpartEmoji,
}) {
  _openSheet(
    context,
    _ChatSheet(
      role: role,
      isDiscussion: true,
      counterpartName: counterpartName,
      counterpartEmoji: counterpartEmoji,
    ),
  );
}

void openProgressChat(
  BuildContext context, {
  required ActivityRole role,
  required String counterpartName,
  required String counterpartEmoji,
  DiscussionTask? fixedTask,
}) {
  _openSheet(
    context,
    _ChatSheet(
      role: role,
      isDiscussion: false,
      counterpartName: counterpartName,
      counterpartEmoji: counterpartEmoji,
      fixedTask: fixedTask,
    ),
  );
}

void openEscrowPage(BuildContext context) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (_) => const EscrowPaymentScreen(),
    ),
  );
}

void _openSheet(BuildContext context, Widget sheet) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.lightSurface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
    ),
    builder: (_) => sheet,
  );
}

// ---------------------------------------------------------------------------
// Chat sheet
// ---------------------------------------------------------------------------

class _ChatSheet extends ConsumerStatefulWidget {
  final ActivityRole role;
  final bool isDiscussion;
  final String counterpartName;
  final String counterpartEmoji;
  final DiscussionTask? fixedTask; // non-null = standalone progress task

  const _ChatSheet({
    required this.role,
    required this.isDiscussion,
    required this.counterpartName,
    required this.counterpartEmoji,
    this.fixedTask,
  });

  @override
  ConsumerState<_ChatSheet> createState() => _ChatSheetState();
}

class _ChatSheetState extends ConsumerState<_ChatSheet> {
  final List<ChatLine> _lines = [];
  final TextEditingController _textCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  _Proposal? _pending;
  bool _ended = false;

  List<QuickReply> get _replies {
    if (widget.isDiscussion) {
      return widget.role == ActivityRole.client
          ? clientDiscussionReplies
          : taskerDiscussionReplies;
    }
    return widget.role == ActivityRole.client
        ? clientProgressReplies
        : taskerProgressReplies;
  }

  @override
  void initState() {
    super.initState();
    _ended = widget.isDiscussion && ref.read(taskPhaseProvider) != TaskPhase.discussing;
    if (widget.isDiscussion) {
      _lines.add(ChatLine(
        text: widget.role == ActivityRole.client
            ? 'မင်္ဂလာပါ။ သင့်အလုပ်ကို စိတ်ဝင်စားလို့ ဆက်သွယ်လိုက်တာပါ။ မေးစရာ ရှိရင် မေးနိုင်ပါတယ်နော်။'
            : 'မင်္ဂလာပါ။ ကျွန်တော့်ကို ရွေးပေးလို့ ကျေးဇူးတင်ပါတယ်။ အသေးစိတ် ဆွေးနွေးကြရအောင်။',
        time: '၁ မိနစ်က',
      ));
    } else {
      _lines.add(ChatLine(
        text: widget.role == ActivityRole.client
            ? 'အလုပ် အတည်ဖြစ်ပြီးပါပြီ။ ထွက်ခွာချိန် ရောက်ရင် အသိပေးပါမယ်။'
            : 'အလုပ် အတည်ဖြစ်ပြီးပါပြီ။ ထွက်ခွာတော့မယ်ဆို အသိပေးပါမယ်နော်။',
        time: '၅ မိနစ်က',
      ));
    }
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: AppMotion.medium,
          curve: AppMotion.enter,
        );
      }
    });
  }

  void _onQuickReply(QuickReply qr) {
    setState(() {
      _lines.add(ChatLine(text: qr.label, time: 'ယခု', kind: BubbleKind.me));
      _lines.add(ChatLine(text: qr.reply, time: 'ယခု'));
      if (widget.isDiscussion && qr.action != ReplyAction.none) {
        _pending = _proposalFor(qr.action, ref.read(discussionTaskProvider));
      }
    });
    _scrollToEnd();
  }

  void _acceptProposal() {
    final p = _pending;
    if (p == null) return;
    final notifier = ref.read(discussionTaskProvider.notifier);
    notifier.state = p.apply(notifier.state);
    setState(() {
      _lines.add(ChatLine(
        text: '✅ Task အချက်အလက် ပြင်ဆင်ပြီး — ${p.acceptedSummary}',
        time: 'ယခု',
        kind: BubbleKind.system,
      ));
      _pending = null;
    });
    _scrollToEnd();
  }

  void _rejectProposal() {
    setState(() {
      _lines.add(const ChatLine(
        text: 'ရပါတယ်၊ မူလအချက်အလက်အတိုင်းပဲ ဆက်ထားလိုက်ပါမယ်။',
        time: 'ယခု',
      ));
      _pending = null;
    });
    _scrollToEnd();
  }

  void _sendFreeText() {
    final text = _textCtrl.text.trim();
    if (text.isEmpty) return;
    final blockReason = aiBlockReason(text);
    if (blockReason != null) {
      setState(() {
        _lines.add(ChatLine(
          text: '🚫 AI က ဤစာတိုကို ပိတ်ပင်လိုက်ပါသည် — $blockReason ပါဝင်နေပါသည်။ '
              'သင့်လုံခြုံရေးအတွက် ဆက်သွယ်ရေးနှင့် ငွေပေးချေမှုအားလုံးကို အက်ပ်အတွင်းသာ ပြုလုပ်ပါ။',
          time: 'ယခု',
          kind: BubbleKind.warning,
        ));
      });
      _scrollToEnd();
      showActivitySnack(context, 'AI က မသင့်လျော်သော စာတိုကို ပိတ်ပင်လိုက်ပါသည်။');
      return;
    }
    setState(() {
      _lines.add(ChatLine(text: text, time: 'ယခု', kind: BubbleKind.me));
      _lines.add(ChatLine(
        text: widget.isDiscussion ? 'ဟုတ်ကဲ့၊ မှတ်သားလိုက်ပါပြီ။' : 'ဟုတ်ကဲ့ ခင်ဗျာ။',
        time: 'ယခု',
      ));
      _textCtrl.clear();
    });
    _scrollToEnd();
  }

  Future<void> _endDiscussion() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ဆွေးနွေးမှု အဆုံးသတ်မလား။'),
        content: const Text(
          'နှစ်ဦးစလုံး သဘောတူမှသာ အဆုံးသတ်ပါ။ အဆုံးသတ်ပြီးနောက် Escrow ငွေပေးချေမှုသို့ ဆက်သွားပါမည်။',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('ဆက်ဆွေးနွေးမည်'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('အတည်ပြုသည်'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    ref.read(taskPhaseProvider.notifier).state = TaskPhase.confirmed;
    setState(() {
      _pending = null;
      _ended = true;
      _lines.add(const ChatLine(
        text: 'ဆွေးနွေးမှု အဆုံးသတ်ရန် အတည်ပြုလိုက်ပါပြီ။',
        time: 'ယခု',
        kind: BubbleKind.me,
      ));
      _lines.add(ChatLine(
        text: widget.role == ActivityRole.client
            ? 'တာဝန်ထမ်းဆောင်သူကလည်း အတည်ပြုပြီးပါပြီ။ နှစ်ဦးသဘောတူ ဆွေးနွေးမှု ပြီးဆုံးပါပြီ။'
            : 'အလုပ်ရှင်ကလည်း အတည်ပြုပြီးပါပြီ။ နှစ်ဦးသဘောတူ ဆွေးနွေးမှု ပြီးဆုံးပါပြီ။',
        time: 'ယခု',
        kind: BubbleKind.system,
      ));
    });
    _scrollToEnd();
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
    final phase = ref.watch(taskPhaseProvider);
    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets),
      child: FractionallySizedBox(
        heightFactor: 0.94,
        child: Column(
          children: [
            _ChatHeader(
              name: widget.counterpartName,
              emoji: widget.counterpartEmoji,
              subtitle: widget.isDiscussion
                  ? 'ဆွေးနွေးညှိနှိုင်းခြင်း · အဆင့် ၂'
                  : 'အလုပ်ဆောင်ရွက်ဆဲ · အဆင့် ၃',
            ),
            Expanded(
              child: ListView(
                controller: _scrollCtrl,
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.md),
                children: [
                  _TaskSummaryCard(
                    fixed: widget.fixedTask,
                    tag: widget.isDiscussion ? 'ညှိနှိုင်းနိုင်' : 'အတည်ပြုပြီး',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _RuleBanner(isDiscussion: widget.isDiscussion),
                  const SizedBox(height: AppSpacing.md),
                  for (final line in _lines) _ChatBubble(line: line),
                  if (_pending != null)
                    _ProposalCard(
                      proposal: _pending!,
                      onAccept: _acceptProposal,
                      onReject: _rejectProposal,
                    ),
                  if (_ended)
                    _DiscussionEndedCard(
                      role: widget.role,
                      phase: phase,
                      onPay: () => openEscrowPage(context),
                    ),
                ],
              ),
            ),
            if (!_ended)
              _ComposerPanel(
                replies: _replies,
                isDiscussion: widget.isDiscussion,
                textCtrl: _textCtrl,
                onQuickReply: _onQuickReply,
                onSend: _sendFreeText,
                onEndDiscussion: widget.isDiscussion ? _endDiscussion : null,
              ),
          ],
        ),
      ),
    );
  }
}

class _ChatHeader extends StatelessWidget {
  final String name;
  final String emoji;
  final String subtitle;

  const _ChatHeader({required this.name, required this.emoji, required this.subtitle});

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
                      style: theme.textTheme.bodySmall?.copyWith(color: AppColors.onBrandMuted),
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

class _TaskSummaryCard extends ConsumerWidget {
  final DiscussionTask? fixed;
  final String tag;

  const _TaskSummaryCard({required this.fixed, required this.tag});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    // A fixed task is static; otherwise watch the live single-source task.
    final DiscussionTask task = fixed ?? ref.watch(discussionTaskProvider);

    Widget row(IconData icon, String label, String value) => Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.xs),
          child: Row(
            children: [
              Icon(icon, size: AppSizes.iconSm, color: AppColors.purple500),
              const SizedBox(width: AppSpacing.sm),
              Text(label, style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  value,
                  textAlign: TextAlign.end,
                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.indigo100,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.assignment_outlined, size: AppSizes.iconMd, color: AppColors.indigo700),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Task အချက်အလက်',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.indigo700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm, vertical: AppSpacing.xxs),
                decoration: BoxDecoration(
                  color: AppColors.indigo500.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Text(
                  tag,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.indigo700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          row(Icons.handyman_outlined, 'ဝန်ဆောင်မှု', task.skillLabel),
          row(Icons.payments_outlined, 'သဘောတူဈေး', formatMmk(task.budgetMmk)),
          row(Icons.event_outlined, 'ရက်စွဲ', task.date),
          row(Icons.schedule_outlined, 'အချိန်', task.timeSlot),
          row(Icons.place_outlined, 'နေရာ', task.location),
        ],
      ),
    );
  }
}

class _RuleBanner extends StatelessWidget {
  final bool isDiscussion;

  const _RuleBanner({required this.isDiscussion});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.blue100,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.blue300.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lock_outline, color: AppColors.purple500),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              isDiscussion
                  ? 'အောက်က မေးခွန်းများကို ရွေး၍ ဆွေးနွေးနိုင်ပြီး၊ ကိုယ်ပိုင်စာလည်း ရိုက်ပို့နိုင်ပါသည်။ နှစ်ဦးသဘောတူမှသာ ဆွေးနွေးမှု အဆုံးသတ်ပါ။'
                  : 'အလုပ်ဆောင်ရွက်နေစဉ် အခြေအနေ အပ်ဒိတ်များကို ဤနေရာတွင် ပေးပို့နိုင်ပါသည်။',
              style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final ChatLine line;

  const _ChatBubble({required this.line});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (line.kind == BubbleKind.system || line.kind == BubbleKind.warning) {
      final isWarning = line.kind == BubbleKind.warning;
      return Container(
        margin: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: (isWarning ? AppColors.error : AppColors.success).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Text(
          line.text,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: isWarning ? AppColors.error : AppColors.tealDark,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    final isMe = line.kind == BubbleKind.me;
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 280),
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: isMe ? AppColors.purple700 : AppColors.lightBg,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(AppRadius.lg),
            topRight: const Radius.circular(AppRadius.lg),
            bottomLeft: Radius.circular(isMe ? AppRadius.lg : AppRadius.sm),
            bottomRight: Radius.circular(isMe ? AppRadius.sm : AppRadius.lg),
          ),
          border: isMe ? null : Border.all(color: AppColors.onboardingDivider),
        ),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              line.text,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isMe ? AppColors.onBrand : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              line.time,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isMe ? AppColors.onBrandMuted : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProposalCard extends StatelessWidget {
  final _Proposal proposal;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const _ProposalCard({
    required this.proposal,
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.lightSurface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.indigo500.withValues(alpha: 0.4)),
        boxShadow: [BoxShadow(color: AppColors.shadowMd, blurRadius: AppSpacing.md)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.swap_horiz_rounded, color: AppColors.indigo700),
              const SizedBox(width: AppSpacing.sm),
              Text(
                proposal.title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.indigo700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            proposal.valueText,
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onReject,
                  child: const Text('ငြင်းပယ်မည်'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: FilledButton(
                  onPressed: onAccept,
                  child: const Text('သဘောတူသည်'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DiscussionEndedCard extends StatelessWidget {
  final ActivityRole role;
  final TaskPhase phase;
  final VoidCallback onPay;

  const _DiscussionEndedCard({required this.role, required this.phase, required this.onPay});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isClient = role == ActivityRole.client;
    final marked = phase == TaskPhase.marked;
    return Container(
      margin: const EdgeInsets.only(top: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.purple100,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        children: [
          Icon(marked ? Icons.task_alt : Icons.verified_outlined,
              color: AppColors.purple700, size: AppSizes.iconLg),
          const SizedBox(height: AppSpacing.sm),
          Text(
            marked ? 'အလုပ် လက်ခံပြီးပါပြီ' : 'ဆွေးနွေးမှု ပြီးဆုံးပါပြီ',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.purple700,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            marked
                ? 'Escrow ငွေ လုံခြုံစွာ ထိန်းသိမ်းပြီးပါပြီ။ ဤအလုပ်ကို Bookings ထဲ "အလုပ်လက်ခံပြီး" တွင် ကြည့်နိုင်ပါသည်။'
                : isClient
                    ? 'အလုပ်ကို ဆက်လက်ဆောင်ရွက်ရန် Escrow ဖြင့် ငွေပေးချေပါ။'
                    : 'အလုပ်ရှင်က Escrow ငွေပေးချေမှု ပြုလုပ်နေပါသည်။ ပြီးပါက အသိပေးပါမည်။',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
          if (isClient && !marked) ...[
            const SizedBox(height: AppSpacing.md),
            LargeButton(
              label: 'Escrow ဖြင့် ငွေပေးချေရန်',
              icon: Icons.lock_outline,
              gradient: AppColors.purpleGradient,
              onTap: onPay,
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Composer: taller quick replies + AI-monitored free text + End Discussion
// ---------------------------------------------------------------------------

class _ComposerPanel extends StatelessWidget {
  final List<QuickReply> replies;
  final bool isDiscussion;
  final TextEditingController textCtrl;
  final ValueChanged<QuickReply> onQuickReply;
  final VoidCallback onSend;
  final Future<void> Function()? onEndDiscussion;

  const _ComposerPanel({
    required this.replies,
    required this.isDiscussion,
    required this.textCtrl,
    required this.onQuickReply,
    required this.onSend,
    required this.onEndDiscussion,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.lightSurface,
        border: const Border(top: BorderSide(color: AppColors.onboardingDivider)),
        boxShadow: [
          BoxShadow(color: AppColors.shadowSm, blurRadius: AppSpacing.md, offset: const Offset(0, -2)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.touch_app_outlined, size: AppSizes.iconMd, color: AppColors.purple700),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  isDiscussion ? 'ဆွေးနွေးရန် မေးခွန်းများ' : 'အမြန် ဖြေကြားချက်များ',
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              if (onEndDiscussion != null)
                TextButton.icon(
                  onPressed: onEndDiscussion,
                  icon: const Icon(Icons.flag_outlined, size: AppSizes.iconSm),
                  label: const Text('ဆွေးနွေးမှု အဆုံးသတ်'),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          // Taller, easier-to-tap quick-reply list.
          SizedBox(
            height: 184,
            child: ListView.separated(
              itemCount: replies.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) {
                final qr = replies[index];
                return Semantics(
                  button: true,
                  label: qr.label,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    onTap: () => onQuickReply(qr),
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 56),
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: AppColors.purple100,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              qr.label,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: AppColors.purple900,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (qr.action != ReplyAction.none)
                            const Padding(
                              padding: EdgeInsets.only(right: AppSpacing.xs),
                              child: Icon(Icons.swap_horiz_rounded,
                                  size: AppSizes.iconSm, color: AppColors.indigo700),
                            ),
                          const Icon(Icons.send_rounded, size: AppSpacing.md, color: AppColors.purple700),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _AiMonitoredField(textCtrl: textCtrl, onSend: onSend),
        ],
      ),
    );
  }
}

class _AiMonitoredField extends StatelessWidget {
  final TextEditingController textCtrl;
  final VoidCallback onSend;

  const _AiMonitoredField({required this.textCtrl, required this.onSend});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: textCtrl,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                minLines: 1,
                maxLines: 3,
                decoration: InputDecoration(
                  isDense: true,
                  hintText: 'စာတို ရိုက်ထည့်ရန်...',
                  filled: true,
                  fillColor: AppColors.lightBg,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Semantics(
              button: true,
              label: 'အသံဖြင့် ပြောရန်',
              child: IconButton(
                icon: const Icon(Icons.mic_none_rounded, color: AppColors.purple700),
                tooltip: 'အသံဖြင့် ပြောရန်',
                onPressed: () =>
                    showActivitySnack(context, 'အသံဖြင့် စာရိုက်ခြင်းကို မကြာမီ ထည့်သွင်းပါမည်။'),
              ),
            ),
            Container(
              decoration: const BoxDecoration(color: AppColors.purple700, shape: BoxShape.circle),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.shield_outlined, size: AppSizes.iconSm, color: AppColors.indigo500),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                'စာတိုများကို ပို့မီ AI ဖြင့် စစ်ဆေးပါသည်။ မသင့်လျော်သော အကြောင်းအရာ၊ ကိုယ်ရေးကိုယ်တာ ဆက်သွယ်ရန် အချက်အလက် သို့မဟုတ် သံသယဖြစ်ဖွယ် တောင်းဆိုမှုများ ပါဝင်ပါက ပိတ်ပင်ခံရနိုင်ပါသည်။',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Live "current task" booking card — the one task across Discussing →
// Task Marked. Self-hides in sections where this phase doesn't belong.
// ---------------------------------------------------------------------------

class LiveTaskBookingCard extends ConsumerWidget {
  final ActivityRole role;
  final int filterIndex; // 0 = Task Marked, 1 = Discussing, 2 = History

  const LiveTaskBookingCard({super.key, required this.role, required this.filterIndex});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final phase = ref.watch(taskPhaseProvider);
    final task = ref.watch(discussionTaskProvider);

    final bool show = filterIndex == 0
        ? phase == TaskPhase.marked
        : filterIndex == 1
            ? (phase == TaskPhase.discussing || phase == TaskPhase.confirmed)
            : false;
    if (!show) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final isClient = role == ActivityRole.client;
    final counterpartName = isClient ? kDiscussionTaskerName : kDiscussionClientName;
    final counterpartEmoji = isClient ? kTaskerEmoji : kClientEmoji;

    final (String statusText, Color statusColor, Color statusBg) = switch (phase) {
      TaskPhase.discussing => ('ဆွေးနွေးနေဆဲ', AppColors.indigo700, AppColors.indigo100),
      TaskPhase.confirmed => ('သဘောတူပြီး', AppColors.purple700, AppColors.purple100),
      TaskPhase.marked => ('အလုပ်လက်ခံပြီး', AppColors.tealDark, AppColors.blue100),
    };

    return Card(
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Stack(
        children: [
          if (phase == TaskPhase.marked)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(height: AppSpacing.xxs, color: AppColors.teal),
            ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm, vertical: AppSpacing.xxs),
                            decoration: BoxDecoration(
                              color: statusBg,
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                            ),
                            child: Text(
                              statusText,
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: statusColor,
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            task.skillLabel,
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '${task.date} • ${task.timeSlot} • ${task.location}',
                            style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: AppColors.blue100,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            phase == TaskPhase.marked ? 'ESCROW' : 'သဘောတူဈေး',
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.purple500,
                            ),
                          ),
                          Text(
                            '${task.budgetMmk ~/ 1000}K MMK',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.orangeDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.lightBg,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: AppSpacing.md,
                        child: Text(counterpartEmoji, style: theme.textTheme.bodyLarge),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          counterpartName,
                          style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      if (phase == TaskPhase.marked)
                        IconButton(
                          tooltip: 'အလုပ်အခြေအနေ စာတိုပို့ရန်',
                          icon: const Icon(Icons.chat_bubble_outline,
                              size: AppSpacing.lg, color: AppColors.purple700),
                          onPressed: () => openProgressChat(
                            context,
                            role: role,
                            counterpartName: counterpartName,
                            counterpartEmoji: counterpartEmoji,
                          ),
                        )
                      else
                        IconButton(
                          tooltip: 'ဆွေးနွေးရန်',
                          icon: const Icon(Icons.forum_outlined,
                              size: AppSpacing.lg, color: AppColors.indigo700),
                          onPressed: () => openDiscussionChat(
                            context,
                            role: role,
                            counterpartName: counterpartName,
                            counterpartEmoji: counterpartEmoji,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                _liveTaskCta(context, phase, isClient, counterpartName, counterpartEmoji),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _liveTaskCta(
    BuildContext context,
    TaskPhase phase,
    bool isClient,
    String counterpartName,
    String counterpartEmoji,
  ) {
    switch (phase) {
      case TaskPhase.discussing:
        return LargeButton(
          label: 'ဆွေးနွေးမှု ဆက်လုပ်ရန်',
          icon: Icons.forum_outlined,
          gradient: AppColors.purpleGradient,
          onTap: () => openDiscussionChat(
            context,
            role: role,
            counterpartName: counterpartName,
            counterpartEmoji: counterpartEmoji,
          ),
        );
      case TaskPhase.confirmed:
        if (isClient) {
          return LargeButton(
            label: 'Escrow ဖြင့် ငွေပေးချေရန်',
            icon: Icons.lock_outline,
            gradient: AppColors.purpleGradient,
            onTap: () => openEscrowPage(context),
          );
        }
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.blue100,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Text(
            'နှစ်ဦးသဘောတူပြီး — အလုပ်ရှင်က Escrow ငွေပေးချေမှု ဆောင်ရွက်နေပါသည်။',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
        );
      case TaskPhase.marked:
        return LargeButton(
          label: 'အလုပ်အခြေအနေ ကြည့်ရန်',
          icon: Icons.local_shipping_outlined,
          gradient: AppColors.purpleGradient,
          onTap: () => openProgressChat(
            context,
            role: role,
            counterpartName: counterpartName,
            counterpartEmoji: counterpartEmoji,
          ),
        );
    }
  }
}

// ---------------------------------------------------------------------------
// Escrow payment page (Phase 3 entry, demo only)
// ---------------------------------------------------------------------------

class EscrowPaymentScreen extends ConsumerStatefulWidget {
  const EscrowPaymentScreen({super.key});

  @override
  ConsumerState<EscrowPaymentScreen> createState() => _EscrowPaymentScreenState();
}

class _EscrowPaymentScreenState extends ConsumerState<EscrowPaymentScreen> {
  bool _paid = false;

  void _pay() {
    setState(() => _paid = true);
    ref.read(taskPhaseProvider.notifier).state = TaskPhase.marked;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final task = ref.watch(discussionTaskProvider);

    return Scaffold(
      backgroundColor: AppColors.lightBg,
      appBar: AppBar(
        backgroundColor: AppColors.purple700,
        foregroundColor: AppColors.onBrand,
        title: const Text('Escrow ငွေပေးချေမှု'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.blue100,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: AppColors.blue300.withValues(alpha: 0.4)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.shield_outlined, color: AppColors.purple500),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      'သင်သည် ယခု Toly Moly သို့ လုံခြုံစွာ ငွေပေးချေနေပါသည်။ အလုပ် ပြီးဆုံးသည်အထိ ငွေကို ထိန်းသိမ်းထားပါမည်။',
                      style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textPrimary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.lightSurface,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                boxShadow: [BoxShadow(color: AppColors.shadowSm, blurRadius: AppSpacing.md)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ငွေပေးချေမှု အကျဉ်းချုပ်',
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: AppSpacing.md),
                  _summaryRow(theme, 'ဝန်ဆောင်မှု', task.skillLabel),
                  _summaryRow(theme, 'ရက်စွဲ', task.date),
                  _summaryRow(theme, 'အချိန်', task.timeSlot),
                  _summaryRow(theme, 'နေရာ', task.location),
                  const Divider(height: AppSpacing.xl),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Escrow ထဲ ထိန်းသိမ်းမည့် ပမာဏ',
                          style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                      Text(
                        formatMmk(task.budgetMmk),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.purple700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            if (_paid)
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: AppColors.success),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        'ငွေကို Escrow ထဲ လုံခြုံစွာ ထိန်းသိမ်းထားပါပြီ။ အလုပ်သည် Bookings ထဲ "အလုပ်လက်ခံပြီး" အပိုင်းသို့ ရွှေ့သွားပါပြီ။',
                        style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.tealDark),
                      ),
                    ),
                  ],
                ),
              )
            else
              LargeButton(
                label: '${formatMmk(task.budgetMmk)} ပေးချေမည်',
                icon: Icons.lock_outline,
                gradient: AppColors.purpleGradient,
                onTap: _pay,
              ),
            if (_paid) ...[
              const SizedBox(height: AppSpacing.md),
              LargeButton(
                label: 'ပြီးပါပြီ',
                filled: false,
                outlineColor: AppColors.purple700,
                onTap: () => Navigator.of(context).pop(),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            Center(
              child: Text(
                'ဤသည် သရုပ်ပြ (demo) ငွေပေးချေမှုသာ ဖြစ်ပါသည်။',
                style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(ThemeData theme, String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.xs),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
            Text(value, style: theme.textTheme.bodyMedium),
          ],
        ),
      );
}
