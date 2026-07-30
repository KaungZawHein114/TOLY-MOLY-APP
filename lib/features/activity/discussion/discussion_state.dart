import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../activity_chat.dart' show ActivityRole;
import 'discussion_models.dart';

// ---------------------------------------------------------------------------
// DISCUSSION — SHARED STATE
//
// One timeline, shared by both sides (like discussionTaskProvider and
// taskPhaseProvider in activity_chat.dart). What the client answers is what
// the tasker sees when the demo switches role.
//
// Phase-1 safe: plain StateProviders and synchronous helpers — no notifier
// layer, no repository, no async.
// ---------------------------------------------------------------------------

/// The discussion begins the moment the tasker taps "Interested", so the
/// client always walks into a greeting plus the tasker's three questions
/// already waiting — never an empty room.
const List<DiscussionMessage> kSeedMessages = [
  DiscussionMessage(
    id: 'seed-hello',
    author: ActivityRole.tasker,
    text: 'မင်္ဂလာပါ။ ဒီအလုပ်ကို ကျွန်တော် စိတ်ဝင်စားပါတယ်။ '
        'မစခင် နည်းနည်းလေး မေးချင်တာ ရှိလို့ပါ။',
    time: '၅ မိနစ်က',
  ),
  DiscussionMessage(
    id: 'seed-photo',
    author: ActivityRole.tasker,
    kind: MessageKind.question,
    topic: DiscussionTopic.photo,
    answerStyle: AnswerStyle.upload,
    text: 'ပျက်နေတဲ့ ရေမော်တာကို ဓာတ်ပုံ ရိုက်ပို့ပေးပါ။',
    time: '၅ မိနစ်က',
  ),
  DiscussionMessage(
    id: 'seed-helper',
    author: ActivityRole.tasker,
    kind: MessageKind.question,
    topic: DiscussionTopic.helper,
    answerStyle: AnswerStyle.yesNo,
    text: 'ဒီပြုပြင်မှုအတွက် လက်ထောက် တစ်ယောက် ခေါ်လာလို့ ရမလား။',
    time: '၄ မိနစ်က',
  ),
  DiscussionMessage(
    id: 'seed-schedule',
    author: ActivityRole.tasker,
    kind: MessageKind.question,
    topic: DiscussionTopic.schedule,
    answerStyle: AnswerStyle.accept,
    text: 'ရောက်မယ့်အချိန်ကို ညနေ ၅:၀၀ ပြောင်းလို့ ရမလား။',
    time: '၄ မိနစ်က',
  ),
];

/// The second conversation: agreed, paid, and waiting for the tasker to show
/// up. It opens on the escrow confirmation so the client can see, in the
/// conversation itself, that their money is held safely.
const List<DiscussionMessage> kProgressSeedMessages = [
  DiscussionMessage(
    id: 'progress-escrow',
    kind: MessageKind.system,
    text: 'ငွေကို Escrow ထဲ လုံခြုံစွာ ထိန်းသိမ်းထားပါပြီ ✓',
    time: 'မနက်က',
  ),
  DiscussionMessage(
    id: 'progress-hello',
    author: ActivityRole.tasker,
    text: 'မင်္ဂလာပါ။ ဆွေးနွေးထားတဲ့အတိုင်း ဒီနေ့ လာပါမယ်နော်။',
    time: 'မနက်က',
  ),
  DiscussionMessage(
    id: 'progress-ok',
    author: ActivityRole.client,
    text: 'ဟုတ်ကဲ့၊ ကျေးဇူးတင်ပါတယ်။ စောင့်နေပါမယ်။',
    time: 'မနက်က',
  ),
];

/// Everything said in this discussion, oldest first.
final discussionMessagesProvider =
    StateProvider<List<DiscussionMessage>>((ref) => kSeedMessages);

/// The progress conversation's own timeline. A separate task, so a separate
/// list — but the same model and the same widgets render it.
final progressMessagesProvider =
    StateProvider<List<DiscussionMessage>>((ref) => kProgressSeedMessages);

/// How far along the tasker is. One value, read by both sides.
final arrivalStatusProvider =
    StateProvider<ArrivalStatus>((ref) => ArrivalStatus.preparing);

StateProvider<List<DiscussionMessage>> messagesProviderFor(ConversationMode mode) =>
    mode == ConversationMode.progress
        ? progressMessagesProvider
        : discussionMessagesProvider;

/// Which sides have tapped "Ready to Proceed". Payment needs both.
final discussionReadyProvider =
    StateProvider<Set<ActivityRole>>((ref) => const <ActivityRole>{});

/// The new arrival time proposed by the schedule question. Accepting it
/// rewrites the shared task, so the booking card and the escrow summary can
/// never show a stale time.
const String kProposedArrivalTime = 'ညနေ ၅:၀၀';

// ---------------------------------------------------------------------------
// Mutations (synchronous, called straight from widget callbacks)
// ---------------------------------------------------------------------------

typedef MessagesProvider = StateProvider<List<DiscussionMessage>>;

void addMessage(WidgetRef ref, MessagesProvider provider, DiscussionMessage message) {
  ref.read(provider.notifier).state = [...ref.read(provider), message];
}

void addMessages(
  WidgetRef ref,
  MessagesProvider provider,
  List<DiscussionMessage> newMessages,
) {
  ref.read(provider.notifier).state = [...ref.read(provider), ...newMessages];
}

void markAnswered(WidgetRef ref, MessagesProvider provider, String id) {
  ref.read(provider.notifier).state = [
    for (final m in ref.read(provider)) m.id == id ? m.copyWith(answered: true) : m,
  ];
}

String newMessageId(String prefix) => '$prefix-${DateTime.now().microsecondsSinceEpoch}';

