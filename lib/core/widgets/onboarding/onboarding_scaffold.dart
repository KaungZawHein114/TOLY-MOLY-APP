import 'package:flutter/material.dart';

import '../../../features/auth/audio/auth_audio_button.dart';
import '../../../features/onboarding/onboarding_models.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../mascot/mascot_message_card.dart';
import '../mascot/mascot_state.dart';
import 'onboarding_progress_header.dart';
import 'read_aloud_button.dart';
import 'staggered_entrance.dart';

/// Distinguishes celebratory/greeting screens (Welcome, completion) from
/// ordinary form steps. `moment` gives the mascot more room and drops the
/// progress chrome; `form` keeps today's shape.
enum OnboardingLayoutMode { form, moment }

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

  /// AUTH-ONLY: when set, the header's read-aloud control plays this
  /// pre-recorded clip (a key from `AuthAudioKeys`) instead of speaking
  /// [readAloudText] via TTS. Takes precedence over [readAloudText]. Non-auth
  /// screens (e.g. task posting) leave this null and keep the TTS button.
  final String? readAloudAudioKey;
  final OnboardingLayoutMode layout;

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
    this.readAloudAudioKey,
    this.layout = OnboardingLayoutMode.form,
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
                  Expanded(
                    // Expanded (not Spacer+Flexible, which used to split the
                    // remaining width evenly into thirds and left almost no
                    // room for the title) so this center block gets all the
                    // space between the two fixed-width end items.
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // A light backdrop badge keeps the logo visible
                          // regardless of header background — the logo's own
                          // dark-navy tones are too close to AppColors.purple900
                          // to read on their own once its white background is
                          // removed.
                          Container(
                            width: 32,
                            height: 32,
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: AppColors.onBrand,
                              shape: BoxShape.circle,
                            ),
                            child: Image.asset("assets/logo_circle.png"),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Flexible(
                            child: Text(
                              "တိုလီမိုလီ",
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: AppColors.onBrand,
                                letterSpacing: 1,
                                fontFamily: "Myanmar Thuriya",
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
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
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          const verticalPadding = AppSpacing.xl + AppSpacing.md;
                          final content = StaggeredEntrance(
                            children: [
                              if (progress != null && layout == OnboardingLayoutMode.form) ...[
                                OnboardingProgressHeader(progress: progress!),
                                const SizedBox(height: AppSpacing.lg),
                              ],
                              MascotMessageCard(
                                state: mascotState,
                                message: mascotMessage,
                                mascotSize: layout == OnboardingLayoutMode.moment ? 160 : 64,
                                centered: layout == OnboardingLayoutMode.moment,
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              if (title != null ||
                                  readAloudText != null ||
                                  readAloudAudioKey != null) ...[
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
                                    // AUTH: pre-recorded clip; otherwise the TTS
                                    // read-aloud button (unchanged for non-auth).
                                    if (readAloudAudioKey != null)
                                      AuthAudioButton(
                                        audioKey: readAloudAudioKey!,
                                        semanticLabel: title,
                                      )
                                    else if (readAloudText != null)
                                      ReadAloudButton(textToRead: readAloudText!),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.lg),
                              ],
                              body,
                            ],
                          );

                          return SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(
                                AppSpacing.xl, AppSpacing.xl, AppSpacing.xl, AppSpacing.md),
                            // Moment screens (Welcome/completion) center their
                            // content vertically when it fits the viewport,
                            // matching the entry WelcomeScreen's greeting feel;
                            // form screens keep the natural top-aligned scroll.
                            child: layout == OnboardingLayoutMode.moment
                                ? ConstrainedBox(
                                    constraints: BoxConstraints(
                                      minHeight:
                                          (constraints.maxHeight - verticalPadding).clamp(0, double.infinity),
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [content],
                                    ),
                                  )
                                : content,
                          );
                        },
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
