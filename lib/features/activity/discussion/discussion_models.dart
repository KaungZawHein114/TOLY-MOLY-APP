import 'package:flutter/material.dart';

import '../activity_chat.dart' show ActivityRole;

// ---------------------------------------------------------------------------
// DISCUSSION — MODELS
//
// The discussion is a conversation, not a form. Everything on the page is a
// message in one timeline; the only special kind is a *question* message,
// which carries a small answer control inside the bubble.
//
// Phase-1 safe: immutable value objects, no async, no backend.
// ---------------------------------------------------------------------------

/// Which conversation this is. The two states of one task: settling the
/// details, then getting the tasker to the door. Same components, same
/// timeline model — only the question list and the bar under the chat differ.
enum ConversationMode { discussion, progress }

/// How far along the tasker is on the day of the job. Shared by both sides:
/// each reads the same value and words it from their own point of view.
enum ArrivalStatus { preparing, onTheWay, arrived }

/// What a message is. `question` bubbles wait for a tap; the rest just read.
enum MessageKind { text, question, system, warning }

/// How a question is answered when the other side has to act.
/// `none` means the counterpart answers instantly with a scripted reply.
enum AnswerStyle { none, upload, yesNo, accept }

/// The subject of a question. Also stops the same thing being asked twice.
enum DiscussionTopic {
  // Tasker → client (need the client to act)
  photo,
  helper,
  schedule,
  // Client → tasker (answered instantly)
  duration,
  extraCost,
  materials,
  preparation,
  experience,
  arrival,
  // Tasker → client (answered instantly)
  parking,
  someoneHome,
  // Progress conversation — the job is paid for, nothing is being negotiated.
  progressArrival,
  progressPrepare,
  progressWhere,
  progressConfirmTime,
  progressOnTheWay,
  progressArrived,
  progressDelay,
  progressAddress,
}

ActivityRole counterpartOf(ActivityRole role) =>
    role == ActivityRole.client ? ActivityRole.tasker : ActivityRole.client;

String roleLabel(ActivityRole role) =>
    role == ActivityRole.client ? 'အလုပ်ရှင်' : 'ဝန်ဆောင်မှုပေးသူ';

@immutable
class DiscussionMessage {
  final String id;

  /// null for system / AI lines.
  final ActivityRole? author;
  final MessageKind kind;
  final String text;
  final String time;

  /// Set on question messages.
  final DiscussionTopic? topic;
  final AnswerStyle answerStyle;
  final bool answered;

  /// Placeholder photo count rendered inside the bubble.
  final int photos;

  const DiscussionMessage({
    required this.id,
    required this.text,
    this.author,
    this.kind = MessageKind.text,
    this.time = 'ယခု',
    this.topic,
    this.answerStyle = AnswerStyle.none,
    this.answered = false,
    this.photos = 0,
  });

  DiscussionMessage copyWith({bool? answered}) => DiscussionMessage(
        id: id,
        text: text,
        author: author,
        kind: kind,
        time: time,
        topic: topic,
        answerStyle: answerStyle,
        answered: answered ?? this.answered,
        photos: photos,
      );

  bool get isOpenQuestion =>
      kind == MessageKind.question && !answered && answerStyle != AnswerStyle.none;

  /// Who still has to tap something, or null when nothing is waiting.
  ActivityRole? get awaitingRole =>
      isOpenQuestion && author != null ? counterpartOf(author!) : null;

  bool isMyTurn(ActivityRole viewer) => awaitingRole == viewer;
}

/// A ready-made question offered in the "ask" menu.
///
/// [reply] non-null means the other side answers it instantly (demo scripts);
/// otherwise [answerStyle] decides which buttons appear in the bubble.
@immutable
class SuggestedQuestion {
  final DiscussionTopic topic;
  final IconData icon;

  /// Short label in the menu.
  final String label;

  /// The full sentence that gets sent into the chat.
  final String text;

  /// Scripted counterpart answer, for questions that need no action.
  final String? reply;
  final AnswerStyle answerStyle;

  /// Set on tasker status updates: sending it also moves the shared arrival
  /// status, so the client's strip changes without a second action.
  final ArrivalStatus? setsStatus;

  const SuggestedQuestion({
    required this.topic,
    required this.icon,
    required this.label,
    required this.text,
    this.reply,
    this.answerStyle = AnswerStyle.none,
    this.setsStatus,
  });
}

// ---------------------------------------------------------------------------
// Question menus — plain things a real person would actually ask.
// ---------------------------------------------------------------------------

