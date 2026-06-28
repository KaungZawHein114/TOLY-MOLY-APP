import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:toly_moly/main.dart';
import 'package:toly_moly/core/constants/app_strings.dart';
import 'package:toly_moly/core/constants/onboarding_strings.dart';
import 'package:toly_moly/core/constants/profile_strings.dart';
import 'package:toly_moly/core/constants/task_posting_strings.dart';
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

    expect(tester.widget<IndexedStack>(find.byType(IndexedStack)).index, 0);
    expect(find.text(AppStrings.homeCategoriesTitle), findsOneWidget);

    await tester.tap(find.text(AppStrings.activityTabLabel));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(tester.widget<IndexedStack>(find.byType(IndexedStack)).index, 1);

    await tester.tap(find.text(AppStrings.profileTabLabel));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(tester.widget<IndexedStack>(find.byType(IndexedStack)).index, 2);

    await tester.tap(find.text(AppStrings.homeTabLabel));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(tester.widget<IndexedStack>(find.byType(IndexedStack)).index, 0);
  });

  testWidgets('Post a task quick action navigates to the task posting flow (Screen 1)',
      (tester) async {
    await tester.pumpWidget(const ProviderScope(child: TolyMolyApp()));
    appRouter.go(Routes.customerHome);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    await tester.tap(find.text(AppStrings.homePostTaskAction));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text(TaskPostingStrings.categoryTitle), findsWidgets);
  });

  testWidgets('Find a worker quick action navigates to WorkerListScreen', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: TolyMolyApp()));
    appRouter.go(Routes.customerHome);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    await tester.tap(find.text(AppStrings.homeFindWorkerAction));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text("All Workers"), findsOneWidget);
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

    expect(find.text(OnboardingStrings.personalInfoTitle), findsWidgets);
    expect(find.text(OnboardingStrings.nameLabel), findsOneWidget);
  });

  testWidgets('Category card tap navigates to WorkerListScreen filtered by skill', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: TolyMolyApp()));
    appRouter.go(Routes.customerHome);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // First category in demo_data.dart is "Home Cleaning" -> skill "Cleaner".
    await tester.tap(find.text("အိမ်သန့်ရှင်းရေး"));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text("Cleaner"), findsWidgets);
  });

  testWidgets('Home header and category grid do not overflow at 360dp width and 1.6x text scale',
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
