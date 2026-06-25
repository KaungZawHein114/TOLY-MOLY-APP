import 'package:flutter/material.dart';

import '../../../core/constants/task_posting_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/large_button.dart';

/// Shared bottom action bar for the task-posting flow's 7 screens: an
/// outlined "Previous" button (hidden on Screen 1, nothing to go back to
/// within the flow) and a filled "Continue" button.
class TaskPostingBottomBar extends StatelessWidget {
  final VoidCallback? onPrevious;
  final VoidCallback onContinue;
  final bool celebratory;
  final String continueLabel;
  final IconData continueIcon;

  const TaskPostingBottomBar({
    super.key,
    required this.onContinue,
    this.onPrevious,
    this.celebratory = false,
    this.continueLabel = TaskPostingStrings.continueButton,
    this.continueIcon = Icons.arrow_forward,
  });

  @override
  Widget build(BuildContext context) {
    final continueButton = LargeButton(
      label: continueLabel,
      icon: continueIcon,
      gradient: AppColors.purpleGradient,
      celebratory: celebratory,
      onTap: onContinue,
    );

    if (onPrevious == null) return continueButton;

    return Row(
      children: [
        Expanded(
          child: LargeButton(
            label: TaskPostingStrings.previousButton,
            filled: false,
            outlineColor: AppColors.purple700,
            onTap: onPrevious!,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(flex: 2, child: continueButton),
      ],
    );
  }
}
