import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/onboarding_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/ai_service.dart' show OnboardingExtraction, AiSource;
import '../../../core/widgets/mascot/mascot_message_card.dart';
import '../../../core/widgets/mascot/mascot_state.dart';
import '../../../core/widgets/mascot/pho_wa_yoke.dart';
import '../onboarding_models.dart';

/// COMPETITION DEMO ONLY — rebuilt 2026-07-29.
///
/// The old sheet drove a REAL on-device speech recognizer (`VoiceInputButton`,
/// package:speech_to_text) and a live/mock AI extraction call. Both are gone:
/// this is now a fully scripted, offline state machine —
/// `idle → listening → processing → verified` — timed with plain [Timer]s.
/// No microphone is ever opened, no permission is ever requested, and no AI
/// call of any kind is made. On reaching `verified` it auto-pops with a fixed
/// canned [OnboardingExtraction] (tagged [AiSource.demo]) that the caller
/// pre-fills into the real, editable form — nothing is ever submitted here.
///
/// Applies identically to the Client and Tasker sign-up flows: both reach
/// this sheet through the same [VoiceFillBanner] on their "About You" step.
class VoiceOnboardingSheet extends ConsumerStatefulWidget {
  final UserRole role;
  const VoiceOnboardingSheet({super.key, required this.role});

  @override
  ConsumerState<VoiceOnboardingSheet> createState() =>
      _VoiceOnboardingSheetState();
}

enum _AuthPhase { idle, listening, processing, verified }

// Demo pacing — "around 2-3 seconds" per the spec; long enough to read as
// real analysis, short enough not to stall the demo.
const _kListeningDuration = Duration(milliseconds: 2400);
const _kProcessingDuration = Duration(milliseconds: 2400);
const _kVerifiedHoldDuration = Duration(milliseconds: 1100);

class _VoiceOnboardingSheetState extends ConsumerState<VoiceOnboardingSheet>
    with SingleTickerProviderStateMixin {
  _AuthPhase _phase = _AuthPhase.idle;
  final List<Timer> _timers = [];
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat();

  bool get _isTasker => widget.role == UserRole.tasker;

  @override
  void dispose() {
    for (final t in _timers) {
      t.cancel();
    }
    _pulse.dispose();
    super.dispose();
  }

  void _after(Duration delay, VoidCallback action) {
    late Timer timer;
    timer = Timer(delay, () {
      _timers.remove(timer);
      if (mounted) action();
    });
    _timers.add(timer);
  }

  /// Click Mic → Listening → Processing → Verified → auto-continue. Nothing
  /// here can be interrupted or fail — that's the point of a demo flow.
  void _start() {
    if (_phase != _AuthPhase.idle) return;
    HapticFeedback.mediumImpact();
    setState(() => _phase = _AuthPhase.listening);
    _after(_kListeningDuration, () {
      HapticFeedback.selectionClick();
      setState(() => _phase = _AuthPhase.processing);
      _after(_kProcessingDuration, () {
        HapticFeedback.mediumImpact();
        setState(() => _phase = _AuthPhase.verified);
        _after(_kVerifiedHoldDuration, () {
          if (mounted) Navigator.of(context).pop(_cannedExtraction());
        });
      });
    });
  }

  /// A fixed, believable demo profile — deliberately not derived from any
  /// real input. Same name/age/phone the app's onboarding script already
  /// shows as a spoken-example sentence elsewhere; taskers additionally get
  /// two sample skills so their profile reads as complete.
  OnboardingExtraction _cannedExtraction() {
    return OnboardingExtraction(
      name: "အောင်အောင်",
      gender: Gender.male,
      age: 25,
      phone: "09789123456",
      skills: _isTasker
          ? const [TaskerSkill.cleaning, TaskerSkill.plumbing]
          : const [],
      source: AiSource.demo,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.onboardingDivider,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
            ),
            switch (_phase) {
              _AuthPhase.idle => _IdleView(onTap: _start, pulse: _pulse),
              _AuthPhase.listening => _ListeningView(pulse: _pulse),
              _AuthPhase.processing => const _ProcessingView(),
              _AuthPhase.verified => const _VerifiedView(),
            },
            if (_phase == _AuthPhase.idle) ...[
              const SizedBox(height: AppSpacing.lg),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(OnboardingStrings.voiceManualButton),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _IdleView extends StatelessWidget {
  final VoidCallback onTap;
  final AnimationController pulse;
  const _IdleView({required this.onTap, required this.pulse});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const MascotMessageCard(
          state: PhoWaYokeState.happy,
          message: OnboardingStrings.voiceAuthTitle,
        ),
        const SizedBox(height: AppSpacing.xl),
        Center(
          child: _MicButton(active: false, pulse: pulse, onTap: onTap),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          OnboardingStrings.voiceAuthIdleHint,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyLarge,
        ),
      ],
    );
  }
}

