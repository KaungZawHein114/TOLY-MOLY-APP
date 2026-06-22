// Smoke + navigation tests.
//   1. App boots to the splash screen (renders on first frame, no async).
//   2. Forward navigation builds a real back stack (the critical fix): after
//      Splash -> Welcome -> Create account, the router can pop back to Welcome.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:toly_moly/main.dart';
import 'package:toly_moly/core/constants/onboarding_strings.dart';
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

    // Advance past the 1.5s splash timer -> the onboarding Welcome screen.
    // Pho Wa Yoke's idle "breathing" animation repeats forever, so
    // pumpAndSettle (which waits for animations to stop) would time out —
    // a bare pump (registers the route change) plus a bounded duration pump
    // (finishes the page transition) are used instead.
    await tester.pump(const Duration(milliseconds: 1600));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text(OnboardingStrings.getStarted), findsOneWidget);
    // At the stack root, there is nothing to pop (back would prompt to exit).
    expect(appRouter.canPop(), isFalse);

    // Push the Create Account screen.
    await tester.tap(find.text(OnboardingStrings.getStarted));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text(OnboardingStrings.chooseRolePrompt), findsWidgets);

    // The critical guarantee: a back stack now exists, so back goes to
    // Welcome instead of exiting the app.
    expect(appRouter.canPop(), isTrue);
    appRouter.pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text(OnboardingStrings.getStarted), findsOneWidget);
    expect(appRouter.canPop(), isFalse);
  });
}
