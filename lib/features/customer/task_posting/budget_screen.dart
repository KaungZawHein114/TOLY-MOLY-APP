import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/task_posting_strings.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/ai_mock.dart';
import '../../../core/widgets/mascot/mascot_state.dart';
import '../../../core/widgets/onboarding/onboarding_scaffold.dart';
import '../../onboarding/onboarding_models.dart';
import 'task_posting_bottom_bar.dart';
import 'task_posting_models.dart';
import 'task_posting_state.dart';

/// Step 6 of 7: Budget & AI Price Evaluation. The client enters their desired
/// budget first; the AI then evaluates it against a reference price and gives
/// advisory feedback only — the client always keeps the final price.
class BudgetScreen extends ConsumerStatefulWidget {
  const BudgetScreen({super.key});

  @override
  ConsumerState<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends ConsumerState<BudgetScreen> {
  late final TextEditingController _controller;
  int? _amount;
  String? _error;

  @override
  void initState() {
    super.initState();
    final existing = ref.read(taskDraftProvider).budgetMmk;
    _amount = existing;
    _controller =
        TextEditingController(text: existing == null ? "" : "$existing");
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _editMode =>
      GoRouterState.of(context).uri.queryParameters['edit'] == '1';

  void _onChanged(String text) {
    final parsed = int.tryParse(text.trim());
    setState(() {
      _amount = (parsed != null && parsed > 0) ? parsed : null;
      if (_amount != null) _error = null;
    });
  }

  void _continue() {
    final amount = _amount;
    setState(() {
      _error = (amount == null || amount <= 0)
          ? TaskPostingStrings.budgetRequiredError
          : null;
    });
    if (amount == null || amount <= 0) return;
    ref.read(taskDraftProvider.notifier).state =
        ref.read(taskDraftProvider).copyWith(budgetMmk: amount);
    if (_editMode) {
      context.pop();
    } else {
      context.push(Routes.postTaskReview);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final amount = _amount;

    return OnboardingScaffold(
      progress: const OnboardingProgress(step: 6, totalSteps: 7),
      mascotState: PhoWaYokeState.thinking,
      mascotMessage: TaskPostingStrings.budgetTitle,
      title: TaskPostingStrings.budgetTitle,
      onBack: () => context.pop(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(TaskPostingStrings.budgetInputLabel,
              style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _controller,
            onChanged: _onChanged,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: theme.textTheme.headlineSmall,
            decoration: InputDecoration(
              hintText: TaskPostingStrings.budgetInputHint,
              suffixText: TaskPostingStrings.budgetCurrency,
              errorText: _error,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.lg),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          if (amount != null) ...[
            const SizedBox(height: AppSpacing.lg),
            _BudgetVerdictCard(verdict: evaluateBudget(amount)),
          ],
          const SizedBox(height: AppSpacing.lg),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline,
                  size: AppSizes.iconSm, color: AppColors.textSecondary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(TaskPostingStrings.budgetGuidanceNote,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: AppColors.textSecondary)),
              ),
            ],
          ),
        ],
      ),
      bottomBar: TaskPostingBottomBar(
        onPrevious: _editMode ? null : () => context.pop(),
        onContinue: _continue,
        continueLabel: _editMode
            ? TaskPostingStrings.saveButton
            : TaskPostingStrings.continueButton,
        continueIcon: _editMode ? Icons.check : Icons.arrow_forward,
      ),
    );
  }
}

/// Color-coded AI feedback on the entered budget. Advisory only.
class _BudgetVerdictCard extends StatelessWidget {
  final BudgetVerdict verdict;
  const _BudgetVerdictCard({required this.verdict});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (IconData icon, Color color, String message) = switch (verdict) {
      BudgetVerdict.low => (
          Icons.trending_down,
          AppColors.warning,
          TaskPostingStrings.budgetVerdictLow,
        ),
      BudgetVerdict.reasonable => (
          Icons.check_circle,
          AppColors.success,
          TaskPostingStrings.budgetVerdictReasonable,
        ),
      BudgetVerdict.high => (
          Icons.trending_up,
          AppColors.warning,
          TaskPostingStrings.budgetVerdictHigh,
        ),
    };

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(TaskPostingStrings.budgetEvalTitle,
              style: theme.textTheme.titleSmall
                  ?.copyWith(color: AppColors.brandPurple)),
          const SizedBox(height: AppSpacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: AppSizes.iconLg),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(message, style: theme.textTheme.bodyLarge),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
