import '../models/ai_task_models.dart';

/// Talks to the Django AI Task Posting backend. Screens depend on this
/// interface, never on [TaskApi] directly — same seam pattern as
/// lib/features/auth/data/auth_repository.dart.
abstract class TaskRepository {
  Future<String> transcribeAudio(List<int> audioBytes);

  Future<AnalyzeResult> analyze({
    required String message,
    required List<ChatTurn> history,
    required Map<String, dynamic> knownFields,
  });

  Future<Map<String, BudgetOption>> budgetOptions({required String category, required String urgency});

  Future<PostedTask> publish(Map<String, dynamic> taskFields);
}
