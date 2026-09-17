import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'features/auth/auth_controller.dart';
import 'features/auth/login_screen.dart';
import 'features/shell/home_shell.dart';

class OrcaApp extends ConsumerWidget {
  const OrcaApp({super.key, this.home});

  /// Allows explicit screen injection for tests or deep navigation.
  final Widget? home;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAuthenticated = ref.watch(isAuthenticatedProvider);

    return MaterialApp(
      title: 'ORCA',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      // Dark is genuinely useful here: night sailing, and it saves battery on
      // a phone that may be days from a charger.
      themeMode: ThemeMode.system,
      builder: (context, child) {
        // Respect the system text scale, but never let it shrink below 1.0 —
        // the type scale is a floor, not a default.
        final scale = MediaQuery.textScalerOf(context).scale(1);
        return MediaQuery.withClampedTextScaling(
          minScaleFactor: 1.0,
          maxScaleFactor: scale.clamp(1.0, 1.5),
          child: child!,
        );
      },
      home: home ?? (isAuthenticated ? const HomeShell() : const LoginScreen()),
    );
  }
}
