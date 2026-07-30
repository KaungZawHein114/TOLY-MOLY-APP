import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';
import '../../core/data/demo_data.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

enum ActivityOverviewRole { client, tasker }

class ActivityOverviewScreen extends StatelessWidget {
  final ActivityOverviewRole role;

  const ActivityOverviewScreen({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ongoing = _itemsForStatus(role, 'Active');
    final pending = _itemsForStatus(role, 'Pending');
    final history = _itemsForStatus(role, 'Completed');

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.md,
                ),
                decoration: const BoxDecoration(
                  color: AppColors.purple700,
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(AppRadius.xl),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.onBrand.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                          child: const Icon(
                            Icons.assignment_outlined,
                            color: AppColors.onBrand,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppStrings.activityTabLabel,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  color: AppColors.onBrand,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xxs),
                              Text(
                                role == ActivityOverviewRole.client
                                    ? 'Tasker အခြေအနေများကို ကြည့်ရန်'
                                    : 'Client အလုပ်အခြေအနေများကို ကြည့်ရန်',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: AppColors.onBrandMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.xxs),
                      decoration: BoxDecoration(
                        color: AppColors.purple900,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                      ),
                      child: TabBar(
                        indicator: BoxDecoration(
                          color: AppColors.lightSurface,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        indicatorSize: TabBarIndicatorSize.tab,
                        dividerColor: AppColors.lightSurface.withValues(alpha: 0),
                        labelColor: AppColors.purple700,
                        unselectedLabelColor: AppColors.onBrandMuted,
                        labelStyle: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                        tabs: const [
                          Tab(text: 'လုပ်ဆောင်နေဆဲ'),
                          Tab(text: 'စောင့်ဆိုင်းနေသည်'),
                          Tab(text: 'မှတ်တမ်း'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _ActivityList(
                      title: 'လက်ရှိလုပ်နေသော အလုပ်များ',
                      items: ongoing,
                    ),
                    _ActivityList(
                      title: 'အတည်ပြုရန် စောင့်နေသော အလုပ်များ',
                      items: pending,
                    ),
                    _ActivityList(
                      title: 'ပြီးဆုံးခဲ့သော အလုပ်မှတ်တမ်း',
                      items: history,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

List<_ActivityItem> _itemsForStatus(ActivityOverviewRole role, String status) {
  final filtered = bookings.where((booking) => booking.status == status);
  return [
    for (final booking in filtered)
      _ActivityItem(
        title: _skillLabel(booking.skill),
        personLabel: role == ActivityOverviewRole.client
            ? booking.workerName
            : booking.customerName,
        personRole: role == ActivityOverviewRole.client ? 'Tasker' : 'Client',
        location: booking.township,
        time: '${booking.date} • ${booking.timeSlot}',
        amount: '${booking.totalMmk} ${AppStrings.currency}',
        statusLabel: _statusLabel(status),
        status: status,
      ),
  ];
}

String _statusLabel(String status) {
  return switch (status) {
    'Active' => 'လုပ်ဆောင်နေဆဲ',
    'Pending' => 'စောင့်ဆိုင်းနေသည်',
    'Completed' => 'ပြီးဆုံးပြီး',
    _ => status,
  };
}

String _skillLabel(String skill) {
  return switch (skill) {
    'Electrician' => 'လျှပ်စစ်ပြုပြင်ခြင်း',
    'AC Technician' => 'အဲကွန်းပြုပြင်ခြင်း',
    'Plumber' => 'ရေပိုက်ပြုပြင်ခြင်း',
    'Cleaner' => 'သန့်ရှင်းရေး',
    'Carpenter' => 'လက်သမားအလုပ်',
    _ => skill,
  };
}

class _ActivityItem {
  final String title;
  final String personLabel;
  final String personRole;
  final String location;
  final String time;
  final String amount;
  final String statusLabel;
  final String status;

  const _ActivityItem({
    required this.title,
    required this.personLabel,
    required this.personRole,
    required this.location,
    required this.time,
    required this.amount,
    required this.statusLabel,
    required this.status,
  });
}

class _ActivityList extends StatelessWidget {
  final String title;
  final List<_ActivityItem> items;

  const _ActivityList({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        for (final item in items) ...[
          _ActivityCard(item: item),
          const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final _ActivityItem item;

  const _ActivityCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _statusColor(item.status);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowSm,
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(_statusIcon(item.status), color: color),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      '${item.personRole}: ${item.personLabel}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              _StatusPill(label: item.statusLabel, color: color),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _MetaRow(icon: Icons.location_on_outlined, label: item.location),
          const SizedBox(height: AppSpacing.xs),
          _MetaRow(icon: Icons.schedule_outlined, label: item.time),
          const SizedBox(height: AppSpacing.xs),
          _MetaRow(icon: Icons.payments_outlined, label: item.amount),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(icon, size: AppSizes.iconSm, color: AppColors.textSecondary),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

Color _statusColor(String status) {
  return switch (status) {
    'Active' => AppColors.indigo700,
    'Pending' => AppColors.warning,
    'Completed' => AppColors.success,
    _ => AppColors.textSecondary,
  };
}

IconData _statusIcon(String status) {
  return switch (status) {
    'Active' => Icons.play_circle_outline,
    'Pending' => Icons.hourglass_top_outlined,
    'Completed' => Icons.check_circle_outline,
    _ => Icons.assignment_outlined,
  };
}
