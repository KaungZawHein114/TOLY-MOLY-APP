// AI Tasker Finder (spec §4.3) — verifies the LOCAL half of the feature, which
// is the half that decides what the client actually sees:
//   • the search + ranking never touch the network (the one network call is
//     the category classifier, mocked out of these tests entirely),
//   • the result NEVER invents a tasker: every id is one of the candidates,
//   • exact-category matches lead, ranked nearest-first but quality-aware,
//   • a category that runs short is topped up with clearly-separated
//     alternates (every real category in the demo data now has 5+ taskers,
//     so this only fires when a limit exceeds a category's pool),
//   • the same input always produces the same output.
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:toly_moly/core/constants/task_posting_strings.dart';
import 'package:toly_moly/core/data/demo_data.dart';
import 'package:toly_moly/core/theme/app_theme.dart';
import 'package:toly_moly/core/utils/ai_mock.dart';
import 'package:toly_moly/core/utils/ai_service.dart';
import 'package:toly_moly/features/customer/data/tasker_finder_api.dart';
import 'package:toly_moly/features/customer/widgets/tasker_shortlist_sheet.dart';

void main() {
  group('findTaskersMock', () {
    test('primary holds only the detected category, at most `limit`', () {
      final result = findTaskersMock('Plumber', workers, limit: 5);
      expect(result.primary, isNotEmpty);
      expect(result.primary.length, lessThanOrEqualTo(5));
      for (final m in result.primary) {
        final w = workers.firstWhere((w) => w.id == m.workerId);
        expect(w.skill, 'Plumber');
        expect(m.reason.trim(), isNotEmpty);
      }
    });

    test('primary is ordered best-first, and the nearest tasker leads a tie-free set', () {
      final result = findTaskersMock('Plumber', workers, limit: 5);
      final ordered = [
        for (final m in result.primary)
          workers.firstWhere((w) => w.id == m.workerId),
      ];
      for (var i = 1; i < ordered.length; i++) {
        expect(
          taskerFinderScore(ordered[i - 1]),
          greaterThanOrEqualTo(taskerFinderScore(ordered[i])),
        );
      }
      // Distance is the dominant signal: the top pick is among the closest.
      final plumbers = workers.where((w) => w.skill == 'Plumber').toList()
        ..sort((a, b) => a.distanceMiles.compareTo(b.distanceMiles));
      expect(
        ordered.first.distanceMiles,
        lessThanOrEqualTo(plumbers[1].distanceMiles),
      );
    });

    test('a request for more than the category has tops up with alternates', () {
      // Delivery has 5 taskers in the (expanded) demo data — asking for more
      // than that is what should trigger the related-category fill.
      final result = findTaskersMock('Delivery', workers, limit: 8);
      expect(result.primary.length, 5);
      expect(result.primary.length + result.alternates.length, 8);

      // Alternates are never the detected category — they are a separate,
      // separately-headed list, not a continuation of the exact matches.
      final primaryIds = {for (final m in result.primary) m.workerId};
      for (final m in result.alternates) {
        final w = workers.firstWhere((w) => w.id == m.workerId);
        expect(w.skill, isNot('Delivery'));
        expect(primaryIds.contains(m.workerId), isFalse);
      }
    });

    test('a full category needs no alternates at the default limit of 5', () {
      // Every category in the expanded demo data has at least 5 taskers, so
      // the default AI Tasker Finder search never needs to fall back.
      for (final category in const [
        'Plumber', 'Electrician', 'Cleaner', 'Carpenter', 'AC Technician',
        'Tutor', 'Handyman', 'Gardener', 'Delivery',
      ]) {
        final result = findTaskersMock(category, workers, limit: 5);
        expect(result.primary.length, 5, reason: category);
        expect(result.alternates, isEmpty, reason: category);
      }
    });

    test('a full category needs no alternates', () {
      final result = findTaskersMock('Plumber', workers, limit: 2);
      expect(result.primary.length, 2);
      expect(result.alternates, isEmpty);
    });

    test('related categories are offered before unrelated ones', () {
      final result = findTaskersMock('Delivery', workers, limit: 8);
      // "Handyman" is Delivery's related category, so a Handyman must lead the
      // alternates ahead of any unrelated skill.
      final firstAlternate =
          workers.firstWhere((w) => w.id == result.alternates.first.workerId);
      expect(firstAlternate.skill, 'Handyman');
    });

    test('an unknown category still returns bookable taskers', () {
      final result = findTaskersMock('Astronaut', workers, limit: 5);
      expect(result.primary, isEmpty);
      expect(result.alternates.length, 5);
    });

    test('is deterministic across calls', () {
      final a = findTaskersMock('Electrician', workers, limit: 5);
      final b = findTaskersMock('Electrician', workers, limit: 5);
      expect(a.primary.map((m) => m.workerId).toList(),
          b.primary.map((m) => m.workerId).toList());
      expect(a.alternates.map((m) => m.workerId).toList(),
          b.alternates.map((m) => m.workerId).toList());
    });

    test('empty candidates -> empty result', () {
      final result = findTaskersMock('Plumber', const [], limit: 5);
      expect(result.primary, isEmpty);
      expect(result.alternates, isEmpty);
    });
  });

  group('AiService.findTaskers (local, deterministic)', () {
    test('returns the local result and marks the source', () async {
      final shortlist = await AiService.findTaskers(
        category: 'Cleaner',
        candidates: workers,
      );
      expect(shortlist.primary, isNotEmpty);
      expect(shortlist.primary.length + shortlist.alternates.length,
          lessThanOrEqualTo(5));
      for (final m in [...shortlist.primary, ...shortlist.alternates]) {
        expect(m.source, AiSource.demo);
        expect(m.reason.trim(), isNotEmpty);
        // Never invents: id must be a real candidate.
        expect(workers.any((w) => w.id == m.workerId), isTrue);
      }
      final top =
          workers.firstWhere((w) => w.id == shortlist.primary.first.workerId);
      expect(top.skill, 'Cleaner');
    });

    test('empty candidate list returns empty (no hang)', () async {
      final shortlist = await AiService.findTaskers(
        category: 'Plumber',
        candidates: const [],
      );
      expect(shortlist.isEmpty, isTrue);
    });
  });

  group('category fallback (backend unreachable)', () {
    setUp(() {
      AiConfig.demoThinkingDelay = Duration.zero;
      // Point the classifier at a dead port so the fallback path runs whether
      // or not a real Django server happens to be up on this machine.
      AiService.taskerFinderApi = TaskerFinderApi(
        dio: Dio(BaseOptions(
          baseUrl: 'http://127.0.0.1:1',
          connectTimeout: const Duration(milliseconds: 200),
          receiveTimeout: const Duration(milliseconds: 200),
        )),
      );
    });
    tearDown(() => AiService.taskerFinderApi = TaskerFinderApi());

    test('falls back to the local keyword matcher without throwing', () async {
      // The user-facing guarantee: a backend outage never shows an error, it
      // just quietly produces a slightly less clever category.
      final result = await AiService.classifyServiceCategory('my sink is leaking');
      expect(result.source, AiSource.demo);
      expect(result.confidence, 0);
      expect(result.category, 'Plumber');
    });

    test('an unintelligible request still yields a searchable category', () async {
      final result = await AiService.classifyServiceCategory('asdfgh qwerty');
      expect(result.category.trim(), isNotEmpty);
      final shortlist = await AiService.findTaskers(
        category: result.category,
        candidates: workers,
      );
      expect(shortlist.isEmpty, isFalse);
    });
  });

  // The sheet itself, driven end to end with the backend unreachable — the
  // demo's worst case, and the one the client must never see fail.
  group('TaskerShortlistSheet', () {
    setUp(() {
      AiConfig.demoThinkingDelay = Duration.zero;
      AiService.taskerFinderApi = TaskerFinderApi(
        dio: Dio(BaseOptions(
          baseUrl: 'http://127.0.0.1:1',
          connectTimeout: const Duration(milliseconds: 200),
          receiveTimeout: const Duration(milliseconds: 200),
        )),
      );
    });
    tearDown(() => AiService.taskerFinderApi = TaskerFinderApi());

    // PhoWaYoke idles on a repeating animation, so pumpAndSettle can never
    // settle here — pump a bounded number of frames instead, which is also
    // long enough for the (refused) classify call to fall back.
    Future<void> settle(WidgetTester tester) async {
      for (var i = 0; i < 25; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    Future<void> pumpSheet(WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(body: TaskerShortlistSheet(candidates: workers)),
      ));
      await settle(tester);
    }

    testWidgets('asks first, and refuses to search on an empty description',
        (tester) async {
      await pumpSheet(tester);
      expect(find.text(TaskPostingStrings.matchAskTitle), findsOneWidget);

      await tester.tap(find.text(TaskPostingStrings.matchAskSubmit));
      await settle(tester);

      expect(find.text(TaskPostingStrings.matchAskEmptyError), findsOneWidget);
      // Still on the question — nothing was searched.
      expect(find.text(TaskPostingStrings.matchAskTitle), findsOneWidget);
    });

    testWidgets('describe -> results: exact category shown, ≤5 taskers, no fill needed',
        (tester) async {
      await pumpSheet(tester);
      await tester.enterText(find.byType(TextField), 'my sink is leaking');
      await tester.tap(find.text(TaskPostingStrings.matchAskSubmit));
      await settle(tester);

      // The detected category is shown back to the client.
      expect(
        find.text('${TaskPostingStrings.matchCategoryPrefix} Plumber'),
        findsOneWidget,
      );

      final cards = find.text(TaskPostingStrings.matchPickButton);
      expect(cards, findsWidgets);
      expect(tester.widgetList(cards).length, lessThanOrEqualTo(5));

      // The demo data now has 7 Plumbers — enough to fill the shortlist on
      // its own, so the related-category fill (covered at the findTaskersMock
      // unit level above) must NOT appear here.
      expect(find.text(TaskPostingStrings.matchAlternatesHeading), findsNothing);
    });

    testWidgets('"ask again" returns to the question', (tester) async {
      await pumpSheet(tester);
      await tester.enterText(find.byType(TextField), 'clean my apartment');
      await tester.tap(find.text(TaskPostingStrings.matchAskSubmit));
      await settle(tester);
      expect(find.text(TaskPostingStrings.matchAskTitle), findsNothing);

      // The correction affordance next to the detected category — reachable
      // without scrolling past the whole shortlist.
      final askAgain = find.byTooltip(TaskPostingStrings.matchAskAgain);
      expect(askAgain, findsOneWidget);
      await tester.tap(askAgain);
      await settle(tester);
      expect(find.text(TaskPostingStrings.matchAskTitle), findsOneWidget);
      // The description is kept and pre-selected, so a correction is a
      // retype, not a retype-from-scratch.
      expect(find.text('clean my apartment'), findsOneWidget);
    });
  });
}
