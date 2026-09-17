import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orca/core/models/user_role.dart';
import 'package:orca/features/auth/auth_controller.dart';
import 'package:orca/features/auth/auth_state.dart';

void main() {
  group('AuthController Riverpod unit tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('initial state defaults to unauthenticated and fishermen role', () {
      final state = container.read(authProvider);
      expect(state.user, isNull);
      expect(state.selectedRole, UserRole.fishermen);
      expect(state.isSignUp, isFalse);
      expect(state.obscurePassword, isTrue);
      expect(container.read(isAuthenticatedProvider), isFalse);
    });

    test('selectRole updates the selected maritime role', () {
      container.read(authProvider.notifier).selectRole(UserRole.coastalAuthorities);

      expect(container.read(authProvider).selectedRole, UserRole.coastalAuthorities);
      expect(container.read(activeRoleProvider), UserRole.coastalAuthorities);
    });

    test('toggleMode switches between login and registration', () {
      expect(container.read(authProvider).isSignUp, isFalse);

      container.read(authProvider.notifier).toggleMode();
      expect(container.read(authProvider).isSignUp, isTrue);

      container.read(authProvider.notifier).toggleMode();
      expect(container.read(authProvider).isSignUp, isFalse);
    });

    test('togglePasswordVisibility updates obscure flag', () {
      expect(container.read(authProvider).obscurePassword, isTrue);

      container.read(authProvider.notifier).togglePasswordVisibility();
      expect(container.read(authProvider).obscurePassword, isFalse);
    });

    test('quickLoginDemo logs in with realistic persona and sets authenticated state', () async {
      await container.read(authProvider.notifier).quickLoginDemo(UserRole.researchers);

      final state = container.read(authProvider);
      expect(state.status, AuthStatus.authenticated);
      expect(state.isAuthenticated, isTrue);
      expect(container.read(isAuthenticatedProvider), isTrue);

      final user = container.read(currentUserProfileProvider);
      expect(user, isNotNull);
      expect(user!.role, UserRole.researchers);
      expect(user.fullName, 'Dr. Ananya Rao');
      expect(user.email, 'ananya.rao@nio.res.in');
    });

    test('signIn with credentials authenticates in offline fallback mode', () async {
      final success = await container.read(authProvider.notifier).signIn(
        email: 'fisherman.murugan@orca.sea',
        password: 'password123',
      );

      expect(success, isTrue);
      final state = container.read(authProvider);
      expect(state.status, AuthStatus.authenticated);
      expect(state.user, isNotNull);
      expect(state.user!.email, 'fisherman.murugan@orca.sea');
      expect(state.user!.isOffline, isTrue);
    });

    test('signOut clears authenticated user state', () async {
      await container.read(authProvider.notifier).quickLoginDemo(UserRole.fishermen);
      expect(container.read(isAuthenticatedProvider), isTrue);

      await container.read(authProvider.notifier).signOut();
      expect(container.read(isAuthenticatedProvider), isFalse);
      expect(container.read(currentUserProfileProvider), isNull);
    });
  });
}
