import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/agent/agent_session.dart';
import '../../../core/constants/task_posting_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/ai_service.dart';
import '../../../core/widgets/mascot/mascot_state.dart';
import '../../../core/widgets/mascot/pho_wa_yoke.dart';
import '../../../core/widgets/onboarding/read_aloud_button.dart';

/// Gentle, dismissible "your post has waited a while" nudge (spec §4.4 Phase 1).
/// A COMPACT banner (so it never starves the surrounding list); the AI tips load
/// only when the client taps it open — no work happens on build, which keeps it
/// cheap even though the host tab is eagerly built. Non-blocking: the client can
/// dismiss it. Nothing on the post is auto-changed.
class StalePostNudge extends StatefulWidget {
  final Map<String, dynamic> task;
  final int ageHours;
  const StalePostNudge({super.key, required this.task, required this.ageHours});

  @override
  State<StalePostNudge> createState() => _StalePostNudgeState();
}

class _StalePostNudgeState extends State<StalePostNudge> {
  bool _dismissed = false;

  @override
  Widget build(BuildContext context) {
    if (_dismissed) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final radius = BorderRadius.circular(AppRadius.lg);

    return Material(
      color: Colors.transparent,
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius,
        onTap: () => showStaleTipsSheet(context,
            task: widget.task, ageHours: widget.ageHours),
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.indigo100,
            borderRadius: radius,
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                const PhoWaYoke(
                    state: PhoWaYokeState.pointing, size: 40, decorative: true),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(TaskPostingStrings.stalePostTitle,
                          style: theme.textTheme.titleSmall
                              ?.copyWith(color: AppColors.indigo700)),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(TaskPostingStrings.stalePostSubtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
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
                    onPressed: () => setState(() => _dismissed = true),
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

/// Opens the AI stale-post tips in a bottom sheet (loaded on open, never on the
/// host screen's build).
Future<void> showStaleTipsSheet(
  BuildContext context, {
  required Map<String, dynamic> task,
  required int ageHours,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
    ),
    constraints: BoxConstraints(
      maxHeight: MediaQuery.of(context).size.height * 0.8,
    ),
    builder: (_) => _StaleTipsSheet(task: task, ageHours: ageHours),
  );
}

class _StaleTipsSheet extends ConsumerStatefulWidget {
  final Map<String, dynamic> task;
  final int ageHours;
  const _StaleTipsSheet({required this.task, required this.ageHours});

  @override
  ConsumerState<_StaleTipsSheet> createState() => _StaleTipsSheetState();
}

class _StaleTipsSheetState extends ConsumerState<_StaleTipsSheet> {
  bool _loading = true;
  bool _flagged = false;
  TaskFixTips? _tips;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(agentModeProvider.notifier).state = AgentMode.taskHandling;
      _load();
    });
  }

  Future<void> _load() async {
    final tips = await AiService.suggestTaskFixes(
      task: widget.task,
      ageHours: widget.ageHours,
    );
    if (!mounted) return;
    setState(() {
      _tips = tips;
      _loading = false;
    });
  }

  void _flagToOps() {
    setState(() => _flagged = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(TaskPostingStrings.stalePostFlaggedMessage),
        duration: Duration(seconds: 3),
      ),
    );
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
                const PhoWaYoke(
                    state: PhoWaYokeState.pointing, size: 48, decorative: true),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(TaskPostingStrings.stalePostTipsTitle,
                      style: theme.textTheme.titleLarge),
                ),
                if (!_loading && _tips != null)
                  ReadAloudButton(
                      textToRead: _tips!.tips.join('. '), compact: true),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
                child: Center(
                  child: PhoWaYoke(state: PhoWaYokeState.thinking, size: 72),
                ),
              )
            else ...[
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final tip in _tips!.tips)
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('• '),
                              Expanded(
                                  child: Text(tip,
                                      style: theme.textTheme.bodyLarge)),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              if (_flagged)
                Row(
                  children: [
                    const Icon(Icons.check_circle,
                        color: AppColors.success, size: AppSizes.iconMd),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(TaskPostingStrings.stalePostFlaggedMessage,
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(color: AppColors.success)),
                    ),
                  ],
                )
              else
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _flagToOps,
                    icon: const Icon(Icons.support_agent, size: AppSizes.iconMd),
                    label: const Text(TaskPostingStrings.stalePostFlagButton),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
