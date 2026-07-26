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

  testWidgets(
      'Jobs tab keeps Discussion and shows Check-In flow on second page',
      (tester) async {
    await tester.pumpWidget(const ProviderScope(child: TolyMolyApp()));
    appRouter.go(Routes.dashboard);
    await settle(tester);

    expect(find.text(AppStrings.executionStartProcess), findsNothing);

    await tester.tap(find.text(AppStrings.jobsTabLabel));
    await settle(tester);

    expect(find.text('စာတိုများ'), findsOneWidget);

    await tester.tap(find.text('Check In / Out'));
    await settle(tester);

    expect(find.text(AppStrings.executionLeavingCta), findsOneWidget);
  });

  testWidgets(
      'Start Process walks through check-in and check-out automatically in demo',
      (tester) async {
    await tester.pumpWidget(const ProviderScope(child: TolyMolyApp()));
    appRouter.go(Routes.dashboard);
    await settle(tester);

    await tester.tap(find.text(AppStrings.jobsTabLabel));
    await settle(tester);

    await tester.tap(find.text('Check In / Out'));
    await settle(tester);

    expect(find.text(AppStrings.executionLeavingCta), findsOneWidget);

    await tester.tap(find.text(AppStrings.executionLeavingCta));
    await settle(tester);
    expect(find.text(AppStrings.executionCheckinCta), findsOneWidget);

    await tester.ensureVisible(find.text(AppStrings.executionCheckinCta));
    await settle(tester);
    await tester.tap(find.text(AppStrings.executionCheckinCta));
    await settle(tester);
    expect(find.text(AppStrings.executionCheckinWaiting), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
    expect(find.text(AppStrings.executionCheckoutCta), findsOneWidget);

    await tester.ensureVisible(find.text(AppStrings.executionCheckoutCta));
    await settle(tester);
    await tester.tap(find.text(AppStrings.executionCheckoutCta));
    await settle(tester);
    expect(find.text(AppStrings.executionCheckoutWaiting), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
    expect(find.text(AppStrings.executionCompletedMsg), findsOneWidget);
  });

  testWidgets(
      'Task execution screen does not overflow at 360dp width and 1.6x text scale',
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
    appRouter.go('${Routes.taskExecution}/2');
    await settle(tester);

    expect(tester.takeException(), isNull);

    await tester.tap(find.text(AppStrings.executionLeavingCta));
    await settle(tester);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text(AppStrings.executionCheckinCta));
    await settle(tester);
    expect(tester.takeException(), isNull);

    await tester.pump(const Duration(seconds: 3));
    expect(tester.takeException(), isNull);

    await tester.tap(find.text(AppStrings.executionCheckoutCta));
    await settle(tester);
    expect(tester.takeException(), isNull);

    await tester.pump(const Duration(seconds: 3));
    expect(tester.takeException(), isNull);
  });
}