/// What the client asks the tasker. Each one is a worry a Myanmar household
/// has before letting a stranger in: how long, how much, what do I prepare,
/// have you done this before, when are you coming.
const List<SuggestedQuestion> kClientQuestions = [
  SuggestedQuestion(
    topic: DiscussionTopic.duration,
    icon: Icons.timer_outlined,
    label: 'ဘယ်လောက်ကြာမလဲ',
    text: 'ဒီအလုပ်က ဘယ်လောက်ကြာနိုင်မလဲ ခင်ဗျာ။',
    reply: 'ခန့်မှန်းခြေ ၂ နာရီလောက် ကြာပါမယ်။',
  ),
  SuggestedQuestion(
    topic: DiscussionTopic.extraCost,
    icon: Icons.payments_outlined,
    label: 'ပိုကုန်မလား',
    text: 'ပြောထားတဲ့ဈေးအပြင် ထပ်ဆောင်း ပေးရမှာ ရှိလား။',
    reply: 'ပစ္စည်းအသစ် လဲစရာ မလိုရင် ထပ်ဆောင်းစရိတ် မရှိပါဘူး။ '
        'လိုအပ်ရင်တော့ ကြိုအသိပေးပါမယ်။',
  ),
  SuggestedQuestion(
    topic: DiscussionTopic.materials,
    icon: Icons.handyman_outlined,
    label: 'ပစ္စည်း ပြင်ဆင်ရမလား',
    text: 'ကျွန်တော့်ဘက်က ဘာပစ္စည်း ပြင်ဆင်ထားပေးရမလဲ။',
    reply: 'ကိရိယာတွေ ကျွန်တော် ယူလာပါမယ်။ ရေပုံးလေး တစ်လုံးလောက်ပဲ ပြင်ဆင်ပေးပါ။',
  ),
  SuggestedQuestion(
    topic: DiscussionTopic.preparation,
    icon: Icons.home_outlined,
    label: 'ကြိုလုပ်ထားရမလား',
    text: 'မလာခင် ကျွန်တော် ဘာလုပ်ထားရမလဲ။',
    reply: 'မော်တာ ပါဝါကို ကြိုပိတ်ထားပေးပါ။ ကျန်တာ ကျွန်တော် လုပ်ပါ့မယ်။',
  ),
  SuggestedQuestion(
    topic: DiscussionTopic.experience,
    icon: Icons.star_outline_rounded,
    label: 'အတွေ့အကြုံ',
    text: 'ဒီလိုအလုပ်မျိုး လုပ်ဖူးပါသလား။',
    reply: 'ဟုတ်ကဲ့၊ ရေမော်တာ ပြုပြင်မှု အများကြီး လုပ်ဖူးပါတယ်။',
  ),
  SuggestedQuestion(
    topic: DiscussionTopic.arrival,
    icon: Icons.schedule_outlined,
    label: 'ဘယ်အချိန် ရောက်မလဲ',
    text: 'ဘယ်အချိန်လောက် ရောက်နိုင်မလဲ ခင်ဗျာ။',
    reply: 'ဒီနေ့ ညနေ ၅ နာရီမှာ ရောက်ပါမယ်။',
  ),
];

/// What the tasker asks the client. The first three are the openers sent the
/// moment the tasker taps "Interested"; the rest stay in the menu.
const List<SuggestedQuestion> kTaskerQuestions = [
  SuggestedQuestion(
    topic: DiscussionTopic.photo,
    icon: Icons.photo_camera_outlined,
    label: 'ဓာတ်ပုံ တောင်းမည်',
    text: 'ပျက်နေတဲ့ ရေမော်တာကို ဓာတ်ပုံ ရိုက်ပို့ပေးပါ။',
    answerStyle: AnswerStyle.upload,
  ),
  SuggestedQuestion(
    topic: DiscussionTopic.helper,
    icon: Icons.groups_outlined,
    label: 'လက်ထောက် ခေါ်မည်',
    text: 'ဒီပြုပြင်မှုအတွက် လက်ထောက် တစ်ယောက် ခေါ်လာလို့ ရမလား။',
    answerStyle: AnswerStyle.yesNo,
  ),
  SuggestedQuestion(
    topic: DiscussionTopic.schedule,
    icon: Icons.event_outlined,
    label: 'အချိန် ပြောင်းမည်',
    text: 'ရောက်မယ့်အချိန်ကို ညနေ ၅:၀၀ ပြောင်းလို့ ရမလား။',
    answerStyle: AnswerStyle.accept,
  ),
  SuggestedQuestion(
    topic: DiscussionTopic.materials,
    icon: Icons.handyman_outlined,
    label: 'ပစ္စည်း မေးမည်',
    text: 'အိမ်မှာ ရေပုံးနဲ့ အဝတ်စုတ် ရှိပါသလား။',
    answerStyle: AnswerStyle.yesNo,
  ),
  SuggestedQuestion(
    topic: DiscussionTopic.extraCost,
    icon: Icons.payments_outlined,
    label: 'ဖြစ်နိုင်သော စရိတ်',
    text: 'ပိုက်အသစ် လဲရရင် ၈,၀၀၀ ကျပ်လောက် ထပ်ကုန်နိုင်ပါတယ်။ ရပါသလား။',
    answerStyle: AnswerStyle.yesNo,
  ),
  SuggestedQuestion(
    topic: DiscussionTopic.parking,
    icon: Icons.local_parking_outlined,
    label: 'ကားရပ်ရန်',
    text: 'အိမ်ရှေ့မှာ ဆိုင်ကယ် ရပ်လို့ ရပါသလား။',
    reply: 'ရပါတယ်၊ အိမ်ရှေ့မှာ ရပ်လို့ ရပါတယ်။',
  ),
  SuggestedQuestion(
    topic: DiscussionTopic.someoneHome,
    icon: Icons.person_outline,
    label: 'အိမ်မှာ လူရှိလား',
    text: 'ကျွန်တော် ရောက်တဲ့အချိန် အိမ်မှာ လူရှိမှာ သေချာလား။',
    reply: 'ဟုတ်ကဲ့၊ ကျွန်တော် ကိုယ်တိုင် စောင့်နေပါမယ်။',
  ),
];

