import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/login_l10n.dart';

const _kLangKey = 'orca_language';

/// Persisted language selection for the ORCA app UI.
///
/// Defaults to [AppLanguage.english] on first launch and remembers the user's
/// last choice across sessions via SharedPreferences.
final languageProvider = NotifierProvider<LanguageNotifier, AppLanguage>(
  LanguageNotifier.new,
);

class LanguageNotifier extends Notifier<AppLanguage> {
  @override
  AppLanguage build() {
    // Restore from prefs asynchronously after the first sync build.
    Future.microtask(_restore);
    return AppLanguage.english;
  }

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_kLangKey);
    if (stored != null) {
      final lang = AppLanguage.values.firstWhere(
        (l) => l.name == stored,
        orElse: () => AppLanguage.english,
      );
      state = lang;
    }
  }

  /// Persist and apply a new language selection.
  Future<void> setLanguage(AppLanguage lang) async {
    state = lang;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLangKey, lang.name);
  }
}
