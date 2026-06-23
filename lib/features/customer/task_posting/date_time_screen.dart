import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/task_posting_strings.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/large_button.dart';
import '../../../core/widgets/mascot/mascot_state.dart';
import '../../../core/widgets/onboarding/onboarding_scaffold.dart';
import '../../onboarding/onboarding_models.dart';
import 'task_posting_bottom_bar.dart';
import 'task_posting_state.dart';

/// Step 3 of 7: Date & Time. The client always picks an exact date/time via
/// the native pickers; "Urgent" is an independent checkbox (extra pay, more
/// visible/prioritized to workers) rather than a shortcut that overrides
/// the chosen time.
class DateTimeScreen extends ConsumerStatefulWidget {
  const DateTimeScreen({super.key});

  @override
  ConsumerState<DateTimeScreen> createState() => _DateTimeScreenState();
}

class _DateTimeScreenState extends ConsumerState<DateTimeScreen> {
  String? _error;

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: ref.read(taskDraftProvider).date ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 90)),
    );
    if (picked != null) {
      ref.read(taskDraftProvider.notifier).state =
          ref.read(taskDraftProvider).copyWith(date: picked);
      setState(() => _error = null);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (picked != null) {
      final formatted =
          "${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}";
      ref.read(taskDraftProvider.notifier).state =
          ref.read(taskDraftProvider).copyWith(timeSlot: formatted);
      setState(() => _error = null);
    }
  }

  void _setUrgent(bool value) {
    ref.read(taskDraftProvider.notifier).state =
        ref.read(taskDraftProvider).copyWith(urgent: value);
  }

  void _continue() {
    final draft = ref.read(taskDraftProvider);
    setState(() {
      _error = draft.date == null
          ? TaskPostingStrings.dateRequiredError
          : draft.timeSlot == null
              ? TaskPostingStrings.timeRequiredError
              : null;
    });
    if (_error != null) return;
    context.push(Routes.postTaskWorkersTier);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final draft = ref.watch(taskDraftProvider);

    return OnboardingScaffold(
      progress: const OnboardingProgress(step: 3, totalSteps: 7),
      mascotState: PhoWaYokeState.pointing,
      mascotMessage: TaskPostingStrings.dateTimeTitle,
      title: TaskPostingStrings.dateTimeTitle,
      onBack: () => context.pop(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LargeButton(
            label: draft.date == null
                ? TaskPostingStrings.pickDateButton
                : "${draft.date!.year}-${draft.date!.month.toString().padLeft(2, '0')}-${draft.date!.day.toString().padLeft(2, '0')}",
            icon: Icons.calendar_month,
            filled: false,
            outlineColor: AppColors.purple700,
            onTap: _pickDate,
          ),
          const SizedBox(height: AppSpacing.lg),
          LargeButton(
            label: draft.timeSlot ?? TaskPostingStrings.customTimeButton,
            icon: Icons.access_time,
            filled: false,
            outlineColor: AppColors.purple700,
            onTap: _pickTime,
          ),
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(_error!, style: theme.textTheme.bodySmall?.copyWith(color: AppColors.error)),
          ],
          const SizedBox(height: AppSpacing.xl),
          Material(
            color: AppColors.blue100,
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadius.md),
              onTap: () => _setUrgent(!draft.urgent),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md, vertical: AppSpacing.md),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Checkbox(
                      value: draft.urgent,
                      activeColor: AppColors.purple700,
                      onChanged: (v) => _setUrgent(v ?? false),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text("⚡", style: TextStyle(fontSize: 18)),
                              const SizedBox(width: AppSpacing.xs),
                              Flexible(
                                child: Text(TaskPostingStrings.urgentToggleLabel,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.titleMedium),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.xxs),
                          Text(
                            TaskPostingStrings.urgentExplanation,
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomBar: TaskPostingBottomBar(
        onPrevious: () => context.pop(),
        onContinue: _continue,
      ),
    );
  }
}
