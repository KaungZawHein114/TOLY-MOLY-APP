import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/onboarding_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/ai_service.dart';
import '../../../core/widgets/large_button.dart';
import '../../../core/widgets/mascot/mascot_message_card.dart';
import '../../../core/widgets/mascot/mascot_state.dart';
import '../../../core/widgets/mascot/pho_wa_yoke.dart';
import '../../../core/widgets/onboarding/read_aloud_button.dart';
import '../../voice_task_posting/widgets/voice_input_button.dart';
import '../onboarding_models.dart';

/// Onboarding voice mode surface (spec §4.1/§4.6). Pho Wa Yoke greets, shows a
/// sample script, listens (Burmese STT), extracts the signup fields, and shows
/// them PRE-FILLED for confirmation — with a read-back and a redo. It NEVER
/// submits: on confirm it just returns the [OnboardingExtraction] to the caller,
/// which pre-fills the real, editable form. Manual entry stays one tap away.
///
/// Opens via [showVoiceOnboarding]; pops with the confirmed extraction or null.
class VoiceOnboardingSheet extends ConsumerStatefulWidget {
  final UserRole role;
  const VoiceOnboardingSheet({super.key, required this.role});

  @override
  ConsumerState<VoiceOnboardingSheet> createState() =>
      _VoiceOnboardingSheetState();
}

class _VoiceOnboardingSheetState extends ConsumerState<VoiceOnboardingSheet> {
  String _transcript = '';
  bool _loading = false;
  OnboardingExtraction? _extraction;

  bool get _isTasker => widget.role == UserRole.tasker;

  Future<void> _extract(String text) async {
    final t = text.trim();
    if (t.isEmpty) return;
    setState(() {
      _transcript = t;
      _loading = true;
    });
    final result =
        await AiService.extractOnboarding(transcript: t, role: widget.role);
    if (!mounted) return;
    setState(() {
      _extraction = result;
      _loading = false;
    });
  }

  void _retry() => setState(() {
        _extraction = null;
        _transcript = '';
      });

  String _readBackSummary(OnboardingExtraction e) {
    final parts = <String>[
      if (e.name.isNotEmpty) '${OnboardingStrings.voiceFieldName} ${e.name}',
      if (e.gender != null)
        '${OnboardingStrings.voiceFieldGender} ${e.gender!.label}',
      if (e.age != null)
        '${OnboardingStrings.voiceFieldAge} ${toBurmeseDigits(e.age!)}',
      if (e.phone.isNotEmpty)
        '${OnboardingStrings.voiceFieldPhone} ${e.phone}',
      if (_isTasker && e.skills.isNotEmpty)
        '${OnboardingStrings.voiceFieldSkills} ${e.skills.map((s) => s.label).join('၊ ')}',
    ];
    if (parts.isEmpty) return OnboardingStrings.voiceNothingHeard;
    return '${OnboardingStrings.voiceReviewPrompt} ${parts.join('။ ')}';
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          top: AppSpacing.md,
          bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.onboardingDivider,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                child: _loading
                    ? _extractingView()
                    : (_extraction == null
                        ? _introView()
                        : _reviewView(_extraction!)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _introView() {
    final theme = Theme.of(context);
    final script = _isTasker
        ? OnboardingStrings.voiceScriptTasker
        : OnboardingStrings.voiceScriptClient;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const MascotMessageCard(
          state: PhoWaYokeState.happy,
          message: OnboardingStrings.voiceOnboardingGreeting,
        ),
        const SizedBox(height: AppSpacing.lg),
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.blue100,
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(OnboardingStrings.voiceOnboardingScriptLabel,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: AppColors.textSecondary)),
                  ),
                  ReadAloudButton(textToRead: script, compact: true),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(script,
                  style: theme.textTheme.bodyLarge
                      ?.copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        if (_transcript.isNotEmpty) ...[
          Text('“$_transcript”',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: AppSpacing.md),
        ],
        Center(
          child: VoiceInputButton(
            localeCandidates: const ['my_MM', 'my-MM', 'my'],
            onPartialResult: (v) => setState(() => _transcript = v),
            onFinalResult: _extract,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(OnboardingStrings.voiceListeningHint,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: AppSpacing.md),
        Center(
          child: TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(OnboardingStrings.voiceManualButton),
          ),
        ),
      ],
    );
  }

