import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:toly_moly/main.dart';
import 'package:toly_moly/core/constants/onboarding_strings.dart';
import 'package:toly_moly/core/constants/task_posting_strings.dart';
import 'package:toly_moly/core/routing/app_router.dart';
import 'package:toly_moly/core/utils/ai_mock.dart';
import 'package:toly_moly/core/utils/ai_service.dart';
import 'package:toly_moly/features/customer/task_posting/task_posting_models.dart';
import 'package:toly_moly/features/customer/task_posting/task_posting_state.dart';

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

/// Advances past the voice flow's scripted "listening" pause.
Future<void> _settleVoice(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 1600));
  await tester.pump(const Duration(milliseconds: 1600));
}

/// The AI Task Assistant conversation makes a REAL Dio call before falling
/// back (no backend is reachable in tests, so every turn resolves to the
/// local fallback engine) — that failure takes real wall-clock time to
/// resolve, not just fake-clock animation time. Repeated short pumps give
/// the actual async I/O repeated chances to progress between awaits, without
/// using `pumpAndSettle` (which would hang forever on the perpetual typing-
/// indicator animation while `_thinking` is true).
Future<void> _settleTaskAssistantTurn(WidgetTester tester) async {
  for (var i = 0; i < 40; i++) {
    await tester.pump(const Duration(milliseconds: 200));
  }
}

ProviderContainer _containerAt(WidgetTester tester, Finder finder) =>
    ProviderScope.containerOf(tester.element(finder));

/// Walks the MANUAL method (method picker → title/category → media → when/
/// where → level → description) to the summary through the real UI, leaving
/// the whole stack in place WITHOUT publishing — the precondition for
/// exercising the "Edit" links (which re-push routes already on the back
/// stack).
Future<void> _walkToSummary(WidgetTester tester) async {
  appRouter.go(Routes.postTask);
  await _settle(tester);

  // Method picker: choose "fill it in myself".
  await tester.tap(find.text(TaskPostingStrings.methodManualLabel));
  await _settle(tester);

  // Step 1: title + pick a category card manually (no AI suggestion).
  await tester.enterText(find.byType(TextField).first, "အိမ် သန့်ရှင်းရေး");
  await tester.ensureVisible(find.text("အိမ်သန့်ရှင်းရေး"));
  await _settle(tester);
  await tester.tap(find.text("အိမ်သန့်ရှင်းရေး"));
  await _settle(tester);
  await tester.tap(find.text(TaskPostingStrings.continueButton));
  await _settle(tester);

  // Step 2: media attachments — entirely optional, so just Skip past it.
  await tester.tap(find.text(TaskPostingStrings.mediaSkipButton));
  await _settle(tester);

  // Step 3: date/time via the provider (native pickers), on-site + township +
  // address, and the urgent switch — all one step now.
  final container = _containerAt(
      tester, find.text(TaskPostingStrings.whenWhereTitle).first);
  container.read(taskDraftProvider.notifier).state = container
      .read(taskDraftProvider)
      .copyWith(date: DateTime.now(), timeSlot: "10:00");
  await _settle(tester);
  await tester.ensureVisible(find.text(TaskPostingStrings.taskTypeOnSiteLabel));
  await _settle(tester);
  await tester.tap(find.text(TaskPostingStrings.taskTypeOnSiteLabel));
  await _settle(tester);
  await tester.ensureVisible(find.byType(DropdownButton<String>));
  await _settle(tester);
  await tester.tap(find.byType(DropdownButton<String>));
  await _settle(tester);
  await tester.tap(find.text("လှိုင်").last);
  await _settle(tester);
  await tester.enterText(find.byType(TextField).first, "အမှတ် ၁၂");
  await _settle(tester);
  // The urgent card sits at the bottom of this now-longer step. Centre the
  // switch in the viewport (alignment 0.5) instead of dragging by a fixed
  // amount — a fixed drag overshoots as the card grows and scrolls the switch
  // clean off the top, where the tap silently lands on the header instead.
  await Scrollable.ensureVisible(
    tester.element(find.byType(Switch)),
    alignment: 0.5,
    duration: Duration.zero,
  );
  await _settle(tester);
  await tester.tap(find.byType(Switch));
  await _settle(tester);
  expect(container.read(taskDraftProvider).urgent, isTrue);

  await tester.tap(find.text(TaskPostingStrings.continueButton));
  await _settle(tester);

  // Step 3: tasker level — this is also what sets the AI-estimated budget.
  await tester.tap(find.text(TaskPostingStrings.tier1Label));
  await _settle(tester);
  await tester.tap(find.text(TaskPostingStrings.continueButton));
  await _settle(tester);

  // Step 4: description — required before the flow reaches Summary.
  await tester.enterText(
      find.byType(TextField).first, "ရေပိုက် ယိုနေလို့ ပြင်ချင်ပါတယ်");
  await _settle(tester);
  await tester.tap(find.text(TaskPostingStrings.continueButton));
  await _settle(tester);
}

