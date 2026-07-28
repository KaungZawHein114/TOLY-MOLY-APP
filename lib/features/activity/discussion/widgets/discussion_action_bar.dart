import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../activity_chat.dart' show ActivityRole;
import '../discussion_models.dart';
import '../discussion_state.dart';

/// One button in the smart action bar.
///
/// [type] is null for "ask a question", which deliberately does *not* create a
/// card — casual questions belong in chat, decisions belong in cards.
@immutable
class DiscussionActionSpec {
  final String label;
  final IconData icon;
  final DiscussionItemType? type;

  const DiscussionActionSpec({
    required this.label,
    required this.icon,
    this.type,
  });
}

const List<DiscussionActionSpec> kTaskerActions = [
  DiscussionActionSpec(
    label: 'ဓာတ်ပုံ တောင်းရန်',
    icon: Icons.photo_camera_outlined,
    type: DiscussionItemType.photoRequest,
  ),
  DiscussionActionSpec(
    label: 'ပစ္စည်း မေးရန်',
    icon: Icons.handyman_outlined,
    type: DiscussionItemType.materialChecklist,
  ),
  DiscussionActionSpec(
    label: 'ကြာချိန် ခန့်မှန်း',
    icon: Icons.schedule_outlined,
    type: DiscussionItemType.durationRequest,
  ),
  DiscussionActionSpec(
    label: 'လက်ထောက် ခေါ်ရန်',
    icon: Icons.groups_outlined,
    type: DiscussionItemType.apprenticeRequest,
  ),
  DiscussionActionSpec(
    label: 'စရိတ် အသိပေးရန်',
    icon: Icons.payments_outlined,
    type: DiscussionItemType.extraCostProposal,
  ),
  DiscussionActionSpec(
    label: 'ချိန်းချိန် ပြောင်းရန်',
    icon: Icons.event_outlined,
    type: DiscussionItemType.scheduleProposal,
  ),
];

const List<DiscussionActionSpec> kClientActions = [
  DiscussionActionSpec(
    label: 'ဓာတ်ပုံ တောင်းရန်',
    icon: Icons.photo_camera_outlined,
    type: DiscussionItemType.photoRequest,
  ),
  DiscussionActionSpec(
    label: 'ကြာချိန် မေးရန်',
    icon: Icons.schedule_outlined,
    type: DiscussionItemType.durationRequest,
  ),
  DiscussionActionSpec(
    label: 'စရိတ် မေးရန်',
    icon: Icons.payments_outlined,
    type: DiscussionItemType.extraCostProposal,
  ),
  DiscussionActionSpec(
    label: 'ချိန်းချိန် ပြောင်းရန်',
    icon: Icons.event_outlined,
    type: DiscussionItemType.scheduleProposal,
  ),
  DiscussionActionSpec(
    label: 'မေးခွန်း မေးရန်',
    icon: Icons.help_outline,
  ),
];

List<DiscussionActionSpec> actionsFor(ActivityRole role) =>
    role == ActivityRole.tasker ? kTaskerActions : kClientActions;

/// The bottom bar: smart actions, the casual-chat composer, and the single
/// "Ready to Proceed" exit. Nothing else competes for attention.
class DiscussionActionBar extends StatelessWidget {
  final ActivityRole viewerRole;
  final List<DiscussionItem> items;
  final ValueChanged<DiscussionActionSpec> onAction;
  final TextEditingController textCtrl;
  final FocusNode chatFocus;
  final VoidCallback onSend;
  final VoidCallback onVoice;
  final VoidCallback? onReady;
  final String readyLabel;

  /// False once the discussion is settled — chat stays open, but no new
  /// discussion points can be raised until someone continues the discussion.
  final bool showActions;

