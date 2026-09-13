import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  // Auth needs real Supabase credentials — unlike the rest of Env, there is
  // no safe fallback for these, so a missing config fails loudly instead of
  // shipping a login screen that can never sign anyone in.
  if (Env.supabaseUrl.isEmpty || Env.supabaseAnonKey.isEmpty) {
    debugPrint(
      'ORCA: SUPABASE_URL / SUPABASE_ANON_KEY missing from mobile/.env — '
      'sign-in and sign-up will fail until they are set.',
    );
  } else {
    await Supabase.initialize(
      url: Env.supabaseUrl,
      anonKey: Env.supabaseAnonKey,
      // Dev/testing convenience: never persist the session to disk, so the
      // login page always shows on a fresh launch instead of resuming a
      // saved session. Remove this line to restore normal "stay logged in"
      // behavior later.
      authOptions: const FlutterAuthClientOptions(
        localStorage: EmptyLocalStorage(),
      ),
    );
  }

  // Portrait only. The app is used one-handed on a moving deck.
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const ProviderScope(child: OrcaApp()));
}