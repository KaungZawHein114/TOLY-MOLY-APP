import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:toly_moly/main.dart';
import 'package:toly_moly/core/constants/app_strings.dart';
import 'package:toly_moly/core/constants/onboarding_strings.dart';
import 'package:toly_moly/core/constants/profile_strings.dart';
import 'package:toly_moly/core/routing/app_router.dart';

void main() {
  setUp(() {
    // Each test below jumps straight to a customer route via appRouter.go,
    // bypassing onboarding — start from a clean stack every time.
    appRouter.go(Routes.onboardingWelcome);
  });

  testWidgets('Bottom nav switches the visible tab', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: TolyMolyApp()));
    appRouter.go(Routes.customerHome);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // Each nav tab maps 1-to-1 to its IndexedStack slot.
    expect(tester.widget<IndexedStack>(find.byType(IndexedStack)).index, 0);
    expect(find.text(AppStrings.homeCategoriesTitle), findsOneWidget);

    // Jobs tab → slot 1 (discussion + check-in/check-out).
    await tester.tap(find.text(AppStrings.jobsTabLabel));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(tester.widget<IndexedStack>(find.byType(IndexedStack)).index, 1);
    expect(find.text(AppStrings.jobsTabLabel), findsWidgets);
    expect(find.text('စာတိုများ'), findsOneWidget);
    expect(find.text('Check In / Out'), findsOneWidget);

    // Activity tab → slot 2 (ongoing / pending / history works).
    await tester.tap(find.text(AppStrings.activityTabLabel));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(tester.widget<IndexedStack>(find.byType(IndexedStack)).index, 2);
    expect(find.text('လက်ရှိလုပ်နေသော အလုပ်များ'), findsOneWidget);

    await tester.tap(find.text('စောင့်ဆိုင်းနေသည်'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('အတည်ပြုရန် စောင့်နေသော အလုပ်များ'), findsOneWidget);

    await tester.tap(find.text('မှတ်တမ်း'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('ပြီးဆုံးခဲ့သော အလုပ်မှတ်တမ်း'), findsOneWidget);

    // Account tab → slot 4.
    await tester.tap(find.text(AppStrings.profileTabLabel));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(tester.widget<IndexedStack>(find.byType(IndexedStack)).index, 4);

    await tester.tap(find.text(AppStrings.homeTabLabel));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(tester.widget<IndexedStack>(find.byType(IndexedStack)).index, 0);
  });

  testWidgets('Post a task quick action navigates to the AI Task Assistant',
      (tester) async {
    await tester.pumpWidget(const ProviderScope(child: TolyMolyApp()));
    appRouter.go(Routes.customerHome);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    await tester.tap(find.text(AppStrings.homePostTaskAction));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // Post a task now opens the AI-driven task posting flow (its AppBar title).
    expect(find.text('AI Task Assistant'), findsOneWidget);
  });

  testWidgets('Find a worker quick action navigates to WorkerListScreen',
      (tester) async {
    await tester.pumpWidget(const ProviderScope(child: TolyMolyApp()));
    appRouter.go(Routes.customerHome);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    await tester.tap(find.text(AppStrings.homeFindWorkerAction));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text(AppStrings.exploreAllWorkers), findsOneWidget);
  });

  testWidgets('How to use app card opens guide page with bottom nav',
      (tester) async {
    await tester.pumpWidget(const ProviderScope(child: TolyMolyApp()));
    appRouter.go(Routes.customerHome);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    final guideCard = find.text('ဒီ App ကို ဘယ်လိုသုံးမလဲ?');
    await tester.dragUntilVisible(
      guideCard,
      find.byType(CustomScrollView),
      const Offset(0, -260),
    );
    await tester.pump();
    await tester.tap(guideCard);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('အသုံးပြုနည်း'), findsOneWidget);
    expect(find.text('TOLY MOLY App ဘယ်လိုအလုပ်လုပ်လဲ'), findsOneWidget);
    expect(find.text(AppStrings.jobsTabLabel), findsWidgets);
    expect(find.text(AppStrings.profileTabLabel), findsWidgets);
  });

  testWidgets('Profile worker signup card opens tasker signup', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: TolyMolyApp()));
    appRouter.go(Routes.customerHome);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    await tester.tap(find.text(AppStrings.profileTabLabel));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    await tester.dragUntilVisible(
      find.text(ProfileStrings.becomeTaskerCta),
      find.byType(ListView).first,
      const Offset(0, -300),
    );
    await tester.pump();
    await tester.tap(find.text(ProfileStrings.becomeTaskerCta));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text(OnboardingStrings.aboutYouTitle), findsWidgets);
    expect(find.text(OnboardingStrings.nameLabel), findsOneWidget);
  });

  testWidgets('Client dashboard check icon opens demo check-in confirmation',
      (tester) async {
    await tester.pumpWidget(const ProviderScope(child: TolyMolyApp()));
    appRouter.go(Routes.customerHome);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    await tester.tap(find.byTooltip('Check-in / Check-out'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    await tester.tap(find.text('Worker check-in စမ်းမည်'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text(AppStrings.checkinCardTitle), findsOneWidget);

    await tester.tap(find.text(AppStrings.checkinAcceptCta));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('ရောက်ရှိကြောင်း အတည်ပြုပြီးပါပြီ။'), findsOneWidget);
  });

  testWidgets(
      'Category card tap navigates to WorkerListScreen filtered by skill',
      (tester) async {
    await tester.pumpWidget(const ProviderScope(child: TolyMolyApp()));
    appRouter.go(Routes.customerHome);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // Category grid is below the hero header and action cards — scroll to it.
    await tester.dragUntilVisible(
      find.text("အိမ်သန့်ရှင်းရေး"),
      find.byType(CustomScrollView),
      const Offset(0, -200),
    );
    await tester.pump();

    // First category in demo_data.dart is "Home Cleaning" -> skill "Cleaner".
    // With the extra "post step by step" button now on the home screen, the
    // category grid can sit below the fold — scroll it into view before tapping.
    final cleaningCard = find.text("အိမ်သန့်ရှင်းရေး");
    await tester.dragUntilVisible(
      cleaningCard,
      find.byType(ListView).first,
      const Offset(0, -200),
    );
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(cleaningCard);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text("Cleaner"), findsWidgets);
  });

  testWidgets(
      'Home header and category grid do not overflow at 360dp width and 1.6x text scale',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          size: Size(360, 800),
          textScaler: TextScaler.linear(1.6),
        ),
        child: const ProviderScope(child: TolyMolyApp()),
      ),
    );
    appRouter.go(Routes.customerHome);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(tester.takeException(), isNull);
  });
}
