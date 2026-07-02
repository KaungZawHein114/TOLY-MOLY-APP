/// Thrown by [TaskRepository] methods on any non-2xx response. Mirrors
/// lib/features/auth/data/auth_failure.dart's shape — `code` is the
/// backend's machine-readable error code (e.g. "ai_unavailable",
/// "incomplete_task") so callers can branch without parsing messages.
class TaskFailure implements Exception {
  final String code;
  final String message;

  const TaskFailure({required this.code, required this.message});

  @override
  String toString() => "TaskFailure($code: $message)";
}
