import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/task_posting_strings.dart';
import '../../../core/data/demo_data.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/ai_service.dart';
import '../../../core/widgets/large_button.dart';
import '../../../core/widgets/mascot/mascot_state.dart';
import '../../../core/widgets/mascot/pho_wa_yoke.dart';
import '../../../core/widgets/onboarding/onboarding_scaffold.dart';
import '../../../core/widgets/onboarding/speech_to_text_button.dart';
import '../../onboarding/onboarding_models.dart';
import '../customer_home_shell.dart';
import 'task_posting_bottom_bar.dart';
import 'task_posting_models.dart';
import 'task_posting_state.dart';

/// Step 7 of 7: Review & Submit. Each summary row's "Edit" link pushes back to
/// the owning screen in edit mode (`?edit=1`) — that screen pre-fills from the
/// shared draft and, on save, pops straight back here with data preserved.
class ReviewPublishScreen extends ConsumerStatefulWidget {
  const ReviewPublishScreen({super.key});

  @override
  ConsumerState<ReviewPublishScreen> createState() =>
      _ReviewPublishScreenState();
}

class _ReviewPublishScreenState extends ConsumerState<ReviewPublishScreen> {
  late final TextEditingController _notesController;
  TaskEvaluation? _eval;
  bool _loadingEval = true;

  @override
  void initState() {
    super.initState();
    _notesController =
        TextEditingController(text: ref.read(taskDraftProvider).notes);
    _loadEvaluation();
  }

