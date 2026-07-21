import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/routing/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

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
                child: const Icon(
                  Icons.diamond,
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
                      'Gold VIP',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: AppColors.onBrand,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      '၁,၂၅၀ မှတ်',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.onBrandMuted,
                      ),
                    ),
                  ],
                ),
              ),
              // Benefits pill button.
              TextButton(
                onPressed: () {},
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
          _buildProgress(context),
        ],
      ),
    );
  }

  Widget _buildProgress(BuildContext context) {
    final theme = Theme.of(context);
    // 1,250 / 2,000 to Platinum VIP — 750 remaining.
    const double progress = 1250 / 2000;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                'Platinum VIP သို့ရောက်ရန်',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.onBrandMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              '၇၅၀ မှတ် လိုသေးသည်',
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
class _Coupon {
  final IconData icon;
  final Color accent;
  final Color accentSurface;
  final String title;
  final String subtitle;
  final String cost;
  const _Coupon({
    required this.icon,
    required this.accent,
    required this.accentSurface,
    required this.title,
    required this.subtitle,
    required this.cost,
  });
}

const List<_Coupon> _coupons = [
  _Coupon(
    icon: Icons.cleaning_services,
    accent: AppColors.teal,
    accentSurface: AppColors.blue100,
    title: 'သန့်ရှင်းရေး Discount',
    subtitle: '၅,၀၀၀ ကျပ် လျှော့စျေး',
    cost: '၅၀၀ မှတ်',
  ),
  _Coupon(
    icon: Icons.bolt,
    accent: AppColors.indigo700,
    accentSurface: AppColors.indigo100,
    title: 'Priority Matching',
    subtitle: 'အလုပ်သမား အမြန်ရှာရန်',
    cost: '၃၀၀ မှတ်',
  ),
  _Coupon(
    icon: Icons.storefront,
    accent: AppColors.tealDark,
    accentSurface: AppColors.tealLight,
    title: 'City Mart',
    subtitle: '၃,၀၀၀ ကျပ် ကူပွန်',
    cost: '၈၀၀ မှတ်',
  ),
  _Coupon(
    icon: Icons.ac_unit,
    accent: AppColors.indigo500,
    accentSurface: AppColors.indigo100,
    title: 'အဲကွန်း ဝန်ဆောင်မှု',
    subtitle: '၁၀,၀၀၀ ကျပ် လျှော့စျေး',
    cost: '၁,၀၀၀ မှတ်',
  ),
  _Coupon(
    icon: Icons.local_cafe,
    accent: AppColors.tealDark,
    accentSurface: AppColors.tealLight,
    title: 'Coffee Voucher',
    subtitle: '၂,၀၀၀ ကျပ် ကူပွန်',
    cost: '၂၀၀ မှတ်',
  ),
  _Coupon(
    icon: Icons.plumbing,
    accent: AppColors.teal,
    accentSurface: AppColors.blue100,
    title: 'ရေပိုက် ပြင်ဆင်ခ',
    subtitle: '၈,၀၀၀ ကျပ် လျှော့စျေး',
    cost: '၉၀၀ မှတ်',
  ),
  _Coupon(
    icon: Icons.local_shipping,
    accent: AppColors.indigo700,
    accentSurface: AppColors.indigo100,
    title: 'အခမဲ့ ပို့ဆောင်ခ',
    subtitle: 'တစ်ကြိမ်စာ ပို့ဆောင်ခ',
    cost: '၄၀၀ မှတ်',
  ),
];

/// The horizontal rail shows the first few; the rest live behind "See All".
const int _couponRailCount = 4;

class _CouponsSection extends StatelessWidget {
  const _CouponsSection();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final railCoupons = _coupons.take(_couponRailCount).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'လဲလှယ်ရန် ကူပွန်များ',
                  style: theme.textTheme.titleLarge,
                ),
              ),
              TextButton(
                onPressed: () => _showAllCouponsSheet(context),
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
          height: 172,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
            itemCount: railCoupons.length,
            itemBuilder: (context, i) => Padding(
              padding: EdgeInsets.only(
                right: i == railCoupons.length - 1 ? 0 : AppSpacing.md,
              ),
              child: _CouponCard(coupon: railCoupons[i]),
            ),
          ),
        ),
      ],
    );
  }
}

/// See-All catalogue: every coupon in a 2-column grid.
void _showAllCouponsSheet(BuildContext context) {
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
                  Text('ကူပွန်အားလုံး', style: theme.textTheme.titleLarge),
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
                            height: 172,
                            child: _CouponCard(coupon: c),
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

class _CouponCard extends StatelessWidget {
  final _Coupon coupon;
  const _CouponCard({required this.coupon});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
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
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: coupon.accentSurface,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            alignment: Alignment.center,
            child: Icon(coupon.icon, color: coupon.accent, size: AppSizes.iconMd),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            coupon.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            coupon.subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {},
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.purple700,
                foregroundColor: AppColors.onBrand,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
              child: Text(
                coupon.cost,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.onBrand,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
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

/// Routes each earn-action to the relevant page. Review/Tip go to the client's
/// bookings (where those actions happen); Weekly booking opens task posting;
/// Invite has no dedicated page yet, so it surfaces a friendly notice.
void _handleEarnTap(BuildContext context, _EarnAction action) {
  switch (action.target) {
    case _EarnTarget.review:
    case _EarnTarget.tip:
      context.push(Routes.activity);
      break;
    case _EarnTarget.weeklyBooking:
      context.push(Routes.postTask);
      break;
    case _EarnTarget.invite:
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ဖိတ်ခေါ်မှုစနစ် မကြာမီ လာမည်နော်')),
      );
      break;
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

class _EarnRow extends StatelessWidget {
  final _EarnAction action;
  const _EarnRow({required this.action});

  @override
  Widget build(BuildContext context) {
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
          onTap: () => _handleEarnTap(context, action),
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
