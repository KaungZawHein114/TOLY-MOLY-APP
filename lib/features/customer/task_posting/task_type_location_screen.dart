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
import '../../../core/widgets/onboarding/onboarding_selection_card.dart';
import '../../onboarding/onboarding_models.dart';
import 'task_posting_bottom_bar.dart';
import 'task_posting_models.dart';
import 'task_posting_state.dart';

/// Step 2 of 7: Task Type & Location. The location section only appears
/// when on-site is selected.
class TaskTypeLocationScreen extends ConsumerStatefulWidget {
  const TaskTypeLocationScreen({super.key});

  @override
  ConsumerState<TaskTypeLocationScreen> createState() => _TaskTypeLocationScreenState();
}

class _TaskTypeLocationScreenState extends ConsumerState<TaskTypeLocationScreen> {
  late final TextEditingController _townshipController;
  late final TextEditingController _addressController;
  String? _taskTypeError;
  String? _locationError;

  @override
  void initState() {
    super.initState();
    final draft = ref.read(taskDraftProvider);
    _townshipController = TextEditingController(text: draft.township);
    _addressController = TextEditingController(text: draft.address);
  }

  @override
  void dispose() {
    _townshipController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _selectType(TaskType type) {
    ref.read(taskDraftProvider.notifier).state =
        ref.read(taskDraftProvider).copyWith(taskType: type);
    setState(() => _taskTypeError = null);
  }

  void _continue() {
    final draft = ref.read(taskDraftProvider);
    final taskType = draft.taskType;
    final township = _townshipController.text.trim();
    final address = _addressController.text.trim();

    setState(() {
      _taskTypeError = taskType == null ? TaskPostingStrings.taskTypeRequiredError : null;
      _locationError = (taskType == TaskType.onSite && (township.isEmpty || address.isEmpty))
          ? TaskPostingStrings.locationRequiredError
          : null;
    });
    if (_taskTypeError != null || _locationError != null) return;

    ref.read(taskDraftProvider.notifier).state =
        draft.copyWith(township: township, address: address);
    context.push(Routes.postTaskDateTime);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final draft = ref.watch(taskDraftProvider);

    return OnboardingScaffold(
      progress: const OnboardingProgress(step: 2, totalSteps: 7),
      mascotState: PhoWaYokeState.pointing,
      mascotMessage: TaskPostingStrings.typeLocationTitle,
      title: TaskPostingStrings.typeLocationTitle,
      onBack: () => context.pop(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: OnboardingSelectionCard(
                  emoji: "📍",
                  label: TaskPostingStrings.taskTypeOnSiteLabel,
                  selected: draft.taskType == TaskType.onSite,
                  onTap: () => _selectType(TaskType.onSite),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: OnboardingSelectionCard(
                  emoji: "💻",
                  label: TaskPostingStrings.taskTypeRemoteLabel,
                  selected: draft.taskType == TaskType.remote,
                  onTap: () => _selectType(TaskType.remote),
                ),
              ),
            ],
          ),
          if (_taskTypeError != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(_taskTypeError!, style: theme.textTheme.bodySmall?.copyWith(color: AppColors.error)),
          ],
          if (draft.taskType == TaskType.onSite) ...[
            const SizedBox(height: AppSpacing.xl),
            Text(TaskPostingStrings.townshipLabel, style: theme.textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _townshipController,
              style: theme.textTheme.bodyLarge,
              decoration: InputDecoration(
                hintText: TaskPostingStrings.townshipPlaceholder,
                contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(TaskPostingStrings.addressLabel, style: theme.textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _addressController,
              style: theme.textTheme.bodyLarge,
              decoration: InputDecoration(
                hintText: TaskPostingStrings.addressPlaceholder,
                contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            if (_locationError != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(_locationError!,
                  style: theme.textTheme.bodySmall?.copyWith(color: AppColors.error)),
            ],
            const SizedBox(height: AppSpacing.lg),
            LargeButton(
              label: TaskPostingStrings.mapPickerButton,
              icon: Icons.map_outlined,
              filled: false,
              outlineColor: AppColors.purple700,
              onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text(TaskPostingStrings.mapNotSupported)),
              ),
            ),
          ],
        ],
      ),
      bottomBar: TaskPostingBottomBar(
        onPrevious: () => context.pop(),
        onContinue: _continue,
      ),
    );
  }
}
