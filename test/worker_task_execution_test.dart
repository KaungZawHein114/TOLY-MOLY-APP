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

  testWidgets('Dashboard shows the Digital Check-In card with a Start Process button',
      (tester) async {
    await tester.pumpWidget(const ProviderScope(child: TolyMolyApp()));
    appRouter.go(Routes.dashboard);
    await settle(tester);

    expect(find.text(AppStrings.executionSectionTitle), findsOneWidget);
    expect(find.text(AppStrings.executionStartProcess), findsOneWidget);
  });

  testWidgets(
      'Start Process walks through leaving -> checked-in (waiting) -> client '
      'confirms -> checked-out (waiting) -> client confirms -> completed',
      (tester) async {
    await tester.pumpWidget(const ProviderScope(child: TolyMolyApp()));
    appRouter.go(Routes.dashboard);
    await settle(tester);

    await tester.tap(find.text(AppStrings.executionStartProcess));
    await settle(tester);

    expect(find.widgetWithText(AppBar, AppStrings.executionPageTitle), findsOneWidget);
    expect(find.text(AppStrings.executionLeavingCta), findsOneWidget);

    await tester.tap(find.text(AppStrings.executionLeavingCta));
    await settle(tester);
    expect(find.text(AppStrings.executionCheckinCta), findsOneWidget);

    // Checking in doesn't complete the job by itself — it gates on the
    // client's confirmation (see TaskExecutionScreen's doc comment).
    await tester.tap(find.text(AppStrings.executionCheckinCta));
    await settle(tester);
    expect(find.text(AppStrings.executionCheckinWaiting), findsOneWidget);

    // Client confirms arrival from the Pending tab — same shared
    // taskExecutionProvider, no network needed in this Phase 1 demo.
    appRouter.go(Routes.customerHome);
    await settle(tester);
    await tester.tap(find.text(AppStrings.pendingTabLabel));
    await settle(tester);
    await tester.ensureVisible(find.text(AppStrings.checkinAcceptCta));
    await settle(tester);
    await tester.tap(find.text(AppStrings.checkinAcceptCta));
    await settle(tester);

    // Back on the worker's execution screen: now in progress, checkout CTA shown.
    appRouter.go('${Routes.taskExecution}/2');
    await settle(tester);
    expect(find.text(AppStrings.executionCheckoutCta), findsOneWidget);

    await tester.tap(find.text(AppStrings.executionCheckoutCta));
    await settle(tester);
    expect(find.text(AppStrings.executionCheckoutWaiting), findsOneWidget);

    // Client confirms completion from the Pending tab.
    appRouter.go(Routes.customerHome);
    await settle(tester);
    await tester.tap(find.text(AppStrings.pendingTabLabel));
    await settle(tester);
    await tester.ensureVisible(find.text(AppStrings.checkoutConfirmCta));
    await settle(tester);
    await tester.tap(find.text(AppStrings.checkoutConfirmCta));
    await settle(tester);

    // Back on the worker's screen: job completed.
    appRouter.go('${Routes.taskExecution}/2');
    await settle(tester);
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

    // Client confirms arrival — still at 360dp/1.6x scale — then checkout.
    // The confirmation card can sit below the fold at this scale, so scroll
    // it into view before tapping (same reason it needed a scrollable body
    // to begin with).
    appRouter.go(Routes.customerHome);
    await settle(tester);
    await tester.tap(find.text(AppStrings.pendingTabLabel));
    await settle(tester);
    await tester.ensureVisible(find.text(AppStrings.checkinAcceptCta));
    await settle(tester);
    await tester.tap(find.text(AppStrings.checkinAcceptCta));
    await settle(tester);
    expect(tester.takeException(), isNull);

    appRouter.go('${Routes.taskExecution}/2');
    await settle(tester);
    await tester.tap(find.text(AppStrings.executionCheckoutCta));
    await settle(tester);
    expect(tester.takeException(), isNull);
  });
}
