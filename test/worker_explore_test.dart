import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:toly_moly/main.dart';
import 'package:toly_moly/core/constants/app_strings.dart';
import 'package:toly_moly/core/constants/task_posting_strings.dart';
import 'package:toly_moly/core/routing/app_router.dart';
import 'package:toly_moly/core/data/demo_data.dart';

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
      'Schedule Worker CTA on the profile sends the client into the task posting flow',
      (tester) async {
    await tester.pumpWidget(const ProviderScope(child: TolyMolyApp()));
    appRouter.go('${Routes.workerProfile}/${workers.first.id}');
    await settle(tester);

    // Profile: no rate, CTA has no rate suffix.
    expect(find.textContaining("MMK"), findsNothing);
    await tester.tap(find.text(AppStrings.scheduleWorkerCta));
    await settle(tester);

    // Category + tier are auto-filled from the chosen worker, so the flow
    // jumps straight to the Location step.
    expect(find.text(TaskPostingStrings.typeLocationTitle), findsWidgets);
  });
}
