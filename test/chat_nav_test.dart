// Overall navigation/chat mode (spec §4.5) — verifies the extended intent
// contract and the intent → Routes.* table:
//   • the offline mock classifies post/find/find_tasker/edit_profile and stays
//     backwards-compatible for the original post/find inputs;
//   • chatNavTargetFor maps each action to the right Routes.* destination
//     (role-aware), and general/off_topic map to no button.
import 'package:flutter_test/flutter_test.dart';

import 'package:toly_moly/core/routing/app_router.dart';
import 'package:toly_moly/core/utils/ai_mock.dart';
import 'package:toly_moly/features/chatbot/chat_nav.dart';

void main() {
  group('chatAssistantReply intent detection (offline mock)', () {
    test('client "find a plumber" -> find_tasker', () {
      final r = chatAssistantReply('Find a plumber', 'client');
      expect(r.intent, 'find_tasker');
      expect(r.action, 'find_tasker');
    });

    test('client "I need to fix my sink" -> post_task (unchanged)', () {
      final r = chatAssistantReply('I need to fix my sink', 'client');
      expect(r.intent, 'post_task');
      expect(r.action, 'post_task');
    });

    test('tasker "find plumbing jobs" -> find_task (unchanged)', () {
      final r = chatAssistantReply('find plumbing jobs', 'tasker');
      expect(r.intent, 'find_task');
      expect(r.action, 'find_task');
    });

    test('"edit my profile" -> edit_profile', () {
      final r = chatAssistantReply('I want to edit my profile', 'client');
      expect(r.intent, 'edit_profile');
      expect(r.action, 'edit_profile');
    });

    test('tasker never gets find_tasker', () {
      final r = chatAssistantReply('find a worker', 'tasker');
      expect(r.intent, isNot('find_tasker'));
    });

    test('off-topic stays refused with no action', () {
      final r = chatAssistantReply('What is the capital of France?', 'client');
      expect(r.intent, 'off_topic');
      expect(r.action, isNull);
    });
  });

  group('chatNavTargetFor routing table', () {
    test('post_task -> postTask (push)', () {
      final t = chatNavTargetFor('post_task', 'client')!;
      expect(t.route, Routes.postTask);
      expect(t.reset, isFalse);
    });

    test('find_task -> dashboard (reset + focus job search)', () {
      final t = chatNavTargetFor('find_task', 'tasker')!;
      expect(t.route, Routes.dashboard);
      expect(t.reset, isTrue);
      expect(t.focusJobSearch, isTrue);
    });

    test('find_tasker -> worker list', () {
      final t = chatNavTargetFor('find_tasker', 'client')!;
      expect(t.route, Routes.workerList);
    });

    test('edit_profile is role-aware', () {
      expect(chatNavTargetFor('edit_profile', 'client')!.route,
          Routes.clientProfileScreen);
      expect(chatNavTargetFor('edit_profile', 'tasker')!.route,
          Routes.taskerProfileScreen);
    });

    test('general / unknown -> no button', () {
      expect(chatNavTargetFor('general', 'client'), isNull);
      expect(chatNavTargetFor(null, 'client'), isNull);
    });
  });
}
