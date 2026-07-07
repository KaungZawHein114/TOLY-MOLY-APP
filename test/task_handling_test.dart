// Task-Handling mode (spec §4.4/§4.8) — verifies the OFFLINE fallbacks:
//   • stale-post tips are short, non-empty, and templated;
//   • the completion summary's SUGGESTED tier delta stays in [-1, 1] and follows
//     the rating/timing signals (AI suggests; rules decide);
//   • the tasker brief always has a summary + prep suggestions.
import 'package:flutter_test/flutter_test.dart';

import 'package:toly_moly/core/utils/ai_mock.dart';
import 'package:toly_moly/core/utils/ai_service.dart';

void main() {
  setUp(() => AiConfig.useLiveAi = false);
  tearDown(() => AiConfig.useLiveAi = true);

  const task = {
    'category': 'Plumber',
    'township': 'လှိုင်',
    'budgetMmk': 12000,
    'urgent': false,
    'description': '',
  };

  group('taskFixTipsMock', () {
    test('returns 2–4 non-empty tips', () {
      final tips = taskFixTipsMock(task, 14);
      expect(tips.length, inInclusiveRange(2, 4));
      expect(tips.every((t) => t.trim().isNotEmpty), isTrue);
    });
  });

  group('completionSummaryMock', () {
    test('on-time, no rating -> suggests +1', () {
      final r = completionSummaryMock(
          task: task, timing: const {'onTime': true}, review: const {});
      expect(r.suggestedTierDelta, 1);
      expect(r.summary.trim(), isNotEmpty);
    });

    test('low rating -> suggests -1', () {
      final r = completionSummaryMock(
          task: task, timing: const {'onTime': true}, review: const {'rating': 2});
      expect(r.suggestedTierDelta, -1);
    });

    test('delta always within [-1, 1]', () {
      for (final onTime in [true, false]) {
        for (final rating in [null, 1, 3, 4.6, 5]) {
          final r = completionSummaryMock(
            task: task,
            timing: {'onTime': onTime},
            review: rating == null ? const {} : {'rating': rating},
          );
          expect(r.suggestedTierDelta, inInclusiveRange(-1, 1));
        }
      }
    });
  });

  group('taskerBriefMock', () {
    test('always has a summary and prep suggestions', () {
      final r = taskerBriefMock(task);
      expect(r.summary.trim(), isNotEmpty);
      expect(r.suggestions, isNotEmpty);
    });
  });

  group('AiService task-handling (offline fallback, marks source=mock)', () {
    test('suggestTaskFixes', () async {
      final r = await AiService.suggestTaskFixes(task: task, ageHours: 14);
      expect(r.source, AiSource.mock);
      expect(r.tips, isNotEmpty);
    });

    test('summarizeCompletion clamps + marks source', () async {
      final r = await AiService.summarizeCompletion(
          task: task, timing: const {'onTime': true});
      expect(r.source, AiSource.mock);
      expect(r.suggestedTierDelta, inInclusiveRange(-1, 1));
    });

    test('briefTasker', () async {
      final r = await AiService.briefTasker(task: task);
      expect(r.source, AiSource.mock);
      expect(r.summary.trim(), isNotEmpty);
    });
  });
}