// ---------------------------------------------------------------------------
// Progress conversation — after both sides agreed and the client paid.
//
// Nothing here negotiates anything: the agreement is closed. These are the
// things two people actually say between "paid" and "knocking on the door".
// ---------------------------------------------------------------------------

const List<SuggestedQuestion> kClientProgressQuestions = [
  SuggestedQuestion(
    topic: DiscussionTopic.progressArrival,
    icon: Icons.schedule_outlined,
    label: 'ဘယ်အချိန် ရောက်မလဲ',
    text: 'ဘယ်အချိန်လောက် ရောက်နိုင်မလဲ ခင်ဗျာ။',
    reply: 'ချိန်းထားတဲ့အတိုင်း ညနေ ၅ နာရီလောက် ရောက်ပါမယ်။',
  ),
  SuggestedQuestion(
    topic: DiscussionTopic.progressPrepare,
    icon: Icons.home_outlined,
    label: 'ဘာပြင်ဆင်ထားရမလဲ',
    text: 'မလာခင် ကျွန်တော် ဘာပြင်ဆင်ထားရမလဲ။',
    reply: 'မော်တာ ပါဝါကို ပိတ်ထားပေးပြီး၊ ရေပုံးလေး တစ်လုံး ပြင်ဆင်ပေးပါ။',
  ),
  SuggestedQuestion(
    topic: DiscussionTopic.progressWhere,
    icon: Icons.near_me_outlined,
    label: 'ဘယ်ရောက်နေပြီလဲ',
    text: 'ခုလောက်ဆို ဘယ်ရောက်နေပြီလဲ ခင်ဗျာ။',
    reply: 'လမ်းမှာ ရှိပါတယ်။ ၁၅ မိနစ်လောက်အတွင်း ရောက်ပါမယ်။',
  ),
];

const List<SuggestedQuestion> kTaskerProgressQuestions = [
  SuggestedQuestion(
    topic: DiscussionTopic.progressConfirmTime,
    icon: Icons.event_available_outlined,
    label: 'ရောက်ချိန် အတည်ပြုမည်',
    text: 'ချိန်းထားတဲ့အတိုင်း ညနေ ၅ နာရီ ရောက်ပါမယ်နော်။',
    reply: 'ဟုတ်ကဲ့၊ စောင့်နေပါမယ်။ ကျေးဇူးတင်ပါတယ်။',
    setsStatus: ArrivalStatus.preparing,
  ),
  SuggestedQuestion(
    topic: DiscussionTopic.progressOnTheWay,
    icon: Icons.directions_bike_outlined,
    label: 'ထွက်လာပြီ',
    text: 'ယခု ထွက်လာပါပြီ။',
    reply: 'ရပါတယ်၊ သတိနဲ့ လာပါနော်။',
    setsStatus: ArrivalStatus.onTheWay,
  ),
  SuggestedQuestion(
    topic: DiscussionTopic.progressArrived,
    icon: Icons.pin_drop_outlined,
    label: 'ရောက်ပါပြီ',
    text: 'အိမ်ရှေ့ ရောက်ပါပြီ။',
    reply: 'ဂိတ် ဖွင့်ပေးထားပါတယ်၊ ဝင်လာပါ။',
    setsStatus: ArrivalStatus.arrived,
  ),
  SuggestedQuestion(
    topic: DiscussionTopic.progressDelay,
    icon: Icons.update_outlined,
    label: 'နည်းနည်း နောက်ကျမည်',
    text: 'ယာဉ်ကြောပိတ်လို့ ၁၅ မိနစ်လောက် နောက်ကျနိုင်ပါတယ်။',
    reply: 'ရပါတယ်၊ ဖြည်းဖြည်း လာပါ။',
  ),
  SuggestedQuestion(
    topic: DiscussionTopic.progressAddress,
    icon: Icons.map_outlined,
    label: 'လိပ်စာ တောင်းမည်',
    text: 'လိပ်စာ တည်နေရာကို ပြန်ပို့ပေးနိုင်မလား။',
    reply: 'ခုပဲ တည်နေရာ ပြန်ပို့လိုက်ပါပြီ။',
  ),
];

List<SuggestedQuestion> questionsFor(ActivityRole role, ConversationMode mode) {
  if (mode == ConversationMode.progress) {
    return role == ActivityRole.client
        ? kClientProgressQuestions
        : kTaskerProgressQuestions;
  }
  return role == ActivityRole.client ? kClientQuestions : kTaskerQuestions;
}
