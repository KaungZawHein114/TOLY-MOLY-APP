import 'package:flutter/material.dart';
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
  // mock document uploads can flip the gate live; everything else is static.
  final ClientProfile _profile = demoClientProfile;
  late final Set<VerificationDoc> _completedDocs = {..._profile.completedDocs};

  VerificationState get _state =>
      verificationStateFor(_completedDocs, ClientProfile.requiredDocs);

  void _toggleDoc(VerificationDoc doc) {
    setState(() => _completedDocs.add(doc));
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
              ProfileInfoRow(
                icon: Icons.location_on_outlined,
                label: ProfileStrings.locationLabel,
                value: _profile.location,
              ),
            ],
          ),
        ),

        // ── Verification (gates task posting) ──
        VerificationStatusCard(
          requiredDocs: ClientProfile.requiredDocs,
          completedDocs: _completedDocs,
          onToggleDoc: _toggleDoc,
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
      ],
    );
  }
}