  const DiscussionActionBar({
    super.key,
    required this.viewerRole,
    required this.items,
    required this.onAction,
    required this.textCtrl,
    required this.chatFocus,
    required this.onSend,
    required this.onVoice,
    required this.onReady,
    required this.readyLabel,
    this.showActions = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final actions = actionsFor(viewerRole);
    // Burmese labels plus a large accessibility text scale need real vertical
    // room; the strip grows with the text instead of clipping it.
    final textScale = (MediaQuery.textScalerOf(context).scale(14) / 14).clamp(1.0, 1.6);

    return Container(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.lightSurface,
        border: const Border(top: BorderSide(color: AppColors.onboardingDivider)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowSm,
            blurRadius: AppSpacing.md,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      // The bar is a fixed child of the sheet's Column, so it must never claim
      // more than its share: past that it scrolls internally instead of
      // overflowing the sheet at large accessibility text scales.
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.45,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showActions) ...[
                Row(
                  children: [
                    const Icon(Icons.bolt_rounded,
                        size: AppSizes.iconMd, color: AppColors.purple700),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        'ဆွေးနွေးရန် ရွေးပါ',
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    if (onReady != null)
                      Flexible(
                        child: TextButton.icon(
                          onPressed: onReady,
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.tealDark,
                            minimumSize: const Size(0, 44),
                          ),
                          icon:
                              const Icon(Icons.verified_outlined, size: AppSizes.iconSm),
                          label: Text(
                            readyLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                SizedBox(
                  height: 84 * textScale,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: actions.length,
                    separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
                    itemBuilder: (context, index) {
                      final spec = actions[index];
                      final existing =
                          spec.type == null ? null : openItemOfType(items, spec.type!);
                      return _ActionTile(
                        spec: spec,
                        existing: existing,
                        onTap: () => onAction(spec),
                      );
                    },
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              _ChatComposer(
                textCtrl: textCtrl,
                chatFocus: chatFocus,
                onSend: onSend,
                onVoice: onVoice,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final DiscussionActionSpec spec;
  final DiscussionItem? existing;
  final VoidCallback onTap;

  const _ActionTile({
    required this.spec,
    required this.existing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final taken = existing != null;

    return Semantics(
      button: true,
      label: taken ? '${spec.label} — ရှိပြီးသား ကတ်ကို ဖွင့်ရန်' : spec.label,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: onTap,
        child: Container(
          width: 96,
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm, vertical: AppSpacing.sm),
          decoration: BoxDecoration(
            color: taken ? AppColors.lightBg : AppColors.purple100,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    spec.icon,
                    size: AppSizes.iconLg,
                    color: taken ? AppColors.textSecondary : AppColors.purple700,
                  ),
                  if (taken)
                    Positioned(
                      right: -6,
                      top: -4,
                      child: Container(
                        padding: const EdgeInsets.all(1),
                        decoration: const BoxDecoration(
                          color: AppColors.lightSurface,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          existing!.status.isPending
                              ? Icons.hourglass_top_rounded
                              : Icons.check_circle_rounded,
                          size: AppSizes.iconSm,
                          color: existing!.status.isPending
                              ? AppColors.orangeDark
                              : AppColors.tealDark,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                spec.label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: taken ? AppColors.textSecondary : AppColors.purple900,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChatComposer extends StatelessWidget {
  final TextEditingController textCtrl;
  final FocusNode chatFocus;
  final VoidCallback onSend;
  final VoidCallback onVoice;

  const _ChatComposer({
    required this.textCtrl,
    required this.chatFocus,
    required this.onSend,
    required this.onVoice,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: textCtrl,
                focusNode: chatFocus,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                minLines: 1,
                maxLines: 3,
                decoration: InputDecoration(
                  isDense: true,
                  hintText: 'ရိုးရိုး စကားပြောရန်...',
                  filled: true,
                  fillColor: AppColors.lightBg,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md, vertical: AppSpacing.md),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Semantics(
              button: true,
              label: 'အသံဖြင့် ပြောရန်',
              child: IconButton(
                icon: const Icon(Icons.mic_none_rounded, color: AppColors.purple700),
                tooltip: 'အသံဖြင့် ပြောရန်',
                onPressed: onVoice,
              ),
            ),
            Container(
              decoration:
                  const BoxDecoration(color: AppColors.purple700, shape: BoxShape.circle),
              child: IconButton(
                icon: const Icon(Icons.send_rounded, color: AppColors.onBrand),
                tooltip: 'ပို့ရန်',
                onPressed: onSend,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.shield_outlined,
                size: AppSizes.iconSm, color: AppColors.indigo500),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                'စာတိုများကို ပို့မီ AI ဖြင့် စစ်ဆေးပါသည်။ အရေးကြီးသော သဘောတူညီချက်များကို '
                'အပေါ်က ကတ်များဖြင့်သာ မှတ်တမ်းတင်ပါ။',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
