// ============================================================================
// EXTRACTED TASK — the result of one-shot AI voice extraction.
// ----------------------------------------------------------------------------
// A plain, immutable holder for the task fields the backend AI parsed out of a
// single spoken description (POST /api/tasks/ai/extract -> {"fields": {...}}).
// EVERY field is nullable on purpose: whatever the client didn't say comes
// back absent and is rendered as "Not given" on the review screen until they
// fill it in by hand. Nothing here talks to the network — that's VoiceTaskApi.
// ============================================================================

class ExtractedTask {
  final String? category; // canonical English skill name, e.g. "Plumber"
  final String? title;
  final String? description;
  final String? date; // "YYYY-MM-DD"
  final String? time; // "HH:MM" (24-hour)
  final bool? urgent; // null = the client never indicated urgency
  final int? budgetMmk;
  final String? township; // human-readable location label

  const ExtractedTask({
    this.category,
    this.title,
    this.description,
    this.date,
    this.time,
    this.urgent,
    this.budgetMmk,
    this.township,
  });

  factory ExtractedTask.empty() => const ExtractedTask();

  /// Builds from the backend's `fields` map. Absent keys stay null; the
  /// backend's `urgency` ("NORMAL"/"URGENT") collapses to the [urgent] bool.
  factory ExtractedTask.fromFields(Map<String, dynamic> fields) {
    final urgency = _str(fields['urgency']);
    return ExtractedTask(
      category: _str(fields['category']),
      title: _str(fields['title']),
      description: _str(fields['description']),
      date: _str(fields['date']),
      time: _str(fields['time']),
      urgent: urgency == null ? null : urgency.toUpperCase() == 'URGENT',
      budgetMmk: _int(fields['budget_mmk']),
      township: _str(fields['township']),
    );
  }

  static String? _str(Object? v) {
    final s = v?.toString().trim();
    return (s == null || s.isEmpty) ? null : s;
  }

  static int? _int(Object? v) {
    if (v is int) return v;
    if (v is double) return v.round();
    if (v is String) return int.tryParse(v.trim());
    return null;
  }

  ExtractedTask copyWith({
    String? category,
    String? title,
    String? description,
    String? date,
    String? time,
    bool? urgent,
    int? budgetMmk,
    String? township,
  }) {
    return ExtractedTask(
      category: category ?? this.category,
      title: title ?? this.title,
      description: description ?? this.description,
      date: date ?? this.date,
      time: time ?? this.time,
      urgent: urgent ?? this.urgent,
      budgetMmk: budgetMmk ?? this.budgetMmk,
      township: township ?? this.township,
    );
  }
}
