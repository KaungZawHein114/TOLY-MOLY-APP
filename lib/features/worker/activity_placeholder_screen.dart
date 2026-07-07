import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/demo_data.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/large_button.dart';
import '../activity/activity_chat.dart';

// LOCAL UI STATE (Riverpod) co-located in the screen file as per architecture rules.
final activityTabProvider = StateProvider<int>((ref) => 0); // 0 = Messages, 1 = Bookings
// 0 = Task Marked (Active), 1 = Interested/Discussing (Pending), 2 = History (Completed)
final bookingFilterProvider = StateProvider<int>((ref) => 0);

// The TASKER's two demo conversations (roles reversed vs the client page):
//   Chat 1 — Discussion (the tasker pressed "Interested", negotiating now).
//   Chat 2 — Task Progress (already agreed/confirmed, work in progress).
const String _discussionClientName = 'ဒေါ်ခင် (အိမ်ရှင်)';
const String _progressClientName = 'ကိုဇော် (အိမ်ရှင်)';
const String _clientEmoji = '🧑';

String _bookingStatusLabel(String status) {
  switch (status) {
    case 'Active':
      return 'အလုပ်လက်ခံပြီး';
    case 'Pending':
      return 'စိတ်ဝင်စားထား';
    case 'Completed':
      return 'ပြီးဆုံးပြီး';
    default:
      return status;
  }
}

String _bookingSkillLabel(String skill) {
  switch (skill) {
    case 'Electrician':
      return 'လျှပ်စစ်ပြုပြင်ခြင်း';
    case 'AC Technician':
      return 'အဲကွန်းပြုပြင်ခြင်း';
    case 'Plumber':
      return 'ရေပိုက်ပြုပြင်ခြင်း';
    case 'Cleaner':
      return 'သန့်ရှင်းရေး';
    case 'Carpenter':
      return 'ပန်းရန်/လက်သမား';
    default:
      return skill;
  }
}

class ActivityScreen extends ConsumerWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeTab = ref.watch(activityTabProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              56,
              AppSpacing.xl,
              AppSpacing.xl,
            ),
            decoration: const BoxDecoration(
              color: AppColors.purple700,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(AppRadius.xl)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'လှုပ်ရှားမှုများ',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: AppColors.onBrand,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Stack(
                      children: [
                        Semantics(
                          label: 'အသိပေးချက်များ',
                          button: true,
                          child: IconButton(
                            icon: const Icon(Icons.notifications_none_outlined, color: AppColors.onBrand),
                            onPressed: () => showActivitySnack(context, 'အသိပေးချက်အသစ်များ မရှိသေးပါ။'),
                          ),
                        ),
                        Positioned(
                          top: AppSpacing.sm,
                          right: AppSpacing.sm,
                          child: Container(
                            width: AppSpacing.sm,
                            height: AppSpacing.sm,
                            decoration: BoxDecoration(
                              color: AppColors.error,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.purple700, width: AppSpacing.xxs),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                const _SegmentedControl(),
              ],
            ),
          ),
          Expanded(
            child: activeTab == 0 ? const _MessagesView() : const _BookingsView(),
          ),
        ],
      ),
    );
  }
}

class _SegmentedControl extends ConsumerWidget {
  const _SegmentedControl();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeTab = ref.watch(activityTabProvider);
    final notifier = ref.read(activityTabProvider.notifier);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xxs),
      decoration: BoxDecoration(
        color: AppColors.purple900,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        children: [
          Expanded(
            child: _TabButton(
              label: 'စာတိုများ',
              isActive: activeTab == 0,
              onTap: () => notifier.state = 0,
            ),
          ),
          Expanded(
            child: _TabButton(
              label: 'ဘွတ်ကင်များ',
              isActive: activeTab == 1,
              onTap: () => notifier.state = 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _TabButton({required this.label, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      selected: isActive,
      button: true,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: AppSpacing.xl * 2),
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          decoration: BoxDecoration(
            color: isActive ? AppColors.lightSurface : AppColors.lightSurface.withValues(alpha: 0),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: isActive ? AppColors.purple700 : AppColors.onBrandMuted,
            ),
          ),
        ),
      ),
    );
  }
}

class _MessagesView extends ConsumerWidget {
  const _MessagesView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final discussionEnded = ref.watch(taskPhaseProvider) != TaskPhase.discussing;

