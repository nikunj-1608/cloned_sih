import '../../core/models/user_profile.dart';
import '../../core/models/user_role.dart';

enum AuthStatus {
  initial,
  authenticating,
  authenticated,
  unauthenticated,
  error,
}

/// Immutable state for authentication and role selection.
class AuthState {
  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.selectedRole = UserRole.fishermen,
    this.isSignUp = false,
    this.obscurePassword = true,
    this.errorMessage,
  });

  final AuthStatus status;
  final UserProfile? user;
  final UserRole selectedRole;
  final bool isSignUp;
  final bool obscurePassword;
  final String? errorMessage;

  bool get isAuthenticated =>
      status == AuthStatus.authenticated && user != null;

  bool get isLoading => status == AuthStatus.authenticating;

  AuthState copyWith({
    AuthStatus? status,
    UserProfile? user,
    UserRole? selectedRole,
    bool? isSignUp,
    bool? obscurePassword,
    String? errorMessage,
    bool clearError = false,
    bool clearUser = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: clearUser ? null : (user ?? this.user),
      selectedRole: selectedRole ?? this.selectedRole,
      isSignUp: isSignUp ?? this.isSignUp,
      obscurePassword: obscurePassword ?? this.obscurePassword,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  String toString() =>
      'AuthState(status: $status, user: ${user?.email}, role: ${selectedRole.metadataKey}, isSignUp: $isSignUp)';
}
