import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../constants/onboarding_strings.dart';
import '../../constants/profile_strings.dart';
import '../../data/demo_data.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../../features/onboarding/onboarding_models.dart';
import '../../../features/profile/models/profile_models.dart';
import '../app_section_card.dart';
import '../large_button.dart';
import '../onboarding/read_aloud_button.dart';
import '../onboarding/speech_to_text_button.dart';

/// Thin, profile-flavored alias over the design system's [AppSectionCard] —
/// kept so every existing profile call site (icon/title/child/trailing) stays
/// unchanged while actually rendering the shared component. New screens
/// should reach for [AppSectionCard] directly instead of this alias.
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
    return AppSectionCard(
      title: title,
      icon: icon,
      trailing: trailing,
      child: child,
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

  const VerificationSection({
    super.key,
    required this.requiredDocs,
    required this.docStatuses,
    required this.onAction,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = verificationStateFor(docStatuses, requiredDocs);
    final done = completedDocCount(docStatuses, requiredDocs);
    final total = requiredDocs.length;
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
              const SizedBox(width: AppSpacing.xs),
              ReadAloudButton(
                textToRead: "${doc.label}။ ${_docDescription(doc)}",
                compact: true,
              ),
              const SizedBox(width: AppSpacing.xs),
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

// ============================================================================
// AGE / GENDER — inline editable row, backend-connected. Pure UI: the actual
// PUT call and provider update happen inside [onSave]'s caller.
// ============================================================================

class AgeGenderEditor extends StatefulWidget {
  final int age;
  final Gender gender;
  final Future<bool> Function(int age, Gender gender) onSave;

  /// When false, gender is shown read-only (no picker, no edit affordance)
  /// and only age can be changed — used by the Tasker profile, where gender
  /// is fixed at signup.
  final bool allowGenderEdit;

  const AgeGenderEditor({
    super.key,
    required this.age,
    required this.gender,
    required this.onSave,
    this.allowGenderEdit = true,
  });

  @override
  State<AgeGenderEditor> createState() => _AgeGenderEditorState();
}

class _AgeGenderEditorState extends State<AgeGenderEditor> {
  bool _editing = false;
  bool _saving = false;
  late final TextEditingController _ageController =
      TextEditingController(text: widget.age.toString());
  late Gender _gender = widget.gender;

  @override
  void didUpdateWidget(AgeGenderEditor old) {
    super.didUpdateWidget(old);
    if (!_editing) {
      _ageController.text = widget.age.toString();
      _gender = widget.gender;
    }
  }

  @override
  void dispose() {
    _ageController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final age = int.tryParse(_ageController.text.trim());
    if (age == null || age < 16 || age > 100) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text(OnboardingStrings.ageRangeError)));
      return;
    }
    setState(() => _saving = true);
    final ok = await widget.onSave(age, _gender);
    if (!mounted) return;
    setState(() {
      _saving = false;
      if (ok) _editing = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok ? ProfileStrings.saveSuccessMessage : ProfileStrings.saveFailedMessage),
    ));
  }

  void _cancel() {
    setState(() {
      _editing = false;
      _ageController.text = widget.age.toString();
      _gender = widget.gender;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (!_editing) {
      if (!widget.allowGenderEdit) {
        // Gender is fixed (Tasker) — only the age row gets an inline edit
        // icon, beside its value, instead of a separate button below.
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: ProfileInfoRow(
                    icon: Icons.cake_outlined,
                    label: OnboardingStrings.ageLabel,
                    value: "${toBurmeseDigits(widget.age)} နှစ်",
                  ),
                ),
                Semantics(
                  label: ProfileStrings.editProfile,
                  button: true,
                  child: IconButton(
                    onPressed: () => setState(() => _editing = true),
                    icon: const Icon(Icons.edit_outlined),
                    style: IconButton.styleFrom(
                      minimumSize: const Size(44, 44),
                      foregroundColor: AppColors.purple700,
                    ),
                  ),
                ),
              ],
            ),
            ProfileInfoRow(
              icon: Icons.wc_outlined,
              label: OnboardingStrings.genderLabel,
              value: widget.gender.label,
            ),
          ],
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ProfileInfoRow(
            icon: Icons.cake_outlined,
            label: OnboardingStrings.ageLabel,
            value: "${toBurmeseDigits(widget.age)} နှစ်",
          ),
          ProfileInfoRow(
            icon: Icons.wc_outlined,
            label: OnboardingStrings.genderLabel,
            value: widget.gender.label,
          ),
          const SizedBox(height: AppSpacing.xs),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => setState(() => _editing = true),
              icon: const Icon(Icons.edit_outlined, size: AppSizes.iconSm),
              label: const Text(ProfileStrings.editProfile),
              style: TextButton.styleFrom(
                minimumSize: const Size(0, 44),
                foregroundColor: AppColors.purple700,
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(OnboardingStrings.ageLabel, style: theme.textTheme.bodyMedium),
        const SizedBox(height: AppSpacing.xs),
        TextField(
          controller: _ageController,
          keyboardType: TextInputType.number,
          enabled: !_saving,
          style: theme.textTheme.bodyLarge,
          decoration: InputDecoration(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
          ),
        ),
        if (widget.allowGenderEdit) ...[
          const SizedBox(height: AppSpacing.md),
          Text(OnboardingStrings.genderLabel, style: theme.textTheme.bodyMedium),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: Gender.values.map((g) {
              final selected = _gender == g;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
                  child: ChoiceChip(
                    label: Text("${g.emoji} ${g.label}"),
                    selected: selected,
                    onSelected: _saving ? null : (_) => setState(() => _gender = g),
                    selectedColor: AppColors.purple100,
                    labelStyle: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: selected ? AppColors.purple700 : AppColors.textPrimary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _saving ? null : _cancel,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 48),
                  side: const BorderSide(color: AppColors.onboardingDivider),
                ),
                child: const Text(ProfileStrings.cancelButton),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: FilledButton(
                onPressed: _saving ? null : _save,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 48),
                  backgroundColor: AppColors.purple700,
                ),
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.onBrand),
                      )
                    : const Text(ProfileStrings.saveButton),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ============================================================================
// PHONE NUMBER — Edit -> new number -> send OTP -> enter OTP -> verify+save.
// Pure UI/orchestration: [onSendOtp]/[onVerifyAndSave] own the actual network
// calls; this widget only walks the 3-step flow and reports outcomes.
// ============================================================================

enum _PhoneEditStep { idle, enteringPhone, enteringOtp }

class PhoneNumberEditor extends StatefulWidget {
  final String currentPhone;

  /// Returns an error message to show, or null on success.
  final Future<String?> Function(String newPhone) onSendOtp;

  /// Returns true on success (caller already persisted the new number).
  final Future<bool> Function(String newPhone, String otp) onVerifyAndSave;

  const PhoneNumberEditor({
    super.key,
    required this.currentPhone,
    required this.onSendOtp,
    required this.onVerifyAndSave,
  });

  @override
  State<PhoneNumberEditor> createState() => _PhoneNumberEditorState();
}

class _PhoneNumberEditorState extends State<PhoneNumberEditor> {
  _PhoneEditStep _step = _PhoneEditStep.idle;
  bool _busy = false;
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _reset() {
    setState(() {
      _step = _PhoneEditStep.idle;
      _busy = false;
      _phoneController.clear();
      _otpController.clear();
    });
  }

  Future<void> _sendOtp() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) return;
    setState(() => _busy = true);
    final error = await widget.onSendOtp(phone);
    if (!mounted) return;
    setState(() => _busy = false);
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    setState(() => _step = _PhoneEditStep.enteringOtp);
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text(ProfileStrings.otpSentMessage)));
  }

  Future<void> _verifyAndSave() async {
    final phone = _phoneController.text.trim();
    final otp = _otpController.text.trim();
    if (otp.isEmpty) return;
    setState(() => _busy = true);
    final ok = await widget.onVerifyAndSave(phone, otp);
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text(ProfileStrings.phoneChangeSuccessMessage)));
      _reset();
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text(ProfileStrings.saveFailedMessage)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_step == _PhoneEditStep.idle) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ProfileInfoRow(
            icon: Icons.phone_outlined,
            label: OnboardingStrings.phoneLabel,
            value: widget.currentPhone,
          ),
          const SizedBox(height: AppSpacing.xs),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => setState(() => _step = _PhoneEditStep.enteringPhone),
              icon: const Icon(Icons.edit_outlined, size: AppSizes.iconSm),
              label: const Text(ProfileStrings.changePhoneCta),
              style: TextButton.styleFrom(
                minimumSize: const Size(0, 44),
                foregroundColor: AppColors.purple700,
              ),
            ),
          ),
        ],
      );
    }

    if (_step == _PhoneEditStep.enteringPhone) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(ProfileStrings.newPhoneLabel, style: theme.textTheme.bodyMedium),
          const SizedBox(height: AppSpacing.xs),
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            enabled: !_busy,
            style: theme.textTheme.bodyLarge,
            decoration: InputDecoration(
              hintText: ProfileStrings.newPhonePlaceholder,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _busy ? null : _reset,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 48),
                    side: const BorderSide(color: AppColors.onboardingDivider),
                  ),
                  child: const Text(ProfileStrings.cancelButton),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: FilledButton(
                  onPressed: _busy ? null : _sendOtp,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 48),
                    backgroundColor: AppColors.purple700,
                  ),
                  child: _busy
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child:
                              CircularProgressIndicator(strokeWidth: 2, color: AppColors.onBrand),
                        )
                      : const Text(ProfileStrings.sendOtpCta),
                ),
              ),
            ],
          ),
        ],
      );
    }

    // enteringOtp
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(ProfileStrings.otpLabel, style: theme.textTheme.bodyMedium),
        const SizedBox(height: AppSpacing.xs),
        TextField(
          controller: _otpController,
          keyboardType: TextInputType.number,
          enabled: !_busy,
          style: theme.textTheme.bodyLarge,
          decoration: InputDecoration(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _busy ? null : _reset,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 48),
                  side: const BorderSide(color: AppColors.onboardingDivider),
                ),
                child: const Text(ProfileStrings.cancelButton),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: FilledButton(
                onPressed: _busy ? null : _verifyAndSave,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 48),
                  backgroundColor: AppColors.purple700,
                ),
                child: _busy
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.onBrand),
                      )
                    : const Text(ProfileStrings.verifyAndSaveCta),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ============================================================================
