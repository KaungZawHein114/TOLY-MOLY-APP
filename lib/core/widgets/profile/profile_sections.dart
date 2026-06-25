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

Color _docStatusColor(VerificationDocStatus status) {
  switch (status) {
    case VerificationDocStatus.notStarted:
      return AppColors.textSecondary; // grey
    case VerificationDocStatus.pending:
      return AppColors.warning; // yellow
    case VerificationDocStatus.completed:
      return AppColors.success; // green
  }
}

String _docDescription(VerificationDoc doc) {
  switch (doc) {
    case VerificationDoc.nrc:
      return ProfileStrings.descNrc;
    case VerificationDoc.faceSelfie:
      return ProfileStrings.descFace;
    case VerificationDoc.permanentAddress:
      return ProfileStrings.descAddress;
    case VerificationDoc.pitchingVideo:
      return ProfileStrings.descPitchingVideo;
  }
}

String _docActionLabel(VerificationDoc doc) {
  switch (doc) {
    case VerificationDoc.nrc:
      return ProfileStrings.actionNrc;
    case VerificationDoc.faceSelfie:
      return ProfileStrings.actionFace;
    case VerificationDoc.permanentAddress:
      return ProfileStrings.actionAddress;
    case VerificationDoc.pitchingVideo:
      return ProfileStrings.actionPitchingVideo;
  }
}

IconData _docActionIcon(VerificationDoc doc) {
  switch (doc) {
    case VerificationDoc.nrc:
      return Icons.file_upload_outlined;
    case VerificationDoc.faceSelfie:
      return Icons.camera_alt_outlined;
    case VerificationDoc.permanentAddress:
      return Icons.my_location; // GPS, not manual entry
    case VerificationDoc.pitchingVideo:
      return Icons.videocam_outlined;
  }
}

/// The full trust section: an overview header (account-wide state badge +
/// progress bar), one structured [VerificationStepCard] per required document,
/// and the gated primary action that unlocks only once every step is complete.
///
/// Captures are mock: tapping a step's action calls [onAction], which advances
/// that document's status so the badge, progress and gate flip live.
class VerificationSection extends StatelessWidget {
  final List<VerificationDoc> requiredDocs;
  final Map<VerificationDoc, VerificationDocStatus> docStatuses;
  final ValueChanged<VerificationDoc> onAction;
  final String hint;
  final String ctaLabel;
  final String ctaLockedHint;
  final VoidCallback onCtaWhenUnlocked;

  const VerificationSection({
    super.key,
    required this.requiredDocs,
    required this.docStatuses,
    required this.onAction,
    required this.hint,
    required this.ctaLabel,
    required this.ctaLockedHint,
    required this.onCtaWhenUnlocked,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = verificationStateFor(docStatuses, requiredDocs);
    final done = completedDocCount(docStatuses, requiredDocs);
    final total = requiredDocs.length;
    final verified = state == VerificationState.verified;
    final stateColor = _stateColor(state);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Overview header (state badge + progress) ──
        ProfileSectionCard(
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
              Text(
                ProfileStrings.progressLabel(
                  toBurmeseDigits(done),
                  toBurmeseDigits(total),
                ),
                style: theme.textTheme.labelMedium
                    ?.copyWith(color: AppColors.purple700),
              ),
              const SizedBox(height: AppSpacing.sm),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.pill),
                child: LinearProgressIndicator(
                  value: total == 0 ? 0 : done / total,
                  minHeight: 8,
                  backgroundColor: AppColors.purple100,
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(AppColors.purple500),
                ),
              ),
            ],
          ),
        ),

        // ── One structured card per required document ──
        for (final doc in requiredDocs)
          VerificationStepCard(
            doc: doc,
            status: docStatuses[doc] ?? VerificationDocStatus.notStarted,
            onAction: () => onAction(doc),
          ),

        const SizedBox(height: AppSpacing.xs),
        _GatedCta(
          label: ctaLabel,
          lockedHint: ctaLockedHint,
          unlocked: verified,
          onTap: onCtaWhenUnlocked,
        ),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }
}

/// One verification requirement as a full, guided card: leading icon + title +
/// status badge, an instruction line, a typed preview placeholder, and a clear
/// action button (or a completed confirmation). The card's accent border is
/// tinted by [status] — grey / yellow / green.
class VerificationStepCard extends StatelessWidget {
  final VerificationDoc doc;
  final VerificationDocStatus status;
  final VoidCallback onAction;

