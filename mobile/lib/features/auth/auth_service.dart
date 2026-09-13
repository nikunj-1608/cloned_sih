import 'package:supabase_flutter/supabase_flutter.dart';

/// Everything the app needs from Supabase auth, in one place.
///
/// Kept deliberately thin: the screen calls these two methods and reacts to
/// [authStateChanges]; nothing else in the app should import
/// `package:supabase_flutter` directly. That keeps a future provider swap
/// (or a mock in tests) to a single file.
abstract final class AuthService {
  static GoTrueClient get _auth => Supabase.instance.client.auth;

  static Stream<AuthState> get authStateChanges => _auth.onAuthStateChange;

  static Session? get currentSession => _auth.currentSession;

  /// Creates a new account. The full name is stored as user metadata
  /// (`full_name`) rather than a separate table, since the app has no other
  /// use for a profile row yet.
  static Future<AuthResponse> signUp({
    required String fullName,
    required String email,
    required String password,
  }) {
    return _auth.signUp(
      email: email,
      password: password,
      data: {'full_name': fullName},
    );
  }

  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) {
    return _auth.signInWithPassword(email: email, password: password);
  }

  static Future<void> signOut() => _auth.signOut();
}
