import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Shared modern card surface for work/service UI.
///
/// This is presentation-only: it owns no data, state, navigation, or actions.
class ModernServiceCard extends StatelessWidget {
  final Widget child;
  final double? width;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry padding;
  final Color backgroundColor;
  final Color borderColor;
  final VoidCallback? onTap;

  const ModernServiceCard({
    super.key,
    required this.child,
    this.width,
    this.margin,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.backgroundColor = AppColors.lightSurface,
    this.borderColor = AppColors.onboardingDivider,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadius.lg);
    final content = Padding(
      padding: padding,
      child: child,
    );

    return Container(
      width: width,
      margin: margin,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: radius,
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowSm,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: onTap == null
            ? content
            : InkWell(
                onTap: onTap,
                borderRadius: radius,
                child: content,
              ),
      ),
    );
  }
}

class ModernIconBox extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color backgroundColor;
  final Color? borderColor;
  final double size;
  final double iconSize;

  const ModernIconBox({
    super.key,
    required this.icon,
    this.color = AppColors.purple700,
    this.backgroundColor = AppColors.workIconSurface,
    this.borderColor,
    this.size = 44,
    this.iconSize = AppSizes.iconMd,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppRadius.md + 2),
        border: Border.all(
          color: borderColor ?? AppColors.purple700.withValues(alpha: 0.08),
        ),
      ),
      child: Icon(icon, color: color, size: iconSize),
    );
  }
}

IconData workIconForLabel(String label) {
  final c = label.toLowerCase();
  if (c.contains('plumb') || c.contains('pipe')) {
    return Icons.plumbing_outlined;
  }
  if (c.contains('electric') || c.contains('power')) {
    return Icons.electrical_services_outlined;
  }
  if (c.contains('clean')) {
    return Icons.cleaning_services_outlined;
  }
  if (c.contains('carpent') || c.contains('wood')) {
    return Icons.carpenter_outlined;
  }
  if (c.contains('paint')) {
    return Icons.format_paint_outlined;
  }
  if (c.contains('ac') || c.contains('air')) {
    return Icons.ac_unit_outlined;
  }
  if (c.contains('garden') || c.contains('yard')) {
    return Icons.yard_outlined;
  }
  if (c.contains('deliver') || c.contains('moving')) {
    return Icons.local_shipping_outlined;
  }
  if (c.contains('tutor') || c.contains('school')) {
    return Icons.school_outlined;
  }
  if (c.contains('handyman') || c.contains('appliance')) {
    return Icons.handyman_outlined;
  }
  if (c.contains('other')) {
    return Icons.add_rounded;
  }
  return Icons.work_outline_rounded;
}
