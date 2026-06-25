import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/task_posting_strings.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/ai_service.dart';
import '../../../core/widgets/mascot/mascot_state.dart';
import '../../../core/widgets/onboarding/onboarding_scaffold.dart';
import '../../onboarding/onboarding_models.dart';
import 'task_posting_bottom_bar.dart';
import 'task_posting_models.dart';
import 'task_posting_state.dart';

/// Step 6 of 7: Budget & AI Price Evaluation. The client enters their desired
/// budget; a live AI price analysis (Firebase → OpenAI, offline-mock fallback)
/// recommends a band and flags the entry as low / ok / high. Advisory only —
/// the client always keeps the final price.
class BudgetScreen extends ConsumerStatefulWidget {
  const BudgetScreen({super.key});

  @override
  ConsumerState<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends ConsumerState<BudgetScreen> {
  late final TextEditingController _controller;
  int? _amount;
  String? _error;
  PriceRange? _range;
  bool _loadingRange = true;

  @override
  void initState() {
    super.initState();
    final existing = ref.read(taskDraftProvider).budgetMmk;
    _amount = existing;
    _controller =
        TextEditingController(text: existing == null ? "" : "$existing");
    _loadRange();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _editMode =>
      GoRouterState.of(context).uri.queryParameters['edit'] == '1';

  Future<void> _loadRange() async {
    final draft = ref.read(taskDraftProvider);
    final location = draft.taskType == TaskType.remote
        ? TaskPostingStrings.remoteLocationValue
        : "${draft.township} ${draft.address}".trim();
    final range = await AiService.analyzePrice(
      title: draft.title,
      category: draft.effectiveCategory,
      description: draft.description,
      location: location,
      urgent: draft.urgent,
    );
    if (!mounted) return;
    setState(() {
      _range = range;
      _loadingRange = false;
    });
  }

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
    final range = _range;

    return OnboardingScaffold(
      progress: const OnboardingProgress(step: 6, totalSteps: 7),
      mascotState: PhoWaYokeState.thinking,
      mascotMessage: TaskPostingStrings.budgetTitle,
      title: TaskPostingStrings.budgetTitle,
      onBack: () => context.pop(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PriceRangeCard(loading: _loadingRange, range: range),
          const SizedBox(height: AppSpacing.lg),
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
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg, vertical: AppSpacing.lg),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          if (amount != null && range != null) ...[
            const SizedBox(height: AppSpacing.lg),
            _BudgetStatusCard(status: range.statusFor(amount)),
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

/// AI-recommended price band, shown above the input. Indigo = the design
/// system's AI accent. Falls back to an offline estimate (badge shown).
class _PriceRangeCard extends StatelessWidget {
  final bool loading;
  final PriceRange? range;
  const _PriceRangeCard({required this.loading, required this.range});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.indigo100,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome,
                  size: AppSizes.iconSm, color: AppColors.indigo700),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(TaskPostingStrings.aiPriceRangeTitle,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(color: AppColors.indigo700)),
              ),
              if (range != null && range!.source == AiSource.mock)
                const _OfflineBadge(),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (loading)
            Row(
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(TaskPostingStrings.aiThinking,
                    style: theme.textTheme.bodyMedium),
              ],
            )
          else if (range != null)
            Text(
              "${range!.low} - ${range!.high} ${TaskPostingStrings.budgetCurrency}",
              style: theme.textTheme.headlineSmall
                  ?.copyWith(color: AppColors.indigo700),
            ),
        ],
      ),
    );
  }
}

/// Low / ok / high read-out of the entered budget vs. the AI band.
class _BudgetStatusCard extends StatelessWidget {
  final PriceStatus status;
  const _BudgetStatusCard({required this.status});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (IconData icon, Color color, String message) = switch (status) {
      PriceStatus.low => (
          Icons.trending_down,
          AppColors.warning,
          TaskPostingStrings.budgetVerdictLow,
        ),
      PriceStatus.ok => (
          Icons.check_circle,
          AppColors.success,
          TaskPostingStrings.budgetVerdictReasonable,
        ),
      PriceStatus.high => (
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: AppSizes.iconLg),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(message, style: theme.textTheme.bodyLarge)),
        ],
      ),
    );
  }
}

class _OfflineBadge extends StatelessWidget {
  const _OfflineBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm, vertical: AppSpacing.xxs),
      decoration: BoxDecoration(
        color: AppColors.onboardingDivider,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        TaskPostingStrings.aiOfflineBadge,
        style: Theme.of(context)
            .textTheme
            .labelSmall
            ?.copyWith(color: AppColors.textSecondary),
      ),
    );
  }
}
