import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';

/// A large, image/icon-assisted selectable card used across onboarding for
/// role, gender, skill, hear-about-us and usage-purpose choices.
///
/// [emoji] is a stable placeholder reference (per CLAUDE.md accessibility
/// rules) — swapping it for real illustrations later needs no screen edits.
class OnboardingSelectionCard extends StatelessWidget {
  final String emoji;
  final String label;
  final String? sublabel;
  final bool selected;
  final VoidCallback onTap;
  final String? semanticLabel;

  const OnboardingSelectionCard({
    super.key,
    required this.emoji,
    required this.label,
    required this.onTap,
    this.sublabel,
    this.selected = false,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final radius = BorderRadius.circular(AppRadius.lg);
    return Semantics(
      label: semanticLabel ?? label,
      selected: selected,
      button: true,
      image: true,
      child: _PressableScale(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(
                vertical: AppSpacing.sm, horizontal: AppSpacing.sm),
            decoration: BoxDecoration(
              gradient: selected ? AppColors.cardFillGradient : null,
              color: selected ? null : AppColors.lightSurface,
              borderRadius: radius,
              boxShadow: [
                BoxShadow(
                  color: selected ? AppColors.selectedShadowMd : AppColors.shadowMd,
                  blurRadius: selected ? 16 : 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            // FittedBox is a safety net (mirrors SkillTile): if a grid cell
            // is ever shorter than the content (long labels, large text
            // scale), the card scales down instead of overflowing.
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ExcludeSemantics(
                    child: Container(
                      width: AppSizes.avatarSm,
                      height: AppSizes.avatarSm,
                      decoration: const BoxDecoration(
                        color: AppColors.blue100,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(emoji, style: const TextStyle(fontSize: 20)),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  if (sublabel != null) ...[
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      sublabel!,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                  if (selected) ...[
                    const SizedBox(height: AppSpacing.xxs),
                    const Icon(Icons.check_circle,
                        color: AppColors.purple700, size: AppSizes.iconSm + 2),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Wraps [child] with a subtle scale-down while pressed. Visual-only — the
/// hit-test area (and thus the 48px minimum touch target) is unchanged,
/// since the Material/InkWell below still own the actual tap area.
class _PressableScale extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const _PressableScale({required this.child, required this.onTap});

  @override
  State<_PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<_PressableScale> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (MediaQuery.of(context).disableAnimations) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _setPressed(true),
      onTapCancel: () => _setPressed(false),
      onTapUp: (_) => _setPressed(false),
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: AppMotion.fast,
        curve: AppMotion.press,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            onTap: widget.onTap,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
