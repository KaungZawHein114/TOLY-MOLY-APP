import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// Rewards & Gamification screen.
///
/// A single continuous, scrollable view: the brand-gradient header scrolls up
/// with the rest of the content (no fixed AppBar). All styling comes from the
/// project's theme tokens (`AppColors`, `AppSpacing`, `AppRadius`, `AppSizes`)
/// and `Theme.of(context)` — no raw hex, no hardcoded text styles.
///
/// Phase-1 rules: static demo values only, no async, no network. The mocked
/// numbers below stand in for what `demo_data.dart` will eventually provide.
///
/// Progression uses TOLY MOLY's 7-tier worker system (Rookie → Ambassador),
/// driven by accumulated AI Points. The demo worker sits at 1,651 points —
/// Tier 3 (Specialist), climbing toward Tier 4 (Trade Pro).
class RewardsScreen extends StatelessWidget {
  const RewardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      // The whole page is one scroll view; the header is part of the content.
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            _HeaderTierSection(),
            SizedBox(height: AppSpacing.lg),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.screen),
              child: _QuickStatsRow(),
            ),
            SizedBox(height: AppSpacing.xxl),
            _RedeemSection(),
            SizedBox(height: AppSpacing.xxl),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.screen),
              child: _LeaderboardCard(),
            ),
            SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// Burmese numeral helpers — format computed values (points, ranks) in
// Myanmar digits with thousands grouping, so nothing is hardcoded per number.
// ============================================================================

String _mmStr(String s) {
  const digits = ['၀', '၁', '၂', '၃', '၄', '၅', '၆', '၇', '၈', '၉'];
  final buf = StringBuffer();
  for (final ch in s.split('')) {
    final c = ch.codeUnitAt(0);
    buf.write(c >= 48 && c <= 57 ? digits[c - 48] : ch);
  }
  return buf.toString();
}

String _mm(int n) {
  final s = n.toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
    buf.write(s[i]);
  }
  return _mmStr(buf.toString());
}

// ============================================================================
// 7-TIER SYSTEM (data)
// ============================================================================

/// One worker tier. `minPoints` is the AI-Points threshold to ENTER the tier;
/// the demo derives the current tier by finding the highest threshold reached.
class _Tier {
  final int level;
  final String name;
  final int minPoints;
  final int minTasks;
  final double minRating;
  final IconData icon;
  final String access; // task access unlocked at this tier
  final String perk; // platform perks
  final String award; // one-time reaching award
  const _Tier({
    required this.level,
    required this.name,
    required this.minPoints,
    required this.minTasks,
    required this.minRating,
    required this.icon,
    required this.access,
    required this.perk,
    required this.award,
  });
}