/// Topics already raised — the ask menu hides them so nobody asks twice.
Set<DiscussionTopic> askedTopics(List<DiscussionMessage> messages) => {
      for (final m in messages)
        if (m.topic != null) m.topic!,
    };

int openQuestionsFor(List<DiscussionMessage> messages, ActivityRole role) =>
    messages.where((m) => m.isMyTurn(role)).length;

// ---------------------------------------------------------------------------
// Answer scripts.
//
// Answering is two bubbles, not a form submit: what I said, then what they
// said back. Written the way the two people would actually say it.
// ---------------------------------------------------------------------------

class AnswerScript {
  /// The answering side's own bubble.
  final String mine;

  /// The scripted reply that comes straight back.
  final String theirs;

  /// Photos attached to the answer bubble (placeholder thumbnails).
  final int photos;

  /// Set when accepting the answer also rewrites the shared task.
  final String? newTimeSlot;

  const AnswerScript(this.mine, this.theirs, {this.photos = 0, this.newTimeSlot});
}

AnswerScript answerScriptFor(DiscussionTopic topic, {required bool positive}) {
  switch (topic) {
    case DiscussionTopic.photo:
      return const AnswerScript(
        'ဓာတ်ပုံ ပို့လိုက်ပါပြီနော်။',
        'ကျေးဇူးတင်ပါတယ်။ ဓာတ်ပုံကြည့်ပြီး လိုအပ်တာတွေ ကြိုယူလာပါမယ်။',
        photos: 2,
      );
    case DiscussionTopic.helper:
      return positive
          ? const AnswerScript(
              'ရပါတယ်၊ လက်ထောက် ခေါ်လာလို့ ရပါတယ်။',
              'ကျေးဇူးတင်ပါတယ်။ နှစ်ယောက်ဆို ပိုမြန်ပါလိမ့်မယ်။',
            )
          : const AnswerScript(
              'လက်ထောက် မလိုပါဘူး။',
              'ရပါတယ်၊ ကျွန်တော် တစ်ယောက်တည်း လာပါမယ်။',
            );
    case DiscussionTopic.schedule:
      return positive
          ? const AnswerScript(
              'ညနေ ၅:၀၀ ဆို အဆင်ပြေပါတယ်။',
              'ကျေးဇူးတင်ပါတယ်။ ညနေ ၅:၀၀ မှာ ရောက်ပါမယ်။',
              newTimeSlot: kProposedArrivalTime,
            )
          : const AnswerScript(
              'မူလ ချိန်းထားတဲ့ အချိန်အတိုင်းပဲ ထားပါ။',
              'ရပါတယ်၊ မူလအချိန်အတိုင်း လာပါမယ်။',
            );
    case DiscussionTopic.materials:
      return positive
          ? const AnswerScript(
              'ရှိပါတယ်၊ ပြင်ဆင်ပေးထားပါမယ်။',
              'ကျေးဇူးတင်ပါတယ်။ ဒါဆို ပိုမြန်ပါလိမ့်မယ်။',
            )
          : const AnswerScript(
              'အိမ်မှာ မရှိပါဘူး။',
              'ရပါတယ်၊ ကျွန်တော် ယူလာပါမယ်။',
            );
    case DiscussionTopic.extraCost:
      return positive
          ? const AnswerScript(
              'နားလည်ပါပြီ။ လိုအပ်ရင် ပြောပါ။',
              'ကျေးဇူးတင်ပါတယ်။ တကယ်လိုအပ်မှသာ ကြိုအသိပေးပါမယ်။',
            )
          : const AnswerScript(
              'မလဲခင် ကျွန်တော့်ကို အရင် အသိပေးပါ။',
              'ရပါတယ်၊ မလုပ်ခင် ကြိုပြောပါမယ်။',
            );
    default:
      return positive
          ? const AnswerScript('ရပါတယ်။', 'ကျေးဇူးတင်ပါတယ် ခင်ဗျာ။')
          : const AnswerScript('မရသေးပါဘူး။', 'ရပါတယ်၊ နားလည်ပါတယ်။');
  }
}

// ---------------------------------------------------------------------------
// One state, two points of view.
//
// The client and the tasker read the same [arrivalStatusProvider]; only the
// wording changes. Keeping both strings in one place is what stops the two
// sides drifting into describing different things.
// ---------------------------------------------------------------------------

String arrivalStatusText(
  ArrivalStatus status,
  ActivityRole viewer,
  String counterpartName,
) {
  final isClient = viewer == ActivityRole.client;
  switch (status) {
    case ArrivalStatus.preparing:
      return isClient
          ? '$counterpartName ပြင်ဆင်နေပါသည်'
          : 'သင် ပြင်ဆင်နေသည် — အလုပ်ရှင် စောင့်နေပါသည်';
    case ArrivalStatus.onTheWay:
      return isClient
          ? '$counterpartName လမ်းမှာ ရောက်နေပါပြီ'
          : 'သင် လမ်းမှာ ရှိသည် — အလုပ်ရှင်ကို အသိပေးပြီးပါပြီ';
    case ArrivalStatus.arrived:
      return isClient
          ? '$counterpartName အိမ်ရှေ့ ရောက်နေပါပြီ'
          : 'သင် ရောက်ရှိပြီ — အလုပ်ရှင် ဂိတ်ဖွင့်ပေးပါလိမ့်မယ်';
  }
}

IconData arrivalStatusIcon(ArrivalStatus status) => switch (status) {
      ArrivalStatus.preparing => Icons.inventory_2_outlined,
      ArrivalStatus.onTheWay => Icons.directions_bike_outlined,
      ArrivalStatus.arrived => Icons.pin_drop_outlined,
    };
