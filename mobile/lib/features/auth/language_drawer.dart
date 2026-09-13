import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n/app_language.dart';
import '../../core/i18n/language_controller.dart';
import '../../core/i18n/login_translations.dart';
import '../../core/theme/app_theme.dart';

/// The drawer opened by the "Languages" burger button.
///
/// Every one of the 22 Eighth Schedule languages, plus English, listed by
/// its own name in its own script — with the English name underneath as a
/// second way to find it, since not everyone reads every script in the list.
class LanguageDrawer extends ConsumerWidget {
  const LanguageDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(languageProvider);
    final theme = Theme.of(context);

    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Row(
                children: [
                  Icon(Icons.language_rounded, color: theme.colorScheme.primary),
                  const SizedBox(width: 10),
                  Text(
                    LoginText.of(current, 'languagesLabel'),
                    style: theme.textTheme.titleLarge,
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 4),
                itemCount: AppLanguage.values.length,
                itemBuilder: (context, index) {
                  final lang = AppLanguage.values[index];
                  final selected = lang == current;
                  return ListTile(
                    selected: selected,
                    selectedTileColor: theme.colorScheme.primary.withValues(
                      alpha: 0.08,
                    ),
                    title: Text(
                      lang.nativeName,
                      style: theme.textTheme.titleMedium,
                    ),
                    subtitle: lang.nativeName != lang.englishName
                        ? Text(lang.englishName, style: theme.textTheme.bodyMedium)
                        : null,
                    trailing: selected
                        ? Icon(
                            Icons.check_circle_rounded,
                            color: theme.colorScheme.primary,
                          )
                        : null,
                    onTap: () {
                      ref.read(languageProvider.notifier).select(lang);
                      Navigator.of(context).pop();
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The top-left burger button that opens [LanguageDrawer], labelled
/// "Languages" (translated) rather than left as a bare icon.
class LanguagesMenuButton extends ConsumerWidget {
  const LanguagesMenuButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(languageProvider);
    final theme = Theme.of(context);

    return InkWell(
      borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
      onTap: () => Scaffold.of(context).openDrawer(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.menu_rounded),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                LoginText.of(current, 'languagesLabel'),
                style: theme.textTheme.labelLarge,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
