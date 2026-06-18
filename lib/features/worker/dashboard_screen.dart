import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/data/demo_data.dart';
import '../../core/routing/app_router.dart';
import '../../core/widgets/demo_card.dart';

// LOCAL UI STATE (Riverpod), declared in this screen file.
final availableToggleProvider = StateProvider<bool>((ref) => false);

class WorkerDashboardScreen extends ConsumerWidget {
  const WorkerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final available = ref.watch(availableToggleProvider);

    // Pending requests = the demo bookings that are not yet completed.
    final pending = bookings
        .where((b) => b.status == "Pending" || b.status == "Active")
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Worker Dashboard"),
        leading: IconButton(
          icon: const Icon(Icons.swap_horiz),
          tooltip: "Switch role",
          onPressed: () => context.go(Routes.role),
        ),
        actions: [
          IconButton(
            icon: const Text("💬", style: TextStyle(fontSize: 20)),
            onPressed: () => context.go(Routes.chatbot),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _AvailabilityToggle(
            available: available,
            onChanged: (v) =>
                ref.read(availableToggleProvider.notifier).state = v,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  emoji: "💰",
                  value: "45,000",
                  unit: AppStrings.currency,
                  label: AppStrings.todaysEarnings,
                  gradient: AppColors.tealGradient,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  emoji: "📋",
                  value: "${pending.length}",
                  unit: "new",
                  label: AppStrings.pendingRequests,
                  gradient: AppColors.orangeGradient,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _MiniStat(
                    label: "Rating", value: "4.9★", color: AppColors.star),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MiniStat(
                    label: "Jobs done", value: "128", color: AppColors.teal),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MiniStat(
                    label: "This week",
                    value: "210k",
                    color: AppColors.orange),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(AppStrings.pendingRequests,
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          if (!available)
            _OfflineHint()
          else
            ...pending.map((b) => _RequestCard(booking: b)),
        ],
      ),
    );
  }
}

class _AvailabilityToggle extends StatelessWidget {
  final bool available;
  final ValueChanged<bool> onChanged;
  const _AvailabilityToggle({required this.available, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        gradient: available ? AppColors.tealGradient : null,
        color: available ? null : Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        border: available
            ? null
            : Border.all(color: Theme.of(context).dividerColor),
        boxShadow: available
            ? [
                BoxShadow(
                  color: AppColors.teal.withValues(alpha: 0.35),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          Icon(
            available ? Icons.flash_on : Icons.flash_off,
            color: available ? Colors.white : Theme.of(context).hintColor,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.availableForBookings,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: available
                        ? Colors.white
                        : Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                Text(
                  available ? "You're online — jobs incoming" : "You're offline",
                  style: TextStyle(
                    color: available
                        ? Colors.white.withValues(alpha: 0.9)
                        : Theme.of(context).hintColor,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: available,
            onChanged: onChanged,
            activeColor: Colors.white,
            activeTrackColor: AppColors.tealDark,
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String emoji;
  final String value;
  final String unit;
  final String label;
  final Gradient gradient;
  const _StatCard({
    required this.emoji,
    required this.value,
    required this.unit,
    required this.label,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: gradient.colors.first.withValues(alpha: 0.3),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 26)),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(value,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w900)),
              const SizedBox(width: 4),
              Text(unit,
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 12)),
            ],
          ),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9), fontSize: 12)),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _MiniStat(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        children: [
          Text(value,
              style: theme.textTheme.titleMedium?.copyWith(
                  color: color, fontWeight: FontWeight.w900)),
          const SizedBox(height: 2),
          Text(label,
              style:
                  theme.textTheme.bodySmall?.copyWith(color: theme.hintColor)),
        ],
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  final Booking booking;
  const _RequestCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.orange.withValues(alpha: 0.15),
                  child: const Text("🧑"),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(booking.customerName,
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700)),
                      Text("${booking.skill} • ${booking.date}",
                          style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
                StatusBadge(status: booking.status),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Text("${booking.totalMmk} MMK",
                    style: theme.textTheme.titleMedium?.copyWith(
                        color: AppColors.orange,
                        fontWeight: FontWeight.w900)),
                const Spacer(),
                OutlinedButton(
                  onPressed: () => _toast(context, "Declined"),
                  child: const Text("Decline"),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  style: FilledButton.styleFrom(
                      backgroundColor: AppColors.teal),
                  onPressed: () => _toast(context, "Accepted ✓"),
                  child: const Text("Accept"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _toast(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 1)),
    );
  }
}

class _OfflineHint extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        children: [
          const Text("😴", style: TextStyle(fontSize: 36)),
          const SizedBox(height: 8),
          Text("Turn on \"Available for bookings\" to see requests",
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.hintColor)),
        ],
      ),
    );
  }
}