    final convos = [
      _ConvoData(
        name: _discussionClientName,
        emoji: _clientEmoji,
        jobCategory: 'လျှပ်စစ်ပြုပြင်ခြင်း',
        statusLabel: discussionEnded ? 'ဆွေးနွေးပြီးဆုံး' : 'ဆွေးနွေးဆဲ',
        statusColor: discussionEnded ? AppColors.success : AppColors.indigo500,
        snippet: discussionEnded
            ? 'ဆွေးနွေးမှု ပြီးဆုံးပါပြီ။ အလုပ်ရှင်က Escrow ဆောင်ရွက်နေပါသည်။'
            : 'မင်္ဂလာပါ။ ကျွန်တော့်အလုပ်ကို စိတ်ဝင်စားပေးလို့ ကျေးဇူးတင်ပါတယ်။',
        time: 'ယခု',
        isUnread: !discussionEnded,
        isOnline: true,
        onTap: () => openDiscussionChat(
          context,
          role: ActivityRole.tasker,
          counterpartName: _discussionClientName,
          counterpartEmoji: _clientEmoji,
        ),
      ),
      _ConvoData(
        name: _progressClientName,
        emoji: _clientEmoji,
        jobCategory: 'ရေပိုက်ပြုပြင်ခြင်း',
        statusLabel: 'အလုပ်ဆောင်ရွက်ဆဲ',
        statusColor: AppColors.tealDark,
        snippet: 'အလုပ် အတည်ပြုပြီးပါပြီ။ အဆင်သင့်ဖြစ်ရင် အသိပေးပါမယ်။',
        time: 'မနက်က',
        isUnread: false,
        isOnline: false,
        onTap: () => openProgressChat(
          context,
          role: ActivityRole.tasker,
          counterpartName: _progressClientName,
          counterpartEmoji: _clientEmoji,
        ),
      ),
    ];

    return Column(
      children: [
        // Compact safety banner (matches client chat screen style)
        Container(
          width: double.infinity,
          color: AppColors.blue100,
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
          child: Row(
            children: [
              const Icon(Icons.shield_outlined,
                  color: AppColors.indigo700, size: 16),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'ငွေပေးချေမှုအားလုံးကို Escrow စနစ်မှသာ ပြုလုပ်ပါ။',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.indigo700,
                        fontWeight: FontWeight.w500,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xxl),
            itemCount: convos.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, i) => _WorkerConvoCard(convo: convos[i]),
          ),
        ),
      ],
    );
  }
}

// ── Lightweight data holder ──────────────────────────────────────────────────

class _ConvoData {
  final String name;
  final String emoji;
  final String jobCategory;
  final String statusLabel;
  final Color statusColor;
  final String snippet;
  final String time;
  final bool isUnread;
  final bool isOnline;
  final VoidCallback onTap;

  const _ConvoData({
    required this.name,
    required this.emoji,
    required this.jobCategory,
    required this.statusLabel,
    required this.statusColor,
    required this.snippet,
    required this.time,
    required this.isUnread,
    required this.isOnline,
    required this.onTap,
  });
}

// ── Modern conversation card (mirrors client ChatScreen _ConversationCard) ───

class _WorkerConvoCard extends StatelessWidget {
  final _ConvoData convo;
  const _WorkerConvoCard({required this.convo});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = convo;
    final radius = BorderRadius.circular(AppRadius.lg);

