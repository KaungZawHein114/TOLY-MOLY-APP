import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/data/demo_data.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/onboarding/read_aloud_button.dart';

/// A soft background/icon tint for a category, derived from its English
/// [Category.name] (per CLAUDE.md's suggested category colors). Falls back
/// to a neutral gray tint for any category outside the suggested set, so new
/// demo categories never render unstyled.
class _CategoryTint {
  final Color background;
  final Color foreground;
  const _CategoryTint(this.background, this.foreground);
}

_CategoryTint _tintFor(String name) {
  final n = name.toLowerCase();
  if (n.contains('clean')) return _CategoryTint(AppColors.blue100, AppColors.indigo700);
  if (n.contains('electric')) return _CategoryTint(AppColors.orangeLight.withValues(alpha: 0.18), AppColors.orangeDark);
  if (n.contains('plumb')) return _CategoryTint(AppColors.tealLight.withValues(alpha: 0.22), AppColors.tealDark);
  if (n.contains('ac ') || n.contains('ac repair') || n.contains('air')) {
    return _CategoryTint(AppColors.purple100, AppColors.purple700);
  }
  if (n.contains('garden') || n.contains('carpentry') || n.contains('handyman') || n.contains('appliance')) {
    return _CategoryTint(AppColors.success.withValues(alpha: 0.14), AppColors.success);
  }
  return const _CategoryTint(Color(0xFFEDEFF2), AppColors.textSecondary);
}

/// "Popular Categories" section for the customer Home dashboard: a header
/// (title, subtitle, work-type search bar) followed by a responsive grid of
/// [CategoryCard]s, filtered live as the user types. Purely presentational —
/// data comes from demo_data's [Category] list and is unchanged by this
/// widget; searching only filters which existing categories are shown.
class CategorySection extends StatefulWidget {
  final List<Category> categories;
  final void Function(Category category) onCategoryTap;

  const CategorySection({
    super.key,
    required this.categories,
    required this.onCategoryTap,
  });

  @override
  State<CategorySection> createState() => _CategorySectionState();
}

class _CategorySectionState extends State<CategorySection> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final crossAxisCount = width >= 600 ? 3 : 2;

    final query = _query.trim().toLowerCase();
    final filtered = query.isEmpty
        ? widget.categories
        : widget.categories
            .where((c) =>
                c.name.toLowerCase().contains(query) || c.burmese.toLowerCase().contains(query))
            .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.homeCategoriesTitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleLarge,
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          AppStrings.homeCategoriesSubtitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: _searchController,
          onChanged: (v) => setState(() => _query = v),
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: AppStrings.homeCategoriesSearchHint,
            prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
            suffixIcon: _query.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.close, color: AppColors.textSecondary),
                    onPressed: () => setState(() {
                      _searchController.clear();
                      _query = '';
                    }),
                  ),
            filled: true,
            fillColor: theme.cardColor,
            contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              borderSide: const BorderSide(color: AppColors.onboardingDivider),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              borderSide: const BorderSide(color: AppColors.onboardingDivider),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              borderSide: const BorderSide(color: AppColors.purple700, width: 2),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        if (filtered.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
            child: Center(
              child: Text(
                AppStrings.homeCategoriesSearchEmpty,
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
              ),
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filtered.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: AppSpacing.lg,
              crossAxisSpacing: AppSpacing.lg,
              childAspectRatio: 0.92,
            ),
            itemBuilder: (context, i) {
              final c = filtered[i];
              return CategoryCard(
                category: c,
                onTap: () => widget.onCategoryTap(c),
              );
            },
          ),
      ],
    );
  }
}

/// A single premium category card: tinted background, large emoji icon,
/// Burmese name, optional English subtitle, ripple + press-scale feedback,
/// and hover lift on desktop/web.
class CategoryCard extends StatefulWidget {
  final Category category;
  final VoidCallback onTap;

  const CategoryCard({super.key, required this.category, required this.onTap});

  @override
  State<CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<CategoryCard> {
  bool _pressed = false;
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tint = _tintFor(widget.category.name);
    final radius = BorderRadius.circular(20);
    final scale = _pressed ? 0.96 : (_hovered ? 1.02 : 1.0);

    return Semantics(
      button: true,
      label: '${widget.category.burmese} (${widget.category.name})',
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTapDown: (_) => setState(() => _pressed = true),
          onTapCancel: () => setState(() => _pressed = false),
          onTapUp: (_) => setState(() => _pressed = false),
          child: AnimatedScale(
            scale: scale,
            duration: AppMotion.fast,
            curve: AppMotion.press,
            child: AnimatedContainer(
              duration: AppMotion.fast,
              curve: AppMotion.press,
              decoration: BoxDecoration(
                color: tint.background,
                borderRadius: radius,
                boxShadow: [
                  BoxShadow(
                    color: _hovered ? AppColors.shadowLg : AppColors.shadowMd,
                    blurRadius: _hovered ? 18 : 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: radius,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    widget.onTap();
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.lg,
                      horizontal: AppSpacing.sm,
                    ),
                    // Safety net for small grid cells (small phones, large text
                    // scale): scale the whole card body down instead of
                    // overflowing, matching the pattern used by SkillTile and
                    // OnboardingSelectionCard.
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: tint.foreground.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Text(widget.category.icon, style: const TextStyle(fontSize: 28)),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          widget.category.burmese,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          widget.category.name,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        ReadAloudButton(textToRead: widget.category.burmese, compact: true),
                      ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
