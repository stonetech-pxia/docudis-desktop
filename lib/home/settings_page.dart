import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../anonymize/anonymize_service.dart';
import '../anonymize/providers.dart';
import '../anonymize/ui/anonymize_messages.dart';
import '../l10n/app_localizations.dart';
import '../licenses.dart';
import '../theme/clay_theme.dart';
import '../theme/clay_widgets.dart';
import 'app_locale.dart';

const privacyPolicyUrl = 'https://docudis.com/privacy/desktop/';
const contactEmail = 'stonetechdigital@gmail.com';

final _versionProvider = FutureProvider<PackageInfo>(
  (ref) => PackageInfo.fromPlatform(),
);

final _recordsFolderProvider = FutureProvider<String>(
  (ref) async => (await ref.watch(recordStoreProvider).directory()).path,
);

/// Interface languages, by their own names.
const _languages = [
  (Locale('en'), 'English'),
  (Locale('es'), 'Español'),
  (Locale('fr'), 'Français'),
  (Locale('zh'), '中文'),
];

/// Settings tab, as a desktop preferences page: general (interface
/// language), data (where records are, clearing them) and about (privacy
/// policy, contact, open-source licenses, version). No account: Docudis has
/// none.
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  /// Opens [uri] outside the app; with nothing to open it, copies [fallback].
  Future<void> _open(BuildContext context, Uri uri, String fallback) async {
    var opened = false;
    try {
      opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } on PlatformException {
      opened = false;
    }
    if (opened || !context.mounted) return;
    await Clipboard.setData(ClipboardData(text: fallback));
    if (context.mounted) {
      showSnack(context, AppLocalizations.of(context).copied);
    }
  }

  Future<void> _clearData(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.clearDataConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.clearDataAction),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(recordStoreProvider).deleteAll();
    ref.read(openRecordProvider.notifier).close();
    ref
      ..invalidate(recordsProvider)
      ..invalidate(_recordsFolderProvider);
    if (context.mounted) showSnack(context, l10n.dataCleared);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final locale = ref.watch(appLocaleProvider);
    final folder = ref.watch(_recordsFolderProvider).value;
    final version = ref.watch(_versionProvider).value;
    final small = OutlinedButton.styleFrom(
      minimumSize: const Size(0, 28),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      textStyle: Clay.body(12.5, weight: FontWeight.w700),
    );

    return ClayPage(
      title: l10n.navSettings,
      showBack: false,
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              _Section(
                title: l10n.settingsGeneral,
                rows: [
                  _Row(
                    label: l10n.languageTitle,
                    trailing: DropdownButton<Locale?>(
                      value: locale,
                      isDense: true,
                      underline: const SizedBox.shrink(),
                      style: Clay.body(13),
                      borderRadius: BorderRadius.circular(Clay.controlRadius),
                      items: [
                        DropdownMenuItem(child: Text(l10n.languageSystem)),
                        for (final (value, name) in _languages)
                          DropdownMenuItem(value: value, child: Text(name)),
                      ],
                      onChanged: (value) =>
                          ref.read(appLocaleProvider.notifier).set(value),
                    ),
                  ),
                ],
              ),
              _Section(
                title: l10n.settingsData,
                rows: [
                  _Row(
                    label: l10n.dataLocation,
                    detail: folder,
                    trailing: OutlinedButton(
                      style: small,
                      onPressed: folder == null
                          ? null
                          : () => _open(context, Uri.file(folder), folder),
                      child: Text(l10n.showInFolder),
                    ),
                  ),
                  _Row(
                    label: l10n.clearData,
                    detail: l10n.clearDataHint(AnonymizeService.maxRecords),
                    trailing: OutlinedButton(
                      style: small.copyWith(
                        foregroundColor: const WidgetStatePropertyAll(
                          Clay.error,
                        ),
                      ),
                      onPressed: () => _clearData(context, ref),
                      child: Text(l10n.clearDataAction),
                    ),
                  ),
                ],
              ),
              _Section(
                title: l10n.settingsAbout,
                rows: [
                  _Row(
                    label: l10n.privacyPolicy,
                    detail: l10n.privacyPolicyHint,
                    trailing: const Icon(
                      Icons.open_in_new_rounded,
                      size: 16,
                      color: Clay.inkCaption,
                    ),
                    onTap: () => _open(
                      context,
                      Uri.parse(privacyPolicyUrl),
                      privacyPolicyUrl,
                    ),
                  ),
                  _Row(
                    label: l10n.contactUs,
                    detail: contactEmail,
                    trailing: const Icon(
                      Icons.mail_outline_rounded,
                      size: 16,
                      color: Clay.inkCaption,
                    ),
                    onTap: () => _open(
                      context,
                      Uri(scheme: 'mailto', path: contactEmail),
                      contactEmail,
                    ),
                  ),
                  _Row(
                    label: l10n.openSourceLicenses,
                    detail: l10n.openSourceLicensesHint,
                    trailing: const Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: Clay.inkCaption,
                    ),
                    onTap: () => showLicensePage(
                      context: context,
                      applicationName: 'Docudis',
                      applicationVersion: version?.version,
                      applicationLegalese: appLegalese,
                    ),
                  ),
                  if (version != null)
                    _Row(
                      label: l10n.appVersion(
                        version.version,
                        version.buildNumber,
                      ),
                      detail:
                          '${Platform.operatingSystem} '
                          '${Platform.operatingSystemVersion}',
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A titled group of rows on a cream panel, as in desktop preferences.
class _Section extends StatelessWidget {
  const _Section({required this.title, required this.rows});

  final String title;
  final List<Widget> rows;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 18),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            title,
            style: Clay.body(
              12,
              weight: FontWeight.w700,
              color: Clay.inkCaption,
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            color: Clay.surface,
            border: Border.all(color: Clay.divider),
            borderRadius: BorderRadius.circular(Clay.controlRadius),
          ),
          child: Column(
            children: [
              for (final (i, row) in rows.indexed) ...[
                if (i > 0) const Divider(height: 1, indent: 14),
                row,
              ],
            ],
          ),
        ),
      ],
    ),
  );
}

/// Label and optional detail on the left, a control on the right.
class _Row extends StatelessWidget {
  const _Row({required this.label, this.detail, this.trailing, this.onTap});

  final String label;
  final String? detail;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    hoverColor: onTap == null ? Colors.transparent : Clay.bg,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Clay.body(13.5, weight: FontWeight.w500)),
                if (detail case final detail?)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: SelectableText(
                      detail,
                      style: Clay.body(12, color: Clay.inkCaption),
                    ),
                  ),
              ],
            ),
          ),
          if (trailing case final trailing?) ...[
            const SizedBox(width: 12),
            trailing,
          ],
        ],
      ),
    ),
  );
}
