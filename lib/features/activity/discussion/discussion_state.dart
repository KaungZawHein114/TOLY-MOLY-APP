import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../activity_chat.dart' show ActivityRole;
import 'discussion_models.dart';

// ---------------------------------------------------------------------------
// DISCUSSION WORKSPACE — SHARED STATE
//
// Deliberately module-level (like discussionTaskProvider / taskPhaseProvider in
// activity_chat.dart) rather than screen-local: the whole point of the
// workspace is that both sides see the same agreement. When the demo switches
// role, the tasker must see the photos the client just uploaded.
//
// Phase-1 safe: plain StateProviders + synchronous helpers. No notifier layer,
// no repository, no async.
// ---------------------------------------------------------------------------

/// A casual chat line. Unlike the old me/them bubbles this stores *who* wrote
/// it, because one log is now rendered from both sides.
enum DiscussionMsgKind { text, system, warning }

@immutable
class DiscussionMessage {
  final String text;
  final String time;

  /// null for system/AI lines.
  final ActivityRole? authorRole;
  final DiscussionMsgKind kind;

  const DiscussionMessage({
    required this.text,
    this.time = 'ယခု',
    this.authorRole,
    this.kind = DiscussionMsgKind.text,
  });
}

// ---------------------------------------------------------------------------
// Seed — a live-looking workspace the moment the page opens.
// ---------------------------------------------------------------------------

const List<DiscussionItem> kSeedDiscussionItems = [
  DiscussionItem(
    id: 'seed-duration',
    type: DiscussionItemType.durationRequest,
    creatorRole: ActivityRole.tasker,
    title: 'ခန့်မှန်း ကြာမြင့်ချိန်',
    description: 'ဒီအလုပ်အတွက် ကျွန်တော် ခန့်မှန်းထားတဲ့ အချိန်ပါ။',
    status: DiscussionStatus.answered,
    data: {'duration': '၂ နာရီ'},
    createdAt: '၁၀ မိနစ်က',
  ),
  DiscussionItem(
    id: 'seed-photo',
    type: DiscussionItemType.photoRequest,
    creatorRole: ActivityRole.tasker,
    title: 'ပျက်စီးမှု ဓာတ်ပုံ ပို့ပေးပါ',
    description: 'ပျက်စီးနေတဲ့ နေရာကို ဓာတ်ပုံ ၂ ပုံလောက် ရိုက်ပို့ပေးပါ။ '
        'ကြိုတင် ပြင်ဆင်ထားနိုင်အောင်ပါ။',
    createdAt: '၈ မိနစ်က',
  ),
];

const List<DiscussionMessage> kSeedDiscussionChat = [
  DiscussionMessage(
    text: 'မင်္ဂလာပါ။ အလုပ်အသေးစိတ်ကို အောက်က ကတ်လေးတွေနဲ့ တစ်ဆင့်ချင်း ညှိကြရအောင်နော်။',
    time: '၁၀ မိနစ်က',
    authorRole: ActivityRole.tasker,
  ),
  DiscussionMessage(
    text: 'ဟုတ်ကဲ့ ရပါတယ်။ ကျေးဇူးတင်ပါတယ်။',
    time: '၉ မိနစ်က',
    authorRole: ActivityRole.client,
  ),
];

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

/// Every discussion card, oldest first.
final discussionItemsProvider = StateProvider<List<DiscussionItem>>(
  (ref) => kSeedDiscussionItems,
);

/// The casual chat log that sits under the cards.
final discussionChatProvider = StateProvider<List<DiscussionMessage>>(
  (ref) => kSeedDiscussionChat,
);

/// Which sides have pressed "Ready to Proceed". Escrow only unlocks at two.
final discussionReadyProvider = StateProvider<Set<ActivityRole>>(
  (ref) => const <ActivityRole>{},
);

// ---------------------------------------------------------------------------
// Mutation helpers (synchronous, called straight from widget callbacks)
// ---------------------------------------------------------------------------

void addDiscussionItem(WidgetRef ref, DiscussionItem item) {
  final items = ref.read(discussionItemsProvider);
  ref.read(discussionItemsProvider.notifier).state = [...items, item];
}

