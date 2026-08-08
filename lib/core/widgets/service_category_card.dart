import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'modern_service_card.dart';

/// A category card for the task-posting category picker: icon + name,
/// borderless fill + soft shadow, matching the look already established by
/// SkillTile/OnboardingSelectionCard.
class ServiceCategoryCard extends StatelessWidget {
  final String emoji;
  final String label;
  final VoidCallback onTap;
  final bool selected;

  const ServiceCategoryCard({
    super.key,
    required this.emoji,
    required this.label,
    required this.onTap,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ModernServiceCard(
      padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.sm, horizontal: AppSpacing.xs),
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Stack(
        alignment: Alignment.topRight,
        children: [
          Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ModernIconBox(
                    icon: workIconForLabel(label),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
          ),
          if (selected)
            const Icon(Icons.check_circle,
                color: AppColors.purple700, size: AppSizes.iconSm + 2),
        ],
      ),
    );
  }
}
