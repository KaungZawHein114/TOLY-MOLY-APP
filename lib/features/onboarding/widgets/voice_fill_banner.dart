import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/agent/agent_session.dart';
import '../../../core/constants/onboarding_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/ai_service.dart';
import '../onboarding_models.dart';
import '../onboarding_state.dart';
import 'voice_onboarding_sheet.dart';

/// Indigo (AI-accent) CTA that opens the onboarding voice-fill sheet — the
/// accessibility headline: speak once instead of typing every field.
///
/// Onboarding voice mode (spec §4.1/§4.6): Pho Wa Yoke listens, extracts the
/// fields, and (on the user's confirm) pre-fills the role's draft. The user
/// still sees and edits the real form and walks the normal steps — nothing is
/// submitted. [onApplied] lets the host screen refresh its text controllers
/// from the updated draft.
class VoiceFillBanner extends ConsumerWidget {
  final UserRole role;
  final VoidCallback onApplied;

  const VoiceFillBanner({super.key, required this.role, required this.onApplied});

  Future<void> _openVoiceFill(BuildContext context, WidgetRef ref) async {
    ref.read(agentModeProvider.notifier).state = AgentMode.onboarding;
    ref.read(agentSessionProvider.notifier).state = AgentSession.active;

    final result = await showVoiceOnboarding(context, role: role);
    if (!context.mounted || result == null) return;
    _applyExtraction(context, ref, result);
  }

  void _applyExtraction(
      BuildContext context, WidgetRef ref, OnboardingExtraction e) {
    if (role == UserRole.tasker) {
      final n = ref.read(taskerDraftProvider.notifier);
      n.state = n.state.copyWith(
        name: e.name.isNotEmpty ? e.name : null,
        phone: e.phone.isNotEmpty ? e.phone : null,
        gender: e.gender,
        age: e.age,
        skills: e.skills.isNotEmpty ? e.skills.toSet() : null,
      );
    } else {
      final n = ref.read(clientDraftProvider.notifier);
      n.state = n.state.copyWith(
        name: e.name.isNotEmpty ? e.name : null,
        phone: e.phone.isNotEmpty ? e.phone : null,
        gender: e.gender,
        age: e.age,
      );
    }

    onApplied();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text(OnboardingStrings.voiceAppliedMessage)),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final radius = BorderRadius.circular(AppRadius.lg);
    return Material(
      color: Colors.transparent,
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius,
        onTap: () => _openVoiceFill(context, ref),
        child: Ink(
          decoration: BoxDecoration(
            gradient: AppColors.indigoGradient,
            borderRadius: radius,
            boxShadow: [
              BoxShadow(
                color: AppColors.indigo700.withValues(alpha: 0.3),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Container(
                  width: AppSizes.avatarSm,
                  height: AppSizes.avatarSm,
                  decoration: const BoxDecoration(
                    color: AppColors.onBrand,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.mic_rounded,
                      color: AppColors.indigo700, size: AppSizes.iconMd),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(OnboardingStrings.voiceFillCta,
                          style: theme.textTheme.titleSmall
                              ?.copyWith(color: AppColors.onBrand)),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(OnboardingStrings.voiceFillCtaSubtitle,
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: AppColors.onBrandMuted)),
                    ],
                  ),
                ),
                const Icon(Icons.auto_awesome, color: AppColors.onBrand),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
