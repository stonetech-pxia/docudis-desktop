import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../preferences.dart';

const _localeKey = 'app_locale';

/// Interface language picked on the Account tab; `null` follows the system.
/// Persisted in SharedPreferences, so "Clear data" leaves it alone.
class AppLocaleNotifier extends Notifier<Locale?> {
  @override
  Locale? build() {
    final code = ref.watch(sharedPreferencesProvider).getString(_localeKey);
    return code == null ? null : Locale(code);
  }

  Future<void> set(Locale? locale) async {
    state = locale;
    final prefs = ref.read(sharedPreferencesProvider);
    if (locale == null) {
      await prefs.remove(_localeKey);
    } else {
      await prefs.setString(_localeKey, locale.languageCode);
    }
  }
}

final appLocaleProvider = NotifierProvider<AppLocaleNotifier, Locale?>(
  AppLocaleNotifier.new,
);
