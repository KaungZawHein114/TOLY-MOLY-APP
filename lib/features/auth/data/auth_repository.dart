import '../models/auth_user.dart';

/// Result of a send-otp call. [devCode] is only ever non-null in dev mode
/// (no real SMS gateway yet — see backend spec §2) and is shown directly in
/// the UI so the flow is testable without a phone.
class OtpSendResult {
  final String? devCode;
  const OtpSendResult({this.devCode});
}

/// Result of a successful register/login call.
class AuthSession {
  final AuthUser user;
  const AuthSession(this.user);
}

/// Talks to the Django onboarding backend. Screens depend on this interface,
/// never on [AuthApi]/[TokenStorage] directly, so the data source can change
/// without touching UI code (same seam pattern as demo_data.dart/ai_mock.dart
/// in Phase 1 — see CLAUDE.md).
abstract class AuthRepository {
  /// The final onboarding step (called once rules are agreed to) — this is
  /// the only call that actually creates the account. It requires the phone
  /// to have already passed [verifyOtp] recently; the backend rejects it
  /// otherwise with `code: "otp_not_verified"`.
  Future<AuthSession> register({
    required String name,
    required String phoneNumber,
    required String password,
    required String gender,
    required int age,
    required String role,
  });

  Future<OtpSendResult> sendOtp(String phoneNumber);

  /// Proves phone ownership — does not create an account or return tokens.
  /// [register] is what actually creates the account afterward.
  Future<void> verifyOtp({required String phoneNumber, required String code});

  Future<AuthSession> login({required String phoneNumber, required String password});

  Future<void> logout();

  Future<AuthUser> me();

  Future<bool> isLoggedIn();
}