  /// Live AI (Firebase → OpenAI) scores the task's attractiveness to workers,
  /// falling back to the offline completeness heuristic on any failure.
  Future<void> _loadEvaluation() async {
    final draft = ref.read(taskDraftProvider);
    final eval = await AiService.evaluateTask({
      'title': draft.title,
      'category': draft.effectiveCategory,
      'location': _formatLocation(draft),
      'date': _formatDate(draft.date),
      'time': draft.timeSlot ?? '',
      'tier': draft.workerTier?.label ?? '',
      'urgent': draft.urgent,
      'description': draft.description,
      'budget': draft.budgetMmk ?? 0,
    });
    if (!mounted) return;
    setState(() {
      _eval = eval;
      _loadingEval = false;
    });
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime? date) {
    if (date == null) return "-";
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  String _formatLocation(TaskDraft draft) {
    if (draft.taskType == TaskType.remote) {
      return TaskPostingStrings.remoteLocationValue;
    }
    if (draft.township.isEmpty && draft.address.isEmpty) return "-";
    return "${draft.township} ${draft.address}".trim();
  }

  void _editAt(String route) {
    // Persist any typed notes before navigating away to edit a step.
    ref.read(taskDraftProvider.notifier).state =
        ref.read(taskDraftProvider).copyWith(notes: _notesController.text);
    context.push('$route?edit=1');
  }

  void _publish() {
    final draft = ref.read(taskDraftProvider).copyWith(notes: _notesController.text);
    ref.read(taskDraftProvider.notifier).state = draft;
    final task = TaskPost(
      id: DateTime.now().millisecondsSinceEpoch,
      title: draft.title,
      category: draft.effectiveCategory,
      taskType: draft.taskType ?? TaskType.onSite,
      township: draft.township,
      address: draft.address,
      date: draft.date ?? DateTime.now(),
      timeSlot: draft.timeSlot ?? "",
      urgent: draft.urgent,
      workerTier: draft.workerTier ?? WorkerTier.tier1,
      description: draft.description,
      budgetMmk: draft.budgetMmk ?? 0,
      notes: draft.notes,
      createdAt: DateTime.now(),
    );
    ref.read(postedTasksProvider.notifier).state = [
      ...ref.read(postedTasksProvider),
      task,
    ];
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _SuccessModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final draft = ref.watch(taskDraftProvider);
    final isRemote = draft.taskType == TaskType.remote;

    return OnboardingScaffold(
      progress: const OnboardingProgress(step: 7, totalSteps: 7),
      mascotState: PhoWaYokeState.pointing,
      mascotMessage: TaskPostingStrings.reviewTitle,
      title: TaskPostingStrings.reviewTitle,
      onBack: () => context.pop(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ScoreCard(loading: _loadingEval, eval: _eval),
          const SizedBox(height: AppSpacing.lg),
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.blue100,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SummaryRow(
                  label: TaskPostingStrings.reviewCategoryLabel,
                  value: draft.effectiveCategory.isEmpty
                      ? "-"
                      : draft.effectiveCategory,
                  onEdit: () => _editAt(Routes.postTask),
                ),
                _SummaryRow(
                  label: TaskPostingStrings.reviewLocationLabel,
                  value: _formatLocation(draft),
                  onEdit: () => _editAt(Routes.postTaskTypeLocation),
                ),
                if (isRemote && draft.remoteWorkMethod != null)
                  _SummaryRow(
                    label: TaskPostingStrings.reviewWorkMethodLabel,
                    value: draft.remoteWorkMethod!.label,
                    onEdit: () => _editAt(Routes.postTaskTypeLocation),
                  ),
                _SummaryRow(
                  label: TaskPostingStrings.reviewDateLabel,
                  value: _formatDate(draft.date),
                  onEdit: () => _editAt(Routes.postTaskDateTime),
                ),
                _SummaryRow(
                  label: TaskPostingStrings.reviewTimeLabel,
                  value: draft.timeSlot ?? "-",
                  onEdit: () => _editAt(Routes.postTaskDateTime),
                ),
                _SummaryRow(
                  label: TaskPostingStrings.reviewUrgentLabel,
                  value: draft.urgent
                      ? TaskPostingStrings.reviewUrgentYes
                      : TaskPostingStrings.reviewUrgentNo,
                  onEdit: () => _editAt(Routes.postTaskDateTime),
                ),
                _SummaryRow(
                  label: TaskPostingStrings.reviewTierLabel,
                  value: draft.workerTier?.label ?? "-",
                  onEdit: () => _editAt(Routes.postTaskWorkersTier),
                ),
                _SummaryRow(
                  label: TaskPostingStrings.reviewBudgetLabel,
                  value: draft.budgetMmk == null
                      ? "-"
                      : "${draft.budgetMmk} ${TaskPostingStrings.budgetCurrency}",
                  onEdit: () => _editAt(Routes.postTaskBudget),
                ),
                _SummaryRow(
                  label: TaskPostingStrings.reviewDescriptionLabel,
                  value: draft.description.isEmpty ? "-" : draft.description,
                  onEdit: () => _editAt(Routes.postTaskDescription),
                  isLast: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          // ── Optional voice/text notes ───────────────────────────────────
          Text(TaskPostingStrings.reviewNotesLabel,
              style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: _notesController,
                  maxLines: 3,
                  style: theme.textTheme.bodyLarge,
                  decoration: InputDecoration(
                    hintText: TaskPostingStrings.reviewNotesHint,
                    contentPadding: const EdgeInsets.all(AppSpacing.lg),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              SpeechToTextButton(
                semanticPrompt: TaskPostingStrings.reviewNotesHint,
                mockTranscript: "ညနေပိုင်း လာပေးပါ",
                onResult: (v) => setState(() => _notesController.text = v),
              ),
            ],
          ),
        ],
      ),
      bottomBar: TaskPostingBottomBar(
        onPrevious: () => context.pop(),
        onContinue: _publish,
        celebratory: true,
        continueLabel: TaskPostingStrings.publishButton,
        continueIcon: Icons.check_circle,
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onEdit;
  final bool isLast;

  const _SummaryRow({
    required this.label,
    required this.value,
    required this.onEdit,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: AppSpacing.xxs),
                Text(value,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          TextButton(onPressed: onEdit, child: const Text(TaskPostingStrings.editLink)),
        ],
      ),
    );
  }
}

/// AI "Task Attractiveness Score" (0–100) plus a short strengths / weaknesses /
/// missing breakdown. Additive card — it does not alter the existing summary.
class _ScoreCard extends StatelessWidget {
  final bool loading;
  final TaskEvaluation? eval;
  const _ScoreCard({required this.loading, required this.eval});

  Color _scoreColor(int score) {
    if (score >= 75) return AppColors.success;
    if (score >= 50) return AppColors.indigo700;
    return AppColors.warning;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: AppColors.guidanceSurfaceGradient,
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
                child: Text(TaskPostingStrings.attractivenessTitle,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(color: AppColors.indigo700)),
              ),
              if (eval != null && eval!.source == AiSource.mock)
                const _OfflineBadge(),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
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
          else if (eval != null) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text("${eval!.score}",
                    style: theme.textTheme.displaySmall
                        ?.copyWith(color: _scoreColor(eval!.score))),
                const SizedBox(width: AppSpacing.xxs),
                Text(TaskPostingStrings.attractivenessScoreSuffix,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(color: AppColors.textSecondary)),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              child: LinearProgressIndicator(
                value: eval!.score / 100,
                minHeight: 8,
                backgroundColor: AppColors.lightSurface,
                valueColor: AlwaysStoppedAnimation(_scoreColor(eval!.score)),
              ),
            ),
            _Breakdown(
              label: TaskPostingStrings.attractivenessStrengths,
              items: eval!.strengths,
              icon: Icons.check_circle,
              color: AppColors.success,
            ),
            _Breakdown(
              label: TaskPostingStrings.attractivenessWeaknesses,
              items: eval!.weaknesses,
              icon: Icons.error_outline,
              color: AppColors.warning,
            ),
            _Breakdown(
              label: TaskPostingStrings.attractivenessMissing,
              items: eval!.missing,
              icon: Icons.add_circle_outline,
              color: AppColors.indigo700,
            ),
          ],
        ],
      ),
    );
  }
}

