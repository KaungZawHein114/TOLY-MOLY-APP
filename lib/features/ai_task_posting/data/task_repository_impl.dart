import '../models/ai_task_models.dart';
import 'task_api.dart';
import 'task_repository.dart';

class TaskRepositoryImpl implements TaskRepository {
  final TaskApi _api;

  TaskRepositoryImpl({TaskApi? api}) : _api = api ?? TaskApi();

  @override
  Future<AnalyzeResult> analyze({
    required String message,
    required List<ChatTurn> history,
    required Map<String, dynamic> knownFields,
  }) async {
    final json = await _api.analyze(
      message: message,
      history: history.map((t) => t.toJson()).toList(),
      knownFields: knownFields,
    );
    return AnalyzeResult.fromJson(json);
  }

  @override
  Future<Map<String, BudgetOption>> budgetOptions({required String category, required String urgency}) async {
    final json = await _api.budgetOptions(category: category, urgency: urgency);
    return json.map((key, value) => MapEntry(key, BudgetOption.fromJson(Map<String, dynamic>.from(value as Map))));
  }

  @override
  Future<PostedTask> publish(Map<String, dynamic> taskFields) async {
    final json = await _api.publish(taskFields);
    return PostedTask.fromJson(json);
  }
}
