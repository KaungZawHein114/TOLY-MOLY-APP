import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:toly_moly/main.dart';
import 'package:toly_moly/core/constants/app_strings.dart';
import 'package:toly_moly/core/routing/app_router.dart';

void main() {
  setUp(() {
    appRouter.go(Routes.onboardingWelcome);
  });

  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  // dragUntilVisible expects its target finder to match at most one widget
  // at every scroll step, but several job cards become visible in the same
  // step here — so just scroll the outer ListView by hand instead.
  Future<void> scrollDown(WidgetTester tester, {int times = 10}) async {
    for (var i = 0; i < times; i++) {
      await tester.drag(find.byType(ListView).first, const Offset(0, -300));
      await settle(tester);
    }
  }

  testWidgets('Job board is hidden until checked in, then shows an eligible job',
      (tester) async {
    await tester.pumpWidget(const ProviderScope(child: TolyMolyApp()));
    appRouter.go(Routes.dashboard);
    await settle(tester);

    // The new Digital Check-In card pushed the job board's hint text below
    // the initial viewport — scroll down to confirm it, then back up so the
    // Check In button (near the top) is mounted again to tap.
    await scrollDown(tester, times: 3);
    expect(find.text(AppStrings.dashboardCheckInToSeeJobs), findsOneWidget);
    expect(find.text(AppStrings.dashboardInterestedCta), findsNothing);
    for (var i = 0; i < 3; i++) {
      await tester.drag(find.byType(ListView).first, const Offset(0, 300));
      await settle(tester);
    }

    await tester.tap(find.text(AppStrings.dashboardCheckIn));
    await settle(tester);

    expect(find.text(AppStrings.dashboardCheckInToSeeJobs), findsNothing);

    await scrollDown(tester);
    expect(find.text(AppStrings.dashboardInterestedCta), findsWidgets);
  });

  testWidgets('Tapping Interested marks the job as Interest Received', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: TolyMolyApp()));
    appRouter.go(Routes.dashboard);
    await settle(tester);

    await tester.tap(find.text(AppStrings.dashboardCheckIn));
    await settle(tester);

    await scrollDown(tester);
    await tester.tap(find.text(AppStrings.dashboardInterestedCta).first);
    await settle(tester);

    expect(find.text(AppStrings.dashboardInterestReceived), findsWidgets);
  });

  testWidgets(
      'Dashboard (checked in, job board + filters visible) does not overflow at 360dp width and 1.6x text scale',
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
    appRouter.go(Routes.dashboard);
    await settle(tester);

    await tester.tap(find.text(AppStrings.dashboardCheckIn));
    await settle(tester);
    expect(tester.takeException(), isNull);

    await scrollDown(tester, times: 15);
    expect(tester.takeException(), isNull);
  });
}