class _ListeningView extends StatelessWidget {
  final AnimationController pulse;
  const _ListeningView({required this.pulse});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: Column(
        children: [
          _MicButton(active: true, pulse: pulse, onTap: null),
          const SizedBox(height: AppSpacing.lg),
          Semantics(
            liveRegion: true,
            child: Text("🎤 ${OnboardingStrings.voiceAuthListening}",
                style: theme.textTheme.titleMedium
                    ?.copyWith(color: AppColors.purple700)),
          ),
        ],
      ),
    );
  }
}

class _ProcessingView extends StatelessWidget {
  const _ProcessingView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
      child: Column(
        children: [
          const PhoWaYoke(state: PhoWaYokeState.thinking, size: 96),
          const SizedBox(height: AppSpacing.lg),
          const SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
          const SizedBox(height: AppSpacing.md),
          Semantics(
            liveRegion: true,
            child: Text("⚙️ ${OnboardingStrings.voiceAuthProcessing}",
                style: theme.textTheme.titleMedium),
          ),
        ],
      ),
    );
  }
}

class _VerifiedView extends StatelessWidget {
  const _VerifiedView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: Column(
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 450),
            curve: Curves.elasticOut,
            builder: (context, value, child) =>
                Transform.scale(scale: value, child: child),
            child: const PhoWaYoke(state: PhoWaYokeState.success, size: 96),
          ),
          const SizedBox(height: AppSpacing.lg),
          Semantics(
            liveRegion: true,
            child: Text("✓ ${OnboardingStrings.voiceAuthVerifiedTitle}",
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium
                    ?.copyWith(color: AppColors.success, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(OnboardingStrings.voiceAuthVerifiedMessage,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

/// Purely decorative mic control — tap only matters in the idle phase
/// ([onTap] is null everywhere else). The pulsing ring runs continuously in
/// [pulse]; only [active] decides whether it's visible, so the same
/// controller drives both the idle glow and the listening animation.
class _MicButton extends StatelessWidget {
  final bool active;
  final VoidCallback? onTap;
  final AnimationController pulse;
  const _MicButton({required this.active, required this.onTap, required this.pulse});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: OnboardingStrings.voiceAuthTitle,
      button: onTap != null,
      child: SizedBox(
        width: 120,
        height: 120,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (active)
              AnimatedBuilder(
                animation: pulse,
                builder: (context, _) => Container(
                  width: 96 + 24 * pulse.value,
                  height: 96 + 24 * pulse.value,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.error
                        .withValues(alpha: 0.25 * (1 - pulse.value)),
                  ),
                ),
              ),
            Material(
              color: Colors.transparent,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onTap,
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    gradient: active ? null : AppColors.purpleGradient,
                    color: active ? AppColors.error : null,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    active ? Icons.graphic_eq : Icons.mic_rounded,
                    color: AppColors.onBrand,
                    size: 44,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Opens the onboarding voice sheet for [role]. Returns the canned
/// [OnboardingExtraction] once the demo verification completes, or null if
/// the user chose manual entry / dismissed the sheet before tapping the mic.
Future<OnboardingExtraction?> showVoiceOnboarding(
  BuildContext context, {
  required UserRole role,
}) {
  return showModalBottomSheet<OnboardingExtraction>(
    context: context,
    isScrollControlled: true,
    isDismissible: false,
    enableDrag: false,
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
