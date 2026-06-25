import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../constants/profile_strings.dart';
import '../../data/demo_data.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../../features/onboarding/onboarding_models.dart';
import '../large_button.dart';

/// A titled, soft-shadowed card used for each profile section. Sits on the
/// white panel, so it uses a faint fill + shadow (no border) to separate —
/// matching the project's "fill + shadow over Border.all" rule.
class ProfileSectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final Widget? trailing;

  const ProfileSectionCard({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.lightBg,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(color: AppColors.shadowSm, blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: AppSizes.iconMd, color: AppColors.purple700),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(title, style: theme.textTheme.titleMedium),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }
}

/// A label/value row for the public-info section.
class ProfileInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const ProfileInfoRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: AppSizes.iconSm, color: AppColors.textSecondary),
          const SizedBox(width: AppSpacing.sm),
          Text(label,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: AppColors.textSecondary)),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

/// A single stat tile (icon, value, label) — used in a row of stats.
class ProfileStat extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  const ProfileStat({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: AppSizes.iconLg - 2),
          const SizedBox(height: AppSpacing.xs),
          Text(value, style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            label,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

/// Tag chips for a tasker's skills (emoji + Burmese label).
class SkillChips extends StatelessWidget {
  final Set<TaskerSkill> skills;
  const SkillChips({super.key, required this.skills});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final skill in skills)
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.xs + 2),
            decoration: BoxDecoration(
              color: AppColors.purple100,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Text(
              "${skill.emoji} ${skill.label}",
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.purple700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }
}

// ============================================================================
// VERIFICATION STATUS CARD + GATED CTA
// ============================================================================

/// Compact verification pill for the gradient header (white background so it
/// reads on the purple gradient; state color carries the meaning).
class VerificationBadgePill extends StatelessWidget {
  final VerificationState state;
  const VerificationBadgePill({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final color = _stateColor(state);
    final icon = state == VerificationState.verified
        ? Icons.verified
        : state == VerificationState.pending
            ? Icons.hourglass_bottom
            : Icons.shield_outlined;
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.xs + 1),
      decoration: BoxDecoration(
        color: AppColors.onBrand,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: AppSizes.iconSm, color: color),
          const SizedBox(width: AppSpacing.xs),
          Text(
            state.label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

Color _stateColor(VerificationState state) {
  switch (state) {
    case VerificationState.notVerified:
      return AppColors.warning;
    case VerificationState.pending:
      return AppColors.purple500;
    case VerificationState.verified:
      return AppColors.success;
  }
}

IconData _docIcon(VerificationDoc doc) {
  switch (doc) {
    case VerificationDoc.nrc:
      return Icons.badge_outlined;
    case VerificationDoc.faceSelfie:
      return Icons.face_outlined;
    case VerificationDoc.permanentAddress:
      return Icons.home_outlined;
    case VerificationDoc.pitchingVideo:
      return Icons.videocam_outlined;
  }
}

/// The trust section: a progress indicator over the required documents, an
/// upload placeholder per document, and a gated primary action (Post Task /
/// Accept Task) that unlocks only once every required document is complete.
///
/// Uploads are mock: tapping a pending document calls [onToggleDoc] so the
/// hosting screen can mark it complete and the gate can flip live.
class VerificationStatusCard extends StatelessWidget {
  final List<VerificationDoc> requiredDocs;
  final Set<VerificationDoc> completedDocs;
  final ValueChanged<VerificationDoc> onToggleDoc;
  final String hint;
  final String ctaLabel;
  final String ctaLockedHint;
  final VoidCallback onCtaWhenUnlocked;

  const VerificationStatusCard({
    super.key,
    required this.requiredDocs,
    required this.completedDocs,
    required this.onToggleDoc,
    required this.hint,
    required this.ctaLabel,
    required this.ctaLockedHint,
    required this.onCtaWhenUnlocked,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = verificationStateFor(completedDocs, requiredDocs);
    final doneCount = requiredDocs.where(completedDocs.contains).length;
    final total = requiredDocs.length;
    final verified = state == VerificationState.verified;
    final stateColor = _stateColor(state);

    return ProfileSectionCard(
      title: ProfileStrings.verificationTitle,
      icon: Icons.verified_user_outlined,
      trailing: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm + 2, vertical: AppSpacing.xxs),
        decoration: BoxDecoration(
          color: stateColor.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Text(
          state.label,
          style: theme.textTheme.bodySmall
              ?.copyWith(color: stateColor, fontWeight: FontWeight.w700),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            hint,
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.md),
          // Progress: "X / N ပြီးစီး" + bar.
          Row(
            children: [
              Text(
                ProfileStrings.progressLabel(
                  toBurmeseDigits(doneCount),
                  toBurmeseDigits(total),
                ),
                style: theme.textTheme.labelMedium
                    ?.copyWith(color: AppColors.purple700),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: LinearProgressIndicator(
              value: total == 0 ? 0 : doneCount / total,
              minHeight: 8,
              backgroundColor: AppColors.purple100,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.purple500),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          for (final doc in requiredDocs)
            _VerificationStepRow(
              doc: doc,
              done: completedDocs.contains(doc),
              onUpload: () => onToggleDoc(doc),
            ),
          const SizedBox(height: AppSpacing.md),
          _GatedCta(
            label: ctaLabel,
            lockedHint: ctaLockedHint,
            unlocked: verified,
            onTap: onCtaWhenUnlocked,
          ),
        ],
      ),
    );
  }
}

class _VerificationStepRow extends StatelessWidget {
  final VerificationDoc doc;
  final bool done;
  final VoidCallback onUpload;

  const _VerificationStepRow({
    required this.doc,
    required this.done,
    required this.onUpload,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs + 1),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: done
                  ? AppColors.success.withValues(alpha: 0.15)
                  : AppColors.purple100,
              borderRadius: BorderRadius.circular(AppRadius.md - 2),
            ),
            child: Icon(
              done ? Icons.check_rounded : _docIcon(doc),
              size: AppSizes.iconMd,
              color: done ? AppColors.success : AppColors.purple700,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(doc.label, style: theme.textTheme.bodyMedium),
          ),
          const SizedBox(width: AppSpacing.sm),
          if (done)
            Row(
              children: [
                const Icon(Icons.verified,
                    size: AppSizes.iconSm, color: AppColors.success),
                const SizedBox(width: AppSpacing.xxs),
                Text(
                  ProfileStrings.uploadedLabel,
                  style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.success, fontWeight: FontWeight.w700),
                ),
              ],
            )
          else
            _UploadButton(onTap: onUpload),
        ],
      ),
    );
  }
}

class _UploadButton extends StatelessWidget {
  final VoidCallback onTap;
  const _UploadButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadius.sm);
    return Semantics(
      label: ProfileStrings.uploadCta,
      button: true,
      child: Material(
        color: AppColors.blue100,
        borderRadius: radius,
        child: InkWell(
          borderRadius: radius,
          onTap: () {
            HapticFeedback.lightImpact();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text(ProfileStrings.mockUploadedMessage)),
            );
            onTap();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.upload_outlined,
                    size: AppSizes.iconSm, color: AppColors.purple700),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  ProfileStrings.uploadCta,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.purple700, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Primary action that is enabled only when verification is complete. When
/// locked it renders a disabled, lock-marked button plus a helper line.
class _GatedCta extends StatelessWidget {
  final String label;
  final String lockedHint;
  final bool unlocked;
  final VoidCallback onTap;

  const _GatedCta({
    required this.label,
    required this.lockedHint,
    required this.unlocked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (unlocked) {
      return LargeButton(
        label: label,
        icon: Icons.add_circle_outline,
        gradient: AppColors.purpleGradient,
        onTap: onTap,
      );
    }
    return Column(
      children: [
        Semantics(
          label: "$label — $lockedHint",
          button: true,
          enabled: false,
          child: Container(
            height: AppSizes.buttonHeight,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.onboardingDivider,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_outline,
                    size: AppSizes.iconMd, color: AppColors.textSecondary),
                const SizedBox(width: AppSpacing.sm),
                Flexible(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          lockedHint,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(color: AppColors.warning),
        ),
      ],
    );
  }
}

// ============================================================================
// AVAILABILITY EDITOR (tasker) — UI-only toggles, local state.
// ============================================================================

/// Weekday/weekend + time-slot toggles for a tasker. Purely presentational in
/// Phase 1: it seeds from [initial] and keeps its own local selection; nothing
/// is persisted.
class AvailabilityEditor extends StatefulWidget {
  final TaskerAvailability initial;
  const AvailabilityEditor({super.key, required this.initial});

  @override
  State<AvailabilityEditor> createState() => _AvailabilityEditorState();
}

class _AvailabilityEditorState extends State<AvailabilityEditor> {
  late bool _weekdays = widget.initial.weekdays;
  late bool _weekends = widget.initial.weekends;
  late final Set<AvailabilitySlot> _slots = {...widget.initial.slots};

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            _ToggleChip(
              label: ProfileStrings.availabilityWeekdays,
              selected: _weekdays,
              onTap: () => setState(() => _weekdays = !_weekdays),
            ),
            _ToggleChip(
              label: ProfileStrings.availabilityWeekends,
              selected: _weekends,
              onTap: () => setState(() => _weekends = !_weekends),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final slot in AvailabilitySlot.values)
              _ToggleChip(
                label: slot.label,
                selected: _slots.contains(slot),
                onTap: () => setState(() {
                  if (!_slots.add(slot)) _slots.remove(slot);
                }),
              ),
          ],
        ),
      ],
    );
  }
}

class _ToggleChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ToggleChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final radius = BorderRadius.circular(AppRadius.pill);
    return Semantics(
      label: label,
      button: true,
      selected: selected,
      child: Material(
        color: selected ? AppColors.purple700 : AppColors.lightSurface,
        borderRadius: radius,
        child: InkWell(
          borderRadius: radius,
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          child: Container(
            constraints: const BoxConstraints(minHeight: 44),
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  selected ? Icons.check_circle : Icons.circle_outlined,
                  size: AppSizes.iconSm,
                  color: selected ? AppColors.onBrand : AppColors.textSecondary,
                ),
                const SizedBox(width: AppSpacing.xs + 2),
                Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: selected ? AppColors.onBrand : AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
