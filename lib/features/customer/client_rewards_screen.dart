import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/routing/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../worker/notifications/notification_service.dart';

/// Client Rewards & VIP screen — STRICTLY the Client/Employer flow.
///
/// This is the customer-side counterpart to the worker's gamification screen,
/// but framed around *spending/engagement* (VIP tier, coupons, ways to earn)
/// rather than the worker's task-based tier ladder. It must never be wired
/// into the worker navigation.
///
/// A single continuous scroll view: the brand-gradient header scrolls up with
/// the rest of the content. All styling comes from the project's theme tokens
/// (`AppColors`, `AppSpacing`, `AppRadius`, `AppSizes`) and `Theme.of(context)`
/// — no raw hex, no hardcoded text styles. Phase-1: static demo values only.
class ClientRewardsScreen extends StatelessWidget {
  const ClientRewardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            _HeaderVipSection(),
            SizedBox(height: AppSpacing.lg),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.screen),
              child: _ClientStatsRow(),
            ),
            SizedBox(height: AppSpacing.xxl),
            _CouponsSection(),
            SizedBox(height: AppSpacing.xxl),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.screen),
              child: _EarnPointsSection(),
            ),
            SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// A. HEADER + CLIENT VIP CARD
// ============================================================================

class _VipTier {
  final String name;
  final int minPoints;
  final IconData icon;
  const _VipTier({
    required this.name,
    required this.minPoints,
    required this.icon,
  });
}

const List<_VipTier> _vipTiers = [
  _VipTier(name: 'Bronze VIP', minPoints: 0, icon: Icons.shield),
  _VipTier(name: 'Silver VIP', minPoints: 300, icon: Icons.stars),
  _VipTier(name: 'Gold VIP', minPoints: 1000, icon: Icons.diamond),
  _VipTier(name: 'Platinum VIP', minPoints: 2000, icon: Icons.workspace_premium),
];

const int _currentClientPoints = 1250;

int _currentVipIndex() {
  var idx = 0;
  for (var i = 0; i < _vipTiers.length; i++) {
    if (_currentClientPoints >= _vipTiers[i].minPoints) idx = i;
  }
  return idx;
}

