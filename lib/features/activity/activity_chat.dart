import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/large_button.dart';
import '../../core/widgets/modern_service_card.dart';
import 'discussion/discussion_chat_page.dart';

// ---------------------------------------------------------------------------
// SHARED ACTIVITY CHAT ENGINE (demo)
//
// The whole Activity demo centers on ONE task that flows through its real
// lifecycle and stays consistent on every surface:
//
//   Discussion (Phase 2)  →  End Discussion  →  Escrow  →  Task Marked (Phase 3)
//
// A single [DiscussionTask] + [taskPhaseProvider] are the one source of truth.
// An accepted budget / time / date / location change rewrites that task, so the
// new value replaces the old one in the discussion summary, the booking card,
// the task-progress chat, and the escrow page — never a stale value left behind.
//
// Phase-1 safe: no backend, no async business logic — every counterpart reply
// is a synchronous scripted string.
// ---------------------------------------------------------------------------

/// Who is using the surface. Flips the scripts so the same engine serves the
/// client page (client asks, tasker answers) and the tasker page (tasker asks,
/// client answers).
enum ActivityRole { client, tasker }

/// Lifecycle of the single demo task.
enum TaskPhase { discussing, confirmed, marked }

// Demo identities for the one lifecycle task (Chat 1 → booking → escrow).
const String kDiscussionTaskerName = 'ကိုအောင် (ရေမော်တာ)';
const String kDiscussionClientName = 'ဒေါ်ခင် (အိမ်ရှင်)';
// A separate, already-in-progress task used only by the standalone Chat 2 tile.
const String kProgressTaskerName = 'ကိုမင်း (ရေပိုက်)';
const String kProgressClientName = 'ကိုဇော် (အိမ်ရှင်)';
const String kTaskerEmoji = '👨‍🔧';
const String kClientEmoji = '🧑';

void showActivitySnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

String formatMmk(int mmk) {
  final s = mmk.toString();
  final buf = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
    buf.write(s[i]);
  }
  return '${buf.toString()} ကျပ်';
}

// ---------------------------------------------------------------------------
// Shared, live task details (single source of truth for the demo).
// ---------------------------------------------------------------------------

@immutable
class DiscussionTask {
  final String skillLabel;
  final int budgetMmk;
  final String date;
  final String timeSlot;
  final String location;

  /// Urgent jobs carry a surcharge and are flagged in the discussion header, so
  /// neither side can later claim they didn't know why the price differs.
  final bool isUrgent;

  const DiscussionTask({
    required this.skillLabel,
    required this.budgetMmk,
    required this.date,
    required this.timeSlot,
    required this.location,
    this.isUrgent = false,
  });

  DiscussionTask copyWith({
    int? budgetMmk,
    String? date,
    String? timeSlot,
    String? location,
    bool? isUrgent,
  }) {
    return DiscussionTask(
      skillLabel: skillLabel,
      budgetMmk: budgetMmk ?? this.budgetMmk,
      date: date ?? this.date,
      timeSlot: timeSlot ?? this.timeSlot,
      location: location ?? this.location,
      isUrgent: isUrgent ?? this.isUrgent,
    );
  }
}

/// The one lifecycle task, shared by the discussion chat, the booking card,
/// the progress chat, and the escrow page.
final discussionTaskProvider = StateProvider<DiscussionTask>(
  (ref) => const DiscussionTask(
    skillLabel: 'ရေမော်တာ ပြုပြင်ခြင်း',
    budgetMmk: 45000,
    date: 'ဇွန် ၂၈ ရက်',
    timeSlot: 'နေ့လည် ၂:၀၀',
    location: 'ကမာရွတ်မြို့နယ်',
    isUrgent: true,
  ),
);

/// Drives the whole flow: discussing → confirmed (both ended) → marked (escrow paid).
final taskPhaseProvider = StateProvider<TaskPhase>((ref) => TaskPhase.discussing);

