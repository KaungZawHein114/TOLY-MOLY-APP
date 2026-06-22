import 'package:flutter/material.dart';

import '../../theme/app_spacing.dart';
import 'onboarding_selection_card.dart';

/// A wrap of [OnboardingSelectionCard]s for single-choice questions
/// (hear-about-us, usage purpose, experience level, etc.) shared by both the
/// client and tasker onboarding flows.
class ChoiceWrap<T> extends StatelessWidget {
  final List<T> values;
  final T? selected;
  final String Function(T) labelOf;
  final String Function(T) emojiOf;
  final ValueChanged<T> onSelect;
  final double cardWidth;

  const ChoiceWrap({
    super.key,
    required this.values,
    required this.selected,
    required this.labelOf,
    required this.emojiOf,
    required this.onSelect,
    this.cardWidth = 104,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.md,
      children: values.map((v) {
        return SizedBox(
          width: cardWidth,
          child: OnboardingSelectionCard(
            emoji: emojiOf(v),
            label: labelOf(v),
            selected: selected == v,
            onTap: () => onSelect(v),
          ),
        );
      }).toList(),
    );
  }
}
