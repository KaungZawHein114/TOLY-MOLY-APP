import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/demo_data.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/large_button.dart';
import '../activity/activity_chat.dart';

// LOCAL UI STATE (Riverpod) co-located in the screen file as per architecture rules.
final activityTabProvider = StateProvider<int>((ref) => 0); // 0 = Messages, 1 = Bookings
// 0 = Task Marked (Active), 1 = Discussing, 2 = History (Completed)
final bookingFilterProvider = StateProvider<int>((ref) => 0);

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
            child: activeTab == 0 ? const ActivityMessagesView() : const ActivityBookingsView(),
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

/// Public: used by [ChatScreen] to render only the conversation list.
class ActivityMessagesView extends ConsumerWidget {
  const ActivityMessagesView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final phase = ref.watch(taskPhaseProvider);

    final (String chat1Status, Color chat1Color) = switch (phase) {
      TaskPhase.discussing => ('ဆွေးနွေးဆဲ', AppColors.indigo500),
      TaskPhase.confirmed => ('သဘောတူပြီး', AppColors.purple700),
      TaskPhase.marked => ('အလုပ်လက်ခံပြီး', AppColors.tealDark),
    };
    final chat1Snippet = switch (phase) {
      TaskPhase.discussing => 'မင်္ဂလာပါ။ သင့်အလုပ်ကို စိတ်ဝင်စားလို့ ဆက်သွယ်လိုက်တာပါ။',
      TaskPhase.confirmed => 'နှစ်ဦးသဘောတူပြီးပါပြီ။ Escrow ဖြင့် ဆက်လက်ဆောင်ရွက်ပါ။',
      TaskPhase.marked => 'အလုပ် လက်ခံပြီးပါပြီ။ အခြေအနေ အပ်ဒိတ်ကို စောင့်ပါ။',
    };

    return ListView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.xxl),
      children: [
        const _SafetyNoticeCard(),
        const SizedBox(height: AppSpacing.lg),
        // Chat 1 — the lifecycle task's discussion thread.
        _ChatTile(
          name: kDiscussionTaskerName,
          emoji: kTaskerEmoji,
          statusLabel: chat1Status,
          statusColor: chat1Color,
          snippet: chat1Snippet,
          time: 'ယခု',
          isUnread: phase == TaskPhase.discussing,
          onTap: () => openDiscussionChat(
            context,
            role: ActivityRole.client,
            counterpartName: kDiscussionTaskerName,
            counterpartEmoji: kTaskerEmoji,
          ),
        ),
        // Chat 2 — a separate, already-confirmed task in progress.
        _ChatTile(
          name: kProgressTaskerName,
          emoji: kTaskerEmoji,
          statusLabel: 'အလုပ်ဆောင်ရွက်ဆဲ',
          statusColor: AppColors.tealDark,
          snippet: 'အလုပ် အတည်ဖြစ်ပြီးပါပြီ။ ထွက်ခွာချိန် ရောက်ရင် အသိပေးပါမယ်။',
          time: 'မနက်က',
          isUnread: false,
          onTap: () => openProgressChat(
            context,
            role: ActivityRole.client,
            counterpartName: kProgressTaskerName,
            counterpartEmoji: kTaskerEmoji,
            fixedTask: kProgressDemoTask,
          ),
        ),
      ],
    );
  }
}

