import 'package:flutter/material.dart';

import '../../../core/constants/task_posting_strings.dart';
import '../../../core/data/demo_data.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/ai_service.dart';
import '../../../core/widgets/demo_card.dart' show TrustBadgePill;
import '../../../core/widgets/large_button.dart';
import '../../../core/widgets/mascot/mascot_state.dart';
import '../../../core/widgets/mascot/pho_wa_yoke.dart';
import '../../../core/widgets/voice_input_button.dart';

/// AI Tasker Finder surface (spec §4.3). A modal bottom sheet with three
/// steps:
///
///   1. **ask** — Pho Wa Yoke asks "ဘာအကူအညီ လိုအပ်ပါသလဲ?" and the client
///      types or speaks their problem.
///   2. **thinking** — ONE call to the classifier backend
///      ([AiService.classifyServiceCategory]) turns that description into a
///      service category. On any failure it silently falls back to the local
///      keyword matcher — the client never sees an error.
///   3. **results** — the category is searched LOCALLY against [candidates]
///      ([AiService.findTaskers]): up to five exact-category taskers ranked
///      nearest-first, then, only if that came up short, related-category
///      suggestions under their own clearly-separated heading. Every stat
///      shown is a real [Worker] field; nothing is model output.
///
/// The client picks one (prepare-and-confirm: the agent recommends, the human
/// chooses); nothing is auto-selected or submitted.
///
/// Opens via [showTaskerShortlist]; pops with the chosen worker id (or null).
class TaskerShortlistSheet extends StatefulWidget {
  /// Every tasker the finder may search — the full demo list, NOT the browse
  /// screen's filtered view: the AI decides the category itself, so a stale
  /// category filter must not silently narrow its answer.
  final List<Worker> candidates;

  const TaskerShortlistSheet({super.key, required this.candidates});

  @override
  State<TaskerShortlistSheet> createState() => _TaskerShortlistSheetState();
}

enum _FinderPhase { ask, thinking, results }

class _TaskerShortlistSheetState extends State<TaskerShortlistSheet> {
  static const int _maxResults = 5;

  final TextEditingController _controller = TextEditingController();
  late final Map<int, Worker> _byId = {for (final w in widget.candidates) w.id: w};

  _FinderPhase _phase = _FinderPhase.ask;
  String? _inputError;
  bool _listening = false;
  ServiceCategoryResult? _understood;
  TaskerShortlist _shortlist = const TaskerShortlist(primary: [], alternates: []);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _find() async {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      setState(() => _inputError = TaskPostingStrings.matchAskEmptyError);
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _inputError = null;
      _phase = _FinderPhase.thinking;
    });

    // One network call (category only), then a local search. If the backend is
    // unreachable, classifyServiceCategory answers from the local keyword
    // matcher instead — same shape, no error state.
    final understood = await AiService.classifyServiceCategory(text);
    final shortlist = await AiService.findTaskers(
      category: understood.category,
      candidates: widget.candidates,
      limit: _maxResults,
    );
    if (!mounted) return;
    setState(() {
      _understood = understood;
      _shortlist = shortlist;
      _phase = _FinderPhase.results;
    });
  }

  void _askAgain() {
    setState(() {
      _phase = _FinderPhase.ask;
      _inputError = null;
      _controller.selection =
          TextSelection(baseOffset: 0, extentOffset: _controller.text.length);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
                IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: TaskPostingStrings.discardDraftCancel,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Flexible(child: _body(theme)),
          ],
        ),
      ),
    );
  }

  Widget _body(ThemeData theme) {
    switch (_phase) {
      case _FinderPhase.ask:
        return _ask(theme);
      case _FinderPhase.thinking:
        return _thinking(theme);
      case _FinderPhase.results:
        return _results(theme);
    }
  }

  // ── Step 1: what do you need help with? ───────────────────────────────────
  Widget _ask(ThemeData theme) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const PhoWaYoke(state: PhoWaYokeState.pointing, size: 64),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(
                      header: true,
                      child: Text(
                        TaskPostingStrings.matchAskTitle,
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      TaskPostingStrings.matchAskHint,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _controller,
            autofocus: false,
            minLines: 2,
            maxLines: 4,
            textInputAction: TextInputAction.done,
            onChanged: (_) {
              if (_inputError != null) setState(() => _inputError = null);
            },
            onSubmitted: (_) => _find(),
            decoration: InputDecoration(
              labelText: TaskPostingStrings.matchAskFieldLabel,
              errorText: _inputError,
              filled: true,
              fillColor: theme.cardColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          // Speech-to-text: writing is optional — the client can just talk.
          Row(
            children: [
              Semantics(
                label: TaskPostingStrings.matchSpeakServicePrompt,
                button: true,
                child: VoiceInputButton(
                  large: false,
                  localeCandidates: const ['my_MM', 'my-MM', 'my'],
                  onListeningChanged: (v) => setState(() => _listening = v),
                  onPartialResult: (text) => _controller.text = text,
                  onFinalResult: (text) {
                    _controller.text = text;
                    if (_inputError != null) {
                      setState(() => _inputError = null);
                    }
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  _listening
                      ? TaskPostingStrings.matchThinkingHint
                      : TaskPostingStrings.matchSpeakServicePrompt,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          LargeButton(
            label: TaskPostingStrings.matchAskSubmit,
            icon: Icons.auto_awesome,
            gradient: AppColors.indigoGradient,
            onTap: _find,
          ),
        ],
      ),
    );
  }

  // ── Step 2: one classify call + the local search ──────────────────────────
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

  // ── Step 3: results ───────────────────────────────────────────────────────
  Widget _results(ThemeData theme) {
    final understood = _understood;
    if (_shortlist.isEmpty) {
      return SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: AppSpacing.lg),
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
            const SizedBox(height: AppSpacing.md),
            TextButton.icon(
              onPressed: _askAgain,
              icon: const Icon(Icons.refresh),
              label: const Text(TaskPostingStrings.matchAskAgain),
            ),
          ],
        ),
      );
    }

    // Low confidence covers both a hesitant model answer and the offline
    // keyword fallback (which always reports 0) — in both cases we say so
    // plainly and invite a correction rather than pretending to be sure.
    final unsure = understood == null || understood.confidence < 0.5;

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
          if (understood != null) ...[
            const SizedBox(height: AppSpacing.sm),
            // The correction affordance sits HERE, next to the detected
            // category — a wrong reading is spotted at the top, and fixing it
            // must not mean scrolling past five cards first.
            _UnderstoodPanel(result: understood, onAskAgain: _askAgain),
          ],
          if (unsure) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              TaskPostingStrings.matchLowConfidenceNote,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: AppColors.textSecondary),
            ),
          ],
          if (understood?.source == AiSource.demo) ...[
            const SizedBox(height: AppSpacing.xxs),
            Text(
              TaskPostingStrings.matchOfflineNote,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: AppColors.textSecondary),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          for (final match in _shortlist.primary)
            if (_byId[match.workerId] != null)
              _ShortlistCard(
                worker: _byId[match.workerId]!,
                reason: match.reason,
                onPick: () => Navigator.of(context).pop(match.workerId),
              ),
          // Related-category fill — ALWAYS under its own heading, never mixed
          // into the exact matches above.
          if (_shortlist.alternates.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            _AlternatesHeading(),
            const SizedBox(height: AppSpacing.md),
            for (final match in _shortlist.alternates)
              if (_byId[match.workerId] != null)
                _ShortlistCard(
                  worker: _byId[match.workerId]!,
                  reason: match.reason,
                  isAlternate: true,
                  onPick: () => Navigator.of(context).pop(match.workerId),
                ),
          ],
          Center(
            child: TextButton.icon(
              onPressed: _askAgain,
              icon: const Icon(Icons.refresh),
              label: const Text(TaskPostingStrings.matchAskAgain),
            ),
          ),
        ],
      ),
    );
  }
}

