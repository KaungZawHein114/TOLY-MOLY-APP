import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/onboarding_strings.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/large_button.dart';
import '../../../core/widgets/mascot/mascot_state.dart';
import '../../../core/widgets/onboarding/choice_wrap.dart';
import '../../../core/widgets/onboarding/onboarding_scaffold.dart';
import '../../../core/widgets/onboarding/profile_picture_picker.dart';
import '../../../core/widgets/onboarding/read_aloud_button.dart';
import '../onboarding_models.dart';
import '../onboarding_state.dart';

class TaskerBasicProfileScreen extends ConsumerWidget {
  const TaskerBasicProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final draft = ref.watch(taskerDraftProvider);
    final notifier = ref.read(taskerDraftProvider.notifier);

    return OnboardingScaffold(
      progress: const OnboardingProgress(step: 4, totalSteps: 6),
      mascotState: PhoWaYokeState.pointing,
      mascotMessage: OnboardingStrings.basicProfileTitle,
      title: OnboardingStrings.basicProfileTitle,
      onBack: () => context.pop(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ProfilePicturePicker(
            pickedPath: draft.profilePicturePath,
            onPicked: (path) =>
                notifier.state = notifier.state.copyWith(profilePicturePath: path),
          ),
          const SizedBox(height: AppSpacing.xxl),
          Row(
            children: [
              Expanded(
                child: Text(OnboardingStrings.hearAboutQuestion, style: theme.textTheme.titleMedium),
              ),
              ReadAloudButton(textToRead: OnboardingStrings.hearAboutQuestion),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ChoiceWrap<HearAboutSource>(
            values: HearAboutSource.values,
            selected: draft.hearAboutSource,
            labelOf: (v) => v.label,
            emojiOf: (v) => v.emoji,
            onSelect: (v) => notifier.state = notifier.state.copyWith(hearAboutSource: v),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
      bottomBar: LargeButton(
        label: OnboardingStrings.continueButton,
        icon: Icons.arrow_forward,
        gradient: AppColors.purpleGradient,
        onTap: () => context.push(Routes.taskerRules),
      ),
    );
  }
}
