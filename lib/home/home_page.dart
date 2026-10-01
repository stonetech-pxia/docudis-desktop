import 'package:flutter/material.dart';

import '../anonymize/ui/history_page.dart';
import '../anonymize/ui/protect_page.dart';
import '../l10n/app_localizations.dart';
import '../theme/clay_widgets.dart';
import 'account_page.dart';

/// App shell, no sign-in: Protect / History / Account behind a side bar on
/// wide windows and the phone's bottom bar on narrow ones. Each tab keeps
/// its own page stack, so a result or review page opens beside the side
/// bar, not over it.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  /// Narrower than this, the side bar would squeeze the page below a phone's
  /// width, so the shell falls back to the bottom bar.
  static const sideNavMinWidth = 720.0;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _index = 0;

  final _tabs = [for (var i = 0; i < 3; i++) GlobalKey<NavigatorState>()];

  /// Switches tab; choosing the current one again goes back to its first
  /// page.
  void _select(int i) {
    if (i == _index) {
      _tabs[i].currentState?.popUntil((route) => route.isFirst);
    } else {
      setState(() => _index = i);
    }
  }

  Widget _tab(int i, Widget page) => Navigator(
    key: _tabs[i],
    onGenerateRoute: (_) => MaterialPageRoute<void>(builder: (_) => page),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final items = [
      (Icons.verified_user_outlined, l10n.anonymizeTitle),
      (Icons.history_rounded, l10n.historyTitle),
      (Icons.person_outline_rounded, l10n.navAccount),
    ];
    final pages = IndexedStack(
      index: _index,
      children: [
        _tab(0, const ProtectPage()),
        _tab(1, const HistoryPage()),
        _tab(2, const AccountPage()),
      ],
    );
    final wide = MediaQuery.sizeOf(context).width >= HomePage.sideNavMinWidth;
    if (!wide) {
      return Scaffold(
        body: pages,
        bottomNavigationBar: ClayNavBar(
          index: _index,
          onChanged: _select,
          items: items,
        ),
      );
    }
    return Scaffold(
      body: Row(
        children: [
          ClaySideNav(
            title: l10n.appTitle,
            index: _index,
            onChanged: _select,
            items: items,
          ),
          Expanded(child: pages),
        ],
      ),
    );
  }
}
