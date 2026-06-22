import 'package:flutter/material.dart';

import '../../../features/onboarding/onboarding_models.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../mascot/mascot_message_card.dart';
import '../mascot/mascot_state.dart';
import 'onboarding_progress_header.dart';
import 'read_aloud_button.dart';

/// Shared visual shell for every onboarding step: a branded gradient header
/// with a rounded white panel overlapping it (per the wireframe reference),
/// progress header, Pho Wa Yoke guidance, scrollable body, and a pinned
/// bottom action area. Screens only supply content — never their own chrome.
class OnboardingScaffold extends StatelessWidget {
  final OnboardingProgress? progress;
  final PhoWaYokeState mascotState;
  final String mascotMessage;
  final String? title;
  final String? subtitle;
  final Widget body;
  final Widget bottomBar;
  final VoidCallback? onBack;
  final String? readAloudText;

  const OnboardingScaffold({
    super.key,
    required this.mascotState,
    required this.mascotMessage,
    required this.body,
    required this.bottomBar,
    this.title,
    this.progress,
    this.subtitle,
    this.onBack,
    this.readAloudText,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: AppColors.purple900,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xxxl),
              child: Row(
                children: [
                  if (onBack != null)
                    Semantics(
                      label: "နောက်သို့",
                      button: true,
                      child: IconButton(
                        onPressed: onBack,
                        icon: const Icon(Icons.arrow_back, color: AppColors.onBrand),
                        style: IconButton.styleFrom(
                          minimumSize: const Size(48, 48),
                          backgroundColor: AppColors.onBrandMuted.withValues(alpha: 0.15),
                        ),
                      ),
                    )
                  else
                    const SizedBox(width: 48),
                  const Spacer(),
                  Flexible(
                    child: Text(
                      "TOLY MOLY",
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                          color: AppColors.onBrand, letterSpacing: 1),
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: AppColors.lightSurface,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
                ),
                child: Column(
                  children: [
                    // Everything above the action bar scrolls as one unit, so
                    // no combination of mascot/progress/title/body content can
                    // ever overflow a short screen — only the pinned bottomBar
                    // below is guaranteed on-screen without scrolling.
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(
                            AppSpacing.xl, AppSpacing.xl, AppSpacing.xl, AppSpacing.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (progress != null) ...[
                              OnboardingProgressHeader(progress: progress!),
                              const SizedBox(height: AppSpacing.lg),
                            ],
                            MascotMessageCard(
                              state: mascotState,
                              message: mascotMessage,
                              mascotSize: 64,
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            if (title != null || readAloudText != null) ...[
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (title != null)
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(title!, style: theme.textTheme.headlineSmall),
                                          if (subtitle != null) ...[
                                            const SizedBox(height: AppSpacing.xs),
                                            Text(
                                              subtitle!,
                                              style: theme.textTheme.bodyMedium
                                                  ?.copyWith(color: AppColors.textSecondary),
                                            ),
                                          ],
                                        ],
                                      ),
                                    )
                                  else
                                    const Spacer(),
                                  if (readAloudText != null)
                                    ReadAloudButton(textToRead: readAloudText!),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.lg),
                            ],
                            body,
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                          AppSpacing.xl, AppSpacing.md, AppSpacing.xl, AppSpacing.lg),
                      child: bottomBar,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
