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
  late final Map<VerificationDoc, VerificationDocStatus> _docStatuses = {
    ..._profile.docStatuses,
  };

  VerificationState get _state =>
      verificationStateFor(_docStatuses, TaskerProfile.requiredDocs);

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
        VerificationSection(
          requiredDocs: TaskerProfile.requiredDocs,
          docStatuses: _docStatuses,
          onAction: _advanceDoc,
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

        // ── Switch role: back to the Task Provider (client) home ──
        BecomeClientCard(
          // Switching role is a sanctioned stack reset (CLAUDE.md routing
          // rules), same as the onboarding-complete/booking-done go() calls —
          // not a forward push, since the tasker shell shouldn't stay on the
          // back stack underneath the client shell.
          onTap: () => context.go(Routes.customerHome),
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
                      ProfileStrings.becomeClientCta,
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
