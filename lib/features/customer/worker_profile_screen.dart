import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/data/demo_data.dart';
import '../../core/routing/app_router.dart';
import '../../core/widgets/large_button.dart';

/// Worker profile. The router guarantees a non-null Worker; if anything is off
/// it passes the hardcoded fallbackWorker, so this screen always renders.
class WorkerProfileScreen extends StatelessWidget {
  final Worker worker;
  const WorkerProfileScreen({super.key, required this.worker});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: AppColors.teal,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(gradient: AppColors.tealGradient),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 30),
                      Container(
                        width: 96,
                        height: 96,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(worker.emoji,
                            style: const TextStyle(fontSize: 48)),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        worker.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        worker.skill,
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Row(
                  children: [
                    _Stat(
                      icon: Icons.star,
                      iconColor: AppColors.star,
                      value: worker.rating.toString(),
                      label: "${worker.reviews} reviews",
                    ),
                    _Stat(
                      icon: Icons.location_on,
                      iconColor: AppColors.teal,
                      value: "${worker.distanceMiles} mi",
                      label: "away",
                    ),
                    _Stat(
                      icon: Icons.work_history,
                      iconColor: AppColors.orange,
                      value: worker.experience.split(' ').first,
                      label: "years exp.",
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _AvailabilityBanner(available: worker.isAvailableNow),
                const SizedBox(height: 20),
                Text("About",
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Text(worker.bio, style: theme.textTheme.bodyMedium),
                const SizedBox(height: 20),
                _RateRow(rate: worker.hourlyRateMmk),
                const SizedBox(height: 28),
                LargeButton(
                  label: "${AppStrings.bookNow} • ${worker.hourlyRateMmk} MMK/hr",
                  icon: Icons.calendar_month,
                  gradient: AppColors.orangeGradient,
                  onTap: () => context.go('${Routes.booking}/${worker.id}'),
                ),
                const SizedBox(height: 12),
                LargeButton(
                  label: "Ask the assistant",
                  icon: Icons.chat_bubble_outline,
                  filled: false,
                  onTap: () => context.go(Routes.chatbot),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;
  const _Stat({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 26),
          const SizedBox(height: 4),
          Text(value,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800)),
          Text(label,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.hintColor)),
        ],
      ),
    );
  }
}

class _AvailabilityBanner extends StatelessWidget {
  final bool available;
  const _AvailabilityBanner({required this.available});

  @override
  Widget build(BuildContext context) {
    final color = available ? AppColors.success : AppColors.orange;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(available ? Icons.check_circle : Icons.schedule, color: color),
          const SizedBox(width: 10),
          Text(
            available ? "Available now" : "Available later today",
            style: TextStyle(color: color, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _RateRow extends StatelessWidget {
  final int rate;
  const _RateRow({required this.rate});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        border: Border.all(color: theme.dividerColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Text("💰", style: TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          const Text("Hourly rate"),
          const Spacer(),
          Text("$rate MMK",
              style: theme.textTheme.titleMedium?.copyWith(
                color: AppColors.orange,
                fontWeight: FontWeight.w900,
              )),
        ],
      ),
    );
  }
}
