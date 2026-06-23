import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/demo_data.dart';
import 'task_posting_models.dart';

// ============================================================================
// LOCAL TASK-POSTING STATE — Riverpod, scoped to this feature only.
// The flow spans 7 routed screens, so the draft provider lives here, once,
// instead of duplicated per screen. No repository/service layer — screens
// read/write this provider directly.
// ============================================================================

final taskDraftProvider = StateProvider<TaskDraft>((ref) => TaskDraft.empty());

/// Written by the review/publish screen on successful publish. Not read by
/// any screen yet — the Activity tab stays a placeholder this slice — but
/// the created task isn't silently discarded, and a future Activity screen
/// has an obvious place to start reading from.
final postedTasksProvider = StateProvider<List<TaskPost>>((ref) => []);
