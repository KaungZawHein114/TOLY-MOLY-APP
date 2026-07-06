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
class RewardsScreen extends StatelessWidget {
  const RewardsScreen({super.key});

  // Leaderboard scope: neighborhood vs nationwide. Purely local UI state, so a
  // StatefulWidget-free StatefulBuilder-style toggle would work, but the scope
  // only affects a label here, so we keep it as simple internal state.
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
  /// the brand gradient.
  Widget _buildTierCard(BuildContext context) {
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
                  Icons.workspace_premium,
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
                      'Gold Member',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: AppColors.onBrand,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      '၁,၆၅၁ မှတ်',
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
    // 1,651 / 2,000 to Platinum — 349 remaining.
    const double progress = 1651 / 2000;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Platinum သို့ရောက်ရန်',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.onBrandMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '၃၄၉ မှတ် လိုသေးသည်',
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
// C. REWARD REDEMPTION (horizontal scroll)
// ============================================================================

/// One redeemable reward — mock model standing in for future `demo_data.dart`.
class _Reward {
  final IconData icon;
  final String title;
  final String subtitle;
  final String cost;
  const _Reward({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.cost,
  });
}

const List<_Reward> _rewards = [
  _Reward(
    icon: Icons.phone_android,
    title: '၁၀,၀၀၀ ကျပ်',
    subtitle: 'ဖုန်းဘေလ်',
    cost: '၅၀၀ မှတ်',
  ),
  _Reward(
    icon: Icons.local_grocery_store,
    title: 'City Mart',
    subtitle: '၅,၀၀၀ ကျပ် ကူပွန်',
    cost: '၃၀၀ မှတ်',
  ),
  _Reward(
    icon: Icons.checkroom,
    title: 'Tolymoly',
    subtitle: 'တီရှပ် အင်္ကျီ',
    cost: '၁,၀၀၀ မှတ်',
  ),
];

class _RedeemSection extends StatelessWidget {
  const _RedeemSection();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
                onPressed: () {},
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
            itemCount: _rewards.length,
            itemBuilder: (context, i) => Padding(
              padding: EdgeInsets.only(
                right: i == _rewards.length - 1 ? 0 : AppSpacing.md,
              ),
              child: _RewardCard(reward: _rewards[i]),
            ),
          ),
        ),
      ],
    );
  }
}

class _RewardCard extends StatelessWidget {
  final _Reward reward;
  const _RewardCard({required this.reward});

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
              color: AppColors.indigo100,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            alignment: Alignment.center,
            child: Icon(
              reward.icon,
              color: AppColors.indigo700,
              size: AppSizes.iconMd,
            ),
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
    );
  }
}

// ============================================================================
// D. LEADERBOARD (podium + list)
// ============================================================================

/// One leaderboard entrant — mock model.
class _Player {
  final String name;
  final String points;
  final int rank;
  const _Player({
    required this.name,
    required this.points,
    required this.rank,
  });
}

const _rank1 = _Player(name: 'You', points: '၁,၆၅၁', rank: 1);
const _rank2 = _Player(name: 'Su Su', points: '၁,၄၂၀', rank: 2);
const _rank3 = _Player(name: 'Aung', points: '၁,၃၉၀', rank: 3);

const List<_Player> _runnersUp = [
  _Player(name: 'Nilar', points: '၁,၂၄၀', rank: 4),
  _Player(name: 'Kyaw', points: '၁,၁၈၀', rank: 5),
];

class _LeaderboardCard extends StatefulWidget {
  const _LeaderboardCard();

  @override
  State<_LeaderboardCard> createState() => _LeaderboardCardState();
}

class _LeaderboardCardState extends State<_LeaderboardCard> {
  // 0 = neighborhood, 1 = nationwide. Local UI-only state.
  int _scope = 0;

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
          _buildPodium(context),
          const SizedBox(height: AppSpacing.lg),
          Divider(color: theme.dividerColor, height: AppSpacing.xl),
          _buildRunnersUpList(context),
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

  Widget _buildPodium(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: const [
        Expanded(child: _PodiumColumn(player: _rank2, height: 74)),
        SizedBox(width: AppSpacing.sm),
        Expanded(child: _PodiumColumn(player: _rank1, height: 104, crowned: true)),
        SizedBox(width: AppSpacing.sm),
        Expanded(child: _PodiumColumn(player: _rank3, height: 58)),
      ],
    );
  }

  Widget _buildRunnersUpList(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _runnersUp.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, i) => _RunnerUpRow(player: _runnersUp[i]),
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
          player.points,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
        ),
        const SizedBox(height: AppSpacing.xs),
        // Podium pedestal.
        Container(
          height: height,
          decoration: BoxDecoration(
            gradient: crowned
                ? AppColors.purpleGradient
                : LinearGradient(
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
            '${player.rank}',
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
          '${player.points} မှတ်',
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
