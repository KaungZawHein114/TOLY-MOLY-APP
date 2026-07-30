import 'package:dio/dio.dart';

import '../../../../core/config/api_config.dart';

/// One turn's reply from the AI Task Assistant backend
/// (`POST /api/tasks/ai/analyze`).
class TaskAssistantTurnResult {
  final Map<String, dynamic> fields;
  final String reply;
  final bool ready;
  const TaskAssistantTurnResult({
    required this.fields,
    required this.reply,
    required this.ready,
  });
}

/// Thin client for the AI Task Assistant conversation endpoint — a SEPARATE
/// agent from the floating App Assistant (`AssistantApi`,
/// `POST /api/assistant/chat`). Different backend app (`backend/apps/tasks`,
/// not `backend/apps/assistant`), different system prompt, different job:
/// this one builds one structured task, not general product help. Never
/// share an HTTP client or a response shape between the two.
///
/// No auth (matches the Django view's current no-auth-for-now state). Every
/// method throws on any non-2xx response, timeout, or malformed body;
/// [AiService.taskAssistant] is the one place that catches it and falls back
/// to the local conversation engine.
class TaskAssistantApi {
  final Dio _dio;

  TaskAssistantApi({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: apiBaseUrl,
              connectTimeout: const Duration(seconds: 7),
              receiveTimeout: const Duration(seconds: 7),
            ));

  Future<TaskAssistantTurnResult> analyze({
    required String message,
    required List<Map<String, String>> history,
    required Map<String, dynamic> knownFields,
  }) async {
    final response = await _dio.post(
      "/api/tasks/ai/analyze",
      data: {
        "message": message,
        "history": history,
        "known_fields": knownFields,
      },
    );
    final data = Map<String, dynamic>.from(response.data as Map);
    final reply = data["reply"];
    if (reply is! String || reply.trim().isEmpty) {
      throw DioException(
        requestOptions: response.requestOptions,
        error: "Task assistant response had no reply",
      );
    }
    return TaskAssistantTurnResult(
      fields: Map<String, dynamic>.from(data["fields"] as Map? ?? const {}),
      reply: reply.trim(),
      ready: data["ready"] == true,
    );
  }
}
