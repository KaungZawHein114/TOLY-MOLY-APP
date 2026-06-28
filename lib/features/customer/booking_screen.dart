import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_strings.dart';
import '../../core/data/demo_data.dart';
import '../../core/routing/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/large_button.dart';
import '../../core/widgets/onboarding/speech_to_text_button.dart';
import 'task_request_state.dart';

/// Schedule Worker screen — a direct request to a specific worker, not an
/// hourly booking. Toly Moly is task-based, not time-based: no hours
/// stepper, no rate, no price anywhere on this screen. Category is locked
/// to the worker's own skill (you're scheduling them because they do that
/// job already). Submitting creates a [TaskRequest] (status always
/// "pending" this slice — no negotiation/matching yet).
class BookingScreen extends ConsumerStatefulWidget {
  final Worker worker;
  const BookingScreen({super.key, required this.worker});

  @override
  ConsumerState<BookingScreen> createState() => _BookingScreenState();
}

const List<String> _days = ["ယနေ့", "မနက်ဖြန်", "သောကြာ ၂၀", "စနေ ၂၁", "တနင်္ဂနွေ ၂၂"];
const List<String> _slots = ["မနက် ၉:၀၀", "မနက် ၁၁:၀၀", "နေ့လည် ၂:၀၀", "ညနေ ၄:၀၀"];

final _scheduleDateIndexProvider = StateProvider.autoDispose<int>((ref) => 0);
final _scheduleTimeIndexProvider = StateProvider.autoDispose<int>((ref) => 1);

class _BookingScreenState extends ConsumerState<BookingScreen> {
  final TextEditingController _townshipController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _townshipController.dispose();
    _addressController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _submit() {
    final township = _townshipController.text.trim();
    final address = _addressController.text.trim();
    final description = _descriptionController.text.trim();
    setState(() {
      _error = (township.isEmpty || address.isEmpty || description.isEmpty)
          ? AppStrings.scheduleRequiredError
          : null;
    });
    if (_error != null) return;

    final dateIdx = ref.read(_scheduleDateIndexProvider);
    final timeIdx = ref.read(_scheduleTimeIndexProvider);
    final request = TaskRequest(
      id: DateTime.now().millisecondsSinceEpoch,
      workerId: widget.worker.id,
      category: widget.worker.skill,
      township: township,
      address: address,
      date: DateTime.now(),
      timeSlot: "${_days[dateIdx]} ${_slots[timeIdx]}",
      description: description,
      createdAt: DateTime.now(),
    );
    ref.read(postedTaskRequestsProvider.notifier).state = [
      ...ref.read(postedTaskRequestsProvider),
      request,
    ];
    _showConfirmation(context, worker: widget.worker);
  }

  void _showConfirmation(BuildContext context, {required Worker worker}) {
    showDialog<void>(
      context: context,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl)),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_rounded, color: AppColors.success, size: 44),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(AppStrings.taskRequestSentTitle, style: theme.textTheme.titleLarge),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  AppStrings.taskRequestSentMessage,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.xl),
                LargeButton(
                  label: "ပြီးပါပြီ",
                  onTap: () {
                    Navigator.of(ctx).pop();
                    context.go(Routes.customerHome);
                  },
                ),
                const SizedBox(height: AppSpacing.sm),
                TextButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    context.push(Routes.chatbot);
                  },
                  child: const Text("အလုပ်သမားထံ စာပို့မည်"),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final worker = widget.worker;
    final dateIdx = ref.watch(_scheduleDateIndexProvider);
    final timeIdx = ref.watch(_scheduleTimeIndexProvider);

    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.scheduleWorkerTitle)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        children: [
          _WorkerStrip(worker: worker),
          const SizedBox(height: AppSpacing.xl + 2),
          Text(AppStrings.scheduleCategoryLabel, style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm + 2),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.purple100,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Text(worker.skill, style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.purple700)),
          ),
          const SizedBox(height: AppSpacing.xl + 2),
          Text(AppStrings.scheduleLocationLabel, style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm + 2),
          TextField(
            controller: _townshipController,
            decoration: InputDecoration(
              hintText: AppStrings.scheduleTownshipPlaceholder,
              contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.md, horizontal: AppSpacing.md),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm + 2),
          TextField(
            controller: _addressController,
            decoration: InputDecoration(
              hintText: AppStrings.scheduleAddressPlaceholder,
              contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.md, horizontal: AppSpacing.md),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl + 2),
          Text(AppStrings.scheduleDateLabel, style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm + 2),
          _OptionWrap(
            options: _days,
            selectedIndex: dateIdx,
            onSelect: (i) => ref.read(_scheduleDateIndexProvider.notifier).state = i,
          ),
          const SizedBox(height: AppSpacing.xl + 2),
          Text(AppStrings.scheduleTimeLabel, style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm + 2),
          _OptionWrap(
            options: _slots,
            selectedIndex: timeIdx,
            onSelect: (i) => ref.read(_scheduleTimeIndexProvider.notifier).state = i,
          ),
          const SizedBox(height: AppSpacing.xl + 2),
          Text(AppStrings.scheduleDescriptionLabel, style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm + 2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: _descriptionController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: AppStrings.scheduleDescriptionPlaceholder,
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
                semanticPrompt: AppStrings.scheduleDescriptionPlaceholder,
                mockTranscript: "ရေယိုနေတယ်",
                onResult: (v) => setState(() => _descriptionController.text = v),
              ),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(_error!, style: theme.textTheme.bodySmall?.copyWith(color: AppColors.error)),
          ],
          const SizedBox(height: AppSpacing.xxl + 4),
          LargeButton(
            label: AppStrings.scheduleSubmitCta,
            icon: Icons.send,
            gradient: AppColors.purpleGradient,
            onTap: _submit,
          ),
        ],
      ),
    );
  }
}

class _WorkerStrip extends StatelessWidget {
  final Worker worker;
  const _WorkerStrip({required this.worker});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: const BoxDecoration(
            color: AppColors.purple100,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(worker.emoji, style: const TextStyle(fontSize: 26)),
        ),
        const SizedBox(width: AppSpacing.md),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(worker.name, style: theme.textTheme.titleMedium),
            Text("${worker.skill} • ⭐ ${worker.rating}",
                style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor)),
          ],
        ),
      ],
    );
  }
}

class _OptionWrap extends StatelessWidget {
  final List<String> options;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  const _OptionWrap({
    required this.options,
    required this.selectedIndex,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Wrap(
      spacing: AppSpacing.sm + 2,
      runSpacing: AppSpacing.sm + 2,
      children: [
        for (int i = 0; i < options.length; i++)
          ChoiceChip(
            label: Text(options[i]),
            selected: selectedIndex == i,
            onSelected: (_) => onSelect(i),
            selectedColor: AppColors.purple700,
            labelStyle: theme.textTheme.bodyMedium?.copyWith(
              color: selectedIndex == i ? AppColors.onBrand : null,
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    );
  }
}
