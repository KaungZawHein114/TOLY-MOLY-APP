import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../discussion_models.dart';

/// The "ask" affordance: one slim pill at the bottom of the conversation that
/// opens a list of ready-made questions when tapped or swiped up.
///
/// This replaces the old permanent action bar. A row of six commands sitting
/// under every message made the page feel like a control panel; a single pill
/// keeps the screen calm and still gets a non-typing user to a real question
/// in two taps.
class ExpandableQuestionMenu extends StatelessWidget {
  final String label;
  final String sheetTitle;
  final List<SuggestedQuestion> questions;
  final ValueChanged<SuggestedQuestion> onSelected;

  const ExpandableQuestionMenu({
    super.key,
    required this.label,
    required this.sheetTitle,
    required this.questions,
    required this.onSelected,
  });

  Future<void> _open(BuildContext context) async {
    if (questions.isEmpty) return;
    final picked = await showModalBottomSheet<SuggestedQuestion>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: AppColors.lightSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (_) => _QuestionSheet(title: sheetTitle, questions: questions),
    );
    if (picked != null) onSelected(picked);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final empty = questions.isEmpty;

    return Semantics(
      button: !empty,
      label: empty ? 'မေးစရာ အားလုံး မေးပြီးပါပြီ' : label,
      child: GestureDetector(
        // Swipe up opens it too — the gesture the pill's handle promises.
        onVerticalDragEnd: (details) {
          if ((details.primaryVelocity ?? 0) < -80) _open(context);
        },
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          onTap: empty ? null : () => _open(context),
          child: Container(
            constraints: const BoxConstraints(minHeight: 52),
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
            decoration: BoxDecoration(
              color: empty ? AppColors.lightBg : AppColors.purple100,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  empty ? Icons.check_circle_outline : Icons.keyboard_arrow_up_rounded,
                  color: empty ? AppColors.textSecondary : AppColors.purple700,
                ),
                const SizedBox(width: AppSpacing.sm),
                Flexible(
                  child: Text(
                    empty ? 'မေးစရာ အားလုံး မေးပြီးပါပြီ' : label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: empty ? AppColors.textSecondary : AppColors.purple900,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QuestionSheet extends StatelessWidget {
  final String title;
  final List<SuggestedQuestion> questions;

  const _QuestionSheet({required this.title, required this.questions});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.75,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.sm),
              child: Column(
                children: [
                  Container(
                    width: AppSpacing.huge,
                    height: AppSpacing.xxs,
                    margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: AppColors.onboardingDivider,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                  ),
                  Text(
                    title,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'တစ်ခုကို နှိပ်လိုက်ရုံနဲ့ စကားပြောထဲ ရောက်သွားပါမယ်။',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xl, AppSpacing.md, AppSpacing.xl, AppSpacing.xl),
                itemCount: questions.length,
                separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                itemBuilder: (context, index) {
                  final question = questions[index];
                  return Semantics(
                    button: true,
                    label: question.text,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      onTap: () => Navigator.of(context).pop(question),
                      child: Container(
                        constraints: const BoxConstraints(minHeight: 64),
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.lightBg,
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(AppSpacing.sm),
                              decoration: BoxDecoration(
                                color: AppColors.purple100,
                                borderRadius: BorderRadius.circular(AppRadius.md),
                              ),
                              child: Icon(question.icon,
                                  color: AppColors.purple700, size: AppSizes.iconMd),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Text(
                                question.text,
                                style: theme.textTheme.bodyLarge?.copyWith(height: 1.3),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            const Icon(Icons.send_rounded,
                                size: AppSizes.iconMd, color: AppColors.purple700),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
