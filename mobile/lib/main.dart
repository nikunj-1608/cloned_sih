import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/config/env.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // A missing `.env` must not be fatal: every key in Env has a sane fallback,
  // and a developer who has not copied the template should still get a
  // running app rather than a black screen.
  try {
    await Env.load();
  } on Object catch (error) {
    debugPrint('ORCA: .env not loaded ($error) — using built-in defaults. '
        'Run `cp .env.example .env` inside mobile/.');
  }

  // Portrait only. The app is used one-handed on a moving deck.
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const ProviderScope(child: OrcaApp()));
}
