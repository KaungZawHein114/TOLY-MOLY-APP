// ============================================================================
// AI SERVICE — the async seam every AI-flavoured feature in the app calls
// through. As of 2026-07-29 (the Firebase-removal / "AI becomes demo logic"
// refactor) every method except [chatAssistant] (client role) and
// [taskAssistant] makes NO network call of any kind: each is a thin async
// wrapper around a synchronous, deterministic mock in ai_mock.dart.
// [evaluateTask] additionally pauses [AiConfig.demoThinkingDelay] first (a
// pre-existing choice from an earlier session, kept as-is) so its caller's
// loading UI reads as "thinking" rather than flashing for a frame.
//
// TWO real backends exist and are each a SEPARATE agent — different prompt,
// different Django app, different Flutter API client, on purpose. Never
// share code between them:
// - [chatAssistant] (client role only): the floating App Assistant —
//   `backend/apps/assistant/`, `AssistantApi`, live-with-fallback to the
//   local mock in ai_mock.dart.
// - [taskAssistant]: the AI Task Assistant conversation (Task Posting's "AI
//   Assistant" method) — `backend/apps/tasks/` (`analyze_task`),
//   `TaskAssistantApi`, live-with-fallback to `taskAssistantFallbackTurn` in
//   ai_mock.dart. Design: docs/superpowers/specs/2026-07-29-ai-task-assistant-design.md.
//
// This file used to proxy 10 Firebase Cloud Functions (OpenAI, plus Pinecone
// for the chatbot's knowledge answers) with live-with-fallback behaviour.
// That backend is gone; the exact prompts it used are preserved for
// reference in docs/ai/cloud-function-prompts.md. One method,
// extractOnboarding, had zero remaining callers (the onboarding voice-auth
// flow was already rewritten to a fixed demo sequence in an earlier session)
// and was deleted outright rather than converted.
// ============================================================================

import '../constants/task_posting_strings.dart' show TaskPostingStrings;
import '../data/demo_data.dart' show Worker;
import '../../features/chatbot/data/assistant_api.dart';
import '../../features/customer/task_posting/data/task_assistant_api.dart';
import '../../features/onboarding/onboarding_models.dart' show Gender, TaskerSkill;
import 'ai_mock.dart';

/// Runtime switches for the AI layer.
class AiConfig {
  AiConfig._();

  /// A short, deliberate pause before a locally-simulated answer lands, so
  /// loading/typing indicators built for a real network round-trip still
  /// read as "thinking" instead of flashing for a single frame. Fixed, never
  /// random — the demo is reproducible. Tests set this to [Duration.zero].
  static Duration demoThinkingDelay = const Duration(milliseconds: 700);
}

/// Where a given AI result came from. Every method in this file now always
/// returns [demo] — [live] and [mock] are kept only so existing UI badge
/// checks (`source == AiSource.mock` → show an "offline" hint) keep
/// compiling; neither can be produced anymore, so those checks are
/// permanently inert. Left in place deliberately rather than ripped out of
/// every call site for a same-day refactor — worth revisiting if this enum
/// is ever simplified.
enum AiSource { live, mock, demo }

/// AI "Task Attractiveness" read-out for the review screen.
class TaskEvaluation {
  final int score; // 0..100
  final List<String> strengths;
  final List<String> weaknesses;
  final List<String> missing;
  final AiSource source;
  const TaskEvaluation({
    required this.score,
    required this.strengths,
    required this.weaknesses,
    required this.missing,
    required this.source,
  });
}

/// One assistant reply for the in-app chatbot.
/// - [action] ("post_task" | "find_task" | null) drives the inline button.
/// - [intent] is the broader classification ("post_task" | "find_task" |
///   "general" | "off_topic"); kept distinct from [action] so new intents
///   (faq, payment, support, …) can be added later without a UI break.
class ChatReply {
  final String message;
  final String? action;
  final String? intent;
  final AiSource source;
  const ChatReply({
    required this.message,
    this.action,
    this.intent,
    required this.source,
  });
}

/// The only actions the chatbot UI knows how to act on. Each maps to a
/// suggested navigation button via `chatNavTargetFor` (spec §4.5) — the
/// assistant never auto-navigates.
const Set<String> kChatActions = {
  'post_task',
  'find_task',
  'find_tasker',
  'edit_profile',
  'view_activity',
  'verification',
};