class _SafetyNoticeCard extends StatelessWidget {
  const _SafetyNoticeCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.blue100,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.blue300.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.shield_outlined, color: AppColors.purple500),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'လုံခြုံရေး သတိပေးချက်',
                  style: theme.textTheme.titleMedium?.copyWith(color: AppColors.purple700),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  'သင့်လုံခြုံရေးနှင့် refund အာမခံရန် ငွေပေးချေမှုအားလုံးကို Tolymoly အက်ပ်အတွင်း Escrow စနစ်မှသာ ပြုလုပ်ပါ။',
                  style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatTile extends StatelessWidget {
  final String name;
  final String emoji;
  final String statusLabel;
  final Color statusColor;
  final String snippet;
  final String time;
  final bool isUnread;
  final VoidCallback onTap;

  const _ChatTile({
    required this.name,
    required this.emoji,
    required this.statusLabel,
    required this.statusColor,
    required this.snippet,
    required this.time,
    required this.isUnread,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              CircleAvatar(
                radius: AppSpacing.xl,
                backgroundColor: AppColors.purple100,
                child: Text(emoji, style: theme.textTheme.titleLarge),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: theme.textTheme.titleMedium,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          time,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isUnread ? AppColors.purple500 : AppColors.textSecondary,
                            fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm, vertical: AppSpacing.xxs),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Text(
                        statusLabel,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      snippet,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isUnread ? AppColors.textPrimary : AppColors.textSecondary,
                        fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (isUnread) ...[
                const SizedBox(width: AppSpacing.xs),
                Container(
                  width: AppSpacing.sm,
                  height: AppSpacing.sm,
                  decoration: const BoxDecoration(color: AppColors.purple500, shape: BoxShape.circle),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Public: used by [PendingScreen] to render only the bookings list.
class ActivityBookingsView extends ConsumerWidget {
  const ActivityBookingsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filterIdx = ref.watch(bookingFilterProvider);
    final phase = ref.watch(taskPhaseProvider);
    final notifier = ref.read(bookingFilterProvider.notifier);
    final theme = Theme.of(context);

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
                _FilterChip(label: 'ဆွေးနွေးနေဆဲ', isSelected: filterIdx == 1, onTap: () => notifier.state = 1),
                const SizedBox(width: AppSpacing.sm),
                _FilterChip(label: 'မှတ်တမ်း', isSelected: filterIdx == 2, onTap: () => notifier.state = 2),
              ],
            ),
          ),
        ),
        Expanded(
          child: _bookingsBody(context, theme, filterIdx, phase),
        ),
      ],
    );
  }

  Widget _bookingsBody(BuildContext context, ThemeData theme, int filterIdx, TaskPhase phase) {
    if (filterIdx == 2) {
      final history = bookings.where((b) => b.status == 'Completed').toList();
      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xxl),
        itemCount: history.length,
        itemBuilder: (context, index) => _HistoryBookingCard(booking: history[index]),
      );
    }

    final bool liveHere = filterIdx == 0
        ? phase == TaskPhase.marked
        : phase == TaskPhase.discussing || phase == TaskPhase.confirmed;

    if (!liveHere) {
      return _EmptyState(
        message: filterIdx == 0
            ? 'လက်ရှိ လက်ခံထားသော အလုပ် မရှိသေးပါ။\nဆွေးနွေးမှု ပြီးပြီး Escrow ပေးချေပြီးမှ ဤနေရာတွင် ပေါ်လာပါမည်။'
            : 'ဆွေးနွေးနေဆဲ အလုပ် မရှိသေးပါ။',
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xxl),
      children: const [
        LiveTaskBookingCard(role: ActivityRole.client, filterIndex: 0),
        LiveTaskBookingCard(role: ActivityRole.client, filterIndex: 1),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;

  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.assignment_outlined, size: 48, color: AppColors.purple300),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
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

/// Completed bookings are read-only history: no messaging, just a receipt.
class _HistoryBookingCard extends StatelessWidget {
  final Booking booking;

  const _HistoryBookingCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Padding(
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
                          color: AppColors.lightBg,
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: Text(
                          'ပြီးဆုံးပြီး',
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        _bookingSkillLabel(booking.skill),
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${booking.workerName} • ${booking.date}',
                        style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.lightBg,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'ပေးချေပြီး',
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
            Row(
              children: [
                Expanded(
                  child: LargeButton(
                    label: 'ပြေစာ ကြည့်ရန်',
                    gradient: AppColors.purpleGradient,
                    onTap: () => showActivitySnack(context, 'ပြေစာ အသေးစိတ်ကို ဒီ MVP တွင် မဖွင့်ထားသေးပါ။'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                OutlinedButton.icon(
                  onPressed: () => showActivitySnack(context, 'အဆင့်သတ်မှတ်ခြင်းကို ဒီ MVP တွင် မဖွင့်ထားသေးပါ။'),
                  icon: const Icon(Icons.star_outline, size: AppSizes.iconSm),
                  label: const Text('အဆင့်ပေး'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
