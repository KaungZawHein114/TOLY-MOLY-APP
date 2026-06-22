import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:toly_moly/core/widgets/onboarding/staggered_entrance.dart';

void main() {
  testWidgets('StaggeredEntrance renders all children', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: StaggeredEntrance(
          children: [Text('one'), Text('two'), Text('three')],
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('one'), findsOneWidget);
    expect(find.text('two'), findsOneWidget);
    expect(find.text('three'), findsOneWidget);
  });

  testWidgets('StaggeredEntrance skips animation when disableAnimations is true',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: StaggeredEntrance(children: [Text('instant')]),
        ),
      ),
    );
    // No pump-forward needed — content should be visible on the very first
    // frame when animations are disabled, with no Opacity/Transform wrapper
    // (the child is returned directly, not animated).
    await tester.pump();
    expect(find.text('instant'), findsOneWidget);
    expect(
      find.ancestor(of: find.text('instant'), matching: find.byType(Opacity)),
      findsNothing,
    );
  });
}
