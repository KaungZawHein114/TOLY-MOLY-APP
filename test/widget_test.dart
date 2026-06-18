// Basic smoke test: the app boots to the splash screen without errors.
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:toly_moly/main.dart';

void main() {
  testWidgets('App boots to splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: TolyMolyApp()));

    // Splash shows the brand name on the first frame (no async needed).
    expect(find.text('TOLY MOLY'), findsOneWidget);
  });
}
