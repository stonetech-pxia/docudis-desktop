import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

/// A record's date and time the way the reader writes them: in the system's
/// own region when it speaks the interface language (English on a UK system
/// gives 24/09/2026), else in the interface language.
String formatWhen(BuildContext context, DateTime at) {
  final app = Localizations.localeOf(context);
  final device = View.of(context).platformDispatcher.locale;
  final regional = device.languageCode == app.languageCode
      ? device.toString()
      : null;
  final locale = regional != null && DateFormat.localeExists(regional)
      ? regional
      : app.toString();
  return DateFormat.yMd(locale).add_Hm().format(at);
}
