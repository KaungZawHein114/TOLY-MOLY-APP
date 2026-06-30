/// One turn in the conversation, sent back to the backend as history on the
/// next call (apps.tasks.services.analyze_task expects this exact shape).
class ChatTurn {
  final String role; // "user" | "assistant"
  final String content;

  const ChatTurn({required this.role, required this.content});

  Map<String, String> toJson() => {"role": role, "content": content};
}

/// Result of one POST /api/tasks/ai/analyze call.
class AnalyzeResult {
  final Map<String, dynamic> fields;
  final String? question;
  final bool ready;

  const AnalyzeResult({required this.fields, required this.question, required this.ready});

  factory AnalyzeResult.fromJson(Map<String, dynamic> json) => AnalyzeResult(
        fields: Map<String, dynamic>.from(json["fields"] as Map),
        question: json["question"] as String?,
        ready: json["ready"] as bool,
      );
}

/// One of the three Economy/Standard/Professional budget options returned
/// by POST /api/tasks/ai/budget-options.
class BudgetOption {
  final int workerTierMin;
  final int workerTierMax;
  final int budgetMmk;

  const BudgetOption({required this.workerTierMin, required this.workerTierMax, required this.budgetMmk});

  factory BudgetOption.fromJson(Map<String, dynamic> json) => BudgetOption(
        workerTierMin: json["worker_tier_min"] as int,
        workerTierMax: json["worker_tier_max"] as int,
        budgetMmk: json["budget_mmk"] as int,
      );
}

/// A published task, as returned by POST /api/tasks/.
class PostedTask {
  final int id;
  final String status;

  const PostedTask({required this.id, required this.status});

  factory PostedTask.fromJson(Map<String, dynamic> json) =>
      PostedTask(id: json["id"] as int, status: json["status"] as String);
}
