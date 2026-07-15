// Layout-safety tests for the redesigned onboarding flow: every redesigned
// screen must render without overflow at a small viewport (360dp) with 1.6x
// text scale — the design system's accessibility floor for elderly and
// large-font users.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:toly_moly/main.dart';
import 'package:toly_moly/core/constants/onboarding_strings.dart';
import 'package:toly_moly/core/routing/app_router.dart';

void main() {
  setUp(() {
    appRouter.go(Routes.onboardingWelcome);
  });

  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  Future<void> pumpAtAccessibilityScale(WidgetTester tester) async {
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
  }

  testWidgets('Welcome screen does not overflow at 360dp and 1.6x text scale',
      (tester) async {
    await pumpAtAccessibilityScale(tester);
    await settle(tester);
    expect(tester.takeException(), isNull);
    expect(find.text(OnboardingStrings.getStarted), findsOneWidget);
  });

  testWidgets(
      'Role-choice screen does not overflow at 360dp and 1.6x text scale',
      (tester) async {
    await pumpAtAccessibilityScale(tester);
    appRouter.go(Routes.onboardingCreateAccount);
    await settle(tester);
    expect(tester.takeException(), isNull);
    expect(find.text(OnboardingStrings.chooseRolePrompt), findsWidgets);
    expect(find.text(OnboardingStrings.roleClientLabel), findsOneWidget);
    expect(find.text(OnboardingStrings.roleTaskerLabel), findsOneWidget);
  });

  testWidgets(
      'Sign-in screen does not overflow at 360dp and 1.6x text scale',
      (tester) async {
    await pumpAtAccessibilityScale(tester);
    appRouter.go(Routes.onboardingSignIn);
    await settle(tester);
    expect(tester.takeException(), isNull);
    expect(find.text(OnboardingStrings.phoneLabel), findsOneWidget);
    expect(find.text(OnboardingStrings.passwordLabel), findsOneWidget);
  });

  testWidgets(
      'Account step (phone + password) does not overflow at 360dp and 1.6x text scale',
      (tester) async {
    await pumpAtAccessibilityScale(tester);
    appRouter.go(Routes.onboardingBasicInfo);
    await settle(tester);
    expect(tester.takeException(), isNull);
    expect(find.text(OnboardingStrings.phoneLabel), findsOneWidget);
    expect(find.text(OnboardingStrings.passwordLabel), findsOneWidget);
  });

  testWidgets(
      'Role tap advances straight to the About You step (card is the button)',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const ProviderScope(child: TolyMolyApp()));
    appRouter.go(Routes.onboardingCreateAccount);
    await settle(tester);

    await tester.tap(find.text(OnboardingStrings.roleClientLabel));
    await settle(tester);
    await settle(tester);

    expect(find.text(OnboardingStrings.aboutYouTitle), findsWidgets);
    expect(find.text(OnboardingStrings.nameLabel), findsOneWidget);
    // Gender is a two-option visual choice — no "other".
    expect(find.text("ကျား"), findsOneWidget);
    expect(find.text("မ"), findsOneWidget);
    expect(find.text("အခြား"), findsNothing);
  });
}