const List<_Tier> _tiers = [
  _Tier(
    level: 1,
    name: 'Rookie',
    minPoints: 0,
    minTasks: 0,
    minRating: 0,
    icon: Icons.eco,
    access: 'အန္တရာယ်နည်း ပြင်ပလုပ်ငန်းများ — ပစ္စည်းပို့ဆောင်၊ တန်းစီပေး၊ ကုန်ဝယ်ပေး၊ ကြော်ငြာဝေ။',
    perk: 'အစပြုအဆင့် — အခြေခံလုပ်ငန်းများ ရယူနိုင်သည်။',
    award: 'အားလုံးအတွက် အစမှတ်။',
  ),
  _Tier(
    level: 2,
    name: 'Helper',
    minPoints: 50,
    minTasks: 3,
    minRating: 4.0,
    icon: Icons.volunteer_activism,
    access: 'အိမ်တွင်းအလုပ်ငယ်များ — ခြံသန့်ရှင်းရေး၊ ကားဆေး၊ ပစ္စည်းသယ်ကူညီ။',
    perk: 'ကော်မရှင် ၁၅%။ ချက်ချင်း မိုဘိုင်းပိုက်ဆံအိတ် ငွေထုတ်ခွင့်။',
    award: '၃,၀၀၀ ကျပ် ပလက်ဖောင်းအကြွေး — ၂၄ နာရီ မြေပုံပေါ် အသားပေးပြသ။',
  ),
  _Tier(
    level: 3,
    name: 'Specialist',
    minPoints: 450,
    minTasks: 15,
    minRating: 4.2,
    icon: Icons.handyman,
    access: 'ကြီးကြပ်မှုမလို အိမ်တွင်းဝန်ဆောင်မှု — အနက်သန့်ရှင်းရေး၊ အဝတ်လျှော်၊ ပရိဘောဂတပ်ဆင်။',
    perk: 'ကော်မရှင် ၁၄%။ "အခုချက်ချင်း" မြေပုံတွင် ဦးစားပေးအဆင့်။',
    award: '၁၀,၀၀၀ ကျပ် ငွေသားဆု — ဒစ်ဂျစ်တယ်ပိုက်ဆံအိတ်သို့။',
  ),
  _Tier(
    level: 4,
    name: 'Trade Pro',
    minPoints: 1800,
    minTasks: 40,
    minRating: 4.5,
    icon: Icons.engineering,
    access: 'ကျွမ်းကျင်လုပ်ငန်းများ — ရေပိုက်ပြင်၊ လျှပ်စစ်ကြိုးသွယ်၊ အဲကွန်းဝန်ဆောင်မှု။',
    perk: 'ကော်မရှင် ၁၃%။ Tip တိုက်ရိုက်ပေးခွင့် (၀% ဖြတ်တောက်ခြင်းမရှိ)။',
    award: '"Verified Pro" တံဆိပ် + အခမဲ့ Premium Lead ၅ ခု။',
  ),
  _Tier(
    level: 5,
    name: 'Elite',
    minPoints: 5200,
    minTasks: 80,
    minRating: 4.7,
    icon: Icons.military_tech,
    access: 'တန်ဖိုးမြင့်/အရေးကြီးအလုပ်များ — အရေးပေါ်ညပြင်ဆင်မှု၊ အဆင့်မြင့်ပစ္စည်းပြုပြင်။',
    perk: 'ကော်မရှင် ၁၂%။ ငွေထုတ်ခ/အခွန်ခ ကင်းလွတ်ခွင့်။',
    award: '၂၅,၀၀၀ ကျပ် စွမ်းဆောင်ရည်ဆု။',
  ),
  _Tier(
    level: 6,
    name: 'Captain',
    minPoints: 11500,
    minTasks: 150,
    minRating: 4.8,
    icon: Icons.groups,
    access: 'အဖွဲ့လိုက်လုပ်ငန်းများ — ရုံးသန့်ရှင်းရေး၊ အိမ်တစ်လုံးဆေးသုတ်။ အောက်အဆင့်များကို ကြီးကြပ်နိုင်။',
    perk: 'ကော်မရှင် ၁၁%။ စီးပွားရေးစာချုပ်ကြီးများ တင်ဒါဝင်နိုင်။',
    award: 'တံဆိပ်ပါ ယူနီဖောင်း + ၅၀,၀၀၀ ကျပ် လုပ်ငန်းငယ်ထောက်ပံ့ကြေး။',
  ),
  _Tier(
    level: 7,
    name: 'Ambassador',
    minPoints: 23000,
    minTasks: 300,
    minRating: 4.85,
    icon: Icons.shield,
    access: 'ကော်ပိုရိတ်အကောင့်၊ VIP ဖောက်သည်၊ တရားဝင်လေ့ကျင့်ရေးအလုပ်ရုံများ ဦးဆောင်။',
    perk: 'ကော်မရှင် ၁၀% (အနိမ့်ဆုံး)။ အမြဲတမ်း ဦးစားပေး Booking။',
    award: 'Hall of Fame + အမြဲတည် "Master Ambassador Shield"။',
  ),
];

