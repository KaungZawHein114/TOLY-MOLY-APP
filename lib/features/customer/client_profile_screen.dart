import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/onboarding_strings.dart';
import '../../core/constants/profile_strings.dart';
import '../../core/data/demo_data.dart';
import '../../core/routing/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/mascot/mascot_message_card.dart';
import '../../core/widgets/mascot/mascot_state.dart';
import '../../core/widgets/profile/profile_scaffold.dart';
import '../../core/widgets/profile/profile_sections.dart';
import '../auth/providers/auth_provider.dart';
import '../onboarding/onboarding_models.dart';
import '../profile/data/profile_repository.dart';
import '../profile/data/profile_repository_impl.dart';
import '../profile/models/profile_models.dart';

// ============================================================================
// PROFILE PROVIDER — backend-connected (name/phone/age/gender/accountStatus).
// Screen-local per CLAUDE.md's Riverpod convention — this is the one screen
// that reads/writes client profile data, so there is no cross-screen state
// to share. Same shape as the tasker screen's provider (both talk to the
// same generic `/api/profile/*` endpoints); duplicated per-screen rather than
// shared, matching this project's "no global provider files" rule.
// ============================================================================

class _ProfileUiState {
  final bool loading;
  final String? error;
  final UserProfileData? data;

  const _ProfileUiState({this.loading = true, this.error, this.data});

  _ProfileUiState copyWith({bool? loading, String? error, UserProfileData? data}) => _ProfileUiState(
        loading: loading ?? this.loading,
        error: error,
        data: data ?? this.data,
      );
}

class _ProfileNotifier extends StateNotifier<_ProfileUiState> {
  final ProfileRepository _repo;
  _ProfileNotifier(this._repo) : super(const _ProfileUiState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(loading: true, error: null);
    try {
      final data = await _repo.getProfile();
      state = _ProfileUiState(loading: false, data: data);
    } catch (_) {
      state = state.copyWith(loading: false, error: ProfileStrings.loadFailedMessage);
    }
  }

