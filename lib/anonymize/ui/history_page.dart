import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/clay_widgets.dart';

/// Placeholder until the Android page is ported.
class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) => ClayPage(
    title: AppLocalizations.of(context).historyTitle,
    showBack: false,
    body: const SizedBox.shrink(),
  );
}
