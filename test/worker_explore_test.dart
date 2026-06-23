import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:toly_moly/main.dart';
import 'package:toly_moly/core/constants/app_strings.dart';
import 'package:toly_moly/core/routing/app_router.dart';
import 'package:toly_moly/core/data/demo_data.dart';
import 'package:toly_moly/features/customer/task_request_state.dart';

void main() {
  setUp(() {
    appRouter.go(Routes.onboardingWelcome);
  });

  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  testWidgets('Tasker Explore shows no pricing anywhere on a worker card',
      (tester) async {
    await tester.pumpWidget(const ProviderScope(child: TolyMolyApp()));
    appRouter.go(Routes.workerList);
    await settle(tester);

    expect(find.textContaining("MMK"), findsNothing);
    expect(find.textContaining("/hr"), findsNothing);
  });

  testWidgets(
      'Schedule Worker happy path: profile -> schedule -> submit -> confirmation creates a TaskRequest',
      (tester) async {
    await tester.pumpWidget(const ProviderScope(child: TolyMolyApp()));
    appRouter.go('${Routes.workerProfile}/${workers.first.id}');
    await settle(tester);

    // Profile: no rate, CTA has no rate suffix.
    expect(find.textContaining("MMK"), findsNothing);
    await tester.tap(find.text(AppStrings.scheduleWorkerCta));
    await settle(tester);

    // Schedule Worker screen.
    expect(find.widgetWithText(AppBar, AppStrings.scheduleWorkerTitle), findsOneWidget);

    // Township + address are within the initial viewport.
    await tester.enterText(find.byType(TextField).first, "လှိုင်");
    await tester.enterText(find.byType(TextField).at(1), "အမှတ် ၅");
    await settle(tester);

    // Description + submit are further down — scroll them into view before
    // touching them, since this ListView doesn't eagerly build offscreen
    // children (so find.byType(TextField).last would otherwise still
    // resolve to the address field).
    await tester.dragUntilVisible(
      find.text(AppStrings.scheduleSubmitCta),
      find.byType(ListView),
      const Offset(0, -300),
    );
    await settle(tester);
    await tester.enterText(find.byType(TextField).last, "ရေယိုနေတယ်");
    await settle(tester);

    final container = ProviderScope.containerOf(tester.element(find.text(AppStrings.scheduleSubmitCta)));
    expect(container.read(postedTaskRequestsProvider), isEmpty);

    await tester.tap(find.text(AppStrings.scheduleSubmitCta));
    await settle(tester);

    expect(find.text(AppStrings.taskRequestSentTitle), findsOneWidget);
    expect(container.read(postedTaskRequestsProvider).length, 1);
  });
}
