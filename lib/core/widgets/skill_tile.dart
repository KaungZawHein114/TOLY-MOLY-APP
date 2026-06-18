import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';

/// A square emoji + label tile used for category grids and skill badges.
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
    final radius = BorderRadius.circular(18);
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
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 30)),
              const SizedBox(height: 6),
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
                const SizedBox(height: 2),
                Text(
                  sublabel!,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.textTheme.bodySmall?.color
                        ?.withValues(alpha: 0.7),
                    fontSize: 10,
                  ),
                ),
              ],
              if (selected) ...[
                const SizedBox(height: 4),
                const Icon(Icons.check_circle, color: AppColors.teal, size: 18),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
