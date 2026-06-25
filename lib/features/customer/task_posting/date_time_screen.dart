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

/// Step 3 of 7: Date, Time & Urgent Task. The client picks an exact date/time;
/// the urgent option is a prominent, benefits-explaining card (extra fee, more
/// visibility, operational team follow-up) rather than an easy-to-miss tick.
class DateTimeScreen extends ConsumerStatefulWidget {
  const DateTimeScreen({super.key});

  @override
  ConsumerState<DateTimeScreen> createState() => _DateTimeScreenState();
}

class _DateTimeScreenState extends ConsumerState<DateTimeScreen> {
  String? _error;

  bool get _editMode =>
      GoRouterState.of(context).uri.queryParameters['edit'] == '1';

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
    final picked =
        await showTimePicker(context: context, initialTime: TimeOfDay.now());
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
    if (_editMode) {
      context.pop();
    } else {
      context.push(Routes.postTaskWorkersTier);
    }
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
            Text(_error!,
                style:
                    theme.textTheme.bodySmall?.copyWith(color: AppColors.error)),
          ],
          const SizedBox(height: AppSpacing.xl),
          _UrgentCard(urgent: draft.urgent, onChanged: _setUrgent),
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

/// Prominent, benefits-explaining urgent-task card with a switch, a benefits
/// list, the extra fee, and the operational-team note.
class _UrgentCard extends StatelessWidget {
  final bool urgent;
  final ValueChanged<bool> onChanged;

  const _UrgentCard({required this.urgent, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedContainer(
      duration: AppMotion.fast,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: urgent ? AppColors.guidanceSurfaceGradient : null,
        color: urgent ? null : AppColors.blue100,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: urgent ? AppColors.purple700 : AppColors.onboardingDivider,
          width: urgent ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text("⚡", style: TextStyle(fontSize: 22)),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(TaskPostingStrings.urgentToggleLabel,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(color: AppColors.brandPurple)),
              ),
              Switch(
                value: urgent,
                activeThumbColor: AppColors.purple700,
                onChanged: onChanged,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(TaskPostingStrings.urgentCardSubtitle,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: AppSpacing.md),
          Text(TaskPostingStrings.urgentBenefitsTitle,
              style: theme.textTheme.titleSmall
                  ?.copyWith(color: AppColors.brandPurple)),
          const SizedBox(height: AppSpacing.xs),
          ...[
            TaskPostingStrings.urgentBenefit1,
            TaskPostingStrings.urgentBenefit2,
            TaskPostingStrings.urgentBenefit3,
            TaskPostingStrings.urgentBenefit4,
          ].map((b) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xxs),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check_circle,
                        size: AppSizes.iconSm, color: AppColors.success),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(b, style: theme.textTheme.bodyMedium),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.lightSurface,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Row(
              children: [
                const Icon(Icons.payments_outlined,
                    size: AppSizes.iconMd, color: AppColors.warning),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(TaskPostingStrings.urgentFeeLabel,
                      style: theme.textTheme.bodyMedium),
                ),
                const SizedBox(width: AppSpacing.sm),
                Flexible(
                  child: Text(TaskPostingStrings.urgentFeeValue,
                      textAlign: TextAlign.right,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(color: AppColors.brandPurple)),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(TaskPostingStrings.urgentStaffNote,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
