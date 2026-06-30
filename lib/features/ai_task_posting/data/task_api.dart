import 'package:dio/dio.dart';

import '../../auth/data/auth_api.dart' show apiBaseUrl;
import '../../auth/data/token_storage.dart';
import 'task_failure.dart';

/// Thin wrapper around `/api/tasks/*` (apps.tasks.urls). Every authenticated
/// call reads the access token from the same [TokenStorage] the auth
/// feature writes to — no separate login is needed for task posting.
class TaskApi {
  final Dio _dio;
  final TokenStorage _tokens;

  TaskApi({Dio? dio, TokenStorage? tokenStorage})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: apiBaseUrl,
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 30),
            )),
        _tokens = tokenStorage ?? TokenStorage();

  Future<Map<String, dynamic>> analyze({
    required String message,
    required List<Map<String, String>> history,
    required Map<String, dynamic> knownFields,
  }) {
    return _authedPost("/api/tasks/ai/analyze", data: {
      "message": message,
      "history": history,
      "known_fields": knownFields,
    });
  }

  Future<Map<String, dynamic>> budgetOptions({required String category, required String urgency}) {
    return _authedPost("/api/tasks/ai/budget-options", data: {"category": category, "urgency": urgency});
  }

  Future<Map<String, dynamic>> publish(Map<String, dynamic> taskFields) {
    return _authedPost("/api/tasks/", data: taskFields);
  }

  Future<List<dynamic>> list({bool mine = false}) async {
    final access = await _requireAccessToken();
    try {
      final response = await _dio.get(
        "/api/tasks/",
        queryParameters: mine ? {"mine": "true"} : null,
        options: Options(headers: {"Authorization": "Bearer $access"}),
      );
      return response.data as List<dynamic>;
    } on DioException catch (e) {
      throw _toTaskFailure(e);
    }
  }

  Future<Map<String, dynamic>> _authedPost(String path, {required dynamic data}) async {
    final access = await _requireAccessToken();
    try {
      final response = await _dio.post(
        path,
        data: data,
        options: Options(headers: {"Authorization": "Bearer $access"}),
      );
      return Map<String, dynamic>.from(response.data as Map);
    } on DioException catch (e) {
      throw _toTaskFailure(e);
    }
  }

  Future<String> _requireAccessToken() async {
    final access = await _tokens.readAccessToken();
    if (access == null) {
      throw const TaskFailure(code: "not_logged_in", message: "Please log in again.");
    }
    return access;
  }

  TaskFailure _toTaskFailure(DioException e) {
    final data = e.response?.data;
    if (data is Map) {
      final code = data["code"];
      if (code is String) {
        final detail = data["detail"];
        return TaskFailure(code: code, message: detail is String ? detail : code);
      }
      final firstKey = data.keys.isNotEmpty ? data.keys.first : null;
      final firstValue = firstKey == null ? null : data[firstKey];
      final message = firstValue is List && firstValue.isNotEmpty
          ? firstValue.first.toString()
          : "Something went wrong. Please try again.";
      return TaskFailure(code: "validation_error", message: message);
    }
    return const TaskFailure(
      code: "network_error",
      message: "Couldn't reach the server. Check your connection and try again.",
    );
  }
}
