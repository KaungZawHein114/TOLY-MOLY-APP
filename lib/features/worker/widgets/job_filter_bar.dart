import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

/// A single selectable value inside a [FilterDropdown]'s menu.
class FilterOption<T> {
  final T value;
  final String label;
  const FilterOption({required this.value, required this.label});
}

/// Compact pill-shaped dropdown for the Job Board filter row — the same
/// pattern as the customer "All Workers" filter bar, kept local to the
/// worker feature so each feature folder owns its own UI-only widgets.
/// Purely presentational: the caller owns the actual filter state (a
/// Riverpod provider) and passes the current value + options + callback.
class FilterDropdown<T> extends StatelessWidget {
  final String semanticLabel;
  final String displayText;
  final bool isActive;
  final List<FilterOption<T>> options;
  final ValueChanged<T> onSelected;

  const FilterDropdown({
    super.key,
    required this.semanticLabel,
    required this.displayText,
    required this.options,
    required this.onSelected,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const activeColor = AppColors.purple700;

    return Semantics(
      label: semanticLabel,
      button: true,
      child: PopupMenuButton<T>(
        tooltip: semanticLabel,
        position: PopupMenuPosition.under,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
        onSelected: onSelected,
        itemBuilder: (context) => [
          for (final o in options) PopupMenuItem<T>(value: o.value, child: Text(o.label)),
        ],
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppSizes.iconLg + AppSpacing.xxl),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            decoration: BoxDecoration(
              color: isActive ? AppColors.purple100 : theme.cardColor,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(
                color: isActive ? activeColor : AppColors.onboardingDivider,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  displayText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isActive ? activeColor : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: AppSpacing.xxs),
                Icon(
                  Icons.keyboard_arrow_down,
                  size: 18,
                  color: isActive ? activeColor : theme.hintColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A compact toggle pill for a binary filter ("Urgent Only") — sits in the
/// same horizontally scrollable row as the dropdowns instead of a full-width
/// switch, per the Job Board redesign spec.
class FilterToggleChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const FilterToggleChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const activeColor = AppColors.purple700;

    return Semantics(
      label: label,
      button: true,
      selected: selected,
      child: Material(
        color: selected ? AppColors.purple100 : theme.cardColor,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: AppSizes.iconLg + AppSpacing.xxl),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.pill),
                border: Border.all(color: selected ? activeColor : AppColors.onboardingDivider),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    selected ? Icons.bolt : Icons.bolt_outlined,
                    size: 16,
                    color: selected ? activeColor : theme.hintColor,
                  ),
                  const SizedBox(width: AppSpacing.xxs),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: selected ? activeColor : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A removable pill summarizing one active filter ("Urgent Only ×").
/// Tapping it clears just that filter.
class ActiveFilterChip extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;

  const ActiveFilterChip({super.key, required this.label, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: AppColors.purple100,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        onTap: onRemove,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: AppColors.purple700, fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: AppSpacing.xxs),
              const Icon(Icons.close, size: 14, color: AppColors.purple700),
            ],
          ),
        ),
      ),
    );
  }
}

/// Lays out the Job Board filter UI: a horizontally scrollable row of
/// [FilterDropdown]s/[FilterToggleChip]s, followed by the active-filters row
/// (removable chips + an optional "Clear All" action) once any filter is
/// non-default.
class JobFilterBar extends StatelessWidget {
  final List<Widget> dropdowns;
  final List<Widget> activeFilterChips;
  final VoidCallback? onClearAll;

  const JobFilterBar({
    super.key,
    required this.dropdowns,
    required this.activeFilterChips,
    this.onClearAll,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: AppSizes.iconLg + AppSpacing.xxl,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: dropdowns.length,
            separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
            itemBuilder: (_, i) => dropdowns[i],
          ),
        ),
        AnimatedSize(
          duration: AppMotion.fast,
          curve: AppMotion.press,
          alignment: Alignment.topLeft,
          child: activeFilterChips.isEmpty
              ? const SizedBox(width: double.infinity)
              : Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.sm,
                          children: activeFilterChips,
                        ),
                      ),
                      if (onClearAll != null)
                        TextButton(
                          onPressed: onClearAll,
                          child: Text(AppStrings.jobBoardClearAllFilters),
                        ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}
