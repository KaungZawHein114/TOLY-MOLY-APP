import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/data/demo_data.dart';
import '../../core/routing/app_router.dart';
import '../../core/widgets/large_button.dart';

// LOCAL UI STATE (Riverpod), declared in this screen file.
final bookingHoursProvider = StateProvider<int>((ref) => 3);
final bookingDateProvider = StateProvider<int>((ref) => 0); // index into _days
final bookingTimeProvider = StateProvider<int>((ref) => 1); // index into _slots

// Static demo options — no runtime date math needed for the demo.
const List<String> _days = ["Today", "Tomorrow", "Fri 20", "Sat 21", "Sun 22"];
const List<String> _slots = ["09:00 AM", "11:00 AM", "02:00 PM", "04:00 PM"];

class BookingScreen extends ConsumerWidget {
  final Worker worker;
  const BookingScreen({super.key, required this.worker});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final hours = ref.watch(bookingHoursProvider);
    final dateIdx = ref.watch(bookingDateProvider);
    final timeIdx = ref.watch(bookingTimeProvider);
    final total = hours * worker.hourlyRateMmk;

    return Scaffold(
      appBar: AppBar(title: const Text("Book a service")),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _WorkerStrip(worker: worker),
          const SizedBox(height: 22),
          _SectionTitle("Select date", theme),
          const SizedBox(height: 10),
          _OptionWrap(
            options: _days,
            selectedIndex: dateIdx,
            onSelect: (i) => ref.read(bookingDateProvider.notifier).state = i,
          ),
          const SizedBox(height: 22),
          _SectionTitle("Select time", theme),
          const SizedBox(height: 10),
          _OptionWrap(
            options: _slots,
            selectedIndex: timeIdx,
            onSelect: (i) => ref.read(bookingTimeProvider.notifier).state = i,
          ),
          const SizedBox(height: 22),
          _SectionTitle("How many hours?", theme),
          const SizedBox(height: 10),
          _HoursStepper(
            hours: hours,
            onChanged: (v) =>
                ref.read(bookingHoursProvider.notifier).state = v,
          ),
          const SizedBox(height: 22),
          _PriceCard(
            hours: hours,
            rate: worker.hourlyRateMmk,
            total: total,
          ),
          const SizedBox(height: 28),
          LargeButton(
            label: "${AppStrings.confirmBooking} • $total MMK",
            icon: Icons.check_circle,
            gradient: AppColors.orangeGradient,
            onTap: () => _showConfirmation(
              context,
              worker: worker,
              day: _days[dateIdx],
              time: _slots[timeIdx],
              hours: hours,
              total: total,
            ),
          ),
        ],
      ),
    );
  }

  // Instant modal — showDialog is framework navigation, not blocking loading.
  void _showConfirmation(
    BuildContext context, {
    required Worker worker,
    required String day,
    required String time,
    required int hours,
    required int total,
  }) {
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
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
                child: const Icon(Icons.check_rounded,
                    color: AppColors.success, size: 44),
              ),
              const SizedBox(height: 16),
              Text(
                AppStrings.bookingConfirmed,
                style: Theme.of(ctx)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              Text(
                "${worker.name} (${worker.skill}) is booked for "
                "$day at $time • $hours hrs.",
                textAlign: TextAlign.center,
                style: Theme.of(ctx).textTheme.bodyMedium,
              ),
              const SizedBox(height: 4),
              Text(
                "$total MMK",
                style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                      color: AppColors.orange,
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 20),
              LargeButton(
                label: "Done",
                onTap: () {
                  Navigator.of(ctx).pop();
                  context.go(Routes.customerHome);
                },
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  context.go(Routes.chatbot);
                },
                child: const Text("Message the worker"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  final ThemeData theme;
  const _SectionTitle(this.text, this.theme);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: theme.textTheme.titleMedium
            ?.copyWith(fontWeight: FontWeight.w800),
      );
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
          decoration: BoxDecoration(
            color: AppColors.teal.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(worker.emoji, style: const TextStyle(fontSize: 26)),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(worker.name,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800)),
            Text("${worker.skill} • ⭐ ${worker.rating}",
                style: theme.textTheme.bodySmall),
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
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (int i = 0; i < options.length; i++)
          ChoiceChip(
            label: Text(options[i]),
            selected: selectedIndex == i,
            onSelected: (_) => onSelect(i),
            selectedColor: AppColors.teal,
            labelStyle: TextStyle(
              color: selectedIndex == i ? Colors.white : null,
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    );
  }
}

class _HoursStepper extends StatelessWidget {
  final int hours;
  final ValueChanged<int> onChanged;
  const _HoursStepper({required this.hours, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: theme.dividerColor),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton.filledTonal(
            onPressed: hours > 1 ? () => onChanged(hours - 1) : null,
            icon: const Icon(Icons.remove),
          ),
          Text("$hours hours",
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w800)),
          IconButton.filledTonal(
            onPressed: hours < 8 ? () => onChanged(hours + 1) : null,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}

class _PriceCard extends StatelessWidget {
  final int hours;
  final int rate;
  final int total;
  const _PriceCard(
      {required this.hours, required this.rate, required this.total});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.teal.withValues(alpha: 0.10),
            AppColors.orange.withValues(alpha: 0.10),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _row(theme, "Hourly rate", "$rate MMK"),
          const SizedBox(height: 6),
          _row(theme, "Hours", "× $hours"),
          const Divider(height: 22),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Estimated total",
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800)),
              Text("$total MMK",
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: AppColors.orange,
                    fontWeight: FontWeight.w900,
                  )),
            ],
          ),
        ],
      ),
    );
  }

  Widget _row(ThemeData theme, String label, String value) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.bodyMedium),
          Text(value,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w700)),
        ],
      );
}