// The demo worker's live stats (would come from demo_data.dart in Phase 2).
const int _currentPoints = 1651;

/// Index into [_tiers] of the highest tier whose point threshold is reached.
int _currentTierIndex() {
  var idx = 0;
  for (var i = 0; i < _tiers.length; i++) {
    if (_currentPoints >= _tiers[i].minPoints) idx = i;
  }
  return idx;
}

// ============================================================================
// A. HEADER + TIER CARD
// ============================================================================

class _HeaderTierSection extends StatelessWidget {
  const _HeaderTierSection();

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
          // Title + avatar row.
          Row(
            children: [
              Expanded(
                child: Text(
                  'ဆုလာဘ်များ',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: AppColors.onBrand,
                  ),
                ),
              ),
              _Avatar(
                initials: 'TM',
                size: AppSizes.avatarSm,
                background: AppColors.onBrand.withValues(alpha: 0.18),
                foreground: AppColors.onBrand,
                borderColor: AppColors.onBrand.withValues(alpha: 0.4),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          _buildTierCard(context),
        ],
      ),
    );
  }

  /// Glassmorphic tier card: semi-transparent fill + light border on top of
  /// the brand gradient. Shows the current 7-tier standing (not membership).
  Widget _buildTierCard(BuildContext context) {
    final theme = Theme.of(context);
    final tierIdx = _currentTierIndex();
    final tier = _tiers[tierIdx];
    final hasNext = tierIdx < _tiers.length - 1;
    final nextTier = hasNext ? _tiers[tierIdx + 1] : null;

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
                      'Tier ${tier.level} · ${tier.name}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: AppColors.onBrand,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      '${_mm(_currentPoints)} AI မှတ်',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.onBrandMuted,
                      ),
                    ),
                  ],
                ),
              ),
              // Benefits button → full 7-tier ladder sheet.
              TextButton(
                onPressed: () => _showBenefitsSheet(context),
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
          _buildProgress(context, tier, nextTier),
        ],
      ),
    );
  }

  Widget _buildProgress(BuildContext context, _Tier tier, _Tier? nextTier) {
    final theme = Theme.of(context);

    if (nextTier == null) {
      // Ambassador — top tier, nothing left to climb.
      return Row(
        children: [
          const Icon(Icons.workspace_premium,
              color: AppColors.thanakaGold, size: AppSizes.iconSm),
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

    final remaining = nextTier.minPoints - _currentPoints;
    final span = nextTier.minPoints - tier.minPoints;
    final progress = ((_currentPoints - tier.minPoints) / span).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                'Tier ${nextTier.level} · ${nextTier.name} သို့ရောက်ရန်',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.onBrandMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              '${_mm(remaining)} မှတ် လိုသေးသည်',
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

/// Bottom sheet: the full 7-tier ladder. Current tier is highlighted, already
/// achieved tiers are checked, higher tiers show a lock.
void _showBenefitsSheet(BuildContext context) {
  final currentIdx = _currentTierIndex();
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
                  const Icon(Icons.stairs, color: AppColors.purple700),
                  const SizedBox(width: AppSpacing.sm),
                  Text('အဆင့် ၇ ဆင့် စနစ်', style: theme.textTheme.titleLarge),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  0,
                  AppSpacing.lg,
                  AppSpacing.xxl,
                ),
                itemCount: _tiers.length,
                separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
                itemBuilder: (ctx, i) => _TierRow(
                  tier: _tiers[i],
                  status: i < currentIdx
                      ? _TierStatus.achieved
                      : (i == currentIdx
                          ? _TierStatus.current
                          : _TierStatus.locked),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

enum _TierStatus { achieved, current, locked }

class _TierRow extends StatelessWidget {
  final _Tier tier;
  final _TierStatus status;
  const _TierRow({required this.tier, required this.status});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCurrent = status == _TierStatus.current;
    final isLocked = status == _TierStatus.locked;

    return Opacity(
      opacity: isLocked ? 0.6 : 1,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: isCurrent ? AppColors.purple100.withValues(alpha: 0.5) : theme.cardColor,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: isCurrent ? AppColors.purple700 : theme.dividerColor,
            width: isCurrent ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: isLocked ? null : AppColors.purpleGradient,
                    color: isLocked ? theme.disabledColor.withValues(alpha: 0.15) : null,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    isLocked ? Icons.lock_outline : tier.icon,
                    size: AppSizes.iconSm,
                    color: isLocked ? theme.hintColor : AppColors.onBrand,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    'Tier ${tier.level} · ${tier.name}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (isCurrent)
                  _pill(theme, 'လက်ရှိအဆင့်', AppColors.purple700)
                else if (status == _TierStatus.achieved)
                  const Icon(Icons.check_circle, color: AppColors.success, size: AppSizes.iconMd),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            _detailLine(theme, Icons.card_giftcard, tier.award),
            _detailLine(theme, Icons.workspace_premium, tier.perk),
            _detailLine(theme, Icons.assignment_turned_in, tier.access),
            const SizedBox(height: AppSpacing.sm),
            Text(
              tier.level == 1
                  ? 'ဝင်ရောက်ရန် — အစပြုအဆင့်'
                  : 'ဝင်ရောက်ရန် — ${_mm(tier.minPoints)} AI မှတ် • အလုပ် ${_mm(tier.minTasks)} ခု • ${_mmStr(tier.minRating.toString())}★',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.indigo700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pill(ThemeData theme, String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xxs),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Text(
          text,
          style: theme.textTheme.bodySmall?.copyWith(color: color, fontWeight: FontWeight.w700),
        ),
      );

  Widget _detailLine(ThemeData theme, IconData icon, String text) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.xs),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: AppSizes.iconSm, color: theme.hintColor),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(text, style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor)),
            ),
          ],
        ),
      );
}

