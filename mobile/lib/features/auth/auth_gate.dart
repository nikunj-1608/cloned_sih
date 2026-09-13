import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../shell/home_shell.dart';
import 'auth_service.dart';
import 'login_screen.dart';

/// The app's true entry point. Shows [LoginScreen] with no session, and
/// [HomeShell] with one — swapping live as Supabase reports sign-in,
/// sign-up, and sign-out events, so nothing else in the app needs to poll
/// auth state itself.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: AuthService.authStateChanges,
      builder: (context, snapshot) {
        final session =
            snapshot.data?.session ?? AuthService.currentSession;
        if (session != null) return const HomeShell();
        return const LoginScreen();
      },
    );
  }
}
