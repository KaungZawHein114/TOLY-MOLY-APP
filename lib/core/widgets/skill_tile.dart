import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// A square emoji + label tile used for category grids and skill badges.
/// Styling comes from theme tokens; the widget only knows about content + tap.
class SkillTile extends StatelessWidget {
  final String emoji;
  final String label;
  final String? sublabel; // e.g. Burmese name
  final bool selected;
  final VoidCallback onTap;

  const SkillTile({
    super.key,
    required this.emoji,
    required this.label,
    required this.onTap,
    this.sublabel,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final radius = BorderRadius.circular(AppRadius.lg);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: radius,
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.teal.withValues(alpha: 0.14)
                : theme.cardColor,
            borderRadius: radius,
            border: Border.all(
              color: selected ? AppColors.teal : theme.dividerColor,
              width: selected ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(
              vertical: AppSpacing.sm, horizontal: AppSpacing.xs + 2),
          // FittedBox is a safety net: if the cell is ever shorter than the
          // content (small phones, big fonts), the tile scales down instead of
          // showing an overflow stripe.
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(emoji, style: const TextStyle(fontSize: 28)),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (sublabel != null) ...[
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    sublabel!,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.hintColor,
                      fontSize: 10,
                    ),
                  ),
                ],
                if (selected) ...[
                  const SizedBox(height: AppSpacing.xxs),
                  const Icon(Icons.check_circle,
                      color: AppColors.teal, size: AppSizes.iconSm + 2),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
