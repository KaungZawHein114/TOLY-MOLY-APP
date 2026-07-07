import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/task_posting_strings.dart';
import '../../../core/data/demo_data.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/ai_mock.dart' show categorizeJob;
import '../../../core/utils/ai_service.dart';
import '../../../core/widgets/demo_card.dart' show TrustBadgePill;
import '../../../core/widgets/large_button.dart';
import '../../../core/widgets/mascot/mascot_state.dart';
import '../../../core/widgets/mascot/pho_wa_yoke.dart';
import '../../../core/widgets/onboarding/read_aloud_button.dart';
import '../../voice_task_posting/widgets/voice_input_button.dart';

/// Tasker-Finding mode surface (spec §4.3). A modal bottom sheet that shows
/// Pho Wa Yoke `thinking → success` while [AiService.matchTaskers] ranks the
/// [candidates] the screen pre-filtered, then displays a shortlist of ≤3 real
/// taskers — each with its REAL stats plus a short spoken reason. The user
/// picks one (prepare-and-confirm: the agent recommends, the human chooses);
/// nothing is auto-selected or submitted.
///
/// Opens via [showTaskerShortlist]; pops with the chosen worker id (or null).
class TaskerShortlistSheet extends ConsumerStatefulWidget {
  /// The task context — its `category` key drives skill-match scoring/reasons.
  final Map<String, dynamic> task;

  /// The candidate taskers, already pre-filtered by the screen's active filters.
  final List<Worker> candidates;

  const TaskerShortlistSheet({
    super.key,
    required this.task,
    required this.candidates,
  });

  @override
  ConsumerState<TaskerShortlistSheet> createState() =>
      _TaskerShortlistSheetState();
}

class _TaskerShortlistSheetState extends ConsumerState<TaskerShortlistSheet> {
  late Map<String, dynamic> _task = Map<String, dynamic>.of(widget.task);
  late final Map<int, Worker> _byId = {
    for (final w in widget.candidates) w.id: w,
  };

  bool _loading = true;
  List<TaskerMatch> _matches = const [];

  @override
  void initState() {
    super.initState();
    // First frame renders the synchronous "thinking" state; the live call is
    // kicked off after it, so the frame never depends on async state.
    WidgetsBinding.instance.addPostFrameCallback((_) => _runMatch());
  }

  Future<void> _runMatch() async {
    setState(() => _loading = true);
    final matches = await AiService.matchTaskers(
      task: _task,
      candidates: widget.candidates,
    );
    if (!mounted) return;
    setState(() {
      _matches = matches;
      _loading = false;
    });
  }