  Future<bool> updateAgeGender({required int age, required Gender gender}) async {
    final current = state.data;
    if (current == null) return false;
    try {
      final updated = await _repo.updateAgeGender(current, age: age, gender: gender.name);
      state = state.copyWith(data: updated);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> updatePhone(String phoneNumber) async {
    final current = state.data;
    if (current == null) return false;
    try {
      await _repo.updatePhone(phoneNumber);
      state = state.copyWith(data: current.copyWith(phoneNumber: phoneNumber));
      return true;
    } catch (_) {
      return false;
    }
  }
}

final _profileProvider = StateNotifierProvider.autoDispose<_ProfileNotifier, _ProfileUiState>(
  (ref) => _ProfileNotifier(ProfileRepositoryImpl()),
);

// ============================================================================
// VERIFICATION DEMO PROVIDER — LOCAL ONLY, never calls the backend. Client
// verification only requires NRC + Face (no address/video — that's the
// tasker-only trust bar). Drives the displayed account-status badge together
// with the real backend status (see [_displayedVerificationState]).
// ============================================================================

class _VerificationDemoState {
  final bool nrcAdded;
  final bool faceAdded;

  const _VerificationDemoState({this.nrcAdded = false, this.faceAdded = false});

  int get doneCount => [nrcAdded, faceAdded].where((v) => v).length;
  bool get allAdded => doneCount == 2;
  double get progress => doneCount / 2;

  _VerificationDemoState copyWith({bool? nrcAdded, bool? faceAdded}) => _VerificationDemoState(
        nrcAdded: nrcAdded ?? this.nrcAdded,
        faceAdded: faceAdded ?? this.faceAdded,
      );
}

class _VerificationDemoNotifier extends StateNotifier<_VerificationDemoState> {
  _VerificationDemoNotifier() : super(const _VerificationDemoState());

  void markAdded(VerificationDoc doc) {
    switch (doc) {
      case VerificationDoc.nrc:
        state = state.copyWith(nrcAdded: true);
      case VerificationDoc.faceSelfie:
        state = state.copyWith(faceAdded: true);
      case VerificationDoc.permanentAddress:
      case VerificationDoc.pitchingVideo:
        break; // not part of the client's 2-item demo checklist.
    }
  }
}

// Not autoDispose: once a step is marked done (and especially once the
// account reaches the PENDING display state), it must stay done for the rest
// of the session — autoDispose would wipe it back to unfilled the moment the
// screen briefly has no listeners (e.g. mid-navigation).
final _verificationDemoProvider =
    StateNotifierProvider<_VerificationDemoNotifier, _VerificationDemoState>(
  (ref) => _VerificationDemoNotifier(),
);

/// account-wide badge: backend VERIFIED always wins; otherwise the 2-item
/// demo checklist can only ever show as far as PENDING, never VERIFIED —
/// only the backend can actually mark an account VERIFIED.
VerificationState _displayedVerificationState(String backendStatus, _VerificationDemoState demo) {
  if (backendStatus == "VERIFIED") return VerificationState.verified;
  if (demo.allAdded) return VerificationState.pending;
  return VerificationState.notVerified;
}

Gender _genderFromBackend(String value) =>
    Gender.values.firstWhere((g) => g.name == value, orElse: () => Gender.other);

/// Client (service-seeker) profile — the Profile tab of [CustomerHomeShell].
///
/// Backend-connected: name, phone, age, gender, account status, logout (see
/// [_profileProvider]). Demo-only (never touches Django/Postgres): profile
/// picture, the NRC/Face verification checklist, switch role (see
/// [_verificationDemoProvider]).
class ClientProfileScreen extends ConsumerStatefulWidget {
  const ClientProfileScreen({super.key});

  @override
  ConsumerState<ClientProfileScreen> createState() => _ClientProfileScreenState();
}

class _ClientProfileScreenState extends ConsumerState<ClientProfileScreen> {
  // Demo-only local avatar toggle (Section 1 — never uploaded/persisted).
  bool _pictureChosen = false;

  void _mockEditPhoto() {
    HapticFeedback.selectionClick();
    setState(() => _pictureChosen = !_pictureChosen);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text(ProfileStrings.editNotSupported)),
    );
  }

  Future<bool> _onSaveAgeGender(int age, Gender gender) {
    return ref.read(_profileProvider.notifier).updateAgeGender(age: age, gender: gender);
  }

  Future<String?> _onSendOtp(String newPhone) async {
    try {
      await ref.read(authRepositoryProvider).sendOtp(newPhone);
      return null;
    } catch (_) {
      return ProfileStrings.saveFailedMessage;
    }
  }

