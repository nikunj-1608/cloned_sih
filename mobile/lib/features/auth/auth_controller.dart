import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/auth_repository.dart';
import '../../core/models/user_profile.dart';
import '../../core/models/user_role.dart';
import 'auth_state.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

/// Riverpod controller managing global authentication and RBAC session.
class AuthController extends Notifier<AuthState> {
  late final AuthRepository _repository;
  bool _disposed = false;

  @override
  AuthState build() {
    _repository = ref.read(authRepositoryProvider);
    _disposed = false;
    ref.onDispose(() => _disposed = true);

    Future.microtask(() {
      if (!_disposed && ref.mounted) {
        restoreSession();
      }
    });

    return const AuthState();
  }

  Future<void> restoreSession() async {
    try {
      final savedUser = await _repository.restoreSession();
      if (_disposed || !ref.mounted) return;
      if (savedUser != null) {
        state = state.copyWith(
          status: AuthStatus.authenticated,
          user: savedUser,
          selectedRole: savedUser.role,
          clearError: true,
        );
      } else {
        state = state.copyWith(
          status: AuthStatus.unauthenticated,
          clearError: true,
        );
      }
    } catch (_) {
      if (_disposed || !ref.mounted) return;
      state = state.copyWith(status: AuthStatus.unauthenticated);
    }
  }

  void selectRole(UserRole role) {
    state = state.copyWith(selectedRole: role, clearError: true);
  }

  void toggleMode() {
    state = state.copyWith(
      isSignUp: !state.isSignUp,
      clearError: true,
    );
  }

  void togglePasswordVisibility() {
    state = state.copyWith(obscurePassword: !state.obscurePassword);
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(
      status: AuthStatus.authenticating,
      clearError: true,
    );

    try {
      final user = await _repository.signInWithPassword(
        email: email,
        password: password,
        role: state.selectedRole,
      );

      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
        selectedRole: user.role,
        clearError: true,
      );
      return true;
    } catch (e) {
      final message = _formatErrorMessage(e);
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: message,
      );
      return false;
    }
  }

  Future<bool> signUp({
    required String email,
    required String password,
    String? fullName,
  }) async {
    state = state.copyWith(
      status: AuthStatus.authenticating,
      clearError: true,
    );

    try {
      final user = await _repository.signUp(
        email: email,
        password: password,
        role: state.selectedRole,
        fullName: fullName,
      );

      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
        selectedRole: user.role,
        clearError: true,
      );
      return true;
    } catch (e) {
      final message = _formatErrorMessage(e);
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: message,
      );
      return false;
    }
  }

  /// Instant 1-tap demo persona login.
  Future<void> quickLoginDemo(UserRole role) async {
    state = state.copyWith(
      status: AuthStatus.authenticating,
      selectedRole: role,
      clearError: true,
    );

    try {
      final user = await _repository.quickLoginDemo(role);
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
        selectedRole: role,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Demo login failed: $e',
      );
    }
  }

  Future<void> signOut() async {
    await _repository.signOut();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  String _formatErrorMessage(Object error) {
    final str = error.toString();
    if (str.contains('AuthException:')) {
      return str.split('AuthException:').last.trim();
    }
    if (str.contains('Invalid login credentials')) {
      return 'Invalid email or password. Please check your credentials.';
    }
    return str.replaceFirst('Exception: ', '').trim();
  }
}

/// Global provider for authentication state.
final authProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);

/// Globally provides the active UserProfile.
final currentUserProfileProvider = Provider<UserProfile?>((ref) {
  return ref.watch(authProvider.select((state) => state.user));
});

/// Globally provides the active UserRole (defaults to fishermen if unauthenticated).
final activeRoleProvider = Provider<UserRole>((ref) {
  final user = ref.watch(currentUserProfileProvider);
  if (user != null) return user.role;
  return ref.watch(authProvider.select((state) => state.selectedRole));
});

/// Globally exposes whether a user is currently authenticated.
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authProvider.select((state) => state.isAuthenticated));
});
