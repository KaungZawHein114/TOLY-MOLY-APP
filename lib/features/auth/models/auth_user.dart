/// Mirrors the `user` object every auth endpoint (verify-otp/login) and
/// `/api/auth/me` return — see backend/apps/authentication/views.py's
/// `_user_payload`.
class AuthUser {
  final int id;
  final String phoneNumber;
  final String role; // "CLIENT" | "TASKER"
  final String status; // UNVERIFIED | PENDING_VERIFICATION | VERIFIED | SUSPENDED

  const AuthUser({
    required this.id,
    required this.phoneNumber,
    required this.role,
    required this.status,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
        id: json["id"] as int,
        phoneNumber: json["phone_number"] as String,
        role: json["role"] as String,
        status: json["status"] as String,
      );
}
