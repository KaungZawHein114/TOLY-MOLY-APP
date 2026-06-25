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

/// Step 2 of 7: Task Location & Work Mode. On-site shows a township dropdown,
/// an address field and a map picker (current vs. different location). Remote
/// shows work method / completion / deliverable choices instead.
class TaskTypeLocationScreen extends ConsumerStatefulWidget {
  const TaskTypeLocationScreen({super.key});

  @override
  ConsumerState<TaskTypeLocationScreen> createState() =>
      _TaskTypeLocationScreenState();
}

class _TaskTypeLocationScreenState
    extends ConsumerState<TaskTypeLocationScreen> {
  late final TextEditingController _addressController;
  String? _taskTypeError;
  String? _locationError;

  @override
  void initState() {
    super.initState();
    _addressController =
        TextEditingController(text: ref.read(taskDraftProvider).address);
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  bool get _editMode =>
      GoRouterState.of(context).uri.queryParameters['edit'] == '1';

  TaskDraft get _draft => ref.read(taskDraftProvider);
  void _update(TaskDraft next) =>
      ref.read(taskDraftProvider.notifier).state = next;

  void _selectType(TaskType type) {
    _update(_draft.copyWith(taskType: type));
    setState(() {
      _taskTypeError = null;
      _locationError = null;
    });
  }

  void _selectTownship(String? value) {
    if (value == null) return;
    _update(_draft.copyWith(township: value));
    setState(() => _locationError = null);
  }

  Future<void> _openMapSheet() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: AppSpacing.md),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Text(TaskPostingStrings.mapSheetTitle,
                  style: Theme.of(ctx).textTheme.titleMedium),
            ),
            const SizedBox(height: AppSpacing.sm),
            ListTile(
              leading: const Icon(Icons.my_location, color: AppColors.purple700),
              title: const Text(TaskPostingStrings.mapUseCurrentLocation),
              subtitle: const Text(TaskPostingStrings.mapUseCurrentLocationSub),
              onTap: () => Navigator.of(ctx).pop("current"),
            ),
            ListTile(
              leading: const Icon(Icons.place_outlined, color: AppColors.purple700),
              title: const Text(TaskPostingStrings.mapPinDifferent),
              subtitle: const Text(TaskPostingStrings.mapPinDifferentSub),
              onTap: () => Navigator.of(ctx).pop("pin"),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
    if (!mounted || choice == null) return;
    if (choice == "current") {
      // Mock GPS: fill a plausible current township + address.
      _addressController.text = "လက်ရှိ တည်နေရာ (GPS)";
      _update(_draft.copyWith(
        township: TaskPostingStrings.yangonTownships.first,
        address: _addressController.text,
      ));
      setState(() => _locationError = null);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(TaskPostingStrings.mapCurrentLocationFilled)),
      );
    } else {
      // No real map in this demo — explain the placeholder.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(TaskPostingStrings.mapNotSupported)),
      );
    }
  }

  void _continue() {
    final draft = _draft;
    final address = _addressController.text.trim();
    setState(() {
      _taskTypeError = draft.taskType == null
          ? TaskPostingStrings.taskTypeRequiredError
          : null;
      if (draft.taskType == TaskType.onSite) {
        _locationError = (draft.township.isEmpty || address.isEmpty)
            ? TaskPostingStrings.locationRequiredError
            : null;
      } else if (draft.taskType == TaskType.remote) {
        _locationError = draft.remoteWorkMethod == null
            ? TaskPostingStrings.remoteMethodRequiredError
            : null;
      }
    });
    if (_taskTypeError != null || _locationError != null) return;

    _update(draft.copyWith(address: address));
    if (_editMode) {
      context.pop();
    } else {
      context.push(Routes.postTaskDateTime);
    }
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
            Text(_taskTypeError!,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: AppColors.error)),
          ],

          // ── On-site location ────────────────────────────────────────────
          if (draft.taskType == TaskType.onSite) ...[
            const SizedBox(height: AppSpacing.xl),
            Text(TaskPostingStrings.townshipLabel,
                style: theme.textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            _FieldShell(
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: draft.township.isEmpty ? null : draft.township,
                  hint: const Text(TaskPostingStrings.townshipHint),
                  items: [
                    for (final t in TaskPostingStrings.yangonTownships)
                      DropdownMenuItem(value: t, child: Text(t)),
                  ],
                  onChanged: _selectTownship,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(TaskPostingStrings.addressLabel,
                style: theme.textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _addressController,
              style: theme.textTheme.bodyLarge,
              onChanged: (_) {
                if (_locationError != null) {
                  setState(() => _locationError = null);
                }
              },
              decoration: InputDecoration(
                hintText: TaskPostingStrings.addressPlaceholder,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            if (_locationError != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(_locationError!,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: AppColors.error)),
            ],
            const SizedBox(height: AppSpacing.lg),
            LargeButton(
              label: TaskPostingStrings.mapPickerButton,
              icon: Icons.map_outlined,
              filled: false,
              outlineColor: AppColors.purple700,
              onTap: _openMapSheet,
            ),
          ],

          // ── Remote work mode ────────────────────────────────────────────
          if (draft.taskType == TaskType.remote) ...[
            const SizedBox(height: AppSpacing.xl),
            Text(TaskPostingStrings.remoteDetailsTitle,
                style: theme.textTheme.titleMedium),
            const SizedBox(height: AppSpacing.md),
            _DropdownField<RemoteWorkMethod>(
              label: TaskPostingStrings.remoteWorkMethodLabel,
              value: draft.remoteWorkMethod,
              items: RemoteWorkMethod.values,
              labelOf: (v) => v.label,
              onChanged: (v) {
                _update(draft.copyWith(remoteWorkMethod: v));
                setState(() => _locationError = null);
              },
            ),
            const SizedBox(height: AppSpacing.md),
            _DropdownField<RemoteCompletionStyle>(
              label: TaskPostingStrings.remoteCompletionLabel,
              value: draft.remoteCompletionStyle,
              items: RemoteCompletionStyle.values,
              labelOf: (v) => v.label,
              onChanged: (v) =>
                  _update(draft.copyWith(remoteCompletionStyle: v)),
            ),
            const SizedBox(height: AppSpacing.md),
            _DropdownField<RemoteDeliverable>(
              label: TaskPostingStrings.remoteDeliverableLabel,
              value: draft.remoteDeliverable,
              items: RemoteDeliverable.values,
              labelOf: (v) => v.label,
              onChanged: (v) => _update(draft.copyWith(remoteDeliverable: v)),
            ),
            if (_locationError != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(_locationError!,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: AppColors.error)),
            ],
          ],
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

/// Rounded filled container matching the flow's TextField look — used to wrap
/// dropdowns so they share the same surface/radius as the text inputs.
class _FieldShell extends StatelessWidget {
  final Widget child;
  const _FieldShell({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: Theme.of(context).inputDecorationTheme.fillColor ??
            AppColors.lightSurface,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: child,
    );
  }
}

/// A labeled dropdown for the remote work-mode choices.
class _DropdownField<T> extends StatelessWidget {
  final String label;
  final T? value;
  final List<T> items;
  final String Function(T) labelOf;
  final ValueChanged<T?> onChanged;

  const _DropdownField({
    required this.label,
    required this.value,
    required this.items,
    required this.labelOf,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.titleSmall),
        const SizedBox(height: AppSpacing.xs),
        _FieldShell(
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              isExpanded: true,
              value: value,
              hint: const Text(TaskPostingStrings.dropdownHint),
              items: [
                for (final item in items)
                  DropdownMenuItem(value: item, child: Text(labelOf(item))),
              ],
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
