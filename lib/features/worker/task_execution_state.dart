import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/demo_data.dart';

// ============================================================================
// DIGITAL TASK CHECK-IN STATE — Riverpod, shared by the dashboard's preview
// card and the full task_execution_screen.dart. Keyed by booking/task id so
// the same shape works if more than one on-site task is ever shown at once.
// ============================================================================

final taskExecutionProvider = StateProvider<Map<int, TaskExecution>>((ref) => {});

/// Returns the stored execution for [taskId], or a fresh `pending` one if
/// this task hasn't been touched yet — callers never need a null check.
TaskExecution executionFor(Map<int, TaskExecution> all, int taskId) =>
    all[taskId] ?? TaskExecution(taskId: taskId);
