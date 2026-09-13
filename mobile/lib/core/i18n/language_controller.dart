import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_language.dart';

/// The single language the auth screens are currently rendered in.
///
/// Deliberately scoped to auth for now — the rest of the app has its own
/// (much larger) localisation job, tracked separately in `PROJECT_STATE.md`
/// under Phase 8 (Bhashini / regional languages).
class LanguageController extends Notifier<AppLanguage> {
  @override
  AppLanguage build() => AppLanguage.english;

  void select(AppLanguage language) => state = language;
}

final languageProvider = NotifierProvider<LanguageController, AppLanguage>(
  LanguageController.new,
);