class _Breakdown extends StatelessWidget {
  final String label;
  final List<String> items;
  final IconData icon;
  final Color color;
  const _Breakdown({
    required this.label,
    required this.items,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: theme.textTheme.labelLarge
                  ?.copyWith(color: AppColors.brandPurple)),
          const SizedBox(height: AppSpacing.xxs),
          ...items.map((t) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xxs),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(icon, size: AppSizes.iconSm, color: color),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(child: Text(t, style: theme.textTheme.bodyMedium)),
                  ],
                ),
              )),
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
        color: AppColors.lightSurface,
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

class _SuccessModal extends ConsumerWidget {
  const _SuccessModal();

  void _goHome(BuildContext context, WidgetRef ref, {required bool toActivity}) {
    ref.read(taskDraftProvider.notifier).state = TaskDraft.empty();
    if (toActivity) {
      ref.read(customerTabIndexProvider.notifier).state = 1;
    } else {
      ref.read(customerTabIndexProvider.notifier).state = 0;
    }
    Navigator.of(context).pop(); // close the dialog
    context.go(Routes.customerHome);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl)),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const PhoWaYoke(state: PhoWaYokeState.success, size: 120),
            const SizedBox(height: AppSpacing.lg),
            Text("🎉 ${TaskPostingStrings.successTitle}",
                textAlign: TextAlign.center, style: theme.textTheme.headlineSmall),
            const SizedBox(height: AppSpacing.sm),
            Text(
              TaskPostingStrings.successMessage,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
            ),
            const SizedBox(height: AppSpacing.xl),
            LargeButton(
              label: TaskPostingStrings.successGoToActivity,
              gradient: AppColors.purpleGradient,
              onTap: () => _goHome(context, ref, toActivity: true),
            ),
            const SizedBox(height: AppSpacing.md),
            LargeButton(
              label: TaskPostingStrings.successGoHome,
              filled: false,
              outlineColor: AppColors.purple700,
              onTap: () => _goHome(context, ref, toActivity: false),
            ),
          ],
        ),
      ),
    );
  }
}
