import 'package:dio/dio.dart';

import '../../../core/config/api_config.dart';

/// What the AI Tasker Finder backend understood from the client's description
/// (`POST /api/matching/classify-category`).
///
/// [category] is always one of the service categories that exist in
/// `demo_data.dart`'s worker list — the server coerces anything else to its
/// fallback before replying, so it can never name a category with no taskers.
/// [confidence] is the model's own 0.0-1.0 estimate. [problem] is a short
/// restatement of what the client asked for, shown back to them; it may be
/// empty, and the UI must not depend on it.
class TaskerFinderClassification {
  final String category;
  final double confidence;
  final String problem;

  const TaskerFinderClassification({
    required this.category,
    required this.confidence,
    required this.problem,
  });
}

/// Thin client for the AI Tasker Finder classifier — a SEPARATE agent from
/// both the floating App Assistant (`AssistantApi`, `POST /api/assistant/chat`)
/// and the AI Task Assistant (`TaskAssistantApi`,
/// `POST /api/tasks/ai/analyze`). Different backend app
/// (`backend/apps/matching`), different system prompt, different job: this one
/// only names a service category. It never sees, searches, or ranks taskers —
/// that happens locally against the hardcoded worker list. Never share an HTTP
/// client or a response shape between the three.
///
/// Timeouts are deliberately short: this is a single classification call on a
/// screen the user is waiting on, and a slow answer is worse than the local
/// keyword fallback that [AiService.classifyServiceCategory] applies on any
/// failure.
///
/// No auth (matches the Django view's current no-auth-for-now state). Throws
/// on any non-2xx response, timeout, or malformed body.
class TaskerFinderApi {
  final Dio _dio;

  TaskerFinderApi({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: apiBaseUrl,
              connectTimeout: const Duration(seconds: 6),
              receiveTimeout: const Duration(seconds: 6),
            ));

  Future<TaskerFinderClassification> classifyCategory({
    required String message,
  }) async {
    final response = await _dio.post(
      "/api/matching/classify-category",
      data: {"message": message},
    );
    final data = Map<String, dynamic>.from(response.data as Map);
    final category = data["category"];
    if (category is! String || category.trim().isEmpty) {
      throw DioException(
        requestOptions: response.requestOptions,
        error: "Tasker Finder response had no category",
      );
    }
    final confidence = data["confidence"];
    final problem = data["problem"];
    return TaskerFinderClassification(
      category: category.trim(),
      confidence: confidence is num ? confidence.toDouble().clamp(0.0, 1.0) : 0.0,
      problem: problem is String ? problem.trim() : "",
    );
  }
}
