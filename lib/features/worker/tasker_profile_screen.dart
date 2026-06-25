import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/onboarding_strings.dart';
import '../../core/constants/profile_strings.dart';
import '../../core/data/demo_data.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/mascot/mascot_message_card.dart';
import '../../core/widgets/mascot/mascot_state.dart';
import '../../core/widgets/profile/profile_scaffold.dart';
import '../../core/widgets/profile/profile_sections.dart';
import '../onboarding/onboarding_models.dart';
import 'worker_home_shell.dart';

/// Tasker (service-provider) profile — the Profile tab of [WorkerHomeShell].
/// Renders [demoTaskerProfile]'s PUBLIC data (incl. skills), the stricter
/// 4-step verification gate that controls task acceptance, static stats, and
/// the availability toggles. PRIVATE registration data (phone, password,
/// source, account type) is intentionally NOT rendered — it lives only on
/// [TaskerProfile.registration] for a future backend.
class TaskerProfileScreen extends ConsumerStatefulWidget {
  const TaskerProfileScreen({super.key});

  @override
  ConsumerState<TaskerProfileScreen> createState() => _TaskerProfileScreenState();
}

class _TaskerProfileScreenState extends ConsumerState<TaskerProfileScreen> {
  final TaskerProfile _profile = demoTaskerProfile;
  late final Set<VerificationDoc> _completedDocs = {..._profile.completedDocs};

  VerificationState get _state =>
      verificationStateFor(_completedDocs, TaskerProfile.requiredDocs);

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
    final completionText =
        "${toBurmeseDigits((_profile.completionRate * 100).round())}%";

    return ProfileScaffold(
      name: _profile.fullName,
      roleLabel: ProfileStrings.taskerRoleLabel,
      badge: VerificationBadgePill(state: _state),
      profilePicturePath: _profile.profilePicturePath,
      onEdit: _editNotSupported,
      onEditPhoto: _editNotSupported,
      readAloudText: "${_profile.fullName}။ ${ProfileStrings.taskerRoleLabel}။ "
          "${verified ? ProfileStrings.mascotTaskerVerified : ProfileStrings.mascotTaskerUnverified}",
      sections: [
        MascotMessageCard(
          state: verified ? PhoWaYokeState.success : PhoWaYokeState.pointing,
          message: verified
              ? ProfileStrings.mascotTaskerVerified
              : ProfileStrings.mascotTaskerUnverified,
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
            ],
          ),
        ),

        // ── Skills ──
        ProfileSectionCard(
          title: ProfileStrings.skillsLabel,
          icon: Icons.handyman_outlined,
          child: Align(
            alignment: Alignment.centerLeft,
            child: SkillChips(skills: _profile.skills),
          ),
        ),

        // ── Verification (gates task acceptance) ──
        VerificationStatusCard(
          requiredDocs: TaskerProfile.requiredDocs,
          completedDocs: _completedDocs,
          onToggleDoc: _toggleDoc,
          hint: ProfileStrings.verificationTaskerHint,
          ctaLabel: ProfileStrings.acceptTaskCta,
          ctaLockedHint: ProfileStrings.acceptTaskLockedHint,
          // Verified taskers accept work from the dashboard job board, so the
          // unlocked CTA switches back to the Home (dashboard) tab.
          onCtaWhenUnlocked: () =>
              ref.read(workerTabIndexProvider.notifier).state = 0,
        ),

        // ── Stats ──
        ProfileSectionCard(
          title: ProfileStrings.statsTitle,
          icon: Icons.insights_outlined,
          child: Column(
            children: [
              Row(
                children: [
                  ProfileStat(
                    icon: Icons.assignment_turned_in_outlined,
                    iconColor: AppColors.success,
                    value: toBurmeseDigits(_profile.tasksCompleted),
                    label: ProfileStrings.statTasksCompleted,
                  ),
                  ProfileStat(
                    icon: Icons.percent_outlined,
                    iconColor: AppColors.purple700,
                    value: completionText,
                    label: ProfileStrings.statCompletionRate,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  ProfileStat(
                    icon: Icons.star_outline,
                    iconColor: AppColors.star,
                    value: ratingText,
                    label: ProfileStrings.statRating,
                  ),
                  ProfileStat(
                    icon: Icons.timer_outlined,
                    iconColor: AppColors.purple500,
                    value: _profile.responseTime,
                    label: ProfileStrings.statResponseTime,
                  ),
                ],
              ),
            ],
          ),
        ),

        // ── Availability (UI-only toggles) ──
        ProfileSectionCard(
          title: ProfileStrings.availabilityTitle,
          icon: Icons.event_available_outlined,
          child: AvailabilityEditor(initial: _profile.availability),
        ),
      ],
    );
  }
}
