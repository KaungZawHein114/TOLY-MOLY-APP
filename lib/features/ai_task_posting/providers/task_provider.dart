import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/task_repository.dart';
import '../data/task_repository_impl.dart';

/// Global provider — same documented exception as authRepositoryProvider
/// (see lib/features/auth/providers/auth_provider.dart): a real cross-screen
/// backend data source, not screen-local UI state.
final taskRepositoryProvider = Provider<TaskRepository>((ref) => TaskRepositoryImpl());