/// The fixed, already-confirmed task behind the standalone Chat 2 tile (a
/// different job from the lifecycle task, so it has its own static details).
const DiscussionTask kProgressDemoTask = DiscussionTask(
  skillLabel: 'ရေပိုက်ပြုပြင်ခြင်း',
  budgetMmk: 38000,
  date: 'ဇွန် ၂၈ ရက်',
  timeSlot: 'နံနက် ၁၀:၀၀',
  location: 'ကမာရွတ်မြို့နယ်',
);

// ---------------------------------------------------------------------------
// AI free-text screening (client-side demo only).
// ---------------------------------------------------------------------------

/// Returns a human reason if the message should be blocked, else null.
String? aiBlockReason(String text) {
  final normalized = text.replaceAll(RegExp(r'[\s\-]'), '');
  // Phone numbers (Myanmar 09… or any 7+ digit run).
  if (RegExp(r'09\d{6,}').hasMatch(normalized) ||
      RegExp(r'\d{7,}').hasMatch(normalized)) {
    return 'ဖုန်းနံပါတ်';
  }
  // Social media handles / off-platform messaging apps.
  if (RegExp(r'@\w+').hasMatch(text) ||
      RegExp(r'(facebook|messenger|viber|telegram|whatsapp|tiktok|instagram|\big\b|\bfb\b|wechat|line)',
              caseSensitive: false)
          .hasMatch(text)) {
    return 'ပြင်ပ ဆက်သွယ်ရေး အကောင့်';
  }
  // Requests to pay outside the platform.
  if (RegExp(
          r'(kpay|kbz|wave|ayapay|aya pay|အပြင်ကနေ|ပြင်ပ.*ငွေ|ငွေ.*လွှဲ|ဘဏ်.*လွှဲ|cash)',
          caseSensitive: false)
      .hasMatch(text)) {
    return 'အက်ပ်ပြင်ပ ငွေပေးချေမှု';
  }
  return null;
}

// ---------------------------------------------------------------------------
// Public openers
// ---------------------------------------------------------------------------

/// Opens the pre-payment discussion (Phase 2).
///
/// Same signature as always so every caller — chat lists, activity list,
/// booking card, worker jobs — is untouched. Both openers now land on the one
/// conversation page in `discussion/`; there is no second chat system.
void openDiscussionChat(
  BuildContext context, {
  required ActivityRole role,
  required String counterpartName,
  required String counterpartEmoji,
}) {
  openDiscussionChatPage(
    context,
    role: role,
    counterpartName: counterpartName,
    counterpartEmoji: counterpartEmoji,
  );
}

/// Opens the post-payment conversation (Phase 3) for an agreed task: same
/// page, same bubbles, but arrival updates instead of negotiation.
void openProgressChat(
  BuildContext context, {
  required ActivityRole role,
  required String counterpartName,
  required String counterpartEmoji,
  DiscussionTask? fixedTask,
}) {
  openProgressChatPage(
    context,
    role: role,
    counterpartName: counterpartName,
    counterpartEmoji: counterpartEmoji,
    fixedTask: fixedTask,
  );
}

void openEscrowPage(BuildContext context) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (_) => const EscrowPaymentScreen(),
    ),
  );
}

// ---------------------------------------------------------------------------
// Live "current task" booking card — the one task across Discussing →
// Task Marked. Self-hides in sections where this phase doesn't belong.
// ---------------------------------------------------------------------------

class LiveTaskBookingCard extends ConsumerWidget {
  final ActivityRole role;
  final int filterIndex; // 0 = Task Marked, 1 = Discussing, 2 = History

  const LiveTaskBookingCard({super.key, required this.role, required this.filterIndex});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final phase = ref.watch(taskPhaseProvider);
    final task = ref.watch(discussionTaskProvider);

    final bool show = filterIndex == 0
        ? phase == TaskPhase.marked
        : filterIndex == 1
            ? (phase == TaskPhase.discussing || phase == TaskPhase.confirmed)
            : false;
    if (!show) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final isClient = role == ActivityRole.client;
    final counterpartName = isClient ? kDiscussionTaskerName : kDiscussionClientName;
    final counterpartEmoji = isClient ? kTaskerEmoji : kClientEmoji;

