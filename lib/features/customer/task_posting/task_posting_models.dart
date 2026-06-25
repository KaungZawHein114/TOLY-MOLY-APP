// ============================================================================
// TASK POSTING MODELS — plain Dart, no async, no persistence.
// Internal identifiers stay English; user-facing labels are Burmese-first.
// ============================================================================

import '../../../core/constants/task_posting_strings.dart';

/// Sentinel category value for a client-specified ("Other") category. When
/// [TaskDraft.category] equals this, the real label lives in
/// [TaskDraft.customCategory].
const String kOtherCategory = "Other";

/// Reference price the budget evaluator compares the client's entered amount
/// against. Demo-only flat figure — a real model would derive it per
/// category/location/tier.
const int kBudgetReferenceMmk = 10000;

/// Flat platform fee added when a task is marked urgent.
const int kUrgentFeeMmk = 3000;

/// Where the task happens.
enum TaskType { onSite, remote }

/// How a remote task is carried out. Shown only for [TaskType.remote].
enum RemoteWorkMethod { liveMeeting, chatBased, phoneCall, documentSubmission, flexible }

/// When a remote task must be finished. Shown only for [TaskType.remote].
enum RemoteCompletionStyle { duringMeeting, beforeDeadline, flexible }

/// What the remote task should produce. Shown only for [TaskType.remote].
enum RemoteDeliverable { text, file, design, code, consultation, other }

/// The AI's read on a client-entered budget (Screen 6). The AI only advises —
/// the client always keeps the final price.
enum BudgetVerdict { low, reasonable, high }

extension RemoteWorkMethodLabel on RemoteWorkMethod {
  String get label {
    switch (this) {
      case RemoteWorkMethod.liveMeeting:
        return TaskPostingStrings.remoteMethodLiveMeeting;
      case RemoteWorkMethod.chatBased:
        return TaskPostingStrings.remoteMethodChat;
      case RemoteWorkMethod.phoneCall:
        return TaskPostingStrings.remoteMethodPhone;
      case RemoteWorkMethod.documentSubmission:
        return TaskPostingStrings.remoteMethodDocument;
      case RemoteWorkMethod.flexible:
        return TaskPostingStrings.remoteFlexible;
    }
  }
}

extension RemoteCompletionStyleLabel on RemoteCompletionStyle {
  String get label {
    switch (this) {
      case RemoteCompletionStyle.duringMeeting:
        return TaskPostingStrings.remoteCompletionDuringMeeting;
      case RemoteCompletionStyle.beforeDeadline:
        return TaskPostingStrings.remoteCompletionBeforeDeadline;
      case RemoteCompletionStyle.flexible:
        return TaskPostingStrings.remoteFlexible;
    }
  }
}

extension RemoteDeliverableLabel on RemoteDeliverable {
  String get label {
    switch (this) {
      case RemoteDeliverable.text:
        return TaskPostingStrings.remoteDeliverableText;
      case RemoteDeliverable.file:
        return TaskPostingStrings.remoteDeliverableFile;
      case RemoteDeliverable.design:
        return TaskPostingStrings.remoteDeliverableDesign;
      case RemoteDeliverable.code:
        return TaskPostingStrings.remoteDeliverableCode;
      case RemoteDeliverable.consultation:
        return TaskPostingStrings.remoteDeliverableConsultation;
      case RemoteDeliverable.other:
        return TaskPostingStrings.remoteDeliverableOther;
    }
  }
}

/// Worker trust ladder, Tier 1 (newest) → Tier 7 (elite). The card UI shows
/// only the friendly [label]/[description]; the literal tier [number] appears
/// solely inside the "what do tiers mean?" info sheet, per the product rule
/// that clients shouldn't have to reason about raw tier numbers.
enum WorkerTier { tier1, tier2, tier3, tier4, tier5, tier6, tier7 }

extension WorkerTierInfo on WorkerTier {
  /// Human tier number, 1-7 (used only in the info sheet + worker matching).
  int get number => index + 1;

  String get label {
    switch (this) {
      case WorkerTier.tier1:
        return TaskPostingStrings.tier1Label;
      case WorkerTier.tier2:
        return TaskPostingStrings.tier2Label;
      case WorkerTier.tier3:
        return TaskPostingStrings.tier3Label;
      case WorkerTier.tier4:
        return TaskPostingStrings.tier4Label;
      case WorkerTier.tier5:
        return TaskPostingStrings.tier5Label;
      case WorkerTier.tier6:
        return TaskPostingStrings.tier6Label;
      case WorkerTier.tier7:
        return TaskPostingStrings.tier7Label;
    }
  }