  Future<bool> _onVerifyAndSavePhone(String newPhone, String otp) async {
    try {
      await ref.read(authRepositoryProvider).verifyOtp(phoneNumber: newPhone, code: otp);
    } catch (_) {
      return false;
    }
    return ref.read(_profileProvider.notifier).updatePhone(newPhone);
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(_profileProvider);
    final verification = ref.watch(_verificationDemoProvider);
    final theme = Theme.of(context);

    final profile = profileState.data;

    // First frame never blocks on the network: while the profile is still
    // loading (or failed), the scaffold still renders with a lightweight
    // skeleton state instead of an empty screen.
    final displayName = profile?.name ?? "...";
    final backendStatus = profile?.accountStatus ?? "UNVERIFIED";
    final verifiedState = _displayedVerificationState(backendStatus, verification);
    final verified = verifiedState == VerificationState.verified;

    return ProfileScaffold(
      name: displayName,
      roleLabel: ProfileStrings.clientRoleLabel,
      badge: VerificationBadgePill(state: verifiedState),
      profilePicturePath: _pictureChosen ? "demo" : null,
      onEditPhoto: _mockEditPhoto,
      sections: [
        // Mascot guidance — selective use, per the verification/profile rule.
        MascotMessageCard(
          state: verified ? PhoWaYokeState.success : PhoWaYokeState.pointing,
          message: verified ? ProfileStrings.mascotClientVerified : ProfileStrings.mascotClientUnverified,
          mascotSize: 64,
        ),
        const SizedBox(height: AppSpacing.lg),

        // ── Personal information (backend: age, gender — editable) ──
        ProfileSectionCard(
          title: ProfileStrings.publicInfoTitle,
          icon: Icons.person_outline,
          child: profileState.loading && profile == null
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                )
              : profile == null
                  ? Text(profileState.error ?? ProfileStrings.loadFailedMessage,
                      style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.error))
                  : AgeGenderEditor(
                      age: profile.age,
                      gender: _genderFromBackend(profile.gender),
                      onSave: _onSaveAgeGender,
                      allowGenderEdit: false,
                    ),
        ),

        // ── Phone number (backend: OTP-gated change) ──
        if (profile != null)
          ProfileSectionCard(
            title: OnboardingStrings.phoneLabel,
            icon: Icons.phone_outlined,
            child: PhoneNumberEditor(
              currentPhone: profile.phoneNumber,
              onSendOtp: _onSendOtp,
              onVerifyAndSave: _onVerifyAndSavePhone,
            ),
          ),

        // ── Verification (DEMO ONLY — local Riverpod state; gates task posting) ──
        VerificationSection(
          requiredDocs: const [VerificationDoc.nrc, VerificationDoc.faceSelfie],
          docStatuses: {
            VerificationDoc.nrc:
                verification.nrcAdded ? VerificationDocStatus.completed : VerificationDocStatus.notStarted,
            VerificationDoc.faceSelfie:
                verification.faceAdded ? VerificationDocStatus.completed : VerificationDocStatus.notStarted,
          },
          onAction: (doc) => ref.read(_verificationDemoProvider.notifier).markAdded(doc),
          hint: ProfileStrings.verificationClientHint,
        ),

        // ── Switch role (DEMO ONLY — navigation only, no backend) ──
        BecomeTaskerSignupCard(
          onTap: () => context.push(Routes.taskerPersonal),
        ),

        // ── Logout (backend: clears JWT + local storage) ──
        const SizedBox(height: AppSpacing.sm),
        ProfileLogoutButton(
          onConfirm: () async {
            await ref.read(authRepositoryProvider).logout();
            if (context.mounted) context.go(Routes.onboardingWelcome);
          },
        ),
      ],
    );
  }
}

class BecomeTaskerSignupCard extends StatelessWidget {
  final VoidCallback onTap;

  const BecomeTaskerSignupCard({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final radius = BorderRadius.circular(AppRadius.lg);

    return Semantics(
      label: "${ProfileStrings.becomeTaskerTitle} "
          "${ProfileStrings.becomeTaskerCta}",
      button: true,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.purple700,
          borderRadius: radius,
          boxShadow: [
            BoxShadow(
              color: AppColors.selectedCardShadow,
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: radius,
          child: InkWell(
            borderRadius: radius,
            onTap: () {
              HapticFeedback.selectionClick();
              onTap();
            },
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              // Stacked layout (icon+copy row, then a full-width CTA below)
              // instead of a single wide Row — this is what keeps the card
              // from cramping/overflowing the CTA text on narrow phones,
              // and it scales cleanly up to tablet widths too.
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.onBrand.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: const Icon(
                          Icons.engineering_outlined,
                          color: AppColors.onBrand,
                          size: AppSizes.iconLg,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              ProfileStrings.becomeTaskerTitle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: AppColors.onBrand,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              ProfileStrings.becomeTaskerSubtitle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.onBrandMuted,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(minHeight: 48),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.onBrand,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            ProfileStrings.becomeTaskerCta,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: AppColors.purple700,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        const Icon(Icons.arrow_forward_rounded,
                            color: AppColors.purple700, size: AppSizes.iconSm),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
