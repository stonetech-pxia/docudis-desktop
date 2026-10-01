import 'dart:async';
import 'dart:io';

import 'package:docudis_ffi/docudis_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/clay_theme.dart';
import '../../theme/desk_widgets.dart';
import '../engine/native_libraries.dart';
import '../providers.dart';
import '../storage/anonymization_record.dart';
import 'anonymize_messages.dart';
import 'dates.dart';
import 'highlights.dart';

/// Paste an AI reply that contains placeholders; get the real values back.
/// The result is shown or copied, never stored.
///
/// The page names the document whose key it uses, and checks the reply
/// against every document (`core.replyCheck`): when another one fits it clearly
/// better, or it has labels this one never issued, the result stays hidden,
/// without copy, until the user switches documents or taps "Show
/// anyway". A label the AI made up (`[PERSON_4]` after `[PERSON_3]`) is only
/// noted under the result.
class RestorePage extends ConsumerStatefulWidget {
  const RestorePage({super.key, required this.recordId});

  final String recordId;

  @override
  ConsumerState<RestorePage> createState() => _RestorePageState();
}

class _RestorePageState extends ConsumerState<RestorePage> {
  final _input = TextEditingController();
  Timer? _debounce;
  late String _recordId = widget.recordId;
  String? _restored;
  ReplyCheck _check = const ReplyCheck();
  bool _showAnyway = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _input.dispose();
    super.dispose();
  }

  void _onChanged(String _) {
    _showAnyway = false;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), _restore);
  }

  Future<void> _restore() async {
    final text = _input.text;
    final id = _recordId;
    if (text.trim().isEmpty) {
      if (_restored != null) setState(() => _restored = null);
      return;
    }
    final result = await ref.read(anonymizeServiceProvider).restore(id, text);
    final candidates = await ref.read(replyCandidatesProvider.future);
    if (!mounted || id != _recordId) return;
    setState(() {
      _restored = result;
      _check = core.replyCheck(text, id, candidates);
    });
  }

  /// A record as History lists it.
  String _nameOf(String id) {
    final records =
        ref.watch(recordsProvider).value ?? const <AnonymizationRecord>[];
    for (final r in records) {
      if (r.id == id) return r.displayName;
    }
    return '';
  }

  /// Restores the same reply with the document it fits better.
  void _useRecord(String id) {
    setState(() {
      _recordId = id;
      _restored = null;
      _showAnyway = false;
    });
    _restore();
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text;
    if (text == null || text.isEmpty || !mounted) return;
    _input.text = text;
    _showAnyway = false;
    _debounce?.cancel();
    await _restore();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final detail = ref.watch(recordDetailProvider(_recordId));
    ref.watch(replyCandidatesProvider); // loaded while the page is open
    final restored = _restored;
    final record = detail.value?.record;
    final check = _check;
    final better = check.betterMatch;
    final blocked =
        !_showAnyway && (better != null || check.unknown.isNotEmpty);
    void showAnyway() => setState(() => _showAnyway = true);
    final mod = Platform.isMacOS ? '⌘' : 'Ctrl+';
    // Title and explanation on one line.
    final stop = Localizations.localeOf(context).languageCode == 'zh'
        ? '。'
        : '. ';
    final noteAction = TextButton.styleFrom(
      foregroundColor: Clay.warningText,
      minimumSize: const Size(0, 26),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      textStyle: Clay.body(12.5, weight: FontWeight.w700),
    );

    final notes = <Widget>[
      if (restored != null && blocked)
        if (better != null)
          DeskNoteBar(
            text:
                '${l10n.restoreOtherTitle}$stop${l10n.restoreOtherBody(_nameOf(better))}',
            actions: [
              TextButton(
                style: noteAction,
                onPressed: showAnyway,
                child: Text(l10n.restoreShowAnyway),
              ),
              TextButton(
                style: noteAction,
                onPressed: () => _useRecord(better),
                child: Text(l10n.restoreUseOther),
              ),
            ],
          )
        else
          DeskNoteBar(
            text:
                '${l10n.restoreMismatchTitle}$stop${l10n.restoreMismatchBody(_labels(check.unknown))}',
            actions: [
              TextButton(
                style: noteAction,
                onPressed: showAnyway,
                child: Text(l10n.restoreShowAnyway),
              ),
            ],
          ),
      if (restored != null && !blocked && better != null)
        DeskNoteBar(text: l10n.restoreShownAnyway(_nameOf(better))),
      if (restored != null &&
          !blocked &&
          (check.unknown.isNotEmpty || check.invented.isNotEmpty))
        DeskNoteBar(
          text: l10n.restoreInvented(
            _labels([...check.unknown, ...check.invented]),
          ),
        ),
    ];

    final originals = detail.value?.map.reverse.values ?? const <String>[];
    final shown = restored != null && !blocked
        ? HighlightedText.restored(
            restored,
            originals,
            style: Clay.body(14, height: 1.7),
          )
        : null;

    Future<void> copy() async {
      if (shown == null) return;
      await Clipboard.setData(ClipboardData(text: restored!));
      if (context.mounted) showSnack(context, l10n.copied);
    }

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): () =>
            Navigator.of(context).maybePop(),
        for (final meta in [true, false])
          SingleActivator(
            LogicalKeyboardKey.keyC,
            meta: meta,
            control: !meta,
            shift: true,
          ): copy,
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DeskToolbar(
                leading: [
                  DeskTool(
                    icon: Icons.arrow_back_rounded,
                    label: l10n.anonymizeTitle,
                    shortcut: 'Esc',
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  DeskTool(
                    icon: Icons.content_paste_rounded,
                    label: l10n.paste,
                    shortcut: '${mod}V',
                    onPressed: _paste,
                  ),
                ],
                trailing: [
                  DeskTool(
                    icon: Icons.copy_rounded,
                    label: l10n.copyRestored,
                    shortcut: '$mod⇧C',
                    primary: true,
                    onPressed: shown == null ? null : copy,
                  ),
                ],
              ),
              ...notes,
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: DocumentPane(
                          caption: l10n.aiReplyLabel,
                          trailing: record == null
                              ? null
                              : Flexible(
                                  child: Text(
                                    '${l10n.restoreDocumentLabel}: '
                                    '${record.displayName} · '
                                    '${formatWhen(context, record.updatedAt)}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Clay.body(
                                      12,
                                      color: Clay.inkPlaceholder,
                                    ),
                                  ),
                                ),
                          child: TextField(
                            controller: _input,
                            onChanged: _onChanged,
                            expands: true,
                            maxLines: null,
                            textAlignVertical: TextAlignVertical.top,
                            style: Clay.body(14, height: 1.7),
                            decoration: InputDecoration(
                              hintText: l10n.restoreHint,
                              filled: false,
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              contentPadding: const EdgeInsets.fromLTRB(
                                14,
                                10,
                                14,
                                14,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DocumentPane(
                          caption: l10n.restoredLabel,
                          trailing: shown == null
                              ? null
                              : Text(
                                  l10n.restoredCount(shown.$2),
                                  style: Clay.body(
                                    12,
                                    color: Clay.secondaryText,
                                  ),
                                ),
                          child: shown == null
                              ? const SizedBox.shrink()
                              : SingleChildScrollView(
                                  padding: const EdgeInsets.fromLTRB(
                                    14,
                                    10,
                                    14,
                                    14,
                                  ),
                                  child: SelectableText.rich(shown.$1),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// At most three labels, as a list to read.
String _labels(List<String> labels) =>
    labels.length > 3 ? '${labels.take(3).join(', ')}…' : labels.join(', ');
