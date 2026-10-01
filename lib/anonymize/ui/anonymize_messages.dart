import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../input/input_source.dart';

/// Localized message for a failed run.
String processErrorMessage(AppLocalizations l10n, Object error) {
  if (error is UnsupportedInputException) {
    return switch (error.reason) {
      'empty' => l10n.errorNoText,
      'ocr' => l10n.errorNeedsOcr,
      _ => l10n.errorUnsupportedFile,
    };
  }
  return l10n.errorProcessingFailed;
}

void showSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}