/// "Here is what I understood" — the client's own words plus the detected
/// service category, so a wrong reading is obvious at a glance and can be
/// corrected with one tap on "ထပ်မံ ရှာမည်".
class _UnderstoodPanel extends StatelessWidget {
  final ServiceCategoryResult result;
  final VoidCallback onAskAgain;
  const _UnderstoodPanel({required this.result, required this.onAskAgain});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.indigo100,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (result.problem.isNotEmpty) ...[
                  Text(
                    '${TaskPostingStrings.matchUnderstoodPrefix} ${result.problem}',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: AppColors.indigo700),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                ],
                Text(
                  '${TaskPostingStrings.matchCategoryPrefix} ${result.category}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.indigo700,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Semantics(
            label: TaskPostingStrings.matchAskAgain,
            button: true,
            child: IconButton(
              icon: const Icon(Icons.refresh, color: AppColors.indigo700),
              // IconButton's default 48x48 already meets the design system's
              // minimum touch target.
              tooltip: TaskPostingStrings.matchAskAgain,
              onPressed: onAskAgain,
            ),
          ),
        ],
      ),
    );
  }
}

/// The divider between exact-category matches and the related-category fill.
class _AlternatesHeading extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(color: AppColors.onboardingDivider),
        const SizedBox(height: AppSpacing.xs),
        Semantics(
          header: true,
          child: Text(
            TaskPostingStrings.matchAlternatesHeading,
            style: theme.textTheme.titleSmall,
          ),
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          TaskPostingStrings.matchAlternatesNote,
          style: theme.textTheme.bodySmall
              ?.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

/// One shortlist entry: the tasker's real stats, the templated reason, and a
/// "pick this one" confirm. [isAlternate] entries sit under the "you may also
/// consider" heading and carry a muted skill chip, so a related-category
/// suggestion can never be mistaken for an exact match.
class _ShortlistCard extends StatelessWidget {
  final Worker worker;
  final String reason;
  final bool isAlternate;
  final VoidCallback onPick;

  const _ShortlistCard({
    required this.worker,
    required this.reason,
    required this.onPick,
    this.isAlternate = false,
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
                decoration: BoxDecoration(
                  color: AppColors.purple100,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.person_rounded,
                  color: AppColors.purple700,
                  size: AppSizes.iconLg,
                ),
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
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.hintColor,
                          fontWeight:
                              isAlternate ? FontWeight.w700 : FontWeight.w400,
                        )),
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
          // "Why I picked them" — composed only from real Worker fields.
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.indigo100,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Text(
              reason,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: AppColors.indigo700),
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

/// Opens the AI Tasker Finder. Returns the chosen worker id, or null if the
/// user dismissed the sheet without picking.
Future<int?> showTaskerShortlist(
  BuildContext context, {
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
    builder: (_) => TaskerShortlistSheet(candidates: candidates),
  );
}
