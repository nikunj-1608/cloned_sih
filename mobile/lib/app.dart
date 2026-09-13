import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'features/auth/auth_gate.dart';

class OrcaApp extends StatelessWidget {
  const OrcaApp({super.key});

  @override
  Widget build(BuildContext context) {
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
      home: const AuthGate(),
    );
  }
}
