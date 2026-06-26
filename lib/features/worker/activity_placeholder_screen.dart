import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/demo_data.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/large_button.dart';

// LOCAL UI STATE (Riverpod) co-located in the screen file as per architecture rules.
final activityTabProvider = StateProvider<int>((ref) => 0); // 0 = Messages, 1 = Bookings
final bookingFilterProvider = StateProvider<int>((ref) => 0); // 0 = Ongoing, 1 = Pending, 2 = History

const List<String> _directReplyChoices = [
  'ရောက်ရှိနေပါပြီ။',
  'အလုပ်စတင်ရန် အဆင်သင့်ဖြစ်ပါပြီ။',
  'ချိန်းထားသောအချိန်ကို အက်ပ်ထဲတွင် အတည်ပြုပေးပါ။',
  'ငွေပေးချေမှုကို Tolymoly အက်ပ်အတွင်းသာ ပြုလုပ်ပါမည်။',
  'Task Details ထဲရှိ အချက်အလက်အတိုင်း ဆောင်ရွက်ပါမည်။',
  'အကူအညီလိုအပ်ပါက Support ကို ဆက်သွယ်ပါမည်။',
];

const List<String> _groupReplyChoices = [
  'အက်ပ်စည်းမျဉ်းအတိုင်းသာ ဆက်သွယ်ပါမည်။',
  'ယနေ့အတွက် အကူအညီရနိုင်ပါသည်။',
  'ချိန်းဆိုချိန်နှင့်နေရာကို Booking ထဲတွင် အတည်ပြုပေးပါ။',
  'ငွေပေးချေမှုကို Tolymoly အက်ပ်အတွင်းသာ ပြုလုပ်ပါမည်။',
  'အရေးကြီးပါက Support ကို ဆက်သွယ်ပါမည်။',
];

String _bookingStatusLabel(String status) {
  switch (status) {
    case 'Active':
      return 'လုပ်ဆောင်နေဆဲ';
    case 'Pending':
      return 'စောင့်ဆိုင်းနေဆဲ';
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
    case 'AC Repair':
      return 'အဲကွန်းပြုပြင်ခြင်း';
    case 'Plumber':
      return 'ရေပိုက်ပြုပြင်ခြင်း';
    case 'Pet Care':
      return 'အိမ်မွေးတိရစ္ဆာန် စောင့်ရှောက်မှု';
    default:
      return skill;
  }
}

void _showActivitySnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

void _openRestrictedChat(
    BuildContext context, {
      required _ChatThread thread,
    }) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.lightSurface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
    ),
    builder: (_) => _RestrictedChatSheet(thread: thread),
  );
}

class _ChatThread {
  final String name;
  final String emoji;
  final bool isGroup;
  final List<_ChatMessage> messages;

  const _ChatThread({
    required this.name,
    required this.emoji,
    required this.messages,
    this.isGroup = false,
  });
}

class _ChatMessage {
  final String text;
  final String time;
  final bool isMe;

  const _ChatMessage({
    required this.text,
    required this.time,
    required this.isMe,
  });
}

const _ChatThread _mayThuThread = _ChatThread(
  name: 'မေသူ',
  emoji: '👩‍🔧',
  messages: [
    _ChatMessage(text: 'Gate မှာ ရောက်နေပါပြီ။', time: '10:42 နံနက်', isMe: false),
    _ChatMessage(text: 'ကျေးဇူးပြု၍ Booking ထဲက လိပ်စာအတိုင်း လာပေးပါ။', time: '10:43 နံနက်', isMe: true),
    _ChatMessage(text: 'အလုပ်စတင်ရန် အဆင်သင့်ဖြစ်ပါပြီ။', time: '10:44 နံနက်', isMe: false),
  ],
);

const _ChatThread _kyawSwarThread = _ChatThread(
  name: 'ကျော်စွာ',
  emoji: '👨‍🔧',
  messages: [
    _ChatMessage(text: 'AC ပြုပြင်မှု ပြီးဆုံးပါပြီ။', time: 'မနေ့က', isMe: false),
    _ChatMessage(text: 'အက်ပ်ထဲမှသာ ငွေပေးချေပါမည်။', time: 'မနေ့က', isMe: true),
    _ChatMessage(text: 'ကူညီပေးလို့ ကျေးဇူးတင်ပါတယ်။', time: 'မနေ့က', isMe: false),
  ],
);

const _ChatThread _petGroupThread = _ChatThread(
  name: 'ရန်ကုန် အိမ်မွေးတိရစ္ဆာန် ချစ်သူများ',
  emoji: '🐾',
  isGroup: true,
  messages: [
    _ChatMessage(text: 'ဇင်ဇင်: ဒီနေ့ လမ်းလျှောက်ပေးနိုင်သူရှိပါသလား။', time: 'တနင်္လာ', isMe: false),
    _ChatMessage(text: 'အက်ပ်စည်းမျဉ်းအတိုင်းသာ ဆက်သွယ်ပါမည်။', time: 'တနင်္လာ', isMe: true),
    _ChatMessage(text: 'မင်းမင်း: Booking ထဲမှာ အချိန်ထည့်ပေးပါ။', time: 'တနင်္လာ', isMe: false),
  ],
);

