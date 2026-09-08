import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orca/app.dart';

void main() {
  testWidgets('home screen leads with a go / no-go verdict', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: OrcaApp()));
    await tester.pump();

    // The status hero is the first thing on screen and must state a verdict.
    expect(find.text('Safe to go'), findsOneWidget);

    // All three destinations are always visible.
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Map'), findsOneWidget);
    expect(find.text('Ask'), findsOneWidget);
  });
}