  // Mic: the user (re)states the service by voice; we map it to a known skill
  // and re-rank. Burmese locale first, matching the app's accessibility rules.
  void _onSpoken(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    final skill = categorizeJob(trimmed);
    setState(() => _task = {..._task, 'category': skill});
    _runMatch();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('🎙️ $skill'), duration: const Duration(seconds: 2)),
    );
  }

  String get _readAloudSummary {
    if (_matches.isEmpty) return TaskPostingStrings.matchEmptyMessage;
    final buffer = StringBuffer('${TaskPostingStrings.matchReadyMessage} ');
    for (var i = 0; i < _matches.length; i++) {
      final w = _byId[_matches[i].workerId];
      if (w == null) continue;
      buffer.write('${i + 1}။ ${w.name}၊ ${_matches[i].reason} ');
    }
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isOffline =
        _matches.isNotEmpty && _matches.first.source == AiSource.mock;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          top: AppSpacing.md,
          bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Grab handle.
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.onboardingDivider,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: Text(
                    TaskPostingStrings.matchSheetTitle,
                    style: theme.textTheme.titleLarge,
                  ),
                ),
                // Read-aloud control — speaks the whole shortlist + reasons.
                ReadAloudButton(textToRead: _readAloudSummary, compact: true),
                const SizedBox(width: AppSpacing.xs),
                Semantics(
                  label: TaskPostingStrings.matchSpeakServicePrompt,
                  button: true,
                  child: VoiceInputButton(
                    large: false,
                    localeCandidates: const ['my_MM', 'my-MM', 'my'],
                    onPartialResult: (_) {},
                    onFinalResult: _onSpoken,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: TaskPostingStrings.discardDraftCancel,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Flexible(child: _loading ? _thinking(theme) : _results(theme, isOffline)),
          ],
        ),
      ),
    );
  }

  Widget _thinking(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const PhoWaYoke(state: PhoWaYokeState.thinking, size: 96),
          const SizedBox(height: AppSpacing.md),
          Semantics(
            liveRegion: true,
            child: Text(
              TaskPostingStrings.matchThinking,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            TaskPostingStrings.matchThinkingHint,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _results(ThemeData theme, bool isOffline) {
    if (_matches.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const PhoWaYoke(state: PhoWaYokeState.idle, size: 88),
            const SizedBox(height: AppSpacing.md),
            Text(TaskPostingStrings.matchEmptyTitle,
                style: theme.textTheme.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            Text(
              TaskPostingStrings.matchEmptyMessage,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const PhoWaYoke(state: PhoWaYokeState.success, size: 56),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  TaskPostingStrings.matchReadyMessage,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          if (isOffline) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              TaskPostingStrings.matchOfflineNote,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: AppColors.textSecondary),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          for (final match in _matches)
            if (_byId[match.workerId] != null)
              _ShortlistCard(
                worker: _byId[match.workerId]!,
                reason: match.reason,
                onPick: () => Navigator.of(context).pop(match.workerId),
              ),
        ],
      ),
    );
  }
}

/// One shortlist entry: the tasker's real stats, the spoken reason (with its own
/// read-aloud), and a "pick this one" confirm.
class _ShortlistCard extends StatelessWidget {
  final Worker worker;
  final String reason;
  final VoidCallback onPick;

  const _ShortlistCard({
    required this.worker,
    required this.reason,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final distanceKm = (worker.distanceMiles * 1.609).toStringAsFixed(1);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowMd,
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: AppSizes.avatar,
                height: AppSizes.avatar,
                decoration: const BoxDecoration(
                  color: AppColors.purple100,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(worker.emoji, style: const TextStyle(fontSize: 26)),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(worker.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleMedium),
                        ),
                        const Icon(Icons.star,
                            color: AppColors.star, size: AppSizes.iconSm),
                        const SizedBox(width: AppSpacing.xxs),
                        Text(worker.rating.toString(),
                            style: theme.textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(worker.skill,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: theme.hintColor)),
                    const SizedBox(height: AppSpacing.sm),
                    TrustBadgePill(tier: worker.currentTier),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Icon(Icons.location_on, size: 14, color: theme.hintColor),
              const SizedBox(width: AppSpacing.xxs),
              Text("$distanceKm km",
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.hintColor)),
              const SizedBox(width: AppSpacing.md),
              Flexible(
                child: Text("${worker.completedTasks} Tasks",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.hintColor)),
              ),
              if (worker.isVerified) ...[
                const SizedBox(width: AppSpacing.xs),
                const Icon(Icons.verified, size: 14, color: AppColors.success),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          // Spoken "why I picked them" — reason bubble + its own read-aloud.
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.indigo100,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    reason,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: AppColors.indigo700),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                ReadAloudButton(textToRead: '${worker.name}။ $reason', compact: true),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          LargeButton(
            label: TaskPostingStrings.matchPickButton,
            icon: Icons.person_pin_circle_rounded,
            gradient: AppColors.purpleGradient,
            onTap: onPick,
          ),
        ],
      ),
    );
  }
}

/// Opens the Tasker-Finding shortlist. Returns the chosen worker id, or null if
/// the user dismissed the sheet without picking.
Future<int?> showTaskerShortlist(
  BuildContext context, {
  required Map<String, dynamic> task,
  required List<Worker> candidates,
}) {
  return showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
    ),
    constraints: BoxConstraints(
      maxHeight: MediaQuery.of(context).size.height * 0.88,
    ),
    builder: (_) => TaskerShortlistSheet(task: task, candidates: candidates),
  );
}
