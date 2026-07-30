// Tasker-Finding shortlist (spec §4.3) — verifies the deterministic, fully
// offline path:
//   • AiService.matchTaskers is a thin wrapper around the local mock — no
//     network, no backend, ever.
//   • The result NEVER invents a tasker: every id is one of the candidates.
//   • The shortlist is ≤3, skill-matched first, and reproducible.
import 'package:flutter_test/flutter_test.dart';

import 'package:toly_moly/core/data/demo_data.dart';
import 'package:toly_moly/core/utils/ai_mock.dart';
import 'package:toly_moly/core/utils/ai_service.dart';

void main() {
  group('matchTaskersMock', () {
    test('returns at most 3, all ids from the candidate set', () {
      final result = matchTaskersMock({'category': 'Plumber'}, workers);
      expect(result.length, lessThanOrEqualTo(3));
      final validIds = {for (final w in workers) w.id};
      for (final m in result) {
        expect(validIds.contains(m.workerId), isTrue);
        expect(m.reason.trim(), isNotEmpty);
      }
    });

    test('ranks a skill-matched candidate first', () {
      final result = matchTaskersMock({'category': 'Plumber'}, workers);
      expect(result, isNotEmpty);
      final top = workers.firstWhere((w) => w.id == result.first.workerId);
      expect(top.skill, 'Plumber');
    });

    test('is deterministic across calls', () {
      final a = matchTaskersMock({'category': 'Electrician'}, workers);
      final b = matchTaskersMock({'category': 'Electrician'}, workers);
      expect(a.map((m) => m.workerId).toList(),
          b.map((m) => m.workerId).toList());
    });

    test('empty candidates -> empty result', () {
      expect(matchTaskersMock({'category': 'Plumber'}, const []), isEmpty);
    });
  });

  group('AiService.matchTaskers (local, deterministic)', () {
    test('returns the mock result and marks the source', () async {
      final matches = await AiService.matchTaskers(
        task: {'category': 'Cleaner'},
        candidates: workers,
      );
      expect(matches, isNotEmpty);
      expect(matches.length, lessThanOrEqualTo(3));
      for (final m in matches) {
        expect(m.source, AiSource.demo);
        expect(m.reason.trim(), isNotEmpty);
        // Never invents: id must be a real candidate.
        expect(workers.any((w) => w.id == m.workerId), isTrue);
      }
      // Skill-matched tasker leads.
      final top = workers.firstWhere((w) => w.id == matches.first.workerId);
      expect(top.skill, 'Cleaner');
    });

    test('empty candidate list returns empty (no hang)', () async {
      final matches = await AiService.matchTaskers(
        task: {'category': 'Plumber'},
        candidates: const [],
      );
      expect(matches, isEmpty);
    });
  });
}