void main() {
  setUp(() {
    // Drop the scripted "thinking" beat so tests stay instant and leave no
    // pending timers; the real app keeps the 700ms pause for demo polish.
    AiConfig.demoThinkingDelay = Duration.zero;
    appRouter.go(Routes.onboardingWelcome);
  });

  testWidgets('Manual method: walk to summary, then publish to success modal',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const ProviderScope(child: TolyMolyApp()));
    await _walkToSummary(tester);

    expect(find.text(TaskPostingStrings.reviewTitle), findsWidgets);

    // The budget was set by the level step, never typed by the client.
    final container =
        _containerAt(tester, find.text(TaskPostingStrings.reviewTitle).first);
    expect(container.read(taskDraftProvider).budgetMmk, isNotNull);

    await tester.tap(find.text(TaskPostingStrings.publishButton));
    await _settle(tester);

    expect(find.text(TaskPostingStrings.successMessage), findsOneWidget);
    await tester.tap(find.text(TaskPostingStrings.successGoHome));
    await _settle(tester);
    expect(find.text(OnboardingStrings.getStarted), findsNothing); // sanity
  });

  testWidgets(
      'Summary "Edit" re-pushes a route already on the stack without crashing, '
      'preserves data, and returns to the summary', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const ProviderScope(child: TolyMolyApp()));
    await _walkToSummary(tester);
    expect(find.text(TaskPostingStrings.reviewTitle), findsWidgets);

    // Tap the FIRST "Edit" (Title → step 1). Step 1 sits at the BOTTOM of the
    // stack, so this is the worst-case duplicate-key path — it used to crash
    // the Navigator with a red error screen.
    await tester.ensureVisible(find.text(TaskPostingStrings.editLink).first);
    await _settle(tester);
    await tester.tap(find.text(TaskPostingStrings.editLink).first);
    await _settle(tester);

    // No crash, and step 1 (with the save-and-return affordance) is shown.
    expect(tester.takeException(), isNull);
    expect(find.text(TaskPostingStrings.categoryTitle), findsWidgets);
    expect(find.text(TaskPostingStrings.saveButton), findsOneWidget);

    // Previously entered category is still selected (data preserved).
    final container =
        _containerAt(tester, find.text(TaskPostingStrings.categoryTitle).first);
    expect(container.read(taskDraftProvider).category, "Cleaner");

    // Save returns to the summary screen, still crash-free.
    await tester.tap(find.text(TaskPostingStrings.saveButton));
    await _settle(tester);
    expect(tester.takeException(), isNull);
    expect(find.text(TaskPostingStrings.reviewTitle), findsWidgets);
    expect(container.read(taskDraftProvider).category, "Cleaner");
  });

  testWidgets(
      'Voice method (AI Task Assistant): local fallback conversation fills '
      'the same draft and lands on the same summary screen', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const ProviderScope(child: TolyMolyApp()));
    appRouter.go(Routes.postTask);
    await _settle(tester);

    await tester.tap(find.text(TaskPostingStrings.methodVoiceLabel));
    await _settle(tester);
    expect(find.text(TaskPostingStrings.taskAssistantGreeting), findsOneWidget);

    final container = _containerAt(
        tester, find.text(TaskPostingStrings.taskAssistantGreeting));

    // No backend is reachable in tests, so every turn falls straight to the
    // local fallback engine (AiService.taskAssistant catches the failed Dio
    // call automatically) — same adaptive rules, deterministic extraction.
    Future<void> sendMessage(String text) async {
      await tester.enterText(find.byType(TextField).first, text);
      await tester.tap(find.byIcon(Icons.send_rounded));
      await _settleTaskAssistantTurn(tester);
    }

    await sendMessage("ရေပိုက် ယိုနေတယ်"); // need -> category/title/description
    await sendMessage("လှိုင်"); // place -> township
    await sendMessage("မနက်ဖြန် မနက်ပိုင်း"); // schedule -> date/time
    await sendMessage("မဟုတ်ပါဘူး"); // urgency -> NORMAL
    await sendMessage("ပိုက်ပေါက်ကြီး ဖြစ်နေတယ်"); // category-specific detail

    // Every always-required field is now filled, so the fallback engine
    // must have reached the confirmation stage automatically.
    expect(find.text(TaskPostingStrings.taskAssistantConfirmYes), findsOneWidget);
    await tester.tap(find.text(TaskPostingStrings.taskAssistantConfirmYes));
    await _settle(tester);

    // Media step — skip it, same shared TaskMediaPicker the manual flow uses.
    expect(find.text(TaskPostingStrings.mediaSkipButton), findsOneWidget);
    await tester.tap(find.text(TaskPostingStrings.mediaSkipButton));
    await _settleVoice(tester); // covers the wrap-up Timer before the push

    // Same summary screen the manual flow reaches — no duplicate.
    expect(find.text(TaskPostingStrings.reviewTitle), findsWidgets);

    // Every field the conversation is responsible for was filled. Tasker
    // level/budget are deliberately NOT set by this flow (locked design:
    // that stays a separate step after the conversation, same as it already
    // is for Manual) — Summary shows "-" for those until the client edits
    // them, exactly like any other incomplete draft.
    final draft = container.read(taskDraftProvider);
    expect(draft.category, isNotNull);
    expect(draft.title, isNotEmpty);
    expect(draft.township, "လှိုင်");
    expect(draft.date, isNotNull);
    expect(draft.timeSlot, isNotNull);
  });

  testWidgets(
      'Title step has no AI category suggestion — category is chosen by '
      'tapping a card, and the grid renders instantly with no loading state',
      (tester) async {
    await tester.pumpWidget(const ProviderScope(child: TolyMolyApp()));
    appRouter.go(Routes.postTaskTitle);
    await _settle(tester);
    await _settle(tester); // let the entrance animation fully settle

    expect(find.textContaining("AI"), findsNothing);

    await tester.enterText(find.byType(TextField).first, "အိမ် သန့်ရှင်းရေး");
    await _settle(tester);
    // The title field's own focus-follow autoscroll can still be settling;
    // dismiss it before scrolling to the category grid so the two scrolls
    // don't race and leave the tap coordinate stale.
    FocusManager.instance.primaryFocus?.unfocus();
    await _settle(tester);
    await tester.ensureVisible(find.text("အိမ်သန့်ရှင်းရေး"));
    await _settle(tester);
    await tester.tap(find.text("အိမ်သန့်ရှင်းရေး"));
    await _settle(tester);
    expect(
      _containerAt(tester, find.text("အိမ်သန့်ရှင်းရေး")).read(taskDraftProvider).category,
      "Cleaner",
    );
  });

  test('The AI budget estimate scales with the tasker level', () {
    final tier1 = estimateTaskBudgetMmk(category: "Plumber", tierNumber: 1);
    final tier7 = estimateTaskBudgetMmk(category: "Plumber", tierNumber: 7);
    expect(tier1, lessThan(tier7));
    // Urgent work costs more at the same level, and every figure is a round
    // number a client can read at a glance.
    expect(
      estimateTaskBudgetMmk(category: "Plumber", tierNumber: 3, urgent: true),
      greaterThan(estimateTaskBudgetMmk(category: "Plumber", tierNumber: 3)),
    );
    expect(tier7 % 500, 0);
    // An unknown category still returns a usable figure, never zero.
    expect(estimateTaskBudgetMmk(category: "", tierNumber: 3), greaterThan(0));
  });

  test('The voice script extracts every field the summary needs', () {
    final need = voiceTaskNeed("မီးဖိုချောင်က ရေပိုက် ယိုနေတယ်");
    expect(need.category, "Plumber");
    expect(need.title, isNotEmpty);

    expect(voiceTaskPlace("လှိုင် မြို့နယ်မှာ ပါ").township, "လှိုင်");
    expect(voiceTaskPlace("ဘယ်နေရာမှန်း မသိ").township, isEmpty);

    expect(voiceTaskSchedule("မနက်ဖြန် မနက်").timeSlot, "09:00");
    expect(voiceTaskSchedule("ဒီနေ့ ညနေ").timeSlot, "17:00");

    expect(voiceTaskUrgent("ဟုတ်ကဲ့၊ အရေးပေါ်"), isTrue);
    expect(voiceTaskUrgent("မဟုတ်ပါ"), isFalse);

    expect(voiceTaskTierNumber(TaskPostingStrings.tier5Label), 5);
    expect(voiceTaskTierNumber("ဘာမှ မပြောဘူး"), 3); // safe middle default
  });

  test('formatBudgetMmk renders Burmese digits with thousands separators', () {
    expect(formatBudgetMmk(22000), "၂၂,၀၀၀ ${TaskPostingStrings.budgetCurrency}");
    expect(formatBudgetMmk(500), "၅၀၀ ${TaskPostingStrings.budgetCurrency}");
  });

  test('Task-posting AI (the attractiveness score) is demo-only: no live '
      'call, deterministic result, and no "offline" tag', () async {
    const task = {
      'category': 'Plumber',
      'location': 'လှိုင် အမှတ် ၁၂',
      'date': '2026-06-26',
      'time': '10:00',
      'tier': 'အသစ် စတင်သူ',
      'description': 'အိမ်တွင် ရေပိုက်ယိုနေပါသည်။ ပြင်ဆင်ပေးရန် လိုအပ်ပါသည်။',
      'budget': 12000,
      'urgent': true,
    };
    final eval = await AiService.evaluateTask(task);
    expect(eval.score, greaterThan(0));
    // demo, NOT mock: the summary card must not show the "offline" badge for
    // what is the intended local implementation.
    expect(eval.source, AiSource.demo);

    // Deterministic — the same task always scores the same.
    final again = await AiService.evaluateTask(task);
    expect(again.score, eval.score);
  });

  testWidgets(
      'Tasker level step (estimate card + section title + info button + 7 tier '
      'cards) does not overflow at 360dp width and 1.6x text scale',
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
    appRouter.go(Routes.postTaskTaskerLevel);
    await _settle(tester);

    expect(tester.takeException(), isNull);
  });
}