/// One turn of the AI Task Assistant conversation (Task Posting's "AI
/// Assistant" method) — a SEPARATE agent from [ChatReply]'s floating App
/// Assistant, with its own backend (`backend/apps/tasks`, not
/// `backend/apps/assistant`) and its own fallback engine. `fields` is the
/// merged known-fields map, same shape the backend/fallback both use:
/// {category, title, description, township, address, date, time, urgency,
/// category_fields}. `reply` is either the next question or (once `ready`)
/// a confirmation recap.
class TaskAssistantReply {
  final Map<String, dynamic> fields;
  final String reply;
  final bool ready;
  final AiSource source;
  const TaskAssistantReply({
    required this.fields,
    required this.reply,
    required this.ready,
    required this.source,
  });
}

/// One AI-ranked tasker recommendation for the Tasker-Finding shortlist
/// (spec §4.3). [workerId] is ALWAYS an id from the candidate list the app
/// supplied — the mock orders and explains, it never invents a tasker or a
/// stat. [reason] is a short Burmese "why I picked them".
class TaskerMatch {
  final int workerId;
  final String reason;
  final AiSource source;
  const TaskerMatch({
    required this.workerId,
    required this.reason,
    required this.source,
  });
}

/// Fields pulled from a spoken self-introduction for the Onboarding voice mode
/// (spec §4.1/§4.6). Every field is what the user actually SAID — the extractor
/// never invents, so any field it couldn't hear stays empty/null for the user to
/// fill manually on the real form. [skills] is only meaningful for taskers.
/// Password is deliberately never extracted (typed privately).
class OnboardingExtraction {
  final String name;
  final Gender? gender;
  final int? age;
  final String phone;
  final List<TaskerSkill> skills;
  final AiSource source;
  const OnboardingExtraction({
    this.name = '',
    this.gender,
    this.age,
    this.phone = '',
    this.skills = const [],
    required this.source,
  });

  /// True if the extractor found at least one usable field — lets the UI decide
  /// whether to offer the pre-filled preview or send the user to manual entry.
  bool get hasAnything =>
      name.isNotEmpty ||
      gender != null ||
      age != null ||
      phone.isNotEmpty ||
      skills.isNotEmpty;
}

/// Gentle "make your waiting post more attractive" tips (spec §4.4 Phase 1).
/// Wording only — the app decides WHEN to show them (time-since-post).
class TaskFixTips {
  final List<String> tips;
  final AiSource source;
  const TaskFixTips({required this.tips, required this.source});
}

/// Completion summary + a SUGGESTED tier move (spec §4.4 Phase 3). The delta is
/// only a recommendation in [-1, 1]; the real tier change is applied by the
/// backend's transparent rules + the client's rating, never by the model.
class CompletionSummary {
  final String summary;
  final int suggestedTierDelta; // -1 | 0 | +1 — a suggestion, not an action
  final String rationale;
  final AiSource source;
  const CompletionSummary({
    required this.summary,
    required this.suggestedTierDelta,
    required this.rationale,
    required this.source,
  });
}

/// A tasker's per-task brief (spec §4.8): what the client wants + prep/tools.
class TaskerBrief {
  final String summary;
  final List<String> suggestions;
  final AiSource source;
  const TaskerBrief({
    required this.summary,
    required this.suggestions,
    required this.source,
  });
}

class AiService {
  AiService._();

  /// The scripted "thinking" beat before a locally-simulated answer.
  static Future<void> _demoPause() =>
      Future<void>.delayed(AiConfig.demoThinkingDelay);

  // ── Review: attractiveness score + breakdown ────────────────────────────
  static Future<TaskEvaluation> evaluateTask(Map<String, dynamic> task) async {
    await _demoPause();
    return _mockEvaluateTask(task);
  }

