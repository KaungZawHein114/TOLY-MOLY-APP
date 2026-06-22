import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/onboarding_strings.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/large_button.dart';
import '../../../core/widgets/mascot/mascot_state.dart';
import '../../../core/widgets/onboarding/onboarding_scaffold.dart';
import '../../../core/widgets/onboarding/staggered_entrance.dart';
import '../onboarding_models.dart';

class TaskerWelcomeScreen extends StatelessWidget {
  const TaskerWelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return OnboardingScaffold(
      progress: const OnboardingProgress(step: 6, totalSteps: 6),
      mascotState: PhoWaYokeState.success,
      mascotMessage: OnboardingStrings.completionUnverifiedMessage,
      title: OnboardingStrings.completionTitle,
      layout: OnboardingLayoutMode.moment,
      body: StaggeredEntrance(
        children: [
          const SizedBox(height: AppSpacing.md),
          Text(
            OnboardingStrings.completionContinuePrompt,
            style: theme.textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          Text(
            OnboardingStrings.completionOrPrompt,
            style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          Text(
            OnboardingStrings.completionUseNowPrompt,
            style: theme.textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),
          _ChecklistRow(label: OnboardingStrings.clientCompletionNrc, icon: "🪪"),
          _ChecklistRow(label: OnboardingStrings.clientCompletionAddress, icon: "📍"),
          _ChecklistRow(label: OnboardingStrings.clientCompletionFace, icon: "🙂"),
          _ChecklistRow(label: OnboardingStrings.taskerCompletionVideo, icon: "🎬"),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
      bottomBar: Column(
        children: [
          LargeButton(
            label: OnboardingStrings.completionContinueButton,
            filled: false,
            outlineColor: AppColors.purple700,
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("ဤ Demo တွင် Profile ဆက်ဖြည့်ခြင်းကို ပံ့ပိုးမထားပါသေးပါ"),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          LargeButton(
            label: OnboardingStrings.completionUseNowButton,
            icon: Icons.check_circle_outline,
            gradient: AppColors.purpleGradient,
            celebratory: true,
            onTap: () => context.go(Routes.dashboard),
          ),
        ],
      ),
    );
  }
}

class _ChecklistRow extends StatelessWidget {
  final String label;
  final String icon;
  const _ChecklistRow({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: "$label - အတည်ပြုထားခြင်း မရှိသေးပါ",
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.all(AppSpacing.md),
        constraints: const BoxConstraints(minHeight: 56),
        decoration: BoxDecoration(
          color: AppColors.blue100,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: Text(label, style: Theme.of(context).textTheme.bodyMedium)),
            const Icon(Icons.radio_button_unchecked, color: AppColors.warning),
          ],
        ),
      ),
    );
  }
}
