import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/auth_repository.dart';
import '../data/auth_repository_impl.dart';

/// The one global provider this app has — a deliberate, documented
/// exception to Phase 1's "providers are screen-local" rule (CLAUDE.md),
/// since the auth repository is now a real cross-screen data source
/// (register/OTP screens, login, and eventually any screen that needs
/// `/me`), not local UI state.
final authRepositoryProvider = Provider<AuthRepository>((ref) => AuthRepositoryImpl());
