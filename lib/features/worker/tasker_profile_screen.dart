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
import '../profile/data/skills_repository.dart';
import '../profile/data/skills_repository_impl.dart';
import '../profile/models/profile_models.dart';
import 'worker_home_shell.dart';

// ============================================================================
// PROFILE PROVIDER — backend-connected (name/phone/age/gender/accountStatus).
// Screen-local per CLAUDE.md's Riverpod convention (every provider lives in
// the screen file that uses it) — this is the one screen that reads/writes
// tasker profile data, so there is no cross-screen state to share.
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
// SKILLS PROVIDER — backend-connected CRUD (`/api/tasker/skills*`).
// ============================================================================

class _SkillsUiState {
  final bool loading;
  final List<TaskerSkillEntry> skills;

  const _SkillsUiState({this.loading = true, this.skills = const []});

  _SkillsUiState copyWith({bool? loading, List<TaskerSkillEntry>? skills}) => _SkillsUiState(
        loading: loading ?? this.loading,
        skills: skills ?? this.skills,
      );
}

class _SkillsNotifier extends StateNotifier<_SkillsUiState> {
  final SkillsRepository _repo;
  _SkillsNotifier(this._repo) : super(const _SkillsUiState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(loading: true);
    try {
      final skills = await _repo.list();
      state = _SkillsUiState(loading: false, skills: skills);
    } catch (_) {
      state = state.copyWith(loading: false);
    }
  }

