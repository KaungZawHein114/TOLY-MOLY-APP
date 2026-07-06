import 'package:dio/dio.dart';

import '../../auth/data/auth_api.dart' show apiBaseUrl;
import '../../auth/data/token_storage.dart';
import '../models/extracted_task.dart';

/// Anything that goes wrong talking to the task backend, surfaced to the UI
/// with a friendly [message]. Kept local to this feature so the voice flow
/// stays self-contained (mirrors ai_task_posting's TaskFailure).
class VoiceTaskFailure implements Exception {
  final String code;
  final String message;
  const VoiceTaskFailure({required this.code, required this.message});

  @override
  String toString() => 'VoiceTaskFailure($code): $message';
}

/// Thin wrapper around the two `/api/tasks/*` endpoints the voice flow needs:
/// one-shot AI extraction and publish. Reads the JWT from the same
/// [TokenStorage] the auth feature writes to — no separate login needed.
class VoiceTaskApi {
  final Dio _dio;
  final TokenStorage _tokens;

  VoiceTaskApi({Dio? dio, TokenStorage? tokenStorage})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: apiBaseUrl,
              connectTimeout: const Duration(seconds: 15),
              // Extraction runs a GPT call server-side, so give it room.
              receiveTimeout: const Duration(seconds: 40),
            )),
        _tokens = tokenStorage ?? TokenStorage();

  /// Sends the full spoken/typed [transcript] to the backend and returns the
  /// fields the AI could pull out. Anything it couldn't stays null on the
  /// returned [ExtractedTask] (shown as "Not given" on the review screen).
  Future<ExtractedTask> extract(String transcript) async {
    final data = await _authedPost('/api/tasks/ai/extract', {'transcript': transcript});
    final rawFields = data['fields'];
    return ExtractedTask.fromFields(
      rawFields is Map ? Map<String, dynamic>.from(rawFields) : const {},
    );
  }

  /// Publishes the reviewed task — creates a real Task row in Postgres, the
  /// same endpoint the other flows publish through.
  Future<void> publish(Map<String, dynamic> taskFields) async {
    await _authedPost('/api/tasks/', taskFields);
  }

  Future<Map<String, dynamic>> _authedPost(String path, Map<String, dynamic> data) async {
    final access = await _tokens.readAccessToken();
    if (access == null) {
      throw const VoiceTaskFailure(
          code: 'not_logged_in', message: 'ကျေးဇူးပြု၍ ပြန်လည်၀င်ရောက်ပါ။');
    }
    try {
      final response = await _dio.post(
        path,
        data: data,
        options: Options(headers: {'Authorization': 'Bearer $access'}),
      );
      if (response.data == null) return {};
      return Map<String, dynamic>.from(response.data as Map);
    } on DioException catch (e) {
      throw _toFailure(e);
    }
  }

  VoiceTaskFailure _toFailure(DioException e) {
    final data = e.response?.data;
    if (data is Map) {
      final code = data['code'];
      if (code is String) {
        final detail = data['detail'];
        return VoiceTaskFailure(code: code, message: detail is String ? detail : code);
      }
      // Plain DRF field-validation error, e.g. {"transcript": ["..."]}.
      final firstKey = data.keys.isNotEmpty ? data.keys.first : null;
      final firstValue = firstKey == null ? null : data[firstKey];
      final message = firstValue is List && firstValue.isNotEmpty
          ? firstValue.first.toString()
          : 'တစ်ခုခု မှားယွင်းသွားပါသည်။ ထပ်မံကြိုးစားပါ။';
      return VoiceTaskFailure(code: 'validation_error', message: message);
    }
    return const VoiceTaskFailure(
      code: 'network_error',
      message: 'ဆာဗာသို့ ချိတ်ဆက်၍မရပါ။ အင်တာနက်ကို စစ်ဆေးပြီး ထပ်ကြိုးစားပါ။',
    );
  }
}
