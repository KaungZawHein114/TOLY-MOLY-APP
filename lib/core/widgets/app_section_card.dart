import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// The one reusable section container for the whole app — a titled, softly
/// elevated card that every feature (profiles, tasker details, booking,
/// verification, settings, dashboards, and anything built later) uses instead
/// of hand-rolling its own `Container` + `BoxDecoration` + header row.
///
/// Deliberately plain: rounded corners, a soft shadow, comfortable padding,
/// theme-driven typography. No glassmorphism, no gradients, no neon — this is
/// the calm, trustworthy shell the design system standardizes on.
///
/// ```dart
/// AppSectionCard(
///   title: "ကိုယ်ရေးအချက်အလက်",
///   icon: Icons.person_outline,
///   trailing: IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () {}),
///   child: Column(children: [...]),
/// )
/// ```
///
/// Three independent modes, combinable:
/// - **Clickable** — pass [onTap] and the whole card becomes a single tap
///   target (e.g. a dashboard tile that navigates to a detail screen).
/// - **Expandable/collapsible** — pass [expandable]`: true` and the header
///   itself toggles the body open/closed with an animated chevron. Control it
///   yourself with [expanded]/[onExpand], or leave both null and the card
///   manages its own open/closed state (starts open).
/// - **Read-only** — the default: no [onTap], not [expandable]. Just a
///   titled container.
class AppSectionCard extends StatefulWidget {
  /// Section heading — always rendered, always Burmese-first copy in practice.
  final String title;

  /// The section's body content. Can be any widget — a Column of rows, chips,
  /// a progress bar, a form, anything.
  final Widget child;

  /// Leading icon shown before the title (e.g. `Icons.person_outline`).
  final IconData? icon;

  /// Small muted line under the title (e.g. an English gloss or a hint).
  final String? subtitle;

  /// Header-right slot — an edit button, a switch, a badge, a chevron, or
  /// any other compact control. Ignored (replaced by an auto chevron) when
  /// [expandable] is true and no [trailing] is supplied.
  final Widget? trailing;

  /// Makes the whole card a single tap target (e.g. a dashboard section that
  /// navigates elsewhere). Not used together with [expandable] — expandable
  /// cards toggle from the header instead so the body's own controls (edit
  /// buttons, chips, switches) stay independently tappable.
  final VoidCallback? onTap;

  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;
  final Color? borderColor;

  /// Divider between the header and the body. Defaults to off (matches the
  /// project's "fill + shadow over hard rules" card language) — turn it on
  /// for denser sections where a hairline helps separate header from content.
  final bool showDivider;

  /// Turns the header into a collapse/expand toggle for [child].
  final bool expandable;

  /// Controlled expansion state. Leave null to let the card manage its own
  /// state (uncontrolled) — only meaningful when [expandable] is true.
  final bool? expanded;

  /// Called with the new expansion state whenever the header is tapped.
  /// Required for controlled usage ([expanded] non-null); optional otherwise.
  final ValueChanged<bool>? onExpand;

  const AppSectionCard({
    super.key,
    required this.title,
    required this.child,
    this.icon,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.borderColor,
    this.showDivider = false,
    this.expandable = false,
    this.expanded,
    this.onExpand,
  });

  @override
  State<AppSectionCard> createState() => _AppSectionCardState();
}

class _AppSectionCardState extends State<AppSectionCard> {
  // Only used in uncontrolled mode (widget.expanded == null). Starts open so
  // a card that forgets to pass `expanded` still shows its content.
  bool _uncontrolledExpanded = true;

  bool get _isExpanded => !widget.expandable || (widget.expanded ?? _uncontrolledExpanded);

  void _toggleExpanded() {
    if (!widget.expandable) return;
    final next = !_isExpanded;
    if (widget.expanded == null) {
      setState(() => _uncontrolledExpanded = next);
    }
    widget.onExpand?.call(next);
  }

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadius.lg);
    final expanded = _isExpanded;
    final padding = widget.padding ?? const EdgeInsets.all(AppSpacing.lg);

    final card = AnimatedContainer(
      duration: AppMotion.medium,
      curve: AppMotion.enter,
      margin: widget.margin ?? const EdgeInsets.only(bottom: AppSpacing.lg),
      decoration: BoxDecoration(
        color: widget.backgroundColor ?? AppColors.lightBg,
        borderRadius: radius,
        border: widget.borderColor != null ? Border.all(color: widget.borderColor!, width: 1.4) : null,
        boxShadow: [
          BoxShadow(color: AppColors.shadowSm, blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Padding(
        padding: padding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Header(
              title: widget.title,
              subtitle: widget.subtitle,
              icon: widget.icon,
              trailing: widget.trailing,
              expandable: widget.expandable,
              expanded: expanded,
              onTap: widget.expandable ? _toggleExpanded : null,
            ),
            if (widget.showDivider && expanded) ...[
              const SizedBox(height: AppSpacing.md),
              const Divider(height: 1, color: AppColors.onboardingDivider),
            ],
            AnimatedSize(
              duration: AppMotion.medium,
              curve: AppMotion.enter,
              alignment: Alignment.topCenter,
              child: AnimatedSwitcher(
                duration: AppMotion.fast,
                child: expanded
                    ? Padding(
                        key: const ValueKey("expanded-body"),
                        padding: const EdgeInsets.only(top: AppSpacing.md),
                        child: widget.child,
                      )
                    : const SizedBox(width: double.infinity, key: ValueKey("collapsed-body")),
              ),
            ),
          ],
        ),
      ),
    );

    if (widget.onTap == null) return card;

    return Semantics(
      button: true,
      label: widget.title,
      child: Material(
        type: MaterialType.transparency,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          borderRadius: radius,
          onTap: () {
            HapticFeedback.selectionClick();
            widget.onTap!();
          },
          child: card,
        ),
      ),
    );
  }
}

/// Header row: optional leading icon, title + optional subtitle, and a
/// trailing slot (custom widget, or an auto chevron in expandable mode).
class _Header extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final Widget? trailing;
  final bool expandable;
  final bool expanded;
  final VoidCallback? onTap;

  const _Header({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.trailing,
    required this.expandable,
    required this.expanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final row = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 48),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: AppSizes.iconMd, color: AppColors.purple700),
            const SizedBox(width: AppSpacing.sm),
          ],
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleMedium),
                if (subtitle != null) ...[
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    subtitle!,
                    style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: AppSpacing.sm),
            trailing!,
          ] else if (expandable) ...[
            const SizedBox(width: AppSpacing.sm),
            AnimatedRotation(
              turns: expanded ? 0.5 : 0,
              duration: AppMotion.medium,
              curve: AppMotion.enter,
              child: const Icon(Icons.expand_more, color: AppColors.textSecondary),
            ),
          ],
        ],
      ),
    );

    if (onTap == null) return row;

    return Semantics(
      button: true,
      label: title,
      hint: expandable ? (expanded ? "ချုံ့ရန်" : "ဖြန့်ရန်") : null, // collapse / expand
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            onTap!();
          },
          child: row,
        ),
      ),
    );
  }
}
