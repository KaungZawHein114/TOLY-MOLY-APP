import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/demo_data.dart';

// ============================================================================
// SCHEDULE-WORKER STATE — Riverpod, scoped to this feature only.
// Mirrors task_posting_state.dart's pattern: written on submit, not read by
// any screen yet (Activity stays a placeholder) — the created request isn't
// silently discarded, and a future Activity screen has an obvious place to
// start reading from.
// ============================================================================

final postedTaskRequestsProvider = StateProvider<List<TaskRequest>>((ref) => []);