// SKILLS — list + add/edit/delete, backend-connected via callbacks. Pure UI:
// the CRUD network calls and provider updates live in the callbacks' caller.
// ============================================================================

class SkillsManager extends StatelessWidget {
  final List<TaskerSkillEntry> skills;
  final bool loading;
  final Future<bool> Function(String name, int years) onAdd;
  final Future<bool> Function(int id, String name, int years) onEdit;
  final Future<bool> Function(int id) onDelete;

  const SkillsManager({
    super.key,
    required this.skills,
    required this.loading,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });

  Future<void> _openAddDialog(BuildContext context) async {
    final result = await showDialog<_SkillDialogResult>(
      context: context,
      builder: (ctx) => const _SkillDialog(),
    );
    if (result == null || !context.mounted) return;
    final ok = await onAdd(result.name, result.years);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok ? ProfileStrings.saveSuccessMessage : ProfileStrings.saveFailedMessage),
    ));
  }

  Future<void> _openEditDialog(BuildContext context, TaskerSkillEntry skill) async {
    final result = await showDialog<_SkillDialogResult>(
      context: context,
      builder: (ctx) => _SkillDialog(initialName: skill.skillName, initialYears: skill.experienceYears),
    );
    if (result == null || !context.mounted) return;
    final ok = await onEdit(skill.id, result.name, result.years);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok ? ProfileStrings.saveSuccessMessage : ProfileStrings.saveFailedMessage),
    ));
  }

  Future<void> _confirmDelete(BuildContext context, TaskerSkillEntry skill) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(ProfileStrings.deleteSkillConfirmTitle),
        content: const Text(ProfileStrings.deleteSkillConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(ProfileStrings.logoutCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(ProfileStrings.deleteConfirmCta),
          ),
        ],
      ),
    );
    if (shouldDelete != true || !context.mounted) return;
    await onDelete(skill.id);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          )
        else if (skills.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Text(
              ProfileStrings.noSkillsMessage,
              style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
          )
        else
          for (final skill in skills)
            Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.purple100,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(skill.skillName,
                            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
                        Text(
                          "${toBurmeseDigits(skill.experienceYears)} ${ProfileStrings.skillYearsLabel}",
                          style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => _openEditDialog(context, skill),
                    icon: const Icon(Icons.edit_outlined, color: AppColors.purple700),
                    tooltip: ProfileStrings.editSkillCta,
                  ),
                  IconButton(
                    onPressed: () => _confirmDelete(context, skill),
                    icon: const Icon(Icons.delete_outline, color: AppColors.error),
                    tooltip: ProfileStrings.deleteSkillCta,
                  ),
                ],
              ),
            ),
        const SizedBox(height: AppSpacing.xs),
        OutlinedButton.icon(
          onPressed: () => _openAddDialog(context),
          icon: const Icon(Icons.add),
          label: const Text(ProfileStrings.addSkillCta),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
            foregroundColor: AppColors.purple700,
            side: const BorderSide(color: AppColors.purple700),
          ),
        ),
      ],
    );
  }
}

