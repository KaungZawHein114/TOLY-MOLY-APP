import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:toly_moly/main.dart';
import 'package:toly_moly/core/constants/onboarding_strings.dart';
import 'package:toly_moly/core/constants/task_posting_strings.dart';
import 'package:toly_moly/core/routing/app_router.dart';
import 'package:toly_moly/core/utils/ai_mock.dart';
import 'package:toly_moly/features/customer/task_posting/task_posting_models.dart';
import 'package:toly_moly/features/customer/task_posting/task_posting_state.dart';

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

/// Walks Screen 1 → Screen 7 (review) through the real UI, leaving the full
/// posting stack in place WITHOUT publishing — the precondition for exercising
/// the "Edit" links (which re-push routes already on the back stack).
Future<void> _walkToReview(WidgetTester tester) async {
  appRouter.go(Routes.postTask);
  await _settle(tester);

  // Screen 1: pick a category card manually.
  await tester.tap(find.text("အိမ်သန့်ရှင်းရေး"));
  await _settle(tester);
  await tester.tap(find.text(TaskPostingStrings.continueButton));
  await _settle(tester);

  // Screen 2: on-site + township dropdown + address.
  await tester.tap(find.text(TaskPostingStrings.taskTypeOnSiteLabel));
  await _settle(tester);
  await tester.tap(find.byType(DropdownButton<String>));
  await _settle(tester);
  await tester.tap(find.text("လှိုင်").last);
  await _settle(tester);
  await tester.enterText(find.byType(TextField).first, "အမှတ် ၁၂");
  await tester.tap(find.text(TaskPostingStrings.continueButton));
  await _settle(tester);

  // Screen 3: set date/time via the provider (native pickers), toggle urgent.
  final container = ProviderScope.containerOf(
      tester.element(find.text(TaskPostingStrings.dateTimeTitle).first));
  container.read(taskDraftProvider.notifier).state = container
      .read(taskDraftProvider)
      .copyWith(date: DateTime.now(), timeSlot: "10:00");
  await _settle(tester);
  await tester.tap(find.byType(Switch));
  await _settle(tester);
  await tester.tap(find.text(TaskPostingStrings.continueButton));
  await _settle(tester);

  // Screen 4: tier.
  await tester.tap(find.text(TaskPostingStrings.tier1Label));
  await _settle(tester);
  await tester.tap(find.text(TaskPostingStrings.continueButton));
  await _settle(tester);

  // Screen 5: description.
  await tester.enterText(find.byType(TextField).first, "ရေယိုနေတယ်");
  await tester.tap(find.text(TaskPostingStrings.continueButton));
  await _settle(tester);

  // Screen 6: budget.
  await tester.enterText(find.byType(TextField).first, "10000");
  await _settle(tester);
  await tester.tap(find.text(TaskPostingStrings.continueButton));
  await _settle(tester);
}

void main() {
  setUp(() {
    appRouter.go(Routes.onboardingWelcome);
  });

  testWidgets('Full happy path: walk to review, then publish to success modal',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const ProviderScope(child: TolyMolyApp()));
    await _walkToReview(tester);

    expect(find.text(TaskPostingStrings.reviewTitle), findsWidgets);
    await tester.tap(find.text(TaskPostingStrings.publishButton));
    await _settle(tester);

    expect(find.text(TaskPostingStrings.successMessage), findsOneWidget);
    await tester.tap(find.text(TaskPostingStrings.successGoHome));
    await _settle(tester);
    expect(find.text(OnboardingStrings.getStarted), findsNothing); // sanity
  });

  testWidgets(
      'Review "Edit" re-pushes a route already on the stack without crashing, '
      'preserves data, and returns to review', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const ProviderScope(child: TolyMolyApp()));
    await _walkToReview(tester);
    expect(find.text(TaskPostingStrings.reviewTitle), findsWidgets);

    // Tap the FIRST "Edit" (Task Title & Category → Screen 1). Screen 1 sits at
    // the BOTTOM of the stack, so this is the worst-case duplicate-key path —
    // it used to crash the Navigator with a red error screen.
    await tester.tap(find.text(TaskPostingStrings.editLink).first);
    await _settle(tester);

    // No crash, and Screen 1 (with the save-and-return affordance) is shown.
    expect(tester.takeException(), isNull);
    expect(find.text(TaskPostingStrings.categoryTitle), findsWidgets);
    expect(find.text(TaskPostingStrings.saveButton), findsOneWidget);

    // Previously entered category is still selected (data preserved).
    final container = ProviderScope.containerOf(
        tester.element(find.text(TaskPostingStrings.categoryTitle).first));
    expect(container.read(taskDraftProvider).category, "Cleaner");

    // Save returns to the review screen, still crash-free.
    await tester.tap(find.text(TaskPostingStrings.saveButton));
    await _settle(tester);
    expect(tester.takeException(), isNull);
    expect(find.text(TaskPostingStrings.reviewTitle), findsWidgets);
    expect(container.read(taskDraftProvider).category, "Cleaner");
  });

  testWidgets('Screen 1 AI path: typing the spec example detects Plumber',
      (tester) async {
    await tester.pumpWidget(const ProviderScope(child: TolyMolyApp()));
    appRouter.go(Routes.postTask);
    await _settle(tester);

    await tester.enterText(find.byType(TextField).first, "ရေယိုနေတယ်");
    await _settle(tester);

    expect(categorizeJob("ရေယိုနေတယ်"), "Plumber");
    expect(find.textContaining("Plumber"), findsOneWidget);
  });

  testWidgets('Screen 6 budget evaluation: low / reasonable / high verdicts',
      (tester) async {
    expect(evaluateBudget(5000), BudgetVerdict.low);
    expect(evaluateBudget(10000), BudgetVerdict.reasonable);
    expect(evaluateBudget(20000), BudgetVerdict.high);
  });

  testWidgets(
      'Screen 4 (section title + info button + 7 tier cards) does not overflow at 360dp width and 1.6x text scale',
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
    await _settle(tester);

    expect(tester.takeException(), isNull);
  });
}
