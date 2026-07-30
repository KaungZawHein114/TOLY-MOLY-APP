import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:toly_moly/core/theme/app_theme.dart';
import 'package:toly_moly/features/activity/activity_chat.dart';
import 'package:toly_moly/features/activity/discussion/discussion_chat_page.dart';
import 'package:toly_moly/features/activity/discussion/discussion_models.dart';

/// The discussion is a guided conversation: the tasker's questions arrive as
/// ordinary bubbles you answer with one tap, and payment only unlocks once
/// both sides say they are ready.
void main() {
  // The mascot's idle float never stops, so pumpAndSettle would time out —
  // the rest of the suite settles with fixed pumps for the same reason.
  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  Future<void> openDiscussion(
    WidgetTester tester,
    ActivityRole role, {
    Size size = const Size(420, 1200),
    double textScale = 1.0,
    ConversationMode mode = ConversationMode.discussion,
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(
          size: size,
          textScaler: TextScaler.linear(textScale),
        ),
        child: ProviderScope(
          child: MaterialApp(
            theme: AppTheme.light,
            home: Builder(
              builder: (context) => Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () => mode == ConversationMode.progress
                        ? openProgressChatPage(
                            context,
                            role: role,
                            counterpartName: role == ActivityRole.client
                                ? kProgressTaskerName
                                : kProgressClientName,
                            counterpartEmoji: kTaskerEmoji,
                            fixedTask: kProgressDemoTask,
                          )
                        : openDiscussionChatPage(
                            context,
                            role: role,
                            counterpartName: role == ActivityRole.client
                                ? kDiscussionTaskerName
                                : kDiscussionClientName,
                            counterpartEmoji: kTaskerEmoji,
                          ),
                    child: const Text('open'),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await settle(tester);
  }

  testWidgets('opens on the mascot line and the tasker\'s three questions',
      (tester) async {
    await openDiscussion(tester, ActivityRole.client);

    expect(
      find.text('ဒီနေရာမှာ အလုပ်မစခင် လိုအပ်တာတွေကို နှစ်ဖက် ညှိနိုင်ပါတယ်။'),
      findsOneWidget,
    );
    // Discussion starts when the tasker taps Interested, so the questions are
    // already waiting.
    expect(find.text('ပျက်နေတဲ့ ရေမော်တာကို ဓာတ်ပုံ ရိုက်ပို့ပေးပါ။'), findsOneWidget);
    expect(find.text('ဓာတ်ပုံ ပို့မည်'), findsOneWidget);
    // No permanent task summary, no progress bar.
    expect(find.text('ဆွေးနွေးမှု ပြီးစီးမှု'), findsNothing);
    expect(find.byType(LinearProgressIndicator), findsNothing);
  });

  testWidgets('answering a question adds both bubbles and clears the buttons',
      (tester) async {
    await openDiscussion(tester, ActivityRole.client);

    await tester.tap(find.text('ဓာတ်ပုံ ပို့မည်'));
    await settle(tester);

    expect(find.text('ဓာတ်ပုံ ပို့လိုက်ပါပြီနော်။'), findsOneWidget);
    expect(
      find.text('ကျေးဇူးတင်ပါတယ်။ ဓာတ်ပုံကြည့်ပြီး လိုအပ်တာတွေ ကြိုယူလာပါမယ်။'),
      findsOneWidget,
    );
    expect(find.text('ဓာတ်ပုံ ပို့မည်'), findsNothing);
  });

  testWidgets('accepting the new time rewrites the shared task', (tester) async {
    await openDiscussion(tester, ActivityRole.client);

    await tester.tap(find.text('လက်ခံမည်'));
    await settle(tester);

    expect(find.text('✅ ရောက်ချိန်ကို ညနေ ၅:၀၀ သို့ ပြောင်းလိုက်ပါပြီ'), findsOneWidget);

    // The task detail sheet shows the new time, not the old one.
    await tester.tap(find.text('အလုပ် အသေးစိတ် ကြည့်ရန်'));
    await settle(tester);
    expect(find.text('ဇွန် ၂၈ ရက် · ညနေ ၅:၀၀'), findsOneWidget);
  });

  testWidgets('the client picks a question and the tasker answers instantly',
      (tester) async {
    await openDiscussion(tester, ActivityRole.client);

    await tester.tap(find.text('ဝန်ဆောင်မှုပေးသူကို မေးရန်'));
    await settle(tester);

    final question = find.text('ဒီအလုပ်က ဘယ်လောက်ကြာနိုင်မလဲ ခင်ဗျာ။');
    expect(question, findsOneWidget);
    await tester.tap(question);
    await settle(tester);

    expect(find.text('ခန့်မှန်းခြေ ၂ နာရီလောက် ကြာပါမယ်။'), findsOneWidget);

    // Asked once: the menu no longer offers it, so the only copy on screen is
    // the bubble already in the conversation.
    await tester.tap(find.text('ဝန်ဆောင်မှုပေးသူကို မေးရန်'));
    await settle(tester);
    expect(find.text('ဒီအလုပ်က ဘယ်လောက်ကြာနိုင်မလဲ ခင်ဗျာ။'), findsOneWidget);
  });

  testWidgets('payment unlocks only after both sides are ready', (tester) async {
    await openDiscussion(tester, ActivityRole.client);

    // Open questions block the exit and say so.
    expect(find.textContaining('အရင် ဖြေပေးပါ'), findsOneWidget);
    expect(find.text('အဆင်သင့် ဖြစ်ပါပြီ'), findsNothing);

    // Each answer pushes the next question up the transcript, so the reminder
    // bar above the composer is what walks the user back to it.
    for (final label in ['ဓာတ်ပုံ ပို့မည်', 'ရပါတယ်', 'လက်ခံမည်']) {
      await tester.tap(find.textContaining('အရင် ဖြေပေးပါ'));
      await settle(tester);
      await tester.ensureVisible(find.text(label));
      await settle(tester);
      await tester.tap(find.text(label));
      await settle(tester);
    }

    await tester.tap(find.text('အဆင်သင့် ဖြစ်ပါပြီ'));
    await settle(tester);

    expect(find.textContaining('အတည်ပြုရန် စောင့်နေသည်'), findsOneWidget);
    expect(find.text('Escrow ဖြင့် ငွေပေးချေရန်'), findsNothing);

    await tester.tap(find.text('သရုပ်ပြ'));
    await settle(tester);

    expect(find.text('Escrow ဖြင့် ငွေပေးချေရန်'), findsOneWidget);
  });

  testWidgets('the tasker sees the same conversation and its own ask menu',
      (tester) async {
    await openDiscussion(tester, ActivityRole.tasker);

    // Its own questions are waiting on the client, not on itself.
    expect(find.text('ဓာတ်ပုံ ပို့မည်'), findsNothing);
    expect(find.text('အဖြေ စောင့်နေပါသည်'), findsWidgets);

    await tester.tap(find.text('အလုပ်ရှင်ကို မေးရန်'));
    await settle(tester);
    expect(find.text('အိမ်ရှေ့မှာ ဆိုင်ကယ် ရပ်လို့ ရပါသလား။'), findsOneWidget);
  });

  testWidgets('does not overflow at 360dp width and 1.6x text scale', (tester) async {
    await openDiscussion(
      tester,
      ActivityRole.client,
      size: const Size(360, 800),
      textScale: 1.6,
    );
    expect(tester.takeException(), isNull);

    await tester.tap(find.textContaining('အရင် ဖြေပေးပါ'));
    await settle(tester);
    await tester.ensureVisible(find.text('ဓာတ်ပုံ ပို့မည်'));
    await settle(tester);
    await tester.tap(find.text('ဓာတ်ပုံ ပို့မည်'));
    await settle(tester);
    expect(tester.takeException(), isNull);
  });

  // ── progress conversation ────────────────────────────────────────────────

  testWidgets('the paid conversation drops negotiation and shows arrival state',
      (tester) async {
    await openDiscussion(tester, ActivityRole.client, mode: ConversationMode.progress);

    expect(find.text('ငွေကို Escrow ထဲ လုံခြုံစွာ ထိန်းသိမ်းထားပါပြီ ✓'), findsOneWidget);
    expect(find.text('$kProgressTaskerName ပြင်ဆင်နေပါသည်'), findsOneWidget);

    // No agreement machinery once the money has moved.
    expect(find.text('အဆင်သင့် ဖြစ်ပါပြီ'), findsNothing);
    expect(find.textContaining('အရင် ဖြေပေးပါ'), findsNothing);

    // The questions offered are about arrival, not about terms.
    await tester.tap(find.text('ဝန်ဆောင်မှုပေးသူကို မေးရန်'));
    await settle(tester);
    expect(find.text('ဘယ်အချိန်လောက် ရောက်နိုင်မလဲ ခင်ဗျာ။'), findsOneWidget);
    expect(find.text('ဒီအလုပ်က ဘယ်လောက်ကြာနိုင်မလဲ ခင်ဗျာ။'), findsNothing);
  });

  testWidgets('a tasker status update moves the strip both sides read', (tester) async {
    await openDiscussion(tester, ActivityRole.tasker, mode: ConversationMode.progress);

    // The tasker's pill sends updates, it does not ask questions.
    await tester.tap(find.text('အခြေအနေ အသိပေးရန်'));
    await settle(tester);
    await tester.tap(find.text('ယခု ထွက်လာပါပြီ။'));
    await settle(tester);

    expect(find.text('ရပါတယ်၊ သတိနဲ့ လာပါနော်။'), findsOneWidget);
    // Same state, worded for the tasker.
    expect(find.textContaining('သင် လမ်းမှာ ရှိသည်'), findsOneWidget);
  });

  testWidgets('the progress thread shows its own task, not the live one', (tester) async {
    await openDiscussion(tester, ActivityRole.client, mode: ConversationMode.progress);

    await tester.tap(find.text('အလုပ် အသေးစိတ် ကြည့်ရန်'));
    await settle(tester);
    expect(find.text(kProgressDemoTask.skillLabel), findsOneWidget);
  });

  testWidgets('the side that has not confirmed is told it is being waited on',
      (tester) async {
    await openDiscussion(tester, ActivityRole.client);

    for (final label in ['ဓာတ်ပုံ ပို့မည်', 'ရပါတယ်', 'လက်ခံမည်']) {
      await tester.tap(find.textContaining('အရင် ဖြေပေးပါ'));
      await settle(tester);
      await tester.ensureVisible(find.text(label));
      await settle(tester);
      await tester.tap(find.text(label));
      await settle(tester);
    }

    // The tasker confirms first: the client sees whose move it is.
    await tester.tap(find.text('အဆင်သင့် ဖြစ်ပါပြီ'));
    await settle(tester);
    await tester.tap(find.text('သရုပ်ပြ'));
    await settle(tester);
    expect(find.text('Escrow ဖြင့် ငွေပေးချေရန်'), findsOneWidget);
  });
}