class _SkillDialogResult {
  final String name;
  final int years;
  const _SkillDialogResult(this.name, this.years);
}

class _SkillDialog extends StatefulWidget {
  final String? initialName;
  final int? initialYears;
  const _SkillDialog({this.initialName, this.initialYears});

  @override
  State<_SkillDialog> createState() => _SkillDialogState();
}

class _SkillDialogState extends State<_SkillDialog> {
  late final TextEditingController _nameController =
      TextEditingController(text: widget.initialName ?? "");
  late final TextEditingController _yearsController =
      TextEditingController(text: widget.initialYears?.toString() ?? "");

  @override
  void dispose() {
    _nameController.dispose();
    _yearsController.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameController.text.trim();
    final years = int.tryParse(_yearsController.text.trim()) ?? 0;
    if (name.isEmpty) return;
    Navigator.of(context).pop(_SkillDialogResult(name, years));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initialName == null ? ProfileStrings.addSkillCta : ProfileStrings.editSkillCta),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: TextField(
                  controller: _nameController,
                  decoration: InputDecoration(labelText: ProfileStrings.skillNameLabel),
                  autofocus: true,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              SpeechToTextButton(
                semanticPrompt: ProfileStrings.skillNameLabel,
                mockTranscript: "ပန်းခြံပြုပြင်ခြင်း",
                compact: true,
                onResult: (v) => setState(() => _nameController.text = v),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _yearsController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: ProfileStrings.skillYearsLabel),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(ProfileStrings.cancelButton),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.purple700),
          onPressed: _submit,
          child: const Text(ProfileStrings.saveButton),
        ),
      ],
    );
  }
}

