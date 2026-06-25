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
    } catch (_) {
      // Firebase not set up, offline, timeout, server error — fall back.
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