_ChatThread _workerThread(String workerName) {
  return _ChatThread(
    name: workerName,
    emoji: '👨‍🔧',
    messages: [
      const _ChatMessage(text: 'Booking ကို လက်ခံပြီးပါပြီ။', time: 'ယနေ့', isMe: false),
      const _ChatMessage(text: 'ငွေပေးချေမှုကို Tolymoly အက်ပ်အတွင်းသာ ပြုလုပ်ပါမည်။', time: 'ယနေ့', isMe: true),
      _ChatMessage(text: '$workerName: Task Details ထဲက အချက်အလက်အတိုင်း လာပါမည်။', time: 'ယနေ့', isMe: false),
    ],
  );
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
                            onPressed: () => _showActivitySnack(context, 'အသိပေးချက်အသစ်များ မရှိသေးပါ။'),
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

class _MessagesView extends StatelessWidget {
  const _MessagesView();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.xxl),
      children: const [
        _SafetyNoticeCard(),
        SizedBox(height: AppSpacing.lg),
        _ChatTile(
          thread: _mayThuThread,
          snippet: 'Gate မှာ ရောက်နေပါပြီ။ အက်ပ်ထဲကနေသာ ဆက်သွယ်ပါမယ်။',
          time: '10:42 နံနက်',
          isUnread: true,
        ),
        _ChatTile(
          thread: _kyawSwarThread,
          snippet: 'AC ပြုပြင်မှုအတွက် ကူညီပေးလို့ ကျေးဇူးတင်ပါတယ်။',
          time: 'မနေ့က',
          isUnread: false,
        ),
        _ChatTile(
          thread: _petGroupThread,
          snippet: 'ဇင်ဇင်: ဒီနေ့ လမ်းလျှောက်ပေးနိုင်သူရှိပါသလား။',
          time: 'တနင်္လာ',
          isUnread: false,
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
  final _ChatThread thread;
  final String snippet;
  final String time;
  final bool isUnread;

  const _ChatTile({
    required this.thread,
    required this.snippet,
    required this.time,
    required this.isUnread,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Opacity(
      opacity: isUnread ? 1.0 : 0.75,
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          onTap: () => _openRestrictedChat(context, thread: thread),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                CircleAvatar(
                  radius: AppSpacing.xl,
                  backgroundColor: thread.isGroup
                      ? AppColors.orangeLight.withValues(alpha: 0.2)
                      : AppColors.purple100,
                  child: Text(thread.emoji, style: theme.textTheme.titleLarge),
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
                              thread.name,
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
      ),
    );
  }
}

class _RestrictedChatSheet extends StatefulWidget {
  final _ChatThread thread;

  const _RestrictedChatSheet({required this.thread});

  @override
  State<_RestrictedChatSheet> createState() => _RestrictedChatSheetState();
}

class _RestrictedChatSheetState extends State<_RestrictedChatSheet> {
  final List<String> _sentReplies = [];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final choices = widget.thread.isGroup ? _groupReplyChoices : _directReplyChoices;

    return FractionallySizedBox(
      heightFactor: 0.94,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.md),
            decoration: const BoxDecoration(
              color: AppColors.purple700,
              borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
            ),
            child: Column(
              children: [
                Container(
                  width: AppSpacing.xl * 2,
                  height: AppSpacing.xxs,
                  margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.onBrandMuted,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.onBrand),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    CircleAvatar(
                      backgroundColor: AppColors.onBrand,
                      child: Text(widget.thread.emoji, style: theme.textTheme.titleMedium),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.thread.name,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: AppColors.onBrand,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'စည်းမျဉ်းအတွင်း စာတိုပို့ခြင်း',
                            style: theme.textTheme.bodySmall?.copyWith(color: AppColors.onBrandMuted),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.volume_up_outlined, color: AppColors.onBrand),
                      tooltip: 'ဖတ်ပြရန်',
                      onPressed: () => _showActivitySnack(context, 'ဤ chat တွင် စာရိုက်၍ မရပါ။ အောက်ပါစာတိုများမှသာ ရွေးချယ်ပို့နိုင်ပါသည်။'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.md),
              children: [
                _ChatRuleBanner(isGroup: widget.thread.isGroup),
                const SizedBox(height: AppSpacing.md),
                for (final message in widget.thread.messages) _ChatBubble(message: message),
                for (final reply in _sentReplies)
                  _ChatBubble(
                    message: _ChatMessage(text: reply, time: 'ယခု', isMe: true),
                  ),
              ],
            ),
          ),
          _AllowedReplyPanel(
            choices: choices,
            onSend: (reply) {
              setState(() => _sentReplies.add(reply));
              _showActivitySnack(context, 'စာတိုပို့ပြီးပါပြီ။');
            },
          ),
        ],
      ),
    );
  }
}

class _ChatRuleBanner extends StatelessWidget {
  final bool isGroup;

