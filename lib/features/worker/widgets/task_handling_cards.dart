import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/agent/agent_session.dart';
import '../../../core/constants/task_posting_strings.dart';
import '../../../core/data/demo_data.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/ai_service.dart';
import '../../../core/widgets/mascot/mascot_state.dart';
import '../../../core/widgets/mascot/pho_wa_yoke.dart';
import '../../../core/widgets/onboarding/read_aloud_button.dart';

/// Builds the task payload the Task-Handling functions expect, from a [Booking].
Map<String, dynamic> bookingTaskMap(Booking b) => {
      'category': b.skill,
      'skill': b.skill,
      'township': b.township,
      'timeSlot': b.timeSlot,
      'date': b.date,
      'budgetMmk': b.totalMmk,
    };

// ── Tasker per-task brief (spec §4.8) ───────────────────────────────────────
/// "What the client wants + suggested prep/tools", read aloud. Async on user
/// arrival (post-frame), never on the first frame. Also marks the agent's
/// Task-Handling mode.
class TaskerBriefCard extends ConsumerStatefulWidget {
  final Map<String, dynamic> task;
  const TaskerBriefCard({super.key, required this.task});

  @override
  ConsumerState<TaskerBriefCard> createState() => _TaskerBriefCardState();
}

class _TaskerBriefCardState extends ConsumerState<TaskerBriefCard> {
  bool _loading = true;
  TaskerBrief? _brief;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(agentModeProvider.notifier).state = AgentMode.taskHandling;
      _load();
    });
  }

  Future<void> _load() async {
    final brief = await AiService.briefTasker(task: widget.task);
    if (!mounted) return;
    setState(() {
      _brief = brief;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_loading) {
      return _ThinkingRow(message: TaskPostingStrings.briefThinking);
    }
    final brief = _brief!;
    final readAloud =
        '${brief.summary}. ${brief.suggestions.join('. ')}';

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
              const PhoWaYoke(
                  state: PhoWaYokeState.pointing, size: 40, decorative: true),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(TaskPostingStrings.briefTitle,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(color: AppColors.indigo700)),
              ),
              ReadAloudButton(textToRead: readAloud, compact: true),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(TaskPostingStrings.briefWhatClientWants,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: AppSpacing.xxs),
          Text(brief.summary, style: theme.textTheme.bodyMedium),
          if (brief.suggestions.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Text(TaskPostingStrings.briefPrepTitle,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: AppSpacing.xxs),
            for (final s in brief.suggestions)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xxs),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• '),
                    Expanded(
                        child: Text(s, style: theme.textTheme.bodyMedium)),
                  ],
                ),
              ),
          ],
          if (brief.source == AiSource.mock) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(TaskPostingStrings.aiOfflineBadge,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: AppColors.textSecondary)),
          ],
        ],
      ),
    );
  }
}

// ── Gentle tasker reminder (spec §4.8) ──────────────────────────────────────
/// A soft, dismissible reminder to do the task in its time window. Non-blocking:
/// it's just a card the tasker can close.
class TaskerReminderBanner extends StatefulWidget {
  final String timeSlot;
  const TaskerReminderBanner({super.key, required this.timeSlot});

  @override
  State<TaskerReminderBanner> createState() => _TaskerReminderBannerState();
}

class _TaskerReminderBannerState extends State<TaskerReminderBanner> {
  bool _visible = true;

  @override
  Widget build(BuildContext context) {
    if (!_visible) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.alarm, color: AppColors.warning),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(TaskPostingStrings.reminderTitle,
                    style: theme.textTheme.titleSmall),
                const SizedBox(height: AppSpacing.xxs),
                Text(TaskPostingStrings.reminderBody(widget.timeSlot),
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: AppColors.textSecondary)),
              ],
            ),
          ),
          Semantics(
            label: TaskPostingStrings.stalePostDismiss,
            button: true,
            child: IconButton(
              icon: const Icon(Icons.close, size: AppSizes.iconMd),
              onPressed: () => setState(() => _visible = false),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Completion summary + suggested tier (spec §4.4 Phase 3) ─────────────────
/// Summarizes a completed task and shows a SUGGESTED tier move. The suggestion
/// is clearly labelled: transparent rules + the client rating decide the real
/// tier, never the model.
class CompletionSummaryCard extends ConsumerStatefulWidget {
  final Map<String, dynamic> task;
  final Map<String, dynamic> timing;
  final Map<String, dynamic> review;
  const CompletionSummaryCard({
    super.key,
    required this.task,
    this.timing = const {},
    this.review = const {},
  });

  @override
  ConsumerState<CompletionSummaryCard> createState() =>
      _CompletionSummaryCardState();
}

class _CompletionSummaryCardState extends ConsumerState<CompletionSummaryCard> {
  bool _loading = true;
  CompletionSummary? _summary;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final summary = await AiService.summarizeCompletion(
      task: widget.task,
      timing: widget.timing,
      review: widget.review,
    );
    if (!mounted) return;
    setState(() {
      _summary = summary;
      _loading = false;
    });
  }

  ({String label, Color color}) _tierChip(int delta) {
    if (delta > 0) {
      return (label: TaskPostingStrings.tierSuggestUp, color: AppColors.success);
    }
    if (delta < 0) {
      return (label: TaskPostingStrings.tierSuggestDown, color: AppColors.warning);
    }
    return (label: TaskPostingStrings.tierSuggestSame, color: AppColors.indigo700);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_loading) {
      return _ThinkingRow(message: TaskPostingStrings.completionThinking);
    }
    final s = _summary!;
    final chip = _tierChip(s.suggestedTierDelta);
    final readAloud = '${s.summary}. ${s.rationale}';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const PhoWaYoke(
                  state: PhoWaYokeState.success, size: 44, decorative: true),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(TaskPostingStrings.completionTitle,
                    style: theme.textTheme.titleMedium),
              ),
              ReadAloudButton(textToRead: readAloud, compact: true),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(s.summary, style: theme.textTheme.bodyMedium),
          const SizedBox(height: AppSpacing.md),
          Text(TaskPostingStrings.completionSuggestedTierTitle,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: AppSpacing.xs),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.xs),
            decoration: BoxDecoration(
              color: chip.color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Text(chip.label,
                style: theme.textTheme.labelLarge
                    ?.copyWith(color: chip.color, fontWeight: FontWeight.bold)),
          ),
          if (s.rationale.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(s.rationale, style: theme.textTheme.bodyMedium),
          ],
          const SizedBox(height: AppSpacing.sm),
          // The hard rule made visible: AI suggests, rules + rating decide.
          Text(TaskPostingStrings.tierSuggestNote,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

/// Shared small "Pho Wa Yoke is thinking" row for the async task-handling cards.
class _ThinkingRow extends StatelessWidget {
  final String message;
  const _ThinkingRow({required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.indigo100,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        children: [
          const PhoWaYoke(
              state: PhoWaYokeState.thinking, size: 40, decorative: true),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Semantics(
              liveRegion: true,
              child: Text(message, style: theme.textTheme.bodyMedium),
            ),
          ),
        ],
      ),
    );
  }
}