  Future<bool> add(String name, int years) async {
    try {
      final created = await _repo.create(skillName: name, experienceYears: years);
      state = state.copyWith(skills: [...state.skills, created]);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> edit(int id, String name, int years) async {
    try {
      final updated = await _repo.update(id, skillName: name, experienceYears: years);
      state = state.copyWith(
        skills: [for (final s in state.skills) if (s.id == id) updated else s],
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> remove(int id) async {
    try {
      await _repo.delete(id);
      state = state.copyWith(skills: state.skills.where((s) => s.id != id).toList());
      return true;
    } catch (_) {
      return false;
    }
  }
}

final _skillsProvider = StateNotifierProvider.autoDispose<_SkillsNotifier, _SkillsUiState>(
  (ref) => _SkillsNotifier(SkillsRepositoryImpl()),
);

// ============================================================================
// VERIFICATION DEMO PROVIDER — LOCAL ONLY. Never calls the backend. Section 5
// (NRC/Face/Address) drives the displayed account-status badge together with
// the real backend status (see [_displayedVerificationState]); Section 6
// (promotion video) is tracked here too but never affects that badge.
// ============================================================================

class _VerificationDemoState {
  final bool nrcAdded;
  final bool faceAdded;
  final bool addressAdded;
  final bool promotionVideoAdded;

  const _VerificationDemoState({
    this.nrcAdded = false,
    this.faceAdded = false,
    this.addressAdded = false,
    this.promotionVideoAdded = false,
  });

  int get doneCount => [nrcAdded, faceAdded, addressAdded].where((v) => v).length;
  bool get allThreeAdded => doneCount == 3;

  _VerificationDemoState copyWith({
    bool? nrcAdded,
    bool? faceAdded,
    bool? addressAdded,
    bool? promotionVideoAdded,
  }) =>
      _VerificationDemoState(
        nrcAdded: nrcAdded ?? this.nrcAdded,
        faceAdded: faceAdded ?? this.faceAdded,
        addressAdded: addressAdded ?? this.addressAdded,
        promotionVideoAdded: promotionVideoAdded ?? this.promotionVideoAdded,
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
        state = state.copyWith(addressAdded: true);
      case VerificationDoc.pitchingVideo:
        state = state.copyWith(promotionVideoAdded: true);
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

/// account-wide badge: backend VERIFIED always wins; otherwise the 3-item
/// demo progress can only ever show as far as PENDING, never VERIFIED —
/// only the backend can actually mark an account VERIFIED.
VerificationState _displayedVerificationState(String backendStatus, _VerificationDemoState demo) {
  if (backendStatus == "VERIFIED") return VerificationState.verified;
  if (demo.allThreeAdded) return VerificationState.pending;
  return VerificationState.notVerified;
}

Gender _genderFromBackend(String value) =>
    Gender.values.firstWhere((g) => g.name == value, orElse: () => Gender.other);

/// Tasker (service-provider) profile — the Profile tab of [WorkerHomeShell].
///
/// Backend-connected: name, phone, age, gender, account status, skills CRUD,
/// logout (see [_profileProvider]/[_skillsProvider]).
/// Demo-only (never touches Django/Postgres): profile picture, the
/// NRC/Face/Address/Promotion-video verification steps, switch role (see
/// [_verificationDemoProvider]).
class TaskerProfileScreen extends ConsumerStatefulWidget {
  const TaskerProfileScreen({super.key});

  @override
  ConsumerState<TaskerProfileScreen> createState() => _TaskerProfileScreenState();
}

class _TaskerProfileScreenState extends ConsumerState<TaskerProfileScreen> {
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
    final skillsState = ref.watch(_skillsProvider);
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
      roleLabel: ProfileStrings.taskerRoleLabel,
      badge: VerificationBadgePill(state: verifiedState),
      profilePicturePath: _pictureChosen ? "demo" : null,
      onEditPhoto: _mockEditPhoto,
      sections: [
        MascotMessageCard(
          state: verified ? PhoWaYokeState.success : PhoWaYokeState.pointing,
          message: verified ? ProfileStrings.mascotTaskerVerified : ProfileStrings.mascotTaskerUnverified,
          mascotSize: 64,
        ),
        const SizedBox(height: AppSpacing.lg),

        // ── Public information (backend: age, gender — editable) ──
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

        // ── Skills (backend: CRUD) ──
        ProfileSectionCard(
          title: ProfileStrings.skillsLabel,
          icon: Icons.handyman_outlined,
          child: SkillsManager(
            skills: skillsState.skills,
            loading: skillsState.loading,
            onAdd: (name, years) => ref.read(_skillsProvider.notifier).add(name, years),
            onEdit: (id, name, years) => ref.read(_skillsProvider.notifier).edit(id, name, years),
            onDelete: (id) => ref.read(_skillsProvider.notifier).remove(id),
          ),
        ),

        // ── Verification (DEMO ONLY — local Riverpod state) ──
        VerificationSection(
          requiredDocs: const [
            VerificationDoc.nrc,
            VerificationDoc.faceSelfie,
            VerificationDoc.permanentAddress,
          ],
          docStatuses: {
            VerificationDoc.nrc:
                verification.nrcAdded ? VerificationDocStatus.completed : VerificationDocStatus.notStarted,
            VerificationDoc.faceSelfie:
                verification.faceAdded ? VerificationDocStatus.completed : VerificationDocStatus.notStarted,
            VerificationDoc.permanentAddress: verification.addressAdded
                ? VerificationDocStatus.completed
                : VerificationDocStatus.notStarted,
          },
          onAction: (doc) => ref.read(_verificationDemoProvider.notifier).markAdded(doc),
          hint: ProfileStrings.verificationTaskerHint,
        ),

        // ── Promotion video (DEMO ONLY, optional) ──
        ProfileSectionCard(
          title: ProfileStrings.promoVideoTitle,
          icon: Icons.videocam_outlined,
          child: PromotionVideoCard(
            added: verification.promotionVideoAdded,
            onAdd: () => ref.read(_verificationDemoProvider.notifier).markAdded(VerificationDoc.pitchingVideo),
          ),
        ),

        // ── Switch role (DEMO ONLY — navigation reset, no backend) ──
        BecomeClientCard(
          onTap: () => context.go(Routes.customerHome),
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

/// Banner prompting a tasker to switch back to being a client ("Task
/// Provider") — mirrors [BecomeTaskerSignupCard] on the client profile, just
/// pointed the other way. Purely presentational; navigation is the caller's.
class BecomeClientCard extends StatelessWidget {
  final VoidCallback onTap;

  const BecomeClientCard({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final radius = BorderRadius.circular(AppRadius.lg);

    return Semantics(
      label: "${ProfileStrings.becomeClientTitle} "
          "${ProfileStrings.becomeClientCta}",
      button: true,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.indigo700,
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
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.onBrand.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: const Icon(
                      Icons.assignment_outlined,
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
                          ProfileStrings.becomeClientTitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: AppColors.onBrand,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          ProfileStrings.becomeClientSubtitle,
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
                  const SizedBox(width: AppSpacing.md),
                  Flexible(
                    child: Container(
                      constraints: const BoxConstraints(
                        minWidth: 96,
                        maxWidth: 112,
                        minHeight: 48,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.onBrand,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            ProfileStrings.becomeClientCta,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: AppColors.indigo700,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xxs),
                          const Icon(Icons.arrow_forward_rounded,
                              color: AppColors.indigo700, size: AppSizes.iconSm),
                        ],
                      ),
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
