import 'package:dio/dio.dart';

import '../../../core/config/api_config.dart';
import 'auth_failure.dart';

/// Thin wrapper around the seven `/api/auth/*` endpoints from
/// backend/apps/authentication/urls.py. Knows nothing about tokens or
/// Riverpod — [AuthRepositoryImpl] owns that. Every method throws
/// [AuthFailure] on a non-2xx response.
class AuthApi {
  final Dio _dio;

  AuthApi({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: apiBaseUrl,
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 10),
            ));

  Future<Map<String, dynamic>> register({
    required String name,
    required String phoneNumber,
    required String password,
    required String gender,
    required int age,
    required String role,
  }) {
    return _post("/api/auth/register", {
      "name": name,
      "phone_number": phoneNumber,
      "password": password,
      "gender": gender,
      "age": age,
      "role": role,
    });
  }

  Future<Map<String, dynamic>> sendOtp(String phoneNumber) {
    return _post("/api/auth/send-otp", {"phone_number": phoneNumber});
  }

  Future<Map<String, dynamic>> verifyOtp({required String phoneNumber, required String code}) {
    return _post("/api/auth/verify-otp", {"phone_number": phoneNumber, "code": code});
  }

  Future<Map<String, dynamic>> login({required String phoneNumber, required String password}) {
    return _post("/api/auth/login", {"phone_number": phoneNumber, "password": password});
  }

  Future<Map<String, dynamic>> refresh(String refreshToken) {
    return _post("/api/auth/refresh", {"refresh_token": refreshToken});
  }

  Future<void> logout({required String accessToken, required String refreshToken}) {
    return _post(
      "/api/auth/logout",
      {"refresh_token": refreshToken},
      accessToken: accessToken,
    );
  }

  Future<Map<String, dynamic>> me(String accessToken) async {
    try {
      final response = await _dio.get(
        "/api/auth/me",
        options: Options(headers: {"Authorization": "Bearer $accessToken"}),
      );
      return Map<String, dynamic>.from(response.data as Map);
    } on DioException catch (e) {
      throw _toAuthFailure(e);
    }
  }

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> body, {
    String? accessToken,
  }) async {
    try {
      final response = await _dio.post(
        path,
        data: body,
        options: accessToken == null
            ? null
            : Options(headers: {"Authorization": "Bearer $accessToken"}),
      );
      if (response.data == null) return {};
      return Map<String, dynamic>.from(response.data as Map);
    } on DioException catch (e) {
      throw _toAuthFailure(e);
    }
  }

  AuthFailure _toAuthFailure(DioException e) {
    final data = e.response?.data;
    if (data is Map) {
      final code = data["code"];
      if (code is String) {
        final detail = data["detail"];
        return AuthFailure(code: code, message: detail is String ? detail : code);
      }
      // Plain DRF field-validation error, e.g. {"password": ["..."]}.
      final firstKey = data.keys.isNotEmpty ? data.keys.first : null;
      final firstValue = firstKey == null ? null : data[firstKey];
      final message = firstValue is List && firstValue.isNotEmpty
          ? firstValue.first.toString()
          : "Something went wrong. Please try again.";
      return AuthFailure(code: "validation_error", message: message);
    }
    return const AuthFailure(
      code: "network_error",
      message: "Couldn't reach the server. Check your connection and try again.",
    );
  }
}