void updateDiscussionItem(WidgetRef ref, DiscussionItem item) {
  final items = ref.read(discussionItemsProvider);
  ref.read(discussionItemsProvider.notifier).state = [
    for (final existing in items) existing.id == item.id ? item : existing,
  ];
}

void addDiscussionMessage(WidgetRef ref, DiscussionMessage message) {
  final chat = ref.read(discussionChatProvider);
  ref.read(discussionChatProvider.notifier).state = [...chat, message];
}

/// The one open card of [type], if any. A rejected proposal doesn't block a new
/// one — you're meant to be able to propose a different time after a "no".
DiscussionItem? openItemOfType(
  List<DiscussionItem> items,
  DiscussionItemType type,
) {
  for (final item in items) {
    if (item.type == type && item.status != DiscussionStatus.rejected) {
      return item;
    }
  }
  return null;
}

/// How many of the six checklist topics are settled.
int settledTopicCount(List<DiscussionItem> items) {
  return kDiscussionChecklist
      .where((type) => (openItemOfType(items, type)?.status.isSettled) ?? false)
      .length;
}

/// True when nothing is waiting on anyone — the moment "Ready to Proceed"
/// stops being a guess.
bool hasNoPendingItems(List<DiscussionItem> items) =>
    items.every((item) => !item.status.isPending);

String newDiscussionId(DiscussionItemType type) =>
    '${type.name}-${DateTime.now().microsecondsSinceEpoch}';

// ---------------------------------------------------------------------------
// Scripted counterpart answers.
//
// The demo runs on one device, so a card you create is stuck waiting on a
// person who isn't there. Every waiting card therefore offers a clearly
// labelled "demo answer" control that plays this script — the same trick the
// existing chat engine uses for its scripted replies.
// ---------------------------------------------------------------------------

DiscussionItem demoAnswerFor(DiscussionItem item) {
  switch (item.type) {
    case DiscussionItemType.photoRequest:
      return item.withData({'photos': 2}).copyWith(status: DiscussionStatus.answered);
    case DiscussionItemType.materialChecklist:
      final materials = item.materials;
      return item.withData({
        'have': materials.take(materials.length > 1 ? materials.length - 1 : 0).toList(),
      }).copyWith(status: DiscussionStatus.answered);
    case DiscussionItemType.durationRequest:
      return item
          .withData({'duration': '၂ နာရီ'}).copyWith(status: DiscussionStatus.answered);
    case DiscussionItemType.apprenticeRequest:
      return item.copyWith(status: DiscussionStatus.accepted);
    case DiscussionItemType.extraCostProposal:
      if (!item.isCostFilled) {
        return item.withData({
          'item': 'ရေပိုက် အသစ်',
          'amount': 8000,
          'reason': 'လက်ရှိပိုက် ပျက်နေမှသာ လိုအပ်ပါမည်။',
        });
      }
      return item.copyWith(status: DiscussionStatus.accepted);
    case DiscussionItemType.scheduleProposal:
      return item.copyWith(status: DiscussionStatus.accepted);
  }
}

/// The chat line the counterpart "says" after a demo answer, so the log still
/// reads like a real two-sided conversation.
String demoAnswerNote(DiscussionItem item) {
  switch (item.type) {
    case DiscussionItemType.photoRequest:
      return 'ဓာတ်ပုံတွေ ပို့ပြီးပါပြီနော်။';
    case DiscussionItemType.materialChecklist:
      return 'ရှိတဲ့ ပစ္စည်းတွေကို အမှန်ခြစ် ပေးထားပါတယ်။';
    case DiscussionItemType.durationRequest:
      return 'ခန့်မှန်း ကြာချိန်ကို ဖြည့်ပေးလိုက်ပါပြီ။';
    case DiscussionItemType.apprenticeRequest:
      return 'လက်ထောက် တစ်ယောက် ပါလာလို့ ရပါတယ်။';
    case DiscussionItemType.extraCostProposal:
      return item.isCostFilled
          ? 'ဖြစ်နိုင်တဲ့ ကုန်ကျစရိတ်ကို နားလည်ပါပြီ။'
          : 'ဖြစ်နိုင်တဲ့ ကုန်ကျစရိတ်ကို ဖြည့်ပေးလိုက်ပါပြီ။';
    case DiscussionItemType.scheduleProposal:
      return 'အချိန်အသစ်ကို လက်ခံပါတယ်။';
  }
}
