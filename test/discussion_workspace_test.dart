import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:toly_moly/core/theme/app_theme.dart';
import 'package:toly_moly/features/activity/activity_chat.dart';
import 'package:toly_moly/features/activity/discussion/discussion_workspace_sheet.dart';

/// The discussion page is a Collaborative Agreement Workspace: structured
/// decision cards with a visible progress count, not a chat transcript.
void main() {
  final listFinder = find
      .descendant(
        of: find.byKey(const Key('discussionWorkspaceList')),
        matching: find.byType(Scrollable),
      )
      .first;

  // The mascot's idle float never stops, so pumpAndSettle would time out —
  // the rest of the suite settles with fixed pumps for the same reason.
  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  Future<void> scrollTo(WidgetTester tester, Finder finder) async {
    await tester.scrollUntilVisible(finder, 150, scrollable: listFinder);
    await settle(tester);
  }

  Future<void> openWorkspace(WidgetTester tester, ActivityRole role) async {
    await tester.binding.setSurfaceSize(const Size(420, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light,
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => openDiscussionWorkspace(
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
    );
    await tester.tap(find.text('open'));
    await settle(tester);
  }

  testWidgets('opens with the six-topic checklist and a live progress count',
      (tester) async {
    await openWorkspace(tester, ActivityRole.client);

    // Seeded: duration answered, photos still pending.
    expect(find.text('ဆွေးနွေးမှု ပြီးစီးမှု'), findsOneWidget);
    expect(find.text('1 / 6'), findsOneWidget);
    expect(find.text('ဖြေဆိုရန် ကျန်နေသေးသည် — 1 ခု'), findsOneWidget);

    // Every checklist topic is visible whether or not a card exists for it.
    expect(find.text('ဓာတ်ပုံ'), findsOneWidget);
    expect(find.text('ပစ္စည်း'), findsOneWidget);
    expect(find.text('လက်ထောက်'), findsOneWidget);
  });

  testWidgets('answering a card settles it and advances the progress count',
      (tester) async {
    await openWorkspace(tester, ActivityRole.client);

    final uploadButton = find.text('ဓာတ်ပုံ တင်ရန်');
    await scrollTo(tester, uploadButton);
    await tester.tap(uploadButton);
    await settle(tester);

    expect(find.text('ဓာတ်ပုံ 2 ပုံ လက်ခံရရှိပါပြီ'), findsOneWidget);
    expect(find.text('ဖြေကြားပြီး'), findsWidgets);

    await scrollTo(tester, find.text('ဆွေးနွေးမှု ပြီးစီးမှု'));
    expect(find.text('2 / 6'), findsOneWidget);
  });

  testWidgets('a second request for the same topic is refused, not duplicated',
      (tester) async {
    await openWorkspace(tester, ActivityRole.client);

    // The client asks about duration — the tasker already answered that one.
    await tester.tap(find.text('ကြာချိန် မေးရန်'));
    await settle(tester);

    expect(find.textContaining('ဆွေးနွေးမှု ရှိပြီးသားပါ'), findsOneWidget);
    expect(find.text('ခန့်မှန်း ကြာမြင့်ချိန်'), findsOneWidget);
  });

  testWidgets('both sides must confirm before escrow unlocks', (tester) async {
    await openWorkspace(tester, ActivityRole.client);

    await tester.tap(find.text('အဆင်သင့် ဖြစ်ပါပြီ'));
    await settle(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'အဆင်သင့် ဖြစ်ပါပြီ'));
    await settle(tester);

    // One side only: no payment yet.
    final waiting = find.text('တစ်ဖက်လူ၏ အတည်ပြုချက်ကို စောင့်နေသည်');
    await scrollTo(tester, waiting);
    expect(waiting, findsOneWidget);
    expect(find.text('Escrow ဖြင့် ငွေပေးချေရန်'), findsNothing);

    final simulate = find.text('သရုပ်ပြ — တစ်ဖက်လူ အတည်ပြုသည်');
    await scrollTo(tester, simulate);
    await tester.tap(simulate);
    await settle(tester);

    final agreed = find.text('နှစ်ဦးစလုံး သဘောတူပြီးပါပြီ');
    await scrollTo(tester, agreed);
    expect(agreed, findsOneWidget);
    expect(find.text('Escrow ဖြင့် ငွေပေးချေရန်'), findsOneWidget);
  });

  testWidgets('the tasker raises a materials card through the composer',
      (tester) async {
    await openWorkspace(tester, ActivityRole.tasker);

    await tester.tap(find.text('ပစ္စည်း မေးရန်'));
    await settle(tester);

    // Pre-filled, so the common case is open → confirm.
    expect(find.text('PVC တိပ်'), findsOneWidget);
    await tester.tap(find.text('ပစ္စည်းစာရင်း ပေးပို့ရန်'));
    await settle(tester);

    final card = find.text('လိုအပ်သော ပစ္စည်းများ');
    await scrollTo(tester, card);
    expect(card, findsOneWidget);

    // It now waits on the client, and the topic shows as pending.
    await scrollTo(tester, find.text('ဆွေးနွေးမှု ပြီးစီးမှု'));
    expect(find.text('ဖြေဆိုရန် ကျန်နေသေးသည် — 2 ခု'), findsOneWidget);
  });

  testWidgets('does not overflow at 360dp width and 1.6x text scale',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          size: Size(360, 800),
          textScaler: TextScaler.linear(1.6),
        ),
        child: ProviderScope(
          child: MaterialApp(
            theme: AppTheme.light,
            home: Builder(
              builder: (context) => Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () => openDiscussionWorkspace(
                      context,
                      role: ActivityRole.client,
                      counterpartName: kDiscussionTaskerName,
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
    expect(tester.takeException(), isNull);

    await scrollTo(tester, find.text('ဓာတ်ပုံ တင်ရန်'));
    await tester.tap(find.text('ဓာတ်ပုံ တင်ရန်'));
    await settle(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the tasker sees tasker actions and waits on the client',
      (tester) async {
    await openWorkspace(tester, ActivityRole.tasker);

    // Tasker-only smart actions.
    expect(find.text('ပစ္စည်း မေးရန်'), findsOneWidget);
    expect(find.text('လက်ထောက် ခေါ်ရန်'), findsOneWidget);

    // The seeded photo request came from the tasker, so it waits on the client.
    final waiting = find.textContaining('အဖြေကို စောင့်နေပါသည်');
    await scrollTo(tester, waiting);
    expect(waiting, findsOneWidget);
    expect(find.text('ဓာတ်ပုံ တင်ရန်'), findsNothing);
  });
}
