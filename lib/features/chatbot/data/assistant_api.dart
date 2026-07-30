import 'package:dio/dio.dart';

import '../../../core/config/api_config.dart';

/// One reply from the App Assistant backend (`POST /api/assistant/chat`).
class AssistantChatResult {
  final String message;
  final String? actionId;
  const AssistantChatResult({required this.message, this.actionId});
}

/// Thin client for the App Assistant endpoint — a separate agent from the
/// Task Posting AI Conversation, with its own backend service, so this class
/// knows nothing about `apps.tasks`. No auth (see the Django view's docstring
/// for why); every method throws on any non-2xx response or network failure,
/// and [AiService.chatAssistant] is the one place that catches it and falls
/// back to the local mock.
class AssistantApi {
  final Dio _dio;

  AssistantApi({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: apiBaseUrl,
              connectTimeout: const Duration(seconds: 8),
              receiveTimeout: const Duration(seconds: 8),
            ));

  /// [history] entries use the same `{'role': 'user'|'assistant', 'text':
  /// '...'}` shape [AiService.chatAssistant] already builds from the chat
  /// screen's transcript.
  Future<AssistantChatResult> chat({
    required String message,
    required List<Map<String, String>> history,
  }) async {
    final response = await _dio.post(
      "/api/assistant/chat",
      data: {
        "message": message,
        "history": [
          for (final turn in history)
            {"role": turn["role"], "content": turn["text"]},
        ],
      },
    );
    final data = Map<String, dynamic>.from(response.data as Map);
    final text = data["message"];
    if (text is! String || text.trim().isEmpty) {
      throw DioException(
        requestOptions: response.requestOptions,
        error: "Assistant response had no message",
      );
    }
    return AssistantChatResult(
      message: text.trim(),
      actionId: data["action_id"] as String?,
    );
  }
}
