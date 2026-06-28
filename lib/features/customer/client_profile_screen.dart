import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import '../onboarding/onboarding_models.dart';

/// Client (service-seeker) profile — the Profile tab of [CustomerHomeShell].
/// Renders [demoClientProfile]'s PUBLIC data, the verification gate that
/// controls task posting, and static stats. The profile's PRIVATE registration
/// data (phone, password, source, account type) is intentionally NOT rendered
/// — it exists on [ClientProfile.registration] for a future backend only.
class ClientProfileScreen extends StatefulWidget {
  const ClientProfileScreen({super.key});

  @override
  State<ClientProfileScreen> createState() => _ClientProfileScreenState();
}

class _ClientProfileScreenState extends State<ClientProfileScreen> {
  // Source of truth for this screen. Verification is mutable locally so the
  // mock document captures can advance status and flip the gate live;
  // everything else is static.
  final ClientProfile _profile = demoClientProfile;
  late final Map<VerificationDoc, VerificationDocStatus> _docStatuses = {
    ..._profile.docStatuses,
  };

  VerificationState get _state =>
      verificationStateFor(_docStatuses, ClientProfile.requiredDocs);

  // Mock capture: advance the document one step (notStarted -> pending ->
  // completed) so the demo can walk through every status.
  void _advanceDoc(VerificationDoc doc) {
    setState(() {
      final current = _docStatuses[doc] ?? VerificationDocStatus.notStarted;
      _docStatuses[doc] = current == VerificationDocStatus.notStarted
          ? VerificationDocStatus.pending
          : VerificationDocStatus.completed;
    });
  }

  void _editNotSupported() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text(ProfileStrings.editNotSupported)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final verified = _state == VerificationState.verified;
    final ratingText = _profile.rating == null
        ? ProfileStrings.ratingNotAvailable
        : _profile.rating!.toStringAsFixed(1);

    return ProfileScaffold(
      name: _profile.fullName,
      roleLabel: ProfileStrings.clientRoleLabel,
      badge: VerificationBadgePill(state: _state),
      profilePicturePath: _profile.profilePicturePath,
      onEdit: _editNotSupported,
      onEditPhoto: _editNotSupported,
      readAloudText: "${_profile.fullName}။ ${ProfileStrings.clientRoleLabel}။ "
          "${verified ? ProfileStrings.mascotClientVerified : ProfileStrings.mascotClientUnverified}",
      sections: [
        // Mascot guidance — selective use, per the verification/profile rule.
        MascotMessageCard(
          state: verified ? PhoWaYokeState.success : PhoWaYokeState.pointing,
          message: verified
              ? ProfileStrings.mascotClientVerified
              : ProfileStrings.mascotClientUnverified,
          mascotSize: 64,
        ),
        const SizedBox(height: AppSpacing.lg),

        // ── Public information ──
        ProfileSectionCard(
          title: ProfileStrings.publicInfoTitle,
          icon: Icons.person_outline,
          child: Column(
            children: [
              ProfileInfoRow(
                icon: Icons.cake_outlined,
                label: OnboardingStrings.ageLabel,
                value: "${toBurmeseDigits(_profile.age)} နှစ်",
              ),
              ProfileInfoRow(
                icon: Icons.wc_outlined,
                label: OnboardingStrings.genderLabel,
                value: _profile.gender.label,
              ),
              // NOTE: no address row — location is captured in the Address
              // verification step (GPS), not stored as profile info.
            ],
          ),
        ),

        // ── Verification (gates task posting) ──
        VerificationSection(
          requiredDocs: ClientProfile.requiredDocs,
          docStatuses: _docStatuses,
          onAction: _advanceDoc,
          hint: ProfileStrings.verificationClientHint,
          ctaLabel: ProfileStrings.postTaskCta,
          ctaLockedHint: ProfileStrings.postTaskLockedHint,
          // Only reachable once verified — wires straight into the task
          // posting flow (blocked otherwise by the gate above).
          onCtaWhenUnlocked: () => context.push(Routes.postTask),
        ),

        // ── Stats ──
        ProfileSectionCard(
          title: ProfileStrings.statsTitle,
          icon: Icons.insights_outlined,
          child: Row(
            children: [
              ProfileStat(
                icon: Icons.post_add_outlined,
                iconColor: AppColors.purple700,
                value: toBurmeseDigits(_profile.tasksPosted),
                label: ProfileStrings.statTasksPosted,
              ),
              ProfileStat(
                icon: Icons.assignment_turned_in_outlined,
                iconColor: AppColors.success,
                value: toBurmeseDigits(_profile.tasksCompleted),
                label: ProfileStrings.statTasksCompleted,
              ),
              ProfileStat(
                icon: Icons.star_outline,
                iconColor: AppColors.star,
                value: ratingText,
                label: ProfileStrings.statRating,
              ),
            ],
          ),
        ),

        BecomeTaskerSignupCard(
          onTap: () => context.push(Routes.taskerPersonal),
        ),

        // ── Logout ──
        const SizedBox(height: AppSpacing.sm),
        ProfileLogoutButton(
          onConfirm: () => context.go(Routes.onboardingWelcome),
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
                  const SizedBox(width: AppSpacing.md),
                  Container(
                    constraints: const BoxConstraints(
                      minWidth: 96,
                      minHeight: 48,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.warning,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      ProfileStrings.becomeTaskerCta,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
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
