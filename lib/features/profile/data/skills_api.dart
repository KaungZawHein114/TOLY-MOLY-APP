import 'package:dio/dio.dart';

import '../../../core/config/api_config.dart';
import '../../auth/data/token_storage.dart';
import 'profile_failure.dart';

/// Thin wrapper around `/api/tasker/skills*` (apps.taskers.urls) — tasker-only
/// (see apps.taskers.permissions.IsTasker on the backend).
class SkillsApi {
  final Dio _dio;
  final TokenStorage _tokens;

  SkillsApi({Dio? dio, TokenStorage? tokenStorage})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: apiBaseUrl,
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 10),
            )),
        _tokens = tokenStorage ?? TokenStorage();

  Future<List<dynamic>> list() async {
    final access = await _requireAccessToken();
    try {
      final response = await _dio.get(
        "/api/tasker/skills",
        options: Options(headers: {"Authorization": "Bearer $access"}),
      );
      return response.data as List<dynamic>;
    } on DioException catch (e) {
      throw _toFailure(e);
    }
  }

  Future<Map<String, dynamic>> create({required String skillName, required int experienceYears}) async {
    final access = await _requireAccessToken();
    try {
      final response = await _dio.post(
        "/api/tasker/skills",
        data: {"skill_name": skillName, "experience_years": experienceYears},
        options: Options(headers: {"Authorization": "Bearer $access"}),
      );
      return Map<String, dynamic>.from(response.data as Map);
    } on DioException catch (e) {
      throw _toFailure(e);
    }
  }

  Future<Map<String, dynamic>> update(int id, {required String skillName, required int experienceYears}) async {
    final access = await _requireAccessToken();
    try {
      final response = await _dio.put(
        "/api/tasker/skills/$id",
        data: {"skill_name": skillName, "experience_years": experienceYears},
        options: Options(headers: {"Authorization": "Bearer $access"}),
      );
      return Map<String, dynamic>.from(response.data as Map);
    } on DioException catch (e) {
      throw _toFailure(e);
    }
  }

  Future<void> delete(int id) async {
    final access = await _requireAccessToken();
    try {
      await _dio.delete(
        "/api/tasker/skills/$id",
        options: Options(headers: {"Authorization": "Bearer $access"}),
      );
    } on DioException catch (e) {
      throw _toFailure(e);
    }
  }

  Future<String> _requireAccessToken() async {
    final access = await _tokens.readAccessToken();
    if (access == null) {
      throw const ProfileFailure(code: "not_logged_in", message: "Please log in again.");
    }
    return access;
  }

  ProfileFailure _toFailure(DioException e) {
    final data = e.response?.data;
    if (data is Map) {
      final code = data["code"];
      if (code is String) {
        final detail = data["detail"];
        return ProfileFailure(code: code, message: detail is String ? detail : code);
      }
      final firstKey = data.keys.isNotEmpty ? data.keys.first : null;
      final firstValue = firstKey == null ? null : data[firstKey];
      final message = firstValue is List && firstValue.isNotEmpty
          ? firstValue.first.toString()
          : "Something went wrong. Please try again.";
      return ProfileFailure(code: "validation_error", message: message);
    }
    return const ProfileFailure(
      code: "network_error",
      message: "Couldn't reach the server. Check your connection and try again.",
    );
  }
}
