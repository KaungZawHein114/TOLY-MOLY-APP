import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/routing/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/mascot/mascot_message_card.dart';
import '../../core/widgets/mascot/mascot_state.dart';
import '../activity/activity_chat.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Data model for a rendered conversation row (pure UI — no backend changes).
// ─────────────────────────────────────────────────────────────────────────────

class _Convo {
  final String name;
  final String emoji;
  final String jobCategory;
  final String snippet;
  final String time;
  final String statusLabel;
  final Color statusColor;
  final bool isUnread;
  final bool isOnline;
  final bool isVerified;
  final VoidCallback onTap;

  const _Convo({
    required this.name,
    required this.emoji,
    required this.jobCategory,
    required this.snippet,
    required this.time,
    required this.statusLabel,
    required this.statusColor,
    required this.isUnread,
    required this.isOnline,
    required this.isVerified,
    required this.onTap,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────

/// Chat tab — conversations only. No booking list, no activity feed.
///
/// Business logic is fully intact:
///   • Reads [taskPhaseProvider] for live status labels/snippets.
///   • Delegates opens to [openDiscussionChat] / [openProgressChat].
class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final phase = ref.watch(taskPhaseProvider);

    // ── Build conversation list from demo state ───────────────────────────
    final (String chat1Status, Color chat1Color) = switch (phase) {
      TaskPhase.discussing => ('ဆွေးနွေးဆဲ', AppColors.indigo500),
      TaskPhase.confirmed  => ('သဘောတူပြီး', AppColors.purple700),
      TaskPhase.marked     => ('အလုပ်လက်ခံပြီး', AppColors.tealDark),
    };
    final chat1Snippet = switch (phase) {
      TaskPhase.discussing =>
        'မင်္ဂလာပါ။ သင့်အလုပ်ကို စိတ်ဝင်စားလို့ ဆက်သွယ်လိုက်တာပါ။',
      TaskPhase.confirmed =>
        'နှစ်ဦးသဘောတူပြီးပါပြီ။ Escrow ဖြင့် ဆက်လက်ဆောင်ရွက်ပါ။',
      TaskPhase.marked =>
        'အလုပ် လက်ခံပြီးပါပြီ။ အခြေအနေ အပ်ဒိတ်ကို စောင့်ပါ။',
    };

    final allConvos = [
      _Convo(
        name: kDiscussionTaskerName,
        emoji: kTaskerEmoji,
        jobCategory: 'လျှပ်စစ်ပြုပြင်ခြင်း',
        snippet: chat1Snippet,
        time: 'ယခု',
        statusLabel: chat1Status,
        statusColor: chat1Color,
        isUnread: phase == TaskPhase.discussing,
        isOnline: true,
        isVerified: true,
        onTap: () => openDiscussionChat(
          context,
          role: ActivityRole.client,
          counterpartName: kDiscussionTaskerName,
          counterpartEmoji: kTaskerEmoji,
        ),
      ),
      _Convo(
        name: kProgressTaskerName,
        emoji: kTaskerEmoji,
        jobCategory: 'ရေပိုက်ပြုပြင်ခြင်း',
        snippet: 'အလုပ် အတည်ဖြစ်ပြီးပါပြီ။ ထွက်ခွာချိန် ရောက်ရင် အသိပေးပါမယ်။',
        time: 'မနက်က',
        statusLabel: 'အလုပ်ဆောင်ရွက်ဆဲ',
        statusColor: AppColors.tealDark,
        isUnread: false,
        isOnline: false,
        isVerified: true,
        onTap: () => openProgressChat(
          context,
          role: ActivityRole.client,
          counterpartName: kProgressTaskerName,
          counterpartEmoji: kTaskerEmoji,
          fixedTask: kProgressDemoTask,
        ),
      ),
    ];

    // ── Filter by search query ────────────────────────────────────────────
    final q = _query.trim().toLowerCase();
    final convos = q.isEmpty
        ? allConvos
        : allConvos
            .where((c) =>
                c.name.toLowerCase().contains(q) ||
                c.jobCategory.toLowerCase().contains(q) ||
                c.snippet.toLowerCase().contains(q))
            .toList();

    return Scaffold(
      backgroundColor: AppColors.lightBg,
      // ── AppBar ────────────────────────────────────────────────────────
      appBar: AppBar(
        backgroundColor: AppColors.purple700,
        foregroundColor: AppColors.onBrand,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'စကားပြော',
          style: theme.textTheme.titleLarge?.copyWith(
            color: AppColors.onBrand,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          Semantics(
            label: 'ရှာဖွေရန်',
            button: true,
            child: IconButton(
              icon: const Icon(Icons.search_rounded, color: AppColors.onBrand),
              onPressed: () => _searchCtrl.selection = TextSelection.fromPosition(
                TextPosition(offset: _searchCtrl.text.length),
              ),
              tooltip: 'ရှာဖွေရန်',
            ),
          ),
          Semantics(
            label: 'ရွေးချယ်စရာများ',
            button: true,
            child: IconButton(
              icon: const Icon(Icons.more_vert_rounded, color: AppColors.onBrand),
              onPressed: () => showActivitySnack(context, 'မကြာမီ ရရှိနိုင်မည်။'),
              tooltip: 'ရွေးချယ်စရာများ',
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Search bar ────────────────────────────────────────────────
          Container(
            color: AppColors.purple700,
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
            child: _ChatSearchBar(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _query = v),
              onClear: () => setState(() {
                _searchCtrl.clear();
                _query = '';
              }),
            ),
          ),

          // ── Safety notice banner ──────────────────────────────────────
          _SafetyBanner(),

          // ── Conversation list / empty state ───────────────────────────
          Expanded(
            child: convos.isEmpty
                ? _EmptyChatState(
                    isSearching: q.isNotEmpty,
                    onFindWorker: () => context.push(Routes.workerList),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg, AppSpacing.md,
                        AppSpacing.lg, AppSpacing.xxxl),
                    itemCount: convos.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, i) =>
                        _ConversationCard(convo: convos[i]),
                  ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Search bar
// ─────────────────────────────────────────────────────────────────────────────

class _ChatSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _ChatSearchBar({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: 'စကားပြောရန် ရှာဖွေပါ...',
        hintStyle:
            TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.8)),
        prefixIcon:
            const Icon(Icons.search_rounded, color: AppColors.textSecondary),
        suffixIcon: controller.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.close_rounded,
                    color: AppColors.textSecondary),
                onPressed: onClear,
                tooltip: 'ရှင်းလင်းရန်',
              )
            : null,
        filled: true,
        fillColor: AppColors.lightSurface,
        contentPadding:
            const EdgeInsets.symmetric(vertical: AppSpacing.md),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          borderSide:
              const BorderSide(color: AppColors.purple300, width: 2),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Safety banner (compact)
// ─────────────────────────────────────────────────────────────────────────────

class _SafetyBanner extends StatelessWidget {
  const _SafetyBanner();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
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
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.indigo700,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Conversation card — Messenger/WhatsApp style
// ─────────────────────────────────────────────────────────────────────────────

class _ConversationCard extends StatefulWidget {
  final _Convo convo;
  const _ConversationCard({required this.convo});

  @override
  State<_ConversationCard> createState() => _ConversationCardState();
}

class _ConversationCardState extends State<_ConversationCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _fadeCtrl =
        AnimationController(vsync: this, duration: AppMotion.medium);
    _fade = CurvedAnimation(parent: _fadeCtrl, curve: AppMotion.enter);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = widget.convo;
    final radius = BorderRadius.circular(AppRadius.lg);

    return FadeTransition(
      opacity: _fade,
      child: Semantics(
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
                  // ── Avatar with online indicator ──────────────────────
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: AppColors.purple100,
                        child: Text(
                          c.emoji,
                          style: theme.textTheme.headlineSmall,
                        ),
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
                                  width: 2),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: AppSpacing.md),

                  // ── Text content ──────────────────────────────────────
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name row + timestamp
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      c.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                        fontWeight: c.isUnread
                                            ? FontWeight.w700
                                            : FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  if (c.isVerified) ...[
                                    const SizedBox(width: AppSpacing.xs),
                                    const Icon(Icons.verified_rounded,
                                        size: 15,
                                        color: AppColors.success),
                                  ],
                                ],
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

                        // Job category chip
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.sm,
                                  vertical: AppSpacing.xxs),
                              decoration: BoxDecoration(
                                color: c.statusColor.withValues(alpha: 0.12),
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
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty state
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyChatState extends StatelessWidget {
  final bool isSearching;
  final VoidCallback onFindWorker;

  const _EmptyChatState({
    required this.isSearching,
    required this.onFindWorker,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            MascotMessageCard(
              state: PhoWaYokeState.idle,
              message: isSearching
                  ? 'ရှာဖွေမှုနှင့် ကိုက်ညီသော စကားပြောမှု မရှိပါ။'
                  : 'စကားပြောထားသော လုပ်သား မရှိသေးပါ',
            ),
            if (!isSearching) ...[
              const SizedBox(height: AppSpacing.xl),
              FilledButton.icon(
                onPressed: onFindWorker,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.purple700,
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
                icon: const Icon(Icons.people_alt_rounded),
                label: Text(
                  'လုပ်သားရှာမည်',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: AppColors.onBrand,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