  // ── Chatbot: app-scoped, intent-aware assistant ─────────────────────────
  /// Sends a user [message] (with the user's [role]) to the assistant and
  /// returns a [ChatReply].
  ///
  /// Two different agents live behind this one call, branched by [role]:
  /// - **client**: the real App Assistant — `POST /api/assistant/chat`
  ///   (a separate Django app/service from the Task Posting AI Conversation,
  ///   see `backend/apps/assistant/`). On ANY failure (no network, backend
  ///   down, malformed response) this falls through to the same local mock
  ///   taskers use, seamlessly — the user never sees an error state.
  /// - **tasker**: unchanged — the local rule-based/templated mock. The
  ///   tasker-side assistant is a later phase (see `chatbotScreen`'s [role]).
  ///
  /// [history] is an optional recent transcript for light context, newest last:
  /// each entry is `{ 'role': 'user'|'assistant', 'text': '...' }`.
  static final AssistantApi _assistantApi = AssistantApi();

  static Future<ChatReply> chatAssistant({
    required String message,
    required String role,
    List<Map<String, String>> history = const [],
  }) async {
    if (role == 'client') {
      try {
        final result =
            await _assistantApi.chat(message: message, history: history);
        return ChatReply(
          message: result.message,
          action: result.actionId,
          source: AiSource.live,
        );
      } catch (_) {
        // Backend/network unavailable — fall through to the local mock
        // below. No error shown; the conversation just keeps going.
      }
    }
    final mock = chatAssistantReply(message, role);
    return ChatReply(
      message: mock.message,
      action: mock.action,
      intent: mock.intent,
      source: AiSource.demo,
    );
  }

  // ── AI Task Assistant conversation (Task Posting's "AI Assistant") ─────
  /// One turn of the Task Assistant conversation — a SEPARATE agent from
  /// [chatAssistant] above, with its own backend
  /// (`POST /api/tasks/ai/analyze`, `backend/apps/tasks`) and its own local
  /// fallback engine (`taskAssistantFallbackTurn` in ai_mock.dart). Never
  /// shares an HTTP client, a prompt, or a response shape with the App
  /// Assistant.
  ///
  /// Tries the real backend first; on ANY failure (no network, timeout,
  /// malformed response) falls through to the local engine, seamlessly — no
  /// error state, [TaskAssistantReply.source] is the only trace of which
  /// path answered. The caller (the chat screen) is expected to remember
  /// once fallback fires and skip the network attempt on later turns in the
  /// same conversation (design doc §10 — no per-turn retries once sticky);
  /// [taskAssistantOffline] is the direct entry point for that.
  ///
  /// [history] entries are `{'role': 'user'|'assistant', 'content': '...'}`.
  /// [knownFields] is the running merged-fields map (see [TaskAssistantReply]).
  static final TaskAssistantApi _taskAssistantApi = TaskAssistantApi();

  static Future<TaskAssistantReply> taskAssistant({
    required String message,
    required List<Map<String, String>> history,
    required Map<String, dynamic> knownFields,
    required int questionsAsked,
  }) async {
    try {
      final result = await _taskAssistantApi.analyze(
        message: message,
        history: history,
        knownFields: knownFields,
      );
      return TaskAssistantReply(
        fields: result.fields,
        reply: result.reply,
        ready: result.ready,
        source: AiSource.live,
      );
    } catch (_) {
      // Backend/network unavailable — fall through to the local engine.
      return taskAssistantOffline(
        message: message,
        knownFields: knownFields,
        questionsAsked: questionsAsked,
      );
    }
  }

  /// The local fallback engine directly, with no network attempt at all.
  /// Called from the second turn onward once a conversation has already
  /// fallen back once (sticky per design doc §10).
  static Future<TaskAssistantReply> taskAssistantOffline({
    required String message,
    required Map<String, dynamic> knownFields,
    required int questionsAsked,
  }) async {
    await _demoPause();
    final result = taskAssistantFallbackTurn(
      message: message,
      knownFields: knownFields,
      questionsAsked: questionsAsked,
    );
    return TaskAssistantReply(
      fields: result.fields,
      reply: result.reply,
      ready: result.ready,
      source: AiSource.demo,
    );
  }

