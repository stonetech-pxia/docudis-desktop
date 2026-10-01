import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../anonymize/providers.dart';
import '../anonymize/ui/history_page.dart';
import '../anonymize/ui/workspace_page.dart';
import '../l10n/app_localizations.dart';
import '../theme/clay_theme.dart';
import '../theme/clay_widgets.dart';
import 'account_page.dart';

/// App shell, no sign-in: Protect / History / Account behind a side bar on
/// wide windows and the phone's bottom bar on narrow ones. Each tab keeps
/// its own page stack, so the restore page opens beside the side bar, not
/// over it. Opening a record (History, the recent list) shows it in the
/// Protect workspace.
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  /// Narrower than this, the side bar would squeeze the page below a phone's
  /// width, so the shell falls back to the bottom bar.
  static const sideNavMinWidth = 720.0;

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
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
    ref.listen(openRecordProvider, (_, id) {
      if (id == null) return;
      _tabs[0].currentState?.popUntil((route) => route.isFirst);
      if (_index != 0) setState(() => _index = 0);
    });
    final l10n = AppLocalizations.of(context);
    final items = [
      (Icons.verified_user_outlined, l10n.anonymizeTitle),
      (Icons.history_rounded, l10n.historyTitle),
      (Icons.person_outline_rounded, l10n.navAccount),
    ];
    final pages = IndexedStack(
      index: _index,
      children: [
        _tab(0, const WorkspacePage()),
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
            footer: _RecentList(highlight: _index == 0),
          ),
          Expanded(child: pages),
        ],
      ),
    );
  }
}

/// The latest records under the side bar's sections, one click from the
/// workspace.
class _RecentList extends ConsumerWidget {
  const _RecentList({required this.highlight});

  /// Whether the open record is marked: only while the workspace shows it.
  final bool highlight;

  static const count = 8;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final records = ref.watch(recordsProvider).value ?? const [];
    if (records.isEmpty) return const SizedBox.shrink();
    final open = ref.watch(openRecordProvider);
    return ListView(
      padding: const EdgeInsets.only(top: 18),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 0, 10, 6),
          child: Text(
            AppLocalizations.of(context).recentTitle,
            style: Clay.body(
              11.5,
              weight: FontWeight.w700,
              color: Clay.inkPlaceholder,
            ),
          ),
        ),
        for (final record in records.take(count))
          ClaySideNavRow(
            label: record.displayName,
            selected: highlight && record.id == open,
            onTap: () => ref.read(openRecordProvider.notifier).open(record.id),
          ),
      ],
    );
  }
}
