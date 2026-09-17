import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orca/app.dart';
import 'package:orca/features/shell/home_shell.dart';

void main() {
  testWidgets('OrcaApp shows login screen on initial launch when unauthenticated', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: OrcaApp()));
    await tester.pump();

    expect(find.text('ORCA'), findsOneWidget);
    expect(find.textContaining('Log In'), findsWidgets);
  });

  testWidgets('home screen leads with a go / no-go verdict', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: OrcaApp(home: HomeShell())));
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