  Widget _extractingView() {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
      child: Column(
        children: [
          const PhoWaYoke(state: PhoWaYokeState.thinking, size: 96),
          const SizedBox(height: AppSpacing.md),
          Semantics(
            liveRegion: true,
            child: Text(OnboardingStrings.voiceExtracting,
                style: theme.textTheme.titleMedium),
          ),
        ],
      ),
    );
  }

  Widget _reviewView(OnboardingExtraction e) {
    final theme = Theme.of(context);
    if (!e.hasAnything) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
        child: Column(
          children: [
            const PhoWaYoke(state: PhoWaYokeState.pointing, size: 88),
            const SizedBox(height: AppSpacing.md),
            Text(OnboardingStrings.voiceNothingHeard,
                textAlign: TextAlign.center, style: theme.textTheme.titleMedium),
            const SizedBox(height: AppSpacing.lg),
            LargeButton(
              label: OnboardingStrings.voiceRetryButton,
              icon: Icons.mic_rounded,
              gradient: AppColors.purpleGradient,
              onTap: _retry,
            ),
            const SizedBox(height: AppSpacing.sm),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(OnboardingStrings.voiceManualButton),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const PhoWaYoke(state: PhoWaYokeState.success, size: 56),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(OnboardingStrings.voiceReviewPrompt,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
            ),
            ReadAloudButton(textToRead: _readBackSummary(e), compact: true),
          ],
        ),
        if (e.source == AiSource.mock) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(OnboardingStrings.voiceOfflineNote,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: AppColors.textSecondary)),
        ],
        const SizedBox(height: AppSpacing.md),
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.blue100,
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: Column(
            children: [
              _row(OnboardingStrings.voiceFieldName, e.name),
              _row(OnboardingStrings.voiceFieldGender, e.gender?.label ?? ''),
              _row(OnboardingStrings.voiceFieldAge,
                  e.age == null ? '' : toBurmeseDigits(e.age!)),
              _row(OnboardingStrings.voiceFieldPhone, e.phone),
              if (_isTasker)
                _row(OnboardingStrings.voiceFieldSkills,
                    e.skills.map((s) => s.label).join('၊ '),
                    isLast: true),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        LargeButton(
          label: OnboardingStrings.voiceConfirmButton,
          icon: Icons.check_circle,
          gradient: AppColors.purpleGradient,
          onTap: () => Navigator.of(context).pop(e),
        ),
        const SizedBox(height: AppSpacing.sm),
        Center(
          child: TextButton.icon(
            onPressed: _retry,
            icon: const Icon(Icons.mic_rounded, size: AppSizes.iconSm),
            label: const Text(OnboardingStrings.voiceRetryButton),
          ),
        ),
      ],
    );
  }

  Widget _row(String label, String value, {bool isLast = false}) {
    final theme = Theme.of(context);
    final hasValue = value.trim().isNotEmpty;
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: Text(label,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: AppColors.textSecondary)),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              hasValue ? value : OnboardingStrings.voiceNotGiven,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: hasValue ? AppColors.textPrimary : AppColors.warning,
                fontStyle: hasValue ? FontStyle.normal : FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Opens the onboarding voice sheet for [role]. Returns the confirmed
/// [OnboardingExtraction], or null if the user chose manual entry / dismissed.
Future<OnboardingExtraction?> showVoiceOnboarding(
  BuildContext context, {
  required UserRole role,
}) {
  return showModalBottomSheet<OnboardingExtraction>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
    ),
    constraints: BoxConstraints(
      maxHeight: MediaQuery.of(context).size.height * 0.9,
    ),
    builder: (_) => VoiceOnboardingSheet(role: role),
  );
}
