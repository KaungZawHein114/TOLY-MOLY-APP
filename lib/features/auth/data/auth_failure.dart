/// Thrown by [AuthRepository] methods on any non-2xx response. `code` is the
/// backend's machine-readable error code (see backend/apps/authentication/
/// views.py — e.g. "phone_already_registered", "account_not_verified",
/// "otp_locked") so callers can branch without parsing message strings.
/// `code` falls back to "unknown_error" for network failures or responses
/// that don't carry a `code` field (plain DRF field-validation errors).
class AuthFailure implements Exception {
  final String code;
  final String message;

  const AuthFailure({required this.code, required this.message});

  @override
  String toString() => "AuthFailure($code: $message)";
}
