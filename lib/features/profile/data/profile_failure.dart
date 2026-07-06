/// Thrown by [ProfileRepository]/[SkillsRepository] methods on any non-2xx
/// response. Mirrors lib/features/auth/data/auth_failure.dart's shape.
class ProfileFailure implements Exception {
  final String code;
  final String message;

  const ProfileFailure({required this.code, required this.message});

  @override
  String toString() => "ProfileFailure($code: $message)";
}
