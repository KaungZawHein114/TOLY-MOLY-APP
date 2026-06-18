// Smoke + navigation tests.
//   1. App boots to the splash screen (renders on first frame, no async).
//   2. Forward navigation builds a real back stack (the critical fix): after
//      Splash -> Role -> Customer Home, the router can pop back to Role.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:toly_moly/main.dart';
import 'package:toly_moly/core/routing/app_router.dart';

void main() {
  testWidgets('App boots to splash screen', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: TolyMolyApp()));
    expect(find.text('TOLY MOLY'), findsOneWidget);
  });

  testWidgets('Forward navigation builds a back stack', (tester) async {
    // Phone-sized canvas so the demo layouts don't overflow the test surface.
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const ProviderScope(child: TolyMolyApp()));

    // Advance past the 1.5s splash timer -> Role Selection.
    await tester.pump(const Duration(milliseconds: 1600));
    await tester.pumpAndSettle();
    expect(find.text('Customer'), findsOneWidget);
    // At the stack root, there is nothing to pop (back would prompt to exit).
    expect(appRouter.canPop(), isFalse);

    // Push the Customer flow.
    await tester.tap(find.text('Customer'));
    await tester.pumpAndSettle();
    expect(find.text('Mingalaba 👋'), findsOneWidget);

    // The critical guarantee: a back stack now exists, so back goes to Role
    // Selection instead of exiting the app.
    expect(appRouter.canPop(), isTrue);
    appRouter.pop();
    await tester.pumpAndSettle();
    expect(find.text('Customer'), findsOneWidget);
    expect(appRouter.canPop(), isFalse);
  });
}
