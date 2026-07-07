// ============================================================================
// AI SERVICE — the async "real AI" seam for the Task Posting flow ONLY.
// ----------------------------------------------------------------------------
// Each method tries a Firebase Cloud Function (which proxies OpenAI, keeping
// the API key server-side) and, on ANY failure — Firebase not configured yet,
// no network, timeout, bad response — falls back to the synchronous offline
// mock in ai_mock.dart. So the demo NEVER hangs or crashes: worst case it
// quietly behaves exactly like the old offline build.
//
// This is the only place in the app that touches the network. Everything
// outside Task Posting still uses ai_mock.dart directly and stays offline.
// ============================================================================

import 'package:cloud_functions/cloud_functions.dart';

import '../constants/task_posting_strings.dart' show TaskPostingStrings;
import '../data/demo_data.dart' show Worker;
import '../../features/onboarding/onboarding_models.dart'
    show Gender, TaskerSkill, TaskerSkillLabel, UserRole;
import 'ai_mock.dart';

/// Runtime switches for the AI layer. The real app leaves [useLiveAi] true
/// (live-with-fallback); tests flip it false for instant, deterministic mock
/// behaviour with no Firebase dependency.
class AiConfig {
  AiConfig._();

  /// When false, [AiService] skips Firebase entirely and returns the offline
  /// mock immediately. When true, it tries live first and falls back to mock.
  static bool useLiveAi = true;

  /// How long to wait on a Cloud Function before falling back to the mock.
  static const Duration timeout = Duration(seconds: 12);
}

/// Where a given AI result actually came from — lets the UI show a subtle
/// "offline" hint when the live call didn't succeed.
enum AiSource { live, mock }

/// AI-recommended budget band, in MMK.
class PriceRange {
  final int low;
  final int high;
  final AiSource source;
  const PriceRange({required this.low, required this.high, required this.source});

  /// Classifies a user-entered [amount] against this band.
  PriceStatus statusFor(int amount) {
    if (amount < low) return PriceStatus.low;
    if (amount > high) return PriceStatus.high;
    return PriceStatus.ok;
  }
}

enum PriceStatus { low, ok, high }

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
};