class _HeaderVipSection extends StatelessWidget {
  const _HeaderVipSection();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final topPadding = MediaQuery.of(context).padding.top;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        AppSpacing.screen,
        topPadding + AppSpacing.lg,
        AppSpacing.screen,
        AppSpacing.xl,
      ),
      decoration: const BoxDecoration(
        gradient: AppColors.purpleGradient,
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(AppRadius.xl),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title + "Client" badge.
          Row(
            children: [
              Expanded(
                child: Text(
                  'အထူးခံစားခွင့်များ',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: AppColors.onBrand,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: AppColors.onBrand.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(color: AppColors.onBrand.withValues(alpha: 0.4)),
                ),
                child: Text(
                  'Client',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: AppColors.onBrand,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          _buildVipCard(context),
        ],
      ),
    );
  }

  /// Glassmorphic VIP card: semi-transparent fill + light border over the
  /// brand gradient.
  Widget _buildVipCard(BuildContext context) {
    final theme = Theme.of(context);
    final vipIdx = _currentVipIndex();
    final tier = _vipTiers[vipIdx];

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.onBrand.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.onBrand.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.thanakaGold.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                alignment: Alignment.center,
                child: Icon(
                  tier.icon,
                  color: AppColors.onBrand,
                  size: AppSizes.iconMd,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tier.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: AppColors.onBrand,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      '$_currentClientPoints မှတ်',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.onBrandMuted,
                      ),
                    ),
                  ],
                ),
              ),
              // Benefits pill button.
              TextButton(
                onPressed: () => _showVipBenefits(context),
                style: TextButton.styleFrom(
                  backgroundColor: AppColors.onBrand.withValues(alpha: 0.18),
                  foregroundColor: AppColors.onBrand,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  minimumSize: const Size(0, 0),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'အကျိုးခံစားခွင့်',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.onBrand,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          _buildProgress(context, vipIdx),
        ],
      ),
    );
  }

  Widget _buildProgress(BuildContext context, int vipIdx) {
    final theme = Theme.of(context);
    final hasNext = vipIdx < _vipTiers.length - 1;

    if (!hasNext) {
      return Row(
        children: [
          const Icon(Icons.workspace_premium, color: AppColors.thanakaGold, size: AppSizes.iconSm),
          const SizedBox(width: AppSpacing.sm),
          Text(
            'အမြင့်ဆုံးအဆင့် ရောက်ရှိပြီး',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.onBrand,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      );
    }

    final nextTier = _vipTiers[vipIdx + 1];
    final remaining = nextTier.minPoints - _currentClientPoints;
    final span = nextTier.minPoints - _vipTiers[vipIdx].minPoints;
    final progress = ((_currentClientPoints - _vipTiers[vipIdx].minPoints) / span).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                '${nextTier.name} သို့ရောက်ရန်',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.onBrandMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              '$remaining မှတ် လိုသေးသည်',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.onBrand,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: AppColors.onBrand.withValues(alpha: 0.2),
            valueColor: const AlwaysStoppedAnimation<Color>(
              AppColors.thanakaGold,
            ),
          ),
        ),
      ],
    );
  }

  void _showVipBenefits(BuildContext context) {
    final currentIdx = _currentVipIndex();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.8,
          expand: false,
          builder: (ctx, controller) => Column(
            children: [
              const SizedBox(height: AppSpacing.sm),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.dividerColor,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Text('VIP အဆင့်များ', style: theme.textTheme.titleLarge),
              ),
              Expanded(
                child: ListView.separated(
                  controller: controller,
                  padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xxl),
                  itemCount: _vipTiers.length,
                  separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
                  itemBuilder: (ctx, i) {
                    final tier = _vipTiers[i];
                    final isCurrent = i == currentIdx;
                    final isLocked = i > currentIdx;
                    return Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: isCurrent ? AppColors.purple100.withValues(alpha: 0.5) : theme.cardColor,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        border: Border.all(
                          color: isCurrent ? AppColors.purple700 : theme.dividerColor,
                          width: isCurrent ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(isLocked ? Icons.lock : tier.icon, color: isLocked ? theme.hintColor : AppColors.purple700),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(tier.name, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
                                Text('${tier.minPoints} မှတ်မှ စတင်သည်', style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor)),
                              ],
                            ),
                          ),
                          if (isCurrent)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xxs),
                              decoration: BoxDecoration(color: AppColors.purple700, borderRadius: BorderRadius.circular(AppRadius.pill)),
                              child: const Text('လက်ရှိ', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ============================================================================
// B. CLIENT QUICK STATS (compact grid)
// ============================================================================

class _ClientStatsRow extends StatelessWidget {
  const _ClientStatsRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Expanded(
          child: _StatCard(emoji: '🛍️', label: 'အလုပ်အပ်နှံမှု', value: '၁၂ ကြိမ်'),
        ),
        SizedBox(width: AppSpacing.md),
        Expanded(
          child: _StatCard(emoji: '⭐', label: 'သုံးသပ်ချက်ပေးမှု', value: '၈ ခု'),
        ),
        SizedBox(width: AppSpacing.md),
        Expanded(
          child: _StatCard(emoji: '💖', label: 'အကြိုက်ဆုံး', value: '၃ ဦး'),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String emoji;
  final String label;
  final String value;
  const _StatCard({
    required this.emoji,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.md,
        horizontal: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowSm,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// C. COUPONS & REDEMPTION (horizontal scroll)
// ============================================================================

/// One redeemable coupon — mock model standing in for future `demo_data.dart`.
/// `accent` drives the icon tile colour so each coupon reads distinctly.
class _ClientReward {
  final IconData icon;
  final Color accent;
  final Color accentSurface;
  final String title;
  final String subtitle;
  final String cost;
  final int unlockTier;
  const _ClientReward({
    required this.icon,
    required this.accent,
    required this.accentSurface,
    required this.title,
    required this.subtitle,
    required this.cost,
    this.unlockTier = 0,
  });
}

const List<_ClientReward> _coupons = [
  _ClientReward(
    icon: Icons.cleaning_services,
    accent: AppColors.teal,
    accentSurface: AppColors.blue100,
    title: 'သန့်ရှင်းရေး Discount',
    subtitle: '၅,၀၀၀ ကျပ် လျှော့စျေး',
    cost: '၅၀၀ မှတ်',
    unlockTier: 0,
  ),
  _ClientReward(
    icon: Icons.bolt,
    accent: AppColors.indigo700,
    accentSurface: AppColors.indigo100,
    title: 'Priority Matching',
    subtitle: 'အလုပ်သမား အမြန်ရှာရန်',
    cost: '၃၀၀ မှတ်',
    unlockTier: 0,
  ),
  _ClientReward(
    icon: Icons.storefront,
    accent: AppColors.tealDark,
    accentSurface: AppColors.tealLight,
    title: 'City Mart',
    subtitle: '၃,၀၀၀ ကျပ် ကူပွန်',
    cost: '၈၀၀ မှတ်',
    unlockTier: 1,
  ),
  _ClientReward(
    icon: Icons.support_agent,
    accent: AppColors.purple700,
    accentSurface: AppColors.purple100,
    title: 'Priority Support',
    subtitle: '၂၄/၇ အထူးဝန်ဆောင်မှု',
    cost: '၁,၅၀၀ မှတ်',
    unlockTier: 3,
  ),
  _ClientReward(
    icon: Icons.money_off,
    accent: AppColors.success,
    accentSurface: AppColors.tealLight,
    title: 'Zero Booking Fee',
    subtitle: 'ဝန်ဆောင်ခ ကင်းလွတ်ခွင့်',
    cost: '၂,၀၀၀ မှတ်',
    unlockTier: 3,
  ),
];

class _CouponsSection extends StatelessWidget {
  const _CouponsSection();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentVipIdx = _currentVipIndex();
    // Show all for the rail but dimmed if locked.
    final railCoupons = _coupons;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'လဲလှယ်ရန် ဆုလာဘ်များ',
                  style: theme.textTheme.titleLarge,
                ),
              ),
              TextButton(
                onPressed: () => _showAllCouponsSheet(context, currentVipIdx),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.indigo700,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'အားလုံးကြည့်မည်',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: AppColors.indigo700,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
            itemCount: railCoupons.length,
            itemBuilder: (context, i) => Padding(
              padding: EdgeInsets.only(
                right: i == railCoupons.length - 1 ? 0 : AppSpacing.md,
              ),
              child: _RewardCard(
                reward: railCoupons[i],
                locked: railCoupons[i].unlockTier > currentVipIdx,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// See-All catalogue: every coupon in a 2-column grid.
void _showAllCouponsSheet(BuildContext context, int currentVipIdx) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).cardColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
    ),
    builder: (ctx) {
      final theme = Theme.of(ctx);
      return DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (ctx, controller) => Column(
          children: [
            const SizedBox(height: AppSpacing.sm),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.dividerColor,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  const Icon(Icons.local_activity, color: AppColors.purple700),
                  const SizedBox(width: AppSpacing.sm),
                  Text('ဆုလာဘ်အားလုံး', style: theme.textTheme.titleLarge),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  0,
                  AppSpacing.lg,
                  AppSpacing.xxl,
                ),
                child: LayoutBuilder(
                  builder: (ctx, constraints) {
                    final w = (constraints.maxWidth - AppSpacing.md) / 2;
                    return Wrap(
                      spacing: AppSpacing.md,
                      runSpacing: AppSpacing.md,
                      children: [
                        for (final c in _coupons)
                          SizedBox(
                            width: w,
                            height: 180,
                            child: _RewardCard(
                              reward: c,
                              locked: c.unlockTier > currentVipIdx,
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

class _RewardCard extends ConsumerWidget {
  final _ClientReward reward;
  final bool locked;
  const _RewardCard({required this.reward, required this.locked});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Opacity(
      opacity: locked ? 0.65 : 1,
      child: Container(
        width: 150,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowSm,
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: reward.accentSurface,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  alignment: Alignment.center,
                  child: Icon(reward.icon, color: reward.accent, size: AppSizes.iconMd),
                ),
                if (locked)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: AppColors.purple700,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.lock, size: 10, color: AppColors.onBrand),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              reward.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              reward.subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: locked
                  ? _lockedButton(theme)
                  : FilledButton(
                      onPressed: () => _showRedeemSuccess(context, ref),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.purple700,
                        foregroundColor: AppColors.onBrand,
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                      ),
                      child: Text(
                        reward.cost,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.onBrand,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _lockedButton(ThemeData theme) => Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: theme.disabledColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline, size: 14, color: theme.hintColor),
            const SizedBox(width: AppSpacing.xs),
            Text(
              '${_vipTiers[reward.unlockTier].name}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.hintColor,
                fontWeight: FontWeight.w700,
                fontSize: 9,
              ),
            ),
          ],
        ),
      );

  void _showRedeemSuccess(BuildContext context, WidgetRef ref) {
    // Notify history
    ref.read(notificationProvider.notifier).notifyRewardRedeemed(reward.title);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: AppColors.success),
            SizedBox(width: AppSpacing.sm),
            Text('လဲလှယ်မှု အောင်မြင်ပါသည်'),
          ],
        ),
        content: Text(
          'သင်ရွေးချယ်ထားသော "${reward.title}" အတွက် ${reward.cost} ကို လဲလှယ်ပြီးပါပြီ။',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: TextButton.styleFrom(foregroundColor: AppColors.tmPurple),
            child: const Text('အိုကေ', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// D. HOW TO EARN POINTS (vertical list)
// ============================================================================

/// Where an earn-action sends the client when tapped. Each maps to the most
/// relevant existing page so the row is actionable, not just informational.
enum _EarnTarget { review, tip, weeklyBooking, invite }

/// One point-earning action. `highlighted` gives the referral row its special
/// look (brand-tinted surface + border) to nudge engagement. `target` makes
/// the row navigate to the related page.
class _EarnAction {
  final String emoji;
  final String title;
  final String subtitle;
  final String points;
  final _EarnTarget target;
  final bool highlighted;
  const _EarnAction({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.points,
    required this.target,
    this.highlighted = false,
  });
}

const List<_EarnAction> _earnActions = [
  _EarnAction(
    emoji: '⭐',
    title: 'သုံးသပ်ချက်ပေးပါ',
    subtitle: 'အလုပ်သမားကို 5-Star ပေးပါ',
    points: '+၂၀ မှတ်',
    target: _EarnTarget.review,
  ),
  _EarnAction(
    emoji: '🎁',
    title: 'ဘောက်ဆူးပေးပါ',
    subtitle: 'အလုပ်သမားကို Tip ပေးပါ',
    points: '+၅၀ မှတ်',
    target: _EarnTarget.tip,
  ),
  _EarnAction(
    emoji: '📅',
    title: 'အပတ်စဉ် အပ်နှံပါ',
    subtitle: 'အပတ်စဉ် ပုံမှန်အလုပ်ခန့်ပါ',
    points: '+၁၀၀ မှတ်',
    target: _EarnTarget.weeklyBooking,
  ),
  _EarnAction(
    emoji: '🤝',
    title: 'သူငယ်ချင်းဖိတ်ခေါ်ပါ',
    subtitle: 'မိတ်ဆွေများကို Tolymoly သို့ဖိတ်ပါ',
    points: '+၂၀၀ မှတ်',
    target: _EarnTarget.invite,
    highlighted: true,
  ),
];

/// Routes each earn-action to a simulated informational popup explaining
/// how to perform the action and earn points.
void _handleEarnTap(BuildContext context, WidgetRef ref, _EarnAction action) {
  // Notify points earned (simulated)
  ref.read(notificationProvider.notifier).notifyPointsEarned(action.title, action.points);

  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
      title: Row(
        children: [
          Text(action.emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(action.title)),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ဘယ်လိုလုပ်ရမလဲ?',
            style: Theme.of(ctx).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(_getEarnInstruction(action.target)),
          const SizedBox(height: AppSpacing.lg),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Row(
              children: [
                const Icon(Icons.stars, color: AppColors.success, size: 20),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'ပြီးမြောက်ပါက ${action.points} ရရှိမည်',
                  style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          style: TextButton.styleFrom(foregroundColor: AppColors.tmPurple),
          child: const Text('နားလည်ပါပြီ', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    ),
  );
}

String _getEarnInstruction(_EarnTarget target) {
  switch (target) {
    case _EarnTarget.review:
      return 'အလုပ်ပြီးဆုံးသွားသောအခါ "ပြီးစီးမှုအသေးစိတ်" စာမျက်နှာတွင် အလုပ်သမားကို ၅-စတား သုံးသပ်ချက်ပေးခြင်းဖြင့် မှတ်များ ရယူနိုင်ပါသည်။';
    case _EarnTarget.tip:
      return 'အလုပ်သမား၏ ဝန်ဆောင်မှုကို သဘောကျပါက ဘောက်ဆူး (Tip) ပေးခြင်းဖြင့် အပိုဆုမှတ်များ ရရှိပါမည်။';
    case _EarnTarget.weeklyBooking:
      return 'အိမ်သန့်ရှင်းရေး သို့မဟုတ် အခြားဝန်ဆောင်မှုများကို အပတ်စဉ် ပုံမှန်အပ်နှံခြင်းဖြင့် VIP အဆင့်သို့ အမြန်ရောက်ရှိနိုင်ပါသည်။';
    case _EarnTarget.invite:
      return 'သင့်သူငယ်ချင်းများကို App သို့ ဖိတ်ခေါ်ပြီး ၎င်းတို့ ပထမဆုံးအကြိမ် အလုပ်အပ်နှံပြီးပါက သင်ရော သင့်သူငယ်ချင်းပါ မှတ်များ ရရှိပါမည်။';
  }
}

class _EarnPointsSection extends StatelessWidget {
  const _EarnPointsSection();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('မှတ်ရယူရန် နည်းလမ်းများ', style: theme.textTheme.titleLarge),
        const SizedBox(height: AppSpacing.md),
        for (var i = 0; i < _earnActions.length; i++) ...[
          _EarnRow(action: _earnActions[i]),
          if (i != _earnActions.length - 1) const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }
}

class _EarnRow extends ConsumerWidget {
  final _EarnAction action;
  const _EarnRow({required this.action});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final highlighted = action.highlighted;
    final radius = BorderRadius.circular(AppRadius.lg);

    return Material(
      color: highlighted ? AppColors.indigo100 : theme.cardColor,
      borderRadius: radius,
      // Shadow only on the non-highlighted rows (highlighted uses a border).
      elevation: 0,
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: radius,
          border: highlighted ? Border.all(color: AppColors.indigo500) : null,
          boxShadow: highlighted
              ? null
              : [
                  BoxShadow(
                    color: AppColors.shadowSm,
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: InkWell(
          borderRadius: radius,
          onTap: () => _handleEarnTap(context, ref, action),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: highlighted
                        ? AppColors.onBrand.withValues(alpha: 0.7)
                        : AppColors.purple100.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  alignment: Alignment.center,
                  child: Text(action.emoji, style: const TextStyle(fontSize: 20)),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        action.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        action.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xxs,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    action.points,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Icon(Icons.chevron_right, size: AppSizes.iconSm, color: theme.hintColor),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
