import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:toly_moly/core/widgets/mascot/mascot_state.dart';
import 'package:toly_moly/core/widgets/onboarding/onboarding_scaffold.dart';

void main() {
  testWidgets('OnboardingScaffold header does not overflow at 360dp width and 1.6x text scale',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(360, 800),
            textScaler: TextScaler.linear(1.6),
          ),
          child: OnboardingScaffold(
            mascotState: PhoWaYokeState.pointing,
            mascotMessage: 'Test message',
            title: 'Test title',
            body: const SizedBox(),
            bottomBar: const SizedBox(),
            onBack: () {},
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });
}