// ============================================================================
// PROMOTION VIDEO — demo-only (no upload/recording/backend). Tapping Add
// flips straight to an "Added" confirmation.
// ============================================================================

class PromotionVideoCard extends StatelessWidget {
  final bool added;
  final VoidCallback onAdd;

  const PromotionVideoCard({super.key, required this.added, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          ProfileStrings.promoVideoDescription,
          style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.md),
        AnimatedSwitcher(
          duration: AppMotion.medium,
          child: added
              ? Container(
                  key: const ValueKey("added"),
                  height: 56,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle, color: AppColors.success, size: AppSizes.iconMd),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        ProfileStrings.promoVideoAddedLabel,
                        style: theme.textTheme.titleMedium
                            ?.copyWith(color: AppColors.success, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                )
              : Semantics(
                  key: const ValueKey("add"),
                  label: ProfileStrings.promoVideoAddCta,
                  button: true,
                  child: Material(
                    color: AppColors.blue100,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      onTap: () {
                        HapticFeedback.lightImpact();
                        onAdd();
                      },
                      child: Container(
                        height: 56,
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.videocam_outlined, color: AppColors.purple700, size: AppSizes.iconMd),
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              ProfileStrings.promoVideoAddCta,
                              style: theme.textTheme.titleMedium?.copyWith(color: AppColors.purple700),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}
