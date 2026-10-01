import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/clay_widgets.dart';

/// Placeholder until the Android page is ported.
class ProtectPage extends StatelessWidget {
  const ProtectPage({super.key});

  @override
  Widget build(BuildContext context) => ClayPage(
    title: AppLocalizations.of(context).anonymizeTitle,
    showBack: false,
    body: const SizedBox.shrink(),
  );
}