  const VerificationStepCard({
    super.key,
    required this.doc,
    required this.status,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _docStatusColor(status);
    final completed = status == VerificationDocStatus.completed;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.lightBg,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: color.withValues(alpha: 0.45), width: 1.4),
        boxShadow: [
          BoxShadow(color: AppColors.shadowSm, blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Title row + status indicator.
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(AppRadius.md - 2),
                ),
                child: Icon(_docIcon(doc), size: AppSizes.iconMd, color: color),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(doc.label, style: theme.textTheme.titleMedium),
              ),
              const SizedBox(width: AppSpacing.sm),
              _StatusBadge(status: status),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          // 2. Instruction.
          Text(
            _docDescription(doc),
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.md),
          // 3. Typed preview placeholder (image / face / map / video).
          _PlaceholderPreview(doc: doc, completed: completed),
          const SizedBox(height: AppSpacing.md),
          // 4. Action (or a completed confirmation).
          if (completed)
            Row(
              children: [
                const Icon(Icons.check_circle,
                    size: AppSizes.iconMd, color: AppColors.success),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  VerificationDocStatus.completed.label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.success, fontWeight: FontWeight.w700),
                ),
              ],
            )
          else
            _VerificationActionButton(
              label: _docActionLabel(doc),
              icon: _docActionIcon(doc),
              onTap: onAction,
            ),
        ],
      ),
    );
  }
}

/// Small status pill (colored dot + label) shown on each step card.
class _StatusBadge extends StatelessWidget {
  final VerificationDocStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = _docStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm, vertical: AppSpacing.xxs),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            status.label,
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

/// Renders the right preview placeholder for a document type. NRC shows two
/// image slots (front/back); face/address/video each show a single typed
/// frame. A completed step reads as "captured" (green).
class _PlaceholderPreview extends StatelessWidget {
  final VerificationDoc doc;
  final bool completed;
  const _PlaceholderPreview({required this.doc, required this.completed});

  @override
  Widget build(BuildContext context) {
    switch (doc) {
      case VerificationDoc.nrc:
        return Row(
          children: [
            Expanded(
              child: _PreviewFrame(
                height: 92,
                icon: Icons.image_outlined,
                caption: ProfileStrings.placeholderNrcFront,
                completed: completed,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _PreviewFrame(
                height: 92,
                icon: Icons.image_outlined,
                caption: ProfileStrings.placeholderNrcBack,
                completed: completed,
              ),
            ),
          ],
        );
      case VerificationDoc.faceSelfie:
        return _PreviewFrame(
          height: 132,
          icon: Icons.face_outlined,
          caption: ProfileStrings.placeholderFace,
          completed: completed,
        );
      case VerificationDoc.permanentAddress:
        return _PreviewFrame(
          height: 132,
          icon: Icons.pin_drop_outlined,
          caption: ProfileStrings.placeholderMap,
          completed: completed,
        );
      case VerificationDoc.pitchingVideo:
        return _PreviewFrame(
          height: 150,
          icon: Icons.play_circle_outline,
          caption: ProfileStrings.placeholderVideo,
          completed: completed,
        );
    }
  }
}

/// A single rounded preview frame: a centered typed icon + caption, or a green
/// "captured" state once the step is completed.
class _PreviewFrame extends StatelessWidget {
  final double height;
  final IconData icon;
  final String caption;
  final bool completed;

  const _PreviewFrame({
    required this.height,
    required this.icon,
    required this.caption,
    required this.completed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = completed ? AppColors.success : AppColors.purple500;
    final fill =
        completed ? AppColors.success.withValues(alpha: 0.10) : AppColors.blue100;
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: accent.withValues(alpha: 0.40), width: 1.4),
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            completed ? Icons.check_circle_outline : icon,
            size: AppSizes.iconLg + 6,
            color: accent,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            completed ? ProfileStrings.placeholderCaptured : caption,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: completed ? AppColors.success : AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Full-width, clearly-labeled action button for a verification step
/// (onboarding "pick" styling). The capture itself is mock.
class _VerificationActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _VerificationActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadius.md);
    return Semantics(
      label: label,
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
          child: Container(
            height: 56,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: AppSizes.iconMd, color: AppColors.purple700),
                const SizedBox(width: AppSpacing.sm),
                Flexible(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(color: AppColors.purple700),
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

// ============================================================================
// LOGOUT
// ============================================================================

/// Outlined, error-colored logout action shared by both profile screens. Asks
/// for confirmation first, then runs [onConfirm] (which resets navigation back
/// to onboarding). Phase 1 has no session to clear — this is navigation only.
class ProfileLogoutButton extends StatelessWidget {
  final VoidCallback onConfirm;
  const ProfileLogoutButton({super.key, required this.onConfirm});

  Future<void> _confirm(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(ProfileStrings.logoutConfirmTitle),
        content: const Text(ProfileStrings.logoutConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(ProfileStrings.logoutCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(ProfileStrings.logoutConfirmCta),
          ),
        ],
      ),
    );
    if (shouldLogout == true) onConfirm();
  }

  @override
  Widget build(BuildContext context) {
    return LargeButton(
      label: ProfileStrings.logoutButton,
      icon: Icons.logout,
      filled: false,
      outlineColor: AppColors.error,
      onTap: () => _confirm(context),
    );
  }
}
