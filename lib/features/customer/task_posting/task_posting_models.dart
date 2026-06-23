// ============================================================================
// TASK POSTING MODELS — plain Dart, no async, no persistence.
// Internal identifiers stay English; user-facing labels are Burmese-first.
// ============================================================================

import '../../../core/constants/task_posting_strings.dart';

/// Where the task happens.
enum TaskType { onSite, remote }

/// Friendly worker trust level. Internal tiers are never shown as numbers —
/// only these labels/descriptions appear in the UI.
enum WorkerTier { basic, trusted, expert }

extension WorkerTierLabel on WorkerTier {
  String get label {
    switch (this) {
      case WorkerTier.basic:
        return TaskPostingStrings.workerTierBasicLabel;
      case WorkerTier.trusted:
        return TaskPostingStrings.workerTierTrustedLabel;
      case WorkerTier.expert:
        return TaskPostingStrings.workerTierExpertLabel;
    }
  }

  String get description {
    switch (this) {
      case WorkerTier.basic:
        return TaskPostingStrings.workerTierBasicDescription;
      case WorkerTier.trusted:
        return TaskPostingStrings.workerTierTrustedDescription;
      case WorkerTier.expert:
        return TaskPostingStrings.workerTierExpertDescription;
    }
  }
}

/// Mutable-by-replacement draft for the task-posting flow. A single Riverpod
/// StateProvider holds an instance; every screen calls copyWith to update it.
class TaskDraft {
  final String? category; // internal skill name, e.g. "Plumber" — matches
  // demo_data's Worker.skill / categoryToSkills values.
  final TaskType? taskType;
  final String township;
  final String address;
  final DateTime? date;
  final String? timeSlot; // a custom "HH:mm" the user picked
  final bool urgent;
  final int workersNeeded;
  final WorkerTier? workerTier;
  final String description;
  final int? suggestedBudgetLowMmk;
  final int? suggestedBudgetHighMmk;
  final int? marketPercent;

  const TaskDraft({
    this.category,
    this.taskType,
    this.township = "",
    this.address = "",
    this.date,
    this.timeSlot,
    this.urgent = false,
    this.workersNeeded = 1,
    this.workerTier,
    this.description = "",
    this.suggestedBudgetLowMmk,
    this.suggestedBudgetHighMmk,
    this.marketPercent,
  });

  factory TaskDraft.empty() => const TaskDraft();

  /// The budget that will actually be published — the AI-suggested range's
  /// midpoint. The price is set by the platform's supply/demand model; the
  /// client cannot override it here (they negotiate with the worker via
  /// chat after matching, a later feature).
  int? get resolvedBudgetMmk {
    if (suggestedBudgetLowMmk == null || suggestedBudgetHighMmk == null) return null;
    return ((suggestedBudgetLowMmk! + suggestedBudgetHighMmk!) / 2).round();
  }

  TaskDraft copyWith({
    String? category,
    TaskType? taskType,
    String? township,
    String? address,
    DateTime? date,
    String? timeSlot,
    bool? urgent,
    int? workersNeeded,
    WorkerTier? workerTier,
    String? description,
    int? suggestedBudgetLowMmk,
    int? suggestedBudgetHighMmk,
    int? marketPercent,
  }) {
    return TaskDraft(
      category: category ?? this.category,
      taskType: taskType ?? this.taskType,
      township: township ?? this.township,
      address: address ?? this.address,
      date: date ?? this.date,
      timeSlot: timeSlot ?? this.timeSlot,
      urgent: urgent ?? this.urgent,
      workersNeeded: workersNeeded ?? this.workersNeeded,
      workerTier: workerTier ?? this.workerTier,
      description: description ?? this.description,
      suggestedBudgetLowMmk: suggestedBudgetLowMmk ?? this.suggestedBudgetLowMmk,
      suggestedBudgetHighMmk: suggestedBudgetHighMmk ?? this.suggestedBudgetHighMmk,
      marketPercent: marketPercent ?? this.marketPercent,
    );
  }
}