// ============================================================================
// B. QUICK STATS (compact grid)
// ============================================================================

class _QuickStatsRow extends StatelessWidget {
  const _QuickStatsRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Expanded(
          child: _StatCard(emoji: '🔥', label: 'အလုပ်ပြီးစီးမှု', value: '၄'),
        ),
        SizedBox(width: AppSpacing.md),
        Expanded(
          child: _StatCard(
            emoji: '⭐',
            label: 'အဆင့်သတ်မှတ်ချက်',
            value: '၄.၉',
          ),
        ),
        SizedBox(width: AppSpacing.md),
        Expanded(
          child: _StatCard(emoji: '🎯', label: 'အပိုဆုကြေး', value: '၃ ဆု'),
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
// C. REWARD REDEMPTION (horizontal scroll + "See All" locked catalogue)
// ============================================================================

/// One reward. `unlockTier` is the tier LEVEL that unlocks it; anything above
/// the worker's current tier is a locked "game item" shown in the See-All
/// catalogue with the tier needed to unlock it.
class _Reward {
  final IconData icon;
  final String title;
  final String subtitle;
  final String cost; // points cost when redeemable ('—' for tier-unlock perks)
  final int unlockTier;
  const _Reward({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.cost,
    required this.unlockTier,
  });
}

const List<_Reward> _rewards = [
  _Reward(icon: Icons.phone_android, title: '၁၀,၀၀၀ ကျပ်', subtitle: 'ဖုန်းဘေလ်', cost: '၅၀၀ မှတ်', unlockTier: 1),
  _Reward(icon: Icons.local_grocery_store, title: 'City Mart', subtitle: '၅,၀၀၀ ကျပ် ကူပွန်', cost: '၃၀၀ မှတ်', unlockTier: 1),
  _Reward(icon: Icons.checkroom, title: 'Tolymoly', subtitle: 'တီရှပ် အင်္ကျီ', cost: '၁,၀၀၀ မှတ်', unlockTier: 2),
  _Reward(icon: Icons.bolt, title: 'Map Boost', subtitle: '၂၄ နာရီ အသားပေးပြ', cost: '၈၀၀ မှတ်', unlockTier: 2),
  _Reward(icon: Icons.verified, title: 'Verified Pro', subtitle: 'ပရော်ဖက်ရှင်နယ် တံဆိပ်', cost: '—', unlockTier: 4),
  _Reward(icon: Icons.person_search, title: 'Premium Leads', subtitle: 'ဖောက်သည် ၅ ဦး', cost: '—', unlockTier: 4),
  _Reward(icon: Icons.checkroom, title: 'ယူနီဖောင်း', subtitle: 'Polo + Tool Vest', cost: '—', unlockTier: 6),
  _Reward(icon: Icons.savings, title: '၅၀,၀၀၀ ကျပ်', subtitle: 'လုပ်ငန်းငယ် ထောက်ပံ့ကြေး', cost: '—', unlockTier: 6),
  _Reward(icon: Icons.shield, title: 'Ambassador Shield', subtitle: 'အမြဲတည် တံဆိပ်', cost: '—', unlockTier: 7),
];

class _RedeemSection extends StatelessWidget {
  const _RedeemSection();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentLevel = _tiers[_currentTierIndex()].level;
    // The rail shows what the worker can redeem right now; the full locked
    // catalogue lives behind "See All".
    final unlocked = _rewards.where((r) => r.unlockTier <= currentLevel).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'ဆုလာဘ်များ လဲလှယ်ရန်',
                  style: theme.textTheme.titleLarge,
                ),
              ),
              TextButton(
                onPressed: () => _showAllRewardsSheet(context, currentLevel),
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
            itemCount: unlocked.length,
            itemBuilder: (context, i) => Padding(
              padding: EdgeInsets.only(
                right: i == unlocked.length - 1 ? 0 : AppSpacing.md,
              ),
              child: _RewardCard(reward: unlocked[i], locked: false),
            ),
          ),
        ),
      ],
    );
  }
}

