import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'onboarding_models.dart';

// ============================================================================
// LOCAL ONBOARDING STATE — Riverpod, scoped to the onboarding feature only.
// The flow spans many routed screens (Welcome -> Create account -> role steps)
// so the draft providers live here, once, instead of duplicated per screen.
// No repository/service layer — screens read/write these providers directly.
// ============================================================================

final selectedRoleProvider = StateProvider<UserRole?>((ref) => null);

final clientDraftProvider =
    StateProvider<ClientProfileDraft>((ref) => ClientProfileDraft.empty());

final taskerDraftProvider =
    StateProvider<TaskerProfileDraft>((ref) => TaskerProfileDraft.empty());
