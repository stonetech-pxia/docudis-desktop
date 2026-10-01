import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'home/app_locale.dart';
import 'home/home_page.dart';
import 'l10n/app_localizations.dart';
import 'theme/clay_theme.dart';

class DocudisApp extends ConsumerWidget {
  const DocudisApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      locale: ref.watch(appLocaleProvider),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: clayTheme(),
      home: const HomePage(),
    );
  }
}