/// See-All catalogue: every reward, including locked higher-tier "game items".
void _showAllRewardsSheet(BuildContext context, int currentLevel) {
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
                  const Icon(Icons.card_giftcard, color: AppColors.purple700),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text('ဆုလာဘ်အားလုံး', style: theme.textTheme.titleLarge),
                  ),
                  Text(
                    'သော့ဖွင့်ရန် အဆင့်တက်ပါ',
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                  ),
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
                    // Two columns, respecting the sheet width.
                    final w = (constraints.maxWidth - AppSpacing.md) / 2;
                    return Wrap(
                      spacing: AppSpacing.md,
                      runSpacing: AppSpacing.md,
                      children: [
                        for (final r in _rewards)
                          SizedBox(
                            width: w,
                            height: 180,
                            child: _RewardCard(
                              reward: r,
                              locked: r.unlockTier > currentLevel,
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

class _RewardCard extends StatelessWidget {
  final _Reward reward;
  final bool locked;
  const _RewardCard({required this.reward, required this.locked});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Opacity(
      opacity: locked ? 0.65 : 1,
      child: Container(
        width: 150,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: locked ? Border.all(color: theme.dividerColor) : null,
          boxShadow: locked
              ? null
              : [
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
            // Icon (with a lock overlay when locked).
            Stack(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: locked
                        ? theme.disabledColor.withValues(alpha: 0.12)
                        : AppColors.indigo100,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    reward.icon,
                    color: locked ? theme.hintColor : AppColors.indigo700,
                    size: AppSizes.iconMd,
                  ),
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
              'Tier ${_mm(reward.unlockTier)} ဖွင့်',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.hintColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
}

// ============================================================================
// D. LEADERBOARD (podium + list) — data changes per scope
// ============================================================================

/// One leaderboard entrant.
class _Player {
  final String name;
  final int points;
  final int rank;
  const _Player({required this.name, required this.points, required this.rank});
}

/// A full board for one scope: top-3 (podium) + runners-up + optional footer
/// note (e.g. the worker's own national rank when out of the top 5).
class _Board {
  final List<_Player> top3; // rank order: 1, 2, 3
  final List<_Player> runnersUp;
  final String? youNote;
  const _Board({required this.top3, required this.runnersUp, this.youNote});
}

// Neighborhood — the worker leads their own township.
const _neighborhood = _Board(
  top3: [
    _Player(name: 'You', points: 1651, rank: 1),
    _Player(name: 'Su Su', points: 1420, rank: 2),
    _Player(name: 'Aung', points: 1390, rank: 3),
  ],
  runnersUp: [
    _Player(name: 'Nilar', points: 1240, rank: 4),
    _Player(name: 'Kyaw', points: 1180, rank: 5),
  ],
);

// Nationwide — different, much higher-scoring people; the worker isn't top-5.
const _nationwide = _Board(
  top3: [
    _Player(name: 'ဟိန်းထက်', points: 48900, rank: 1),
    _Player(name: 'အိအိဖြူ', points: 42300, rank: 2),
    _Player(name: 'ဇော်မင်း', points: 39750, rank: 3),
  ],
  runnersUp: [
    _Player(name: 'မြသီရိ', points: 35100, rank: 4),
    _Player(name: 'ကောင်းစံ', points: 31900, rank: 5),
  ],
  youNote: 'သင့်နိုင်ငံအဆင့် — #၄,၅၁၂',
);

class _LeaderboardCard extends StatefulWidget {
  const _LeaderboardCard();

  @override
  State<_LeaderboardCard> createState() => _LeaderboardCardState();
}

class _LeaderboardCardState extends State<_LeaderboardCard> {
  // 0 = neighborhood, 1 = nationwide. Local UI-only state.
  int _scope = 0;

  _Board get _board => _scope == 0 ? _neighborhood : _nationwide;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowMd,
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildScopeToggle(context),
          const SizedBox(height: AppSpacing.xl),
          // AnimatedSwitcher so swapping scope visibly re-draws the chart.
          AnimatedSwitcher(
            duration: AppMotion.medium,
            child: _buildPodium(context, key: ValueKey(_scope)),
          ),
          const SizedBox(height: AppSpacing.lg),
          Divider(color: theme.dividerColor, height: AppSpacing.xl),
          _buildRunnersUpList(context),
          if (_board.youNote != null) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.indigo100,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Row(
                children: [
                  const Icon(Icons.person_pin_circle, color: AppColors.indigo700, size: AppSizes.iconSm),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    _board.youNote!,
                    style: theme.textTheme.titleSmall?.copyWith(color: AppColors.indigo700),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Segmented control: အနီးအနား (Neighborhood) / နိုင်ငံတစ်ဝှမ်း (Nationwide).
  Widget _buildScopeToggle(BuildContext context) {
    final theme = Theme.of(context);
    Widget segment(String label, int value) {
      final selected = _scope == value;
      return Expanded(
        child: GestureDetector(
          onTap: () => setState(() => _scope = value),
          child: AnimatedContainer(
            duration: AppMotion.fast,
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm + 2),
            decoration: BoxDecoration(
              color: selected ? AppColors.purple700 : Colors.transparent,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleSmall?.copyWith(
                color: selected ? AppColors.onBrand : theme.hintColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xxs),
      decoration: BoxDecoration(
        color: AppColors.purple100.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        children: [
          segment('အနီးအနား', 0),
          segment('နိုင်ငံတစ်ဝှမ်း', 1),
        ],
      ),
    );
  }

  /// Podium bar heights are computed from points, so the "chart" visibly
  /// changes shape when the scope (and its data) changes. Rank 1 is always
  /// tallest (104), rank 3 shortest (58), rank 2 interpolated between them.
  Widget _buildPodium(BuildContext context, {required Key key}) {
    final r1 = _board.top3[0];
    final r2 = _board.top3[1];
    final r3 = _board.top3[2];
    final h2 = _middleHeight(r1.points, r2.points, r3.points);

    return Row(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(child: _PodiumColumn(player: r2, height: h2)),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: _PodiumColumn(player: r1, height: 104, crowned: true)),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: _PodiumColumn(player: r3, height: 58)),
      ],
    );
  }

  double _middleHeight(int p1, int p2, int p3) {
    if (p1 == p3) return 104;
    final t = (p2 - p3) / (p1 - p3);
    return 58 + t * (104 - 58);
  }

  Widget _buildRunnersUpList(BuildContext context) {
    final runners = _board.runnersUp;
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: runners.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, i) => _RunnerUpRow(player: runners[i]),
    );
  }
}

class _PodiumColumn extends StatelessWidget {
  final _Player player;
  final double height;
  final bool crowned;
  const _PodiumColumn({
    required this.player,
    required this.height,
    this.crowned = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Avatar + optional crown.
        SizedBox(
          height: AppSizes.avatar + AppSpacing.md,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomCenter,
            children: [
              _Avatar(
                initials: _initials(player.name),
                size: crowned ? AppSizes.avatar : AppSizes.avatarSm,
                background: AppColors.purple100,
                foreground: AppColors.purple700,
                borderColor: crowned ? AppColors.thanakaGold : null,
              ),
              if (crowned)
                const Positioned(
                  top: -6,
                  child: Icon(
                    Icons.emoji_events,
                    color: AppColors.thanakaGold,
                    size: AppSizes.iconMd,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          player.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          _mm(player.points),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
        ),
        const SizedBox(height: AppSpacing.xs),
        // Podium pedestal.
        AnimatedContainer(
          duration: AppMotion.medium,
          curve: AppMotion.enter,
          height: height,
          decoration: BoxDecoration(
            gradient: crowned
                ? AppColors.purpleGradient
                : const LinearGradient(
                    colors: [
                      AppColors.purple300,
                      AppColors.purple500,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppRadius.sm),
            ),
          ),
          alignment: Alignment.topCenter,
          padding: const EdgeInsets.only(top: AppSpacing.sm),
          child: Text(
            '${player.rank}',
            style: theme.textTheme.titleLarge?.copyWith(
              color: AppColors.onBrand,
            ),
          ),
        ),
      ],
    );
  }

  String _initials(String name) =>
      name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();
}

class _RunnerUpRow extends StatelessWidget {
  final _Player player;
  const _RunnerUpRow({required this.player});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        SizedBox(
          width: 28,
          child: Text(
            _mm(player.rank),
            style: theme.textTheme.titleSmall?.copyWith(color: theme.hintColor),
          ),
        ),
        _Avatar(
          initials: player.name.trim().isEmpty
              ? '?'
              : player.name.trim()[0].toUpperCase(),
          size: AppSizes.avatarSm,
          background: AppColors.purple100,
          foreground: AppColors.purple700,
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(
            player.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleSmall,
          ),
        ),
        Text(
          '${_mm(player.points)} မှတ်',
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppColors.purple700,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// Shared: circular initials avatar
// ============================================================================

class _Avatar extends StatelessWidget {
  final String initials;
  final double size;
  final Color background;
  final Color foreground;
  final Color? borderColor;
  const _Avatar({
    required this.initials,
    required this.size,
    required this.background,
    required this.foreground,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: background,
        shape: BoxShape.circle,
        border: borderColor == null
            ? null
            : Border.all(color: borderColor!, width: 2),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          color: foreground,
          fontWeight: FontWeight.w800,
          fontSize: size * 0.38,
        ),
      ),
    );
  }
}