  const _ChatRuleBanner({required this.isGroup});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.blue100,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.blue300.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lock_outline, color: AppColors.purple500),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              isGroup
                  ? 'Group chat တွင်လည်း စည်းမျဉ်းအတိုင်း ကြိုတင်ရေးထားသော စာတိုများမှသာ ပို့နိုင်ပါသည်။'
                  : 'ဤ chat တွင် စာရိုက်ဧရိယာ မပါပါ။ အက်ပ်စည်းမျဉ်းနှင့်ကိုက်ညီသော စာတိုများမှသာ ရွေးချယ်ပို့နိုင်ပါသည်။',
              style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final _ChatMessage message;

  const _ChatBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Align(
      alignment: message.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 280),
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: message.isMe ? AppColors.purple700 : AppColors.lightBg,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(AppRadius.lg),
            topRight: const Radius.circular(AppRadius.lg),
            bottomLeft: Radius.circular(message.isMe ? AppRadius.lg : AppRadius.sm),
            bottomRight: Radius.circular(message.isMe ? AppRadius.sm : AppRadius.lg),
          ),
          border: message.isMe ? null : Border.all(color: AppColors.onboardingDivider),
        ),
        child: Column(
          crossAxisAlignment: message.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              message.text,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: message.isMe ? AppColors.onBrand : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              message.time,
              style: theme.textTheme.bodySmall?.copyWith(
                color: message.isMe ? AppColors.onBrandMuted : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AllowedReplyPanel extends StatelessWidget {
  final List<String> choices;
  final ValueChanged<String> onSend;

  const _AllowedReplyPanel({required this.choices, required this.onSend});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.lightSurface,
        border: Border(top: BorderSide(color: AppColors.onboardingDivider)),
        boxShadow: [BoxShadow(color: AppColors.shadowSm, blurRadius: AppSpacing.md, offset: const Offset(0, -2))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.fact_check_outlined, size: AppSpacing.lg, color: AppColors.purple700),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  'ပို့နိုင်သောစာတိုများ',
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: 120,
            child: ListView.separated(
              itemCount: choices.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.xs),
              itemBuilder: (context, index) {
                final choice = choices[index];
                return Semantics(
                  button: true,
                  label: 'စာတိုပို့ရန် $choice',
                  child: InkWell(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    onTap: () => onSend(choice),
                    child: Container(
                      constraints: const BoxConstraints(minHeight: AppSpacing.xl * 2),
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: AppColors.purple100,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              choice,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: AppColors.purple900,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const Icon(Icons.send_rounded, size: AppSpacing.md, color: AppColors.purple700),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
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
                _FilterChip(label: 'လုပ်ဆောင်နေဆဲ', isSelected: filterIdx == 0, onTap: () => notifier.state = 0),
                const SizedBox(width: AppSpacing.sm),
                _FilterChip(label: 'စောင့်ဆိုင်း', isSelected: filterIdx == 1, onTap: () => notifier.state = 1),
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
  final int filterType; // 0 = Ongoing, 1 = Pending, 2 = History

  const _BookingTaskCard({required this.booking, required this.filterType});

  Color get _statusBackgroundColor {
    if (filterType == 0) return AppColors.blue100;
    if (filterType == 1) return AppColors.purple100;
    return AppColors.lightBg;
  }

  Color get _statusTextColor {
    if (filterType == 0) return AppColors.tealDark;
    if (filterType == 1) return AppColors.purple700;
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
                            booking.date,
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
                            'ESCROW',
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
                if (filterType != 1) ...[
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: AppColors.lightBg,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(radius: AppSpacing.md, child: Text('👨‍🔧', style: theme.textTheme.bodyLarge)),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                booking.workerName,
                                style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                '4.9 • ယုံကြည်မှု 98%',
                                style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'စည်းမျဉ်းအတိုင်း စာတိုပို့ရန်',
                          icon: const Icon(Icons.chat_bubble_outline, size: AppSpacing.lg, color: AppColors.purple700),
                          onPressed: () => _openRestrictedChat(
                            context,
                            thread: _workerThread(booking.workerName),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                if (filterType == 1) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.lightBg,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Text(
                      'AI Task Scoper အသုံးပြုပြီးပါပြီ။ အကြံပြုဘတ်ဂျက်သည် ဒေသတွင်းပျမ်းမျှနှင့် ကိုက်ညီပါသည်။',
                      style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                Row(
                  children: [
                    Expanded(
                      child: LargeButton(
                        label: filterType == 1 ? 'Task ပြင်ရန်' : 'Task အသေးစိတ်',
                        gradient: AppColors.purpleGradient,
                        onTap: () => _showActivitySnack(
                          context,
                          filterType == 1
                              ? 'Task ပြင်ရန် စာမျက်နှာကို ဒီ MVP တွင် မဖွင့်ထားသေးပါ။'
                              : 'Task အသေးစိတ်ကို ဒီ MVP တွင် မဖွင့်ထားသေးပါ။',
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
                          onPressed: () => _showActivitySnack(context, 'အရေးပေါ်အကူအညီအတွက် Support ကို ဆက်သွယ်ပါ။'),
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