    return Semantics(
      button: true,
      label: '${c.name} — ${c.snippet}',
      child: Material(
        color: c.isUnread ? AppColors.purple100 : AppColors.lightSurface,
        borderRadius: radius,
        elevation: c.isUnread ? 2 : 1,
        shadowColor: AppColors.shadowSm,
        child: InkWell(
          onTap: c.onTap,
          borderRadius: radius,
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg, vertical: AppSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar + online dot
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: AppColors.purple100,
                      child: Text(c.emoji,
                          style: theme.textTheme.headlineSmall),
                    ),
                    if (c.isOnline)
                      Positioned(
                        right: 1,
                        bottom: 1,
                        child: Container(
                          width: 13,
                          height: 13,
                          decoration: BoxDecoration(
                            color: AppColors.success,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: c.isUnread
                                  ? AppColors.purple100
                                  : AppColors.lightSurface,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: AppSpacing.md),

                // Text content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name + timestamp
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              c.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: c.isUnread
                                    ? FontWeight.w700
                                    : FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            c.time,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: c.isUnread
                                  ? AppColors.purple700
                                  : AppColors.textSecondary,
                              fontWeight: c.isUnread
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xxs),

                      // Status pill + job category
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm,
                                vertical: AppSpacing.xxs),
                            decoration: BoxDecoration(
                              color:
                                  c.statusColor.withValues(alpha: 0.12),
                              borderRadius:
                                  BorderRadius.circular(AppRadius.sm),
                            ),
                            child: Text(
                              c.statusLabel,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: c.statusColor,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Flexible(
                            child: Text(
                              '• ${c.jobCategory}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                  color: AppColors.textSecondary),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),

                      // Snippet + unread dot
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              c.snippet,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: c.isUnread
                                    ? AppColors.textPrimary
                                    : AppColors.textSecondary,
                                fontWeight: c.isUnread
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                          if (c.isUnread) ...[
                            const SizedBox(width: AppSpacing.sm),
                            Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(
                                color: AppColors.purple700,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
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


class _BookingsView extends ConsumerWidget {
  const _BookingsView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filterIdx = ref.watch(bookingFilterProvider);
    final notifier = ref.read(bookingFilterProvider.notifier);
    final theme = Theme.of(context);

    final filteredBookings = bookings.where((booking) {
      if (filterIdx == 0) return booking.status == 'Active';
      if (filterIdx == 1) return booking.status == 'Pending';
      return booking.status == 'Completed';
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          child: SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              children: [
                _FilterChip(label: 'အလုပ်လက်ခံပြီး', isSelected: filterIdx == 0, onTap: () => notifier.state = 0),
                const SizedBox(width: AppSpacing.sm),
                _FilterChip(label: 'စိတ်ဝင်စားထား', isSelected: filterIdx == 1, onTap: () => notifier.state = 1),
                const SizedBox(width: AppSpacing.sm),
                _FilterChip(label: 'မှတ်တမ်း', isSelected: filterIdx == 2, onTap: () => notifier.state = 2),
              ],
            ),
          ),
        ),
        Expanded(
          child: filteredBookings.isEmpty
              ? Center(child: Text('မှတ်တမ်းမတွေ့ပါ', style: theme.textTheme.bodyMedium))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xxl),
                  itemCount: filteredBookings.length,
                  itemBuilder: (context, index) {
                    final booking = filteredBookings[index];
                    return _BookingTaskCard(booking: booking, filterType: filterIdx);
                  },
                ),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minWidth: AppSpacing.xl * 2),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.purple700 : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: isSelected ? null : Border.all(color: AppColors.onboardingDivider),
        ),
        child: Center(
          child: Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: isSelected ? AppColors.onBrand : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _BookingTaskCard extends StatelessWidget {
  final Booking booking;
  // 0 = Task Marked, 1 = Interested/Discussing, 2 = History
  final int filterType;

  const _BookingTaskCard({required this.booking, required this.filterType});

  Color get _statusBackgroundColor {
    if (filterType == 0) return AppColors.blue100;
    if (filterType == 1) return AppColors.indigo100;
    return AppColors.lightBg;
  }

  Color get _statusTextColor {
    if (filterType == 0) return AppColors.tealDark;
    if (filterType == 1) return AppColors.indigo700;
    return AppColors.textSecondary;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Stack(
        children: [
          if (filterType == 0)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(height: AppSpacing.xxs, color: AppColors.teal),
            ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xxs),
                            decoration: BoxDecoration(
                              color: _statusBackgroundColor,
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                            ),
                            child: Text(
                              _bookingStatusLabel(booking.status),
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: _statusTextColor,
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            _bookingSkillLabel(booking.skill),
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '${booking.date} • ${booking.township}',
                            style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: AppColors.blue100,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'ဝင်ငွေ',
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.purple500,
                            ),
                          ),
                          Text(
                            '${booking.totalMmk ~/ 1000}K MMK',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.orangeDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                // Client row. Task Marked → Chat 2 (progress) icon. Interested →
                // Discussion chat icon. History → no messaging at all.
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.lightBg,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(radius: AppSpacing.md, child: Text('🧑', style: theme.textTheme.bodyLarge)),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              booking.customerName,
                              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'အလုပ်ရှင် • ${booking.timeSlot}',
                              style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      if (filterType == 0)
                        IconButton(
                          tooltip: 'အလုပ်အခြေအနေ စာတိုပို့ရန်',
                          icon: const Icon(Icons.chat_bubble_outline, size: AppSpacing.lg, color: AppColors.purple700),
                          onPressed: () => openProgressChat(
                            context,
                            role: ActivityRole.tasker,
                            counterpartName: booking.customerName,
                            counterpartEmoji: '🧑',
                          ),
                        ),
                      if (filterType == 1)
                        IconButton(
                          tooltip: 'ဆွေးနွေးရန်',
                          icon: const Icon(Icons.forum_outlined, size: AppSpacing.lg, color: AppColors.indigo700),
                          onPressed: () => openDiscussionChat(
                            context,
                            role: ActivityRole.tasker,
                            counterpartName: booking.customerName,
                            counterpartEmoji: '🧑',
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                // Primary action per state. NO "Edit Task" anywhere — that is a
                // client-only capability.
                if (filterType == 1)
                  LargeButton(
                    label: 'ဆွေးနွေးမှု ဆက်လုပ်ရန်',
                    icon: Icons.forum_outlined,
                    gradient: AppColors.purpleGradient,
                    onTap: () => openDiscussionChat(
                      context,
                      role: ActivityRole.tasker,
                      counterpartName: booking.customerName,
                      counterpartEmoji: '🧑',
                    ),
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        child: LargeButton(
                          label: 'Task အသေးစိတ်',
                          gradient: AppColors.purpleGradient,
                          onTap: () => showActivitySnack(
                            context,
                            'Task အသေးစိတ်ကို ဒီ MVP တွင် မဖွင့်ထားသေးပါ။',
                          ),
                        ),
                      ),
                      if (filterType == 0) ...[
                        const SizedBox(width: AppSpacing.sm),
                        Container(
                          width: AppSpacing.xl * 2,
                          height: AppSpacing.xl * 2,
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                          ),
                          child: IconButton(
                            tooltip: 'အရေးပေါ်အကူအညီ',
                            icon: const Icon(Icons.warning_amber_rounded, color: AppColors.error),
                            onPressed: () => showActivitySnack(context, 'အရေးပေါ်အကူအညီအတွက် Support ကို ဆက်သွယ်ပါ။'),
                          ),
                        ),
                      ],
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
