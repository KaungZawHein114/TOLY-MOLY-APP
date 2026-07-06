import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/voice_task_api.dart';
import 'models/extracted_task.dart';

// ============================================================================
// VOICE TASK-POSTING STATE — feature-scoped Riverpod.
// The flow spans two screens (dictate -> review), so the draft lives here once
// rather than being threaded through navigation. Same documented exception as
// taskRepositoryProvider/authRepositoryProvider: [voiceTaskApiProvider] is a
// real backend data source, not screen-local UI state.
// ============================================================================

final voiceTaskApiProvider = Provider<VoiceTaskApi>((ref) => VoiceTaskApi());

/// The task being reviewed: written by the intro screen once the AI returns,
/// then edited in place by the review screen as the client fills the gaps.
final voiceDraftProvider =
    StateProvider<ExtractedTask>((ref) => ExtractedTask.empty());