  // ── Tasker-Finding: ranked shortlist with reasons (spec §4.3) ───────────
  /// Ranks [candidates] for [task] and returns up to 3 [TaskerMatch]es, best
  /// first. Deterministic — the app pre-filters + supplies the candidates,
  /// and the ranking only ever returns ids from that set, so it can never
  /// invent a tasker or a stat.
  static Future<List<TaskerMatch>> matchTaskers({
    required Map<String, dynamic> task,
    required List<Worker> candidates,
  }) async {
    if (candidates.isEmpty) return const [];
    return [
      for (final r in matchTaskersMock(task, candidates))
        TaskerMatch(workerId: r.workerId, reason: r.reason, source: AiSource.demo),
    ];
  }

  // ── Task-Handling mode (spec §4.4/§4.8) ─────────────────────────────────
  /// Gentle fixes for a task that has waited [ageHours] with no taker.
  /// Wording only; the app decides WHEN to show them (time-since-post).
  static Future<TaskFixTips> suggestTaskFixes({
    required Map<String, dynamic> task,
    required int ageHours,
  }) async {
    return TaskFixTips(
      tips: taskFixTipsMock(task, ageHours),
      source: AiSource.demo,
    );
  }

  /// Summarizes a completed task and RECOMMENDS a tier move (spec §4.4 Phase 3).
  /// The delta is a suggestion only, clamped to [-1, 1]; the app/backend rules +
  /// client rating decide the real tier.
  static Future<CompletionSummary> summarizeCompletion({
    required Map<String, dynamic> task,
    Map<String, dynamic> timing = const {},
    Map<String, dynamic> review = const {},
  }) async {
    final mock = completionSummaryMock(task: task, timing: timing, review: review);
    return CompletionSummary(
      summary: mock.summary,
      suggestedTierDelta: mock.suggestedTierDelta,
      rationale: mock.rationale,
      source: AiSource.demo,
    );
  }

  /// Briefs a tasker before a task: what the client wants + prep/tools (§4.8).
  /// Wording only, read aloud in the app.
  static Future<TaskerBrief> briefTasker({
    required Map<String, dynamic> task,
  }) async {
    final mock = taskerBriefMock(task);
    return TaskerBrief(
      summary: mock.summary,
      suggestions: mock.suggestions,
      source: AiSource.demo,
    );
  }

  // ── Offline simulation ──────────────────────────────────────────────────
  /// Deterministic completeness scoring.
  static TaskEvaluation _mockEvaluateTask(Map<String, dynamic> task) {
    final hasCategory = (task['category']?.toString() ?? '').isNotEmpty;
    final hasLocation = (task['location']?.toString() ?? '').isNotEmpty;
    final hasSchedule = (task['date']?.toString() ?? '').isNotEmpty &&
        (task['time']?.toString() ?? '').isNotEmpty;
    final hasTier = (task['tier']?.toString() ?? '').isNotEmpty;
    final desc = task['description']?.toString() ?? '';
    final budget = _asInt(task['budget']) ?? 0;
    final urgent = task['urgent'] == true;

    var score = 0;
    if (hasCategory) score += 15;
    if (hasLocation) score += 15;
    if (hasSchedule) score += 15;
    if (hasTier) score += 10;
    if (desc.trim().length >= 40) {
      score += 20;
    } else if (desc.trim().length >= 15) {
      score += 10;
    }
    if (budget > 0) score += 15;
    if (urgent) score += 10;
    score = score.clamp(0, 100);

    final strengths = <String>[];
    final weaknesses = <String>[];
    final missing = <String>[];
    if (hasLocation) strengths.add(TaskPostingStrings.evalStrengthLocation);
    if (budget > 0) strengths.add(TaskPostingStrings.evalStrengthBudget);
    if (urgent) strengths.add(TaskPostingStrings.evalStrengthUrgent);
    if (desc.trim().length < 40) weaknesses.add(TaskPostingStrings.evalWeaknessShortDesc);
    if (budget == 0) missing.add(TaskPostingStrings.evalMissingBudget);
    if (!hasSchedule) missing.add(TaskPostingStrings.evalMissingSchedule);
    if (strengths.isEmpty) strengths.add(TaskPostingStrings.evalStrengthGeneric);

    return TaskEvaluation(
      score: score,
      strengths: strengths,
      weaknesses: weaknesses,
      missing: missing,
      source: AiSource.demo,
    );
  }

  static int? _asInt(Object? v) {
    if (v is int) return v;
    if (v is double) return v.round();
    if (v is String) return int.tryParse(v.trim());
    return null;
  }
}