/// One AI-ranked tasker recommendation for the Tasker-Finding shortlist
/// (spec §4.3). [workerId] is ALWAYS an id from the candidate list the app
/// supplied — the model orders and explains, it never invents a tasker or a
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

  static FirebaseFunctions get _functions => FirebaseFunctions.instance;

  static Future<Map<String, dynamic>?> _call(
    String name,
    Map<String, dynamic> payload,
  ) async {
    if (!AiConfig.useLiveAi) return null;
    try {
      final result = await _functions
          .httpsCallable(name)
          .call(payload)
          .timeout(AiConfig.timeout);
      final data = result.data;
      if (data is Map) {
        return data.map((key, value) => MapEntry(key.toString(), value));
      }
      return null;
    } catch (e) {
      // ignore: avoid_print
      print('AiService._call($name) failed: $e');
      return null;
    }
  }

  // ── Screen 1: suggest a category from the title ─────────────────────────
  /// Returns one value from [categories] (the app's existing skill list) — the
  /// AI is constrained to that list, so the suggestion is always applicable.
  static Future<String> suggestCategory(
    String title,
    List<String> categories,
  ) async {
    final data = await _call('suggestCategory', {
      'title': title,
      'categories': categories,
    });
    final cat = data?['category']?.toString();
    if (cat != null && categories.contains(cat)) return cat;
    return categorizeJob(title); // offline mock
  }

  // ── Screen 5: rewrite the description professionally ────────────────────
  static Future<String> rewriteDescription({
    required String title,
    required String category,
    required String location,
    required bool urgent,
    required String currentText,
  }) async {
    final data = await _call('rewriteDescription', {
      'title': title,
      'category': category,
      'location': location,
      'urgent': urgent,
      'currentText': currentText,
    });
    final rewritten = data?['description']?.toString();
    if (rewritten != null && rewritten.trim().isNotEmpty) return rewritten.trim();
    return generateTaskDescription(category, currentText); // offline mock
  }

  // ── Screen 6: recommend a price band ────────────────────────────────────
  static Future<PriceRange> analyzePrice({
    required String title,
    required String category,
    required String description,
    required String location,
    required bool urgent,
  }) async {
    final data = await _call('analyzePrice', {
      'title': title,
      'category': category,
      'description': description,
      'location': location,
      'urgent': urgent,
    });
    final low = _asInt(data?['low']);
    final high = _asInt(data?['high']);
    if (low != null && high != null && low > 0 && high >= low) {
      return PriceRange(low: low, high: high, source: AiSource.live);
    }
    final mock = _mockPriceRange(category, urgent);
    return PriceRange(low: mock.$1, high: mock.$2, source: AiSource.mock);
  }

  // ── Review: attractiveness score + breakdown ────────────────────────────
  static Future<TaskEvaluation> evaluateTask(Map<String, dynamic> task) async {
    final data = await _call('evaluateTask', task);
    final score = _asInt(data?['score']);
    if (score != null) {
      return TaskEvaluation(
        score: score.clamp(0, 100),
        strengths: _asStringList(data?['strengths']),
        weaknesses: _asStringList(data?['weaknesses']),
        missing: _asStringList(data?['missing']),
        source: AiSource.live,
      );
    }
    return _mockEvaluateTask(task);
  }

  // ── Chatbot: app-scoped, intent-aware assistant ─────────────────────────
  /// Sends a user [message] (with the user's [role]) to the `chatAssistant`
  /// Cloud Function and returns a [ChatReply]. On ANY failure it falls back to
  /// the synchronous offline mock, so the chat never hangs or crashes.
  ///
  /// [history] is an optional recent transcript for light context, newest last:
  /// each entry is `{ 'role': 'user'|'assistant', 'text': '...' }`.
  static Future<ChatReply> chatAssistant({
    required String message,
    required String role,
    List<Map<String, String>> history = const [],
  }) async {
    final data = await _call('chatAssistant', {
      'message': message,
      'role': role,
      'history': history,
    });
    final reply = data?['message']?.toString();
    if (reply != null && reply.trim().isNotEmpty) {
      final raw = data?['action']?.toString();
      final action = (raw != null && kChatActions.contains(raw)) ? raw : null;
      return ChatReply(
        message: reply.trim(),
        action: action,
        intent: data?['intent']?.toString(),
        source: AiSource.live,
      );
    }
    final mock = chatAssistantReply(message, role); // offline fallback
    return ChatReply(
      message: mock.message,
      action: mock.action,
      intent: mock.intent,
      source: AiSource.mock,
    );
  }

  // ── Tasker-Finding: ranked shortlist with reasons (spec §4.3) ───────────
  /// Ranks [candidates] for [task] and returns up to 3 [TaskerMatch]es, best
  /// first. The app pre-filters + supplies the candidates; the model may ONLY
  /// return ids from that set (any other id is dropped) and only writes the
  /// one-line reason — exactly the "constrain to the provided list" safety used
  /// by [suggestCategory]. Every displayed stat stays app data, not model output.
  ///
  /// On ANY failure (offline, timeout, bad response, no ids in-set) it falls
  /// back to the deterministic [matchTaskersMock], so it never hangs and never
  /// returns an invented tasker.
  static Future<List<TaskerMatch>> matchTaskers({
    required Map<String, dynamic> task,
    required List<Worker> candidates,
  }) async {
    if (candidates.isEmpty) return const [];

    // Compact, id-keyed payload of REAL fields only — nothing to hallucinate.
    final candidatePayload = [
      for (final w in candidates)
        {
          'id': w.id,
          'name': w.name,
          'skill': w.skill,
          'rating': w.rating,
          'reviews': w.reviews,
          'distanceMiles': w.distanceMiles,
          'currentTier': w.currentTier,
          'completedTasks': w.completedTasks,
          'isAvailableNow': w.isAvailableNow,
          'isVerified': w.isVerified,
          'township': w.township,
        },
    ];

    final data = await _call('matchTaskers', {
      'task': task,
      'candidates': candidatePayload,
    });

    final rawMatches = data?['matches'];
    if (rawMatches is List) {
      final validIds = {for (final w in candidates) w.id};
      final seen = <int>{};
      final result = <TaskerMatch>[];
      for (final m in rawMatches) {
        if (m is Map) {
          final id = _asInt(m['id']);
          final reason = m['reason']?.toString().trim() ?? '';
          // Drop any id not in the provided set, and any duplicate/empty reason.
          if (id != null &&
              validIds.contains(id) &&
              seen.add(id) &&
              reason.isNotEmpty) {
            result.add(
              TaskerMatch(workerId: id, reason: reason, source: AiSource.live),
            );
          }
        }
        if (result.length >= 3) break;
      }
      if (result.isNotEmpty) return result;
    }

    // Offline / invalid response — deterministic fallback (never invents).
    return [
      for (final r in matchTaskersMock(task, candidates))
        TaskerMatch(
          workerId: r.workerId,
          reason: r.reason,
          source: AiSource.mock,
        ),
    ];
  }

  // ── Onboarding voice mode: extract signup fields from speech (spec §4.1) ─
  /// Extracts onboarding fields from a spoken [transcript]. The model is
  /// constrained to a fixed gender set and (for taskers) the app's known skill
  /// list — anything outside those is dropped, and `age`/`phone` are validated,
  /// so it can only return real, in-vocabulary values. On ANY failure it falls
  /// back to the synchronous offline extractor, so it never hangs. It NEVER
  /// submits — the caller shows a pre-filled, editable form and asks the user to
  /// confirm.
  static Future<OnboardingExtraction> extractOnboarding({
    required String transcript,
    required UserRole role,
  }) async {
    final isTasker = role == UserRole.tasker;
    final knownSkills = [
      for (final s in TaskerSkill.values) {'id': s.name, 'label': s.label},
    ];

    final data = await _call('extractOnboarding', {
      'role': isTasker ? 'tasker' : 'client',
      'transcript': transcript,
      'knownSkills': isTasker ? knownSkills : const [],
    });

    if (data != null) {
      final name = data['name']?.toString().trim() ?? '';
      final gender = _genderFrom(data['gender']);
      final age = _validAge(_asInt(data['age']));
      final phone = _digitsOnly(data['phone']);
      final skills = isTasker ? _skillsFrom(data['skills']) : const <TaskerSkill>[];
      final live = OnboardingExtraction(
        name: name,
        gender: gender,
        age: age,
        phone: phone,
        skills: skills,
        source: AiSource.live,
      );
      if (live.hasAnything) return live;
    }

    // Offline / empty response — synchronous best-effort extractor.
    final mock = extractOnboardingMock(transcript, isTasker: isTasker);
    return OnboardingExtraction(
      name: mock.name,
      gender: _genderFrom(mock.gender),
      age: _validAge(mock.age),
      phone: _digitsOnly(mock.phone),
      skills: isTasker ? _skillsFrom(mock.skillIds) : const [],
      source: AiSource.mock,
    );
  }

  // ── Task-Handling mode (spec §4.4/§4.8) ─────────────────────────────────
  /// Gentle fixes for a task that has waited [ageHours] with no taker. Wording
  /// only; falls back to templated tips. Never hangs, never blocks.
  static Future<TaskFixTips> suggestTaskFixes({
    required Map<String, dynamic> task,
    required int ageHours,
  }) async {
    final data = await _call('suggestTaskFixes', {
      'task': task,
      'ageHours': ageHours,
    });
    final tips = _asStringList(data?['tips']);
    if (tips.isNotEmpty) {
      return TaskFixTips(tips: tips.take(4).toList(), source: AiSource.live);
    }
    return TaskFixTips(
      tips: taskFixTipsMock(task, ageHours),
      source: AiSource.mock,
    );
  }

  /// Summarizes a completed task and RECOMMENDS a tier move (spec §4.4 Phase 3).
  /// The delta is a suggestion only, clamped to [-1, 1]; the app/backend rules +
  /// client rating decide the real tier. Falls back to a templated summary.
  static Future<CompletionSummary> summarizeCompletion({
    required Map<String, dynamic> task,
    Map<String, dynamic> timing = const {},
    Map<String, dynamic> review = const {},
  }) async {
    final data = await _call('summarizeCompletion', {
      'task': task,
      'timing': timing,
      'review': review,
    });
    final summary = data?['summary']?.toString().trim() ?? '';
    if (summary.isNotEmpty) {
      final delta = (_asInt(data?['suggestedTierDelta']) ?? 0).clamp(-1, 1);
      return CompletionSummary(
        summary: summary,
        suggestedTierDelta: delta,
        rationale: data?['rationale']?.toString().trim() ?? '',
        source: AiSource.live,
      );
    }
    final mock = completionSummaryMock(task: task, timing: timing, review: review);
    return CompletionSummary(
      summary: mock.summary,
      suggestedTierDelta: mock.suggestedTierDelta,
      rationale: mock.rationale,
      source: AiSource.mock,
    );
  }

  /// Briefs a tasker before a task: what the client wants + prep/tools (§4.8).
  /// Wording only; falls back to a templated brief. Read aloud in the app.
  static Future<TaskerBrief> briefTasker({
    required Map<String, dynamic> task,
  }) async {
    final data = await _call('briefTasker', {'task': task});
    final summary = data?['summary']?.toString().trim() ?? '';
    if (summary.isNotEmpty) {
      return TaskerBrief(
        summary: summary,
        suggestions: _asStringList(data?['suggestions']).take(4).toList(),
        source: AiSource.live,
      );
    }
    final mock = taskerBriefMock(task);
    return TaskerBrief(
      summary: mock.summary,
      suggestions: mock.suggestions,
      source: AiSource.mock,
    );
  }

  static Gender? _genderFrom(Object? v) {
    switch (v?.toString().toLowerCase()) {
      case 'male':
        return Gender.male;
      case 'female':
        return Gender.female;
      case 'other':
        return Gender.other;
      default:
        return null;
    }
  }

  static int? _validAge(int? age) =>
      (age != null && age >= 1 && age <= 120) ? age : null;

  static String _digitsOnly(Object? v) =>
      (v?.toString() ?? '').replaceAll(RegExp(r'\D'), '');

  /// Maps a list of skill ids ([TaskerSkill.name] values) to enums, dropping any
  /// id not in the enum — the same "constrain to the known set" safety used
  /// everywhere else, so a bad id can never reach the form.
  static List<TaskerSkill> _skillsFrom(Object? v) {
    if (v is! List) return const [];
    final byName = {for (final s in TaskerSkill.values) s.name: s};
    final result = <TaskerSkill>[];
    for (final item in v) {
      final skill = byName[item.toString()];
      if (skill != null && !result.contains(skill)) result.add(skill);
    }
    return result;
  }

  // ── Offline mock fallbacks ──────────────────────────────────────────────
  /// Deterministic per-category band (mirrors a realistic Yangon spread).
  static (int, int) _mockPriceRange(String category, bool urgent) {
    const base = {
      "Plumber": (10000, 15000),
      "Electrician": (10000, 15000),
      "AC Technician": (15000, 25000),
      "Cleaner": (8000, 12000),
      "Carpenter": (15000, 25000),
      "Tutor": (10000, 15000),
      "Gardener": (8000, 12000),
      "Delivery": (5000, 8000),
      "Handyman": (10000, 15000),
    };
    final (low, high) = base[category] ?? (10000, 15000);
    final m = urgent ? 1.2 : 1.0;
    return ((low * m).round(), (high * m).round());
  }

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
      source: AiSource.mock,
    );
  }

  static int? _asInt(Object? v) {
    if (v is int) return v;
    if (v is double) return v.round();
    if (v is String) return int.tryParse(v.trim());
    return null;
  }

  static List<String> _asStringList(Object? v) {
    if (v is List) {
      return v.map((e) => e.toString()).where((e) => e.trim().isNotEmpty).toList();
    }
    return const [];
  }
}
