import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:toly_moly/core/widgets/app_section_card.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('Read-only card renders title, subtitle and child', (tester) async {
    await tester.pumpWidget(_wrap(const AppSectionCard(
      title: "Personal Information",
      subtitle: "Public",
      icon: Icons.person_outline,
      child: Text("Age: 32"),
    )));

    expect(find.text("Personal Information"), findsOneWidget);
    expect(find.text("Public"), findsOneWidget);
    expect(find.text("Age: 32"), findsOneWidget);
    expect(find.byIcon(Icons.person_outline), findsOneWidget);
  });

  testWidgets('onTap makes the whole card a single tap target', (tester) async {
    var tapped = false;
    await tester.pumpWidget(_wrap(AppSectionCard(
      title: "Dashboard Section",
      onTap: () => tapped = true,
      child: const Text("body"),
    )));

    await tester.tap(find.text("Dashboard Section"));
    await tester.pump();
    expect(tapped, isTrue);
  });

  testWidgets('Expandable card starts open and collapses/expands on header tap (uncontrolled)',
      (tester) async {
    await tester.pumpWidget(_wrap(const AppSectionCard(
      title: "Verification",
      expandable: true,
      child: Text("progress body"),
    )));
    await tester.pumpAndSettle();

    // Starts expanded by default.
    expect(find.text("progress body"), findsOneWidget);

    await tester.tap(find.text("Verification"));
    await tester.pumpAndSettle();
    expect(find.text("progress body"), findsNothing);

    await tester.tap(find.text("Verification"));
    await tester.pumpAndSettle();
    expect(find.text("progress body"), findsOneWidget);
  });

  testWidgets('Controlled expandable card reports state via onExpand without flipping itself',
      (tester) async {
    bool? reported;
    await tester.pumpWidget(_wrap(StatefulBuilder(
      builder: (context, setState) => AppSectionCard(
        title: "Skills",
        expandable: true,
        expanded: false,
        onExpand: (v) => reported = v,
        child: const Text("skill chips"),
      ),
    )));
    await tester.pumpAndSettle();

    expect(find.text("skill chips"), findsNothing);
    await tester.tap(find.text("Skills"));
    await tester.pumpAndSettle();

    expect(reported, isTrue);
    // Parent never updated `expanded`, so it stays collapsed.
    expect(find.text("skill chips"), findsNothing);
  });

  testWidgets('Custom trailing widget is rendered instead of the auto chevron', (tester) async {
    await tester.pumpWidget(_wrap(AppSectionCard(
      title: "Settings",
      expandable: true,
      trailing: const Icon(Icons.language),
      child: const Text("body"),
    )));

    expect(find.byIcon(Icons.language), findsOneWidget);
    expect(find.byIcon(Icons.expand_more), findsNothing);
  });
}
