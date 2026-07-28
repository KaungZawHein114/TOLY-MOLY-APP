import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_strings.dart';
import '../../core/routing/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import 'customer_home_shell.dart';

class ClientGuideScreen extends StatelessWidget {
  const ClientGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBg,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(child: _GuideHeader()),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              sliver: SliverList.separated(
                itemCount: _guideSections.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: AppSpacing.md),
                itemBuilder: (context, index) =>
                    _GuideSectionCard(section: _guideSections[index]),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),
          ],
        ),
      ),
      bottomNavigationBar: const _GuideBottomNavigation(),
    );
  }
}

class _GuideSection {
  final IconData icon;
  final String title;
  final String body;
  final List<String> points;

  const _GuideSection({
    required this.icon,
    required this.title,
    required this.body,
    required this.points,
  });
}

const _guideSections = [
  _GuideSection(
    icon: Icons.apps_rounded,
    title: 'TOLY MOLY App ဘယ်လိုအလုပ်လုပ်လဲ',
    body:
        'TOLY MOLY က အလုပ်လိုအပ်တဲ့ customer နဲ့ ကျွမ်းကျင်တဲ့ worker ကို ချိတ်ဆက်ပေးတဲ့ app ဖြစ်ပါတယ်။',
    points: [
      'Customer က လုပ်ရမယ့်အလုပ်ကို တင်နိုင်ပါတယ်။',
      'Worker က အလုပ်ကို ကြည့်ပြီး လက်ခံနိုင်ပါတယ်။',
      'Booking ပြီးရင် chat နဲ့ အလုပ်အခြေအနေကို ဆက်သွယ်နိုင်ပါတယ်။',
    ],
  ),
  _GuideSection(
    icon: Icons.edit_note_rounded,
    title: 'အလုပ်ဘယ်လိုတင်မလဲ',
    body: 'ပင်မစာမျက်နှာက “အလုပ်တင်မည်” ကိုနှိပ်ပြီး လုပ်ရမယ့်အလုပ်ကို ရေးပါ။',
    points: [
      'အလုပ်အမျိုးအစား၊ နေရာ၊ အချိန်ကို ဖြည့်ပါ။',
      'လုပ်ငန်းအကြောင်းကို ရိုးရိုးရှင်းရှင်း ရေးပါ။',
      'ဘတ်ဂျက်ထည့်ပြီး အလုပ်တင်ရန် အတည်ပြုပါ။',
    ],
  ),
  _GuideSection(
    icon: Icons.search_rounded,
    title: 'Worker ဘယ်လိုရှာမလဲ',
    body:
        'ပင်မစာမျက်နှာက category icon တွေကိုနှိပ်ပြီး သင့်တော်တဲ့ worker တွေကို ရှာနိုင်ပါတယ်။',
    points: [
      'Rating၊ အကွာအဝေး၊ ကျွမ်းကျင်မှုကို ကြည့်ပါ။',
      'Worker profile ထဲမှာ အတွေ့အကြုံနဲ့ အလုပ်အမျိုးအစားကို ဖတ်ပါ။',
      'သင့်တော်တဲ့ worker ကိုရွေးပြီး booking လုပ်ပါ။',
    ],
  ),
  _GuideSection(
    icon: Icons.event_available_rounded,
    title: 'Booking ဘယ်လိုလုပ်မလဲ',
    body:
        'Worker ကိုရွေးပြီးနောက် အချိန်၊ နေရာ၊ ဈေးနှုန်းကို စစ်ပြီး booking အတည်ပြုနိုင်ပါတယ်။',
    points: [
      'Booking ပြီးရင် အလုပ်များ စာမျက်နှာမှာ တွေ့နိုင်ပါတယ်။',
      'လိုအပ်ရင် worker နဲ့ chat ပြောနိုင်ပါတယ်။',
      'အလုပ်အခြေအနေကို check-in/out မှာ ကြည့်နိုင်ပါတယ်။',
    ],
  ),
  _GuideSection(
    icon: Icons.verified_user_rounded,
    title: 'Check In / Check Out ဘယ်လိုအတည်ပြုမလဲ',
    body:
        'Worker ရောက်လာချိန်နဲ့ အလုပ်ပြီးချိန်မှာ customer ဘက်က အတည်ပြုပေးရပါတယ်။',
    points: [
      'Worker check-in လုပ်ရင် အလုပ်များ စာမျက်နှာမှာ အတည်ပြုပါ။',
      'အလုပ်ပြီးရင် check-out ကို ထပ်မံအတည်ပြုပါ။',
      'မမှန်ကန်ရင် report/မအတည်ပြု ရွေးနိုင်ပါတယ်။',
    ],
  ),
  _GuideSection(
    icon: Icons.account_balance_wallet_rounded,
    title: 'ငွေပေးချေမှုနဲ့ လုံခြုံရေး',
    body:
        'Demo အနေနဲ့ Escrow ပုံစံပြထားပြီး အလုပ်ပြီးမှ worker ကို ငွေထုတ်ပေးတဲ့ flow ကိုပြထားပါတယ်။',
    points: [
      'Customer က တင်ထားတဲ့ဈေးကို မြင်နိုင်ပါတယ်။',
      'Worker ရမယ့် amount ကိုလည်း demo အနေနဲ့ ပြထားပါတယ်။',
      'အလုပ်ပြီးဆုံးမှုကို အတည်ပြုပြီးမှ payment flow ပြီးဆုံးပါတယ်။',
    ],
  ),
];

class _GuideHeader extends StatelessWidget {
  const _GuideHeader();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      decoration: const BoxDecoration(
        color: AppColors.purple700,
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(AppRadius.xl),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back_rounded),
            color: AppColors.onBrand,
            tooltip: 'နောက်သို့',
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'အသုံးပြုနည်း',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: AppColors.onBrand,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  'App ကို စတင်သုံးနိုင်ရန် လိုအပ်တဲ့အချက်တွေကို အဆင့်လိုက် ဖတ်နိုင်ပါတယ်။',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.onBrand.withValues(alpha: 0.82),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GuideSectionCard extends StatelessWidget {
  final _GuideSection section;

  const _GuideSectionCard({required this.section});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.lightSurface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.onboardingDivider),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowSm,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.indigo100,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(
                  section.icon,
                  color: AppColors.indigo700,
                  size: 26,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  section.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            section.body,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
              height: 1.45,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          ...section.points.map(
            (point) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.success,
                    size: 18,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      point,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.textPrimary,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GuideBottomNavigation extends ConsumerWidget {
  const _GuideBottomNavigation();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return NavigationBar(
      selectedIndex: 0,
      onDestinationSelected: (index) {
        ref.read(customerTabIndexProvider.notifier).state = index;
        context.go(Routes.customerHome);
      },
      backgroundColor: AppColors.lightSurface,
      indicatorColor: AppColors.purple100,
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home_rounded),
          label: AppStrings.homeTabLabel,
        ),
        NavigationDestination(
          icon: Icon(Icons.work_outline),
          selectedIcon: Icon(Icons.work),
          label: AppStrings.jobsTabLabel,
        ),
        NavigationDestination(
          icon: Icon(Icons.assignment_outlined),
          selectedIcon: Icon(Icons.assignment_rounded),
          label: AppStrings.activityTabLabel,
        ),
        NavigationDestination(
          icon: Icon(Icons.card_giftcard_outlined),
          selectedIcon: Icon(Icons.card_giftcard_rounded),
          label: AppStrings.rewardsTabLabel,
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline_rounded),
          selectedIcon: Icon(Icons.person_rounded),
          label: AppStrings.profileTabLabel,
        ),
      ],
    );
  }
}
