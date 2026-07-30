import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/demo_data.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../activity/activity_chat.dart';
import 'task_execution_screen.dart';

// LOCAL UI STATE (Riverpod) co-located in the screen file as per architecture rules.
final activityTabProvider =
    StateProvider<int>((ref) => 0); // 0 = Discussion, 1 = Check-in/out

// The TASKER's two demo conversations (roles reversed vs the client page):
//   Chat 1 — Discussion (the tasker pressed "Interested", negotiating now).
//   Chat 2 — Task Progress (already agreed/confirmed, work in progress).
const String _discussionClientName = 'ဒေါ်ခင် (အိမ်ရှင်)';
const String _progressClientName = 'ကိုဇော် (အိမ်ရှင်)';
const String _clientEmoji = '🧑';

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
              borderRadius:
                  BorderRadius.vertical(bottom: Radius.circular(AppRadius.xl)),
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
                            icon: const Icon(Icons.notifications_none_outlined,
                                color: AppColors.onBrand),
                            onPressed: () => showActivitySnack(
                                context, 'အသိပေးချက်အသစ်များ မရှိသေးပါ။'),
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
                              border: Border.all(
                                  color: AppColors.purple700,
                                  width: AppSpacing.xxs),
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
            child: activeTab == 0
                ? const _MessagesView()
                : const _TaskerCheckInOutView(),
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
              label: 'Check In / Out',
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

  const _TabButton(
      {required this.label, required this.isActive, required this.onTap});

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
            color: isActive
                ? AppColors.lightSurface
                : AppColors.lightSurface.withValues(alpha: 0),
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
    final discussionEnded =
        ref.watch(taskPhaseProvider) != TaskPhase.discussing;

    final convos = [
      _ConvoData(
        name: _discussionClientName,
        emoji: _clientEmoji,
        jobCategory: 'ရေမော်တာ ပြုပြင်ခြင်း',
        statusLabel: discussionEnded ? 'ဆွေးနွေးပြီးဆုံး' : 'ဆွေးနွေးဆဲ',
        statusColor: discussionEnded ? AppColors.success : AppColors.indigo500,
        snippet: discussionEnded
            ? 'ဆွေးနွေးမှု ပြီးဆုံးပါပြီ။ အလုပ်ရှင်က Escrow ဆောင်ရွက်နေပါသည်။'
            : 'မေးခွန်း ၃ ခု ပို့ထားပြီး အလုပ်ရှင်ရဲ့ အဖြေကို စောင့်နေပါသည်။',
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
                      child:
                          Text(c.emoji, style: theme.textTheme.headlineSmall),
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
                              color: c.statusColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(AppRadius.sm),
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
                              style: theme.textTheme.bodySmall
                                  ?.copyWith(color: AppColors.textSecondary),
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

class _TaskerCheckInOutView extends StatelessWidget {
  const _TaskerCheckInOutView();

  @override
  Widget build(BuildContext context) {
    final activeBooking = bookings.firstWhere(
      (booking) => booking.status == 'Active',
      orElse: () => bookings.first,
    );

    return TaskExecutionScreen(
      booking: activeBooking,
      embedded: true,
    );
  }
}
