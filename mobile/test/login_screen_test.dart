import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orca/core/models/user_role.dart';
import 'package:orca/core/theme/app_theme.dart';
import 'package:orca/features/auth/auth_controller.dart';
import 'package:orca/features/auth/login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget buildTestableLoginScreen({ProviderContainer? container}) {
    final scope = UncontrolledProviderScope(
      container: container ?? ProviderContainer(),
      child: MaterialApp(
        theme: AppTheme.light,
        home: const LoginScreen(),
      ),
    );
    return scope;
  }

  void configureViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets('renders ORCA branding, role card, and input fields', (tester) async {
    configureViewport(tester);
    await tester.pumpWidget(buildTestableLoginScreen());
    await tester.pumpAndSettle();

    expect(find.text('ORCA'), findsOneWidget);
    expect(find.textContaining('Marine Safety'), findsOneWidget);
    expect(find.textContaining('Fisherman'), findsWidgets);
    expect(find.textContaining('Email Address'), findsOneWidget);
    expect(find.textContaining('Password'), findsOneWidget);
    expect(find.textContaining('Log In'), findsWidgets);
  });

  testWidgets('shows validation errors when submitting empty form', (tester) async {
    configureViewport(tester);
    await tester.pumpWidget(buildTestableLoginScreen());
    await tester.pumpAndSettle();

    // Tap submit without entering email or password
    final submitButton = find.byType(FilledButton).first;
    await tester.ensureVisible(submitButton);
    await tester.tap(submitButton);
    await tester.pumpAndSettle();

    expect(find.text('Email address is required'), findsOneWidget);
    expect(find.text('Password is required'), findsOneWidget);
  });

  testWidgets('toggles between Sign In and Sign Up modes', (tester) async {
    configureViewport(tester);
    await tester.pumpWidget(buildTestableLoginScreen());
    await tester.pumpAndSettle();

    // Initially in Log In mode (no Full Name field)
    expect(find.textContaining('Full Name'), findsNothing);

    // Tap Sign Up toggle
    final toggleButton = find.textContaining('Sign Up');
    await tester.ensureVisible(toggleButton);
    await tester.tap(toggleButton);
    await tester.pumpAndSettle();

    // Now in Sign Up mode
    expect(find.textContaining('Full Name'), findsOneWidget);
    expect(find.textContaining('Create Account'), findsOneWidget);
  });

  testWidgets('opens role picker bottom sheet and selects different role', (tester) async {
    configureViewport(tester);
    final container = ProviderContainer();
    await tester.pumpWidget(buildTestableLoginScreen(container: container));
    await tester.pumpAndSettle();

    // Tap "Change" button next to Active Profile
    final changeButton = find.text('Change');
    expect(changeButton, findsOneWidget);
    await tester.tap(changeButton);
    await tester.pumpAndSettle();

    // Bottom sheet should open with all 5 roles
    final bottomSheet = find.byType(BottomSheet);
    expect(bottomSheet, findsOneWidget);
    expect(find.text('Select Maritime Profile'), findsOneWidget);

    // Select "Coastal Authority" from within the bottom sheet
    final coastalAuthCard = find.descendant(
      of: bottomSheet,
      matching: find.textContaining('Coastal Authority'),
    );
    expect(coastalAuthCard, findsOneWidget);
    await tester.tap(coastalAuthCard);
    await tester.pumpAndSettle();

    expect(container.read(authProvider).selectedRole, UserRole.coastalAuthorities);
  });

  testWidgets('hamburger button opens language drawer', (tester) async {
    configureViewport(tester);
    await tester.pumpWidget(buildTestableLoginScreen());
    await tester.pumpAndSettle();

    // Tap the menu icon to open the language drawer
    await tester.tap(find.byIcon(Icons.menu_rounded));
    await tester.pumpAndSettle();

    // Drawer should show all 23 languages — spot-check a few
    expect(find.text('English'), findsWidgets);
    expect(find.text('தமிழ்'), findsOneWidget);
    expect(find.text('हिन्दी'), findsOneWidget);
  });
}
