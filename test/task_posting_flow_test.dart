import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:toly_moly/main.dart';
import 'package:toly_moly/core/constants/onboarding_strings.dart';
import 'package:toly_moly/core/constants/task_posting_strings.dart';
import 'package:toly_moly/core/routing/app_router.dart';
import 'package:toly_moly/core/utils/ai_mock.dart';
import 'package:toly_moly/features/customer/task_posting/task_posting_state.dart';

void main() {
  setUp(() {
    appRouter.go(Routes.onboardingWelcome);
  });

  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  testWidgets(
      'Full happy path: Screen 1 manual category through publish to the success modal',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const ProviderScope(child: TolyMolyApp()));
    appRouter.go(Routes.postTask);
    await settle(tester);

    // Screen 1: pick the first category card manually (not the AI path).
    expect(find.text(TaskPostingStrings.categoryTitle), findsWidgets);
    await tester.tap(find.text("အိမ်သန့်ရှင်းရေး"));
    await settle(tester);
    await tester.tap(find.text(TaskPostingStrings.continueButton));
    await settle(tester);

    // Screen 2: on-site + location.
    expect(find.text(TaskPostingStrings.typeLocationTitle), findsWidgets);
    await tester.tap(find.text(TaskPostingStrings.taskTypeOnSiteLabel));
    await settle(tester);
    await tester.enterText(find.byType(TextField).first, "လှိုင်");
    await tester.enterText(find.byType(TextField).at(1), "အမှတ် ၁၂");
    await tester.tap(find.text(TaskPostingStrings.continueButton));
    await settle(tester);

    // Screen 3: native date/time pickers aren't practical to drive in a
    // widget test, so set them directly via the shared provider; still
    // exercise the urgent checkbox through the real UI.
    expect(find.text(TaskPostingStrings.dateTimeTitle), findsWidgets);
    final container = ProviderScope.containerOf(tester.element(find.text(TaskPostingStrings.dateTimeTitle).first));
    container.read(taskDraftProvider.notifier).state =
        container.read(taskDraftProvider).copyWith(date: DateTime.now(), timeSlot: "10:00");
    await settle(tester);
    await tester.tap(find.text(TaskPostingStrings.urgentToggleLabel));
    await settle(tester);
    await tester.tap(find.text(TaskPostingStrings.continueButton));
    await settle(tester);

    // Screen 4: workers + tier.
    expect(find.text(TaskPostingStrings.workersTierTitle), findsWidgets);
    await tester.tap(find.text(TaskPostingStrings.workerTierBasicLabel));
    await settle(tester);
    await tester.tap(find.text(TaskPostingStrings.continueButton));
    await settle(tester);

    // Screen 5: description.
    expect(find.text(TaskPostingStrings.descriptionTitle), findsWidgets);
    await tester.enterText(find.byType(TextField).first, "ရေယိုနေတယ်");
    await tester.tap(find.text(TaskPostingStrings.continueButton));
    await settle(tester);

    // Screen 6: budget is platform-set (no user choice) — just continue.
    expect(find.text(TaskPostingStrings.budgetTitle), findsWidgets);
    await tester.tap(find.text(TaskPostingStrings.continueButton));
    await settle(tester);

    // Screen 7: review + publish.
    expect(find.text(TaskPostingStrings.reviewTitle), findsWidgets);
    await tester.tap(find.text(TaskPostingStrings.publishButton));
    await settle(tester);

    // Success modal.
    expect(find.text(TaskPostingStrings.successMessage), findsOneWidget);

    await tester.tap(find.text(TaskPostingStrings.successGoHome));
    await settle(tester);
    expect(find.text(OnboardingStrings.getStarted), findsNothing); // sanity: not back on Welcome
  });

  testWidgets('Screen 1 AI path: typing the spec example detects Plumber', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: TolyMolyApp()));
    appRouter.go(Routes.postTask);
    await settle(tester);

    await tester.enterText(find.byType(TextField).first, "ရေယိုနေတယ်");
    await settle(tester);

    expect(categorizeJob("ရေယိုနေတယ်"), "Plumber");
    expect(find.textContaining("Plumber"), findsOneWidget);
  });

  testWidgets(
      'Screen 4 (stepper + section title + 3 tier cards) does not overflow at 360dp width and 1.6x text scale',
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
    appRouter.go(Routes.postTaskWorkersTier);
    await settle(tester);

    expect(tester.takeException(), isNull);
  });
}