    final (String statusText, Color statusColor, Color statusBg) = switch (phase) {
      TaskPhase.discussing => ('ဆွေးနွေးနေဆဲ', AppColors.indigo700, AppColors.indigo100),
      TaskPhase.confirmed => ('သဘောတူပြီး', AppColors.purple700, AppColors.purple100),
      TaskPhase.marked => ('အလုပ်လက်ခံပြီး', AppColors.tealDark, AppColors.blue100),
    };

    return ModernServiceCard(
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      padding: EdgeInsets.zero,
      child: Stack(
        children: [
          if (phase == TaskPhase.marked)
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
                          Row(
                            children: [
                              ModernIconBox(
                                  icon: phase == TaskPhase.marked
                                      ? Icons.work_outline_rounded
                                      : Icons.forum_outlined),
                              const SizedBox(width: AppSpacing.sm),
                              Flexible(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.sm,
                                      vertical: AppSpacing.xxs),
                                  decoration: BoxDecoration(
                                    color: statusBg,
                                    borderRadius:
                                        BorderRadius.circular(AppRadius.sm),
                                  ),
                                  child: Text(
                                    statusText,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style:
                                        theme.textTheme.labelSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: statusColor,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            task.skillLabel,
                            style: theme.textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '${task.date} • ${task.timeSlot} • ${task.location}',
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: AppColors.textSecondary),
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
                            phase == TaskPhase.marked ? 'ESCROW' : 'သဘောတူဈေး',
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.purple500,
                            ),
                          ),
                          Text(
                            '${task.budgetMmk ~/ 1000}K MMK',
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
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.lightBg,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: AppSpacing.md,
                        child: isClient
                            ? const Icon(
                                Icons.person_rounded,
                                color: AppColors.purple700,
                                size: AppSizes.iconSm,
                              )
                            : Text(counterpartEmoji,
                                style: theme.textTheme.bodyLarge),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          counterpartName,
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      if (phase == TaskPhase.marked)
                        IconButton(
                          tooltip: 'အလုပ်အခြေအနေ စာတိုပို့ရန်',
                          icon: const Icon(Icons.chat_bubble_outline,
                              size: AppSpacing.lg, color: AppColors.purple700),
                          onPressed: () => openProgressChat(
                            context,
                            role: role,
                            counterpartName: counterpartName,
                            counterpartEmoji: counterpartEmoji,
                          ),
                        )
                      else
                        IconButton(
                          tooltip: 'ဆွေးနွေးရန်',
                          icon: const Icon(Icons.forum_outlined,
                              size: AppSpacing.lg, color: AppColors.indigo700),
                          onPressed: () => openDiscussionChat(
                            context,
                            role: role,
                            counterpartName: counterpartName,
                            counterpartEmoji: counterpartEmoji,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                _liveTaskCta(context, phase, isClient, counterpartName, counterpartEmoji),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _liveTaskCta(
    BuildContext context,
    TaskPhase phase,
    bool isClient,
    String counterpartName,
    String counterpartEmoji,
  ) {
    switch (phase) {
      case TaskPhase.discussing:
        return LargeButton(
          label: 'ဆွေးနွေးမှု ဆက်လုပ်ရန်',
          icon: Icons.forum_outlined,
          gradient: AppColors.purpleGradient,
          onTap: () => openDiscussionChat(
            context,
            role: role,
            counterpartName: counterpartName,
            counterpartEmoji: counterpartEmoji,
          ),
        );
      case TaskPhase.confirmed:
        if (isClient) {
          return LargeButton(
            label: 'Escrow ဖြင့် ငွေပေးချေရန်',
            icon: Icons.lock_outline,
            gradient: AppColors.purpleGradient,
            onTap: () => openEscrowPage(context),
          );
        }
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.blue100,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Text(
            'နှစ်ဦးသဘောတူပြီး — အလုပ်ရှင်က Escrow ငွေပေးချေမှု ဆောင်ရွက်နေပါသည်။',
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: AppColors.textSecondary),
          ),
        );
      case TaskPhase.marked:
        return LargeButton(
          label: 'အလုပ်အခြေအနေ ကြည့်ရန်',
          icon: Icons.local_shipping_outlined,
          gradient: AppColors.purpleGradient,
          onTap: () => openProgressChat(
            context,
            role: role,
            counterpartName: counterpartName,
            counterpartEmoji: counterpartEmoji,
          ),
        );
    }
  }
}

// ---------------------------------------------------------------------------
// Escrow payment page (Phase 3 entry, demo only)
// ---------------------------------------------------------------------------

class EscrowPaymentScreen extends ConsumerStatefulWidget {
  const EscrowPaymentScreen({super.key});

  @override
  ConsumerState<EscrowPaymentScreen> createState() => _EscrowPaymentScreenState();
}

class _EscrowPaymentScreenState extends ConsumerState<EscrowPaymentScreen> {
  bool _paid = false;

  void _pay() {
    setState(() => _paid = true);
    ref.read(taskPhaseProvider.notifier).state = TaskPhase.marked;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final task = ref.watch(discussionTaskProvider);

    return Scaffold(
      backgroundColor: AppColors.lightBg,
      appBar: AppBar(
        backgroundColor: AppColors.purple700,
        foregroundColor: AppColors.onBrand,
        title: const Text('Escrow ငွေပေးချေမှု'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.blue100,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: AppColors.blue300.withValues(alpha: 0.4)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.shield_outlined, color: AppColors.purple500),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      'သင်သည် ယခု Toly Moly သို့ လုံခြုံစွာ ငွေပေးချေနေပါသည်။ အလုပ် ပြီးဆုံးသည်အထိ ငွေကို ထိန်းသိမ်းထားပါမည်။',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: AppColors.textPrimary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.lightSurface,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                boxShadow: [
                  BoxShadow(color: AppColors.shadowSm, blurRadius: AppSpacing.md)
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ငွေပေးချေမှု အကျဉ်းချုပ်',
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: AppSpacing.md),
                  _summaryRow(theme, 'ဝန်ဆောင်မှု', task.skillLabel),
                  _summaryRow(theme, 'ရက်စွဲ', task.date),
                  _summaryRow(theme, 'အချိန်', task.timeSlot),
                  _summaryRow(theme, 'နေရာ', task.location),
                  const Divider(height: AppSpacing.xl),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Escrow ထဲ ထိန်းသိမ်းမည့် ပမာဏ',
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      Text(
                        formatMmk(task.budgetMmk),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.purple700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            if (_paid)
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: AppColors.success),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        'ငွေကို Escrow ထဲ လုံခြုံစွာ ထိန်းသိမ်းထားပါပြီ။ အလုပ်သည် Bookings ထဲ "အလုပ်လက်ခံပြီး" အပိုင်းသို့ ရွှေ့သွားပါပြီ။',
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: AppColors.tealDark),
                      ),
                    ),
                  ],
                ),
              )
            else
              LargeButton(
                label: '${formatMmk(task.budgetMmk)} ပေးချေမည်',
                icon: Icons.lock_outline,
                gradient: AppColors.purpleGradient,
                onTap: _pay,
              ),
            if (_paid) ...[
              const SizedBox(height: AppSpacing.md),
              LargeButton(
                label: 'ပြီးပါပြီ',
                filled: false,
                outlineColor: AppColors.purple700,
                onTap: () => Navigator.of(context).pop(),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            Center(
              child: Text(
                'ဤသည် သရုပ်ပြ (demo) ငွေပေးချေမှုသာ ဖြစ်ပါသည်။',
                style:
                    theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(ThemeData theme, String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.xs),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style:
                    theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
            Text(value, style: theme.textTheme.bodyMedium),
          ],
        ),
      );
}