  String get description {
    switch (this) {
      case WorkerTier.tier1:
        return TaskPostingStrings.tier1Description;
      case WorkerTier.tier2:
        return TaskPostingStrings.tier2Description;
      case WorkerTier.tier3:
        return TaskPostingStrings.tier3Description;
      case WorkerTier.tier4:
        return TaskPostingStrings.tier4Description;
      case WorkerTier.tier5:
        return TaskPostingStrings.tier5Description;
      case WorkerTier.tier6:
        return TaskPostingStrings.tier6Description;
      case WorkerTier.tier7:
        return TaskPostingStrings.tier7Description;
    }
  }

  String get emoji {
    switch (this) {
      case WorkerTier.tier1:
        return "🌱";
      case WorkerTier.tier2:
        return "🔰";
      case WorkerTier.tier3:
        return "✅";
      case WorkerTier.tier4:
        return "⭐";
      case WorkerTier.tier5:
        return "🚀";
      case WorkerTier.tier6:
        return "🏅";
      case WorkerTier.tier7:
        return "👑";
    }
  }
}

/// Mutable-by-replacement draft for the task-posting flow. A single Riverpod
/// StateProvider holds an instance; every screen calls copyWith to update it.
class TaskDraft {
  final String? category; // internal skill name, e.g. "Plumber" — matches
  // demo_data's Worker.skill / categoryToSkills values, OR [kOtherCategory].
  final String customCategory; // free text when category == kOtherCategory.
  final TaskType? taskType;
  final String township;
  final String address;
  // Remote-only details (null/unset for on-site tasks).
  final RemoteWorkMethod? remoteWorkMethod;
  final RemoteCompletionStyle? remoteCompletionStyle;
  final RemoteDeliverable? remoteDeliverable;
  final DateTime? date;
  final String? timeSlot; // a custom "HH:mm" the user picked
  final bool urgent;
  final WorkerTier? workerTier;
  final String description;
  final int? budgetMmk; // client-entered budget (Screen 6).
  final String notes; // optional voice/text notes from the review screen.

  const TaskDraft({
    this.category,
    this.customCategory = "",
    this.taskType,
    this.township = "",
    this.address = "",
    this.remoteWorkMethod,
    this.remoteCompletionStyle,
    this.remoteDeliverable,
    this.date,
    this.timeSlot,
    this.urgent = false,
    this.workerTier,
    this.description = "",
    this.budgetMmk,
    this.notes = "",
  });

  factory TaskDraft.empty() => const TaskDraft();

  /// The label to display/publish for the chosen category — the custom text
  /// when "Other" was picked, otherwise the internal skill name.
  String get effectiveCategory =>
      category == kOtherCategory ? customCategory : (category ?? "");

  /// Whether the location step has everything it needs to continue.
  bool get isLocationComplete {
    if (taskType == TaskType.remote) return remoteWorkMethod != null;
    if (taskType == TaskType.onSite) {
      return township.isNotEmpty && address.isNotEmpty;
    }
    return false;
  }

  TaskDraft copyWith({
    String? category,
    String? customCategory,
    TaskType? taskType,
    String? township,
    String? address,
    RemoteWorkMethod? remoteWorkMethod,
    RemoteCompletionStyle? remoteCompletionStyle,
    RemoteDeliverable? remoteDeliverable,
    DateTime? date,
    String? timeSlot,
    bool? urgent,
    WorkerTier? workerTier,
    String? description,
    int? budgetMmk,
    String? notes,
  }) {
    return TaskDraft(
      category: category ?? this.category,
      customCategory: customCategory ?? this.customCategory,
      taskType: taskType ?? this.taskType,
      township: township ?? this.township,
      address: address ?? this.address,
      remoteWorkMethod: remoteWorkMethod ?? this.remoteWorkMethod,
      remoteCompletionStyle: remoteCompletionStyle ?? this.remoteCompletionStyle,
      remoteDeliverable: remoteDeliverable ?? this.remoteDeliverable,
      date: date ?? this.date,
      timeSlot: timeSlot ?? this.timeSlot,
      urgent: urgent ?? this.urgent,
      workerTier: workerTier ?? this.workerTier,
      description: description ?? this.description,
      budgetMmk: budgetMmk ?? this.budgetMmk,
      notes: notes ?? this.notes,
    );
  }
}
