import 'dart:async';

import 'package:docudis_ffi/docudis_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/clay_theme.dart';
import '../../theme/clay_widgets.dart';
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

    return ClayPage(
      title: l10n.restoreTitle,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        children: [
          Text(
            l10n.restoreHint,
            style: Clay.body(14, color: Clay.inkMuted, height: 1.5),
          ),
          if (record != null) ...[
            const SizedBox(height: 12),
            _DocumentRow(record: record, label: l10n.restoreDocumentLabel),
          ],
          const SizedBox(height: 16),
          ClayCard(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            border: Border.all(color: Clay.primary, width: 1.5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(child: ClayLabel(l10n.aiReplyLabel)),
                    _PasteButton(label: l10n.paste, onPressed: _paste),
                  ],
                ),
                TextField(
                  controller: _input,
                  onChanged: _onChanged,
                  minLines: 4,
                  maxLines: 10,
                  style: Clay.body(14, color: Clay.inkMuted, height: 1.7),
                  decoration: const InputDecoration(
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ),
          if (restored != null && blocked) ...[
            const SizedBox(height: 16),
            if (better != null)
              _Mismatch(
                title: l10n.restoreOtherTitle,
                body: l10n.restoreOtherBody(_nameOf(better)),
                actions: [
                  TextButton(
                    onPressed: showAnyway,
                    child: Text(l10n.restoreShowAnyway),
                  ),
                  TextButton(
                    onPressed: () => _useRecord(better),
                    child: Text(l10n.restoreUseOther),
                  ),
                ],
              )
            else
              _Mismatch(
                title: l10n.restoreMismatchTitle,
                body: l10n.restoreMismatchBody(_labels(check.unknown)),
                actions: [
                  TextButton(
                    onPressed: showAnyway,
                    child: Text(l10n.restoreShowAnyway),
                  ),
                ],
              ),
          ],
          if (restored != null && !blocked) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                const Expanded(child: Divider()),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: ClayLabel(l10n.restoredLabel),
                ),
                const Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: 16),
            ClayCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Builder(
                    builder: (context) {
                      final originals =
                          detail.value?.map.reverse.values ?? const <String>[];
                      final (span, found) = HighlightedText.restored(
                        restored,
                        originals,
                      );
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SelectableText.rich(span),
                          const SizedBox(height: 12),
                          // Shown here only after "Show anyway".
                          if (better != null) ...[
                            ClayWarningNote(
                              text: l10n.restoreShownAnyway(_nameOf(better)),
                            ),
                            const SizedBox(height: 8),
                          ],
                          if (check.unknown.isNotEmpty ||
                              check.invented.isNotEmpty)
                            ClayWarningNote(
                              text: l10n.restoreInvented(
                                _labels([...check.unknown, ...check.invented]),
                              ),
                            )
                          else if (better == null)
                            Text(
                              l10n.restoredCount(found),
                              style: Clay.body(
                                12.5,
                                color: Clay.secondaryText,
                                weight: FontWeight.w500,
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
      bottom: restored == null || blocked
          ? null
          : FilledButton.icon(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: restored));
                if (context.mounted) showSnack(context, l10n.copied);
              },
              icon: const Icon(Icons.copy_rounded, size: 20),
              label: Text(l10n.copyRestored),
            ),
    );
  }
}

/// At most three labels, as a list to read.
String _labels(List<String> labels) =>
    labels.length > 3 ? '${labels.take(3).join(', ')}…' : labels.join(', ');

class _PasteButton extends StatelessWidget {
  const _PasteButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => TextButton.icon(
    onPressed: onPressed,
    style: TextButton.styleFrom(
      backgroundColor: Clay.primaryTint,
      foregroundColor: Clay.primaryPressed,
      minimumSize: const Size(0, 32),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      shape: const StadiumBorder(),
      textStyle: Clay.body(13, weight: FontWeight.w700),
    ),
    icon: const Icon(Icons.content_paste_rounded, size: 14),
    label: Text(label),
  );
}

/// The document whose restore key the page uses, as History lists it.
class _DocumentRow extends StatelessWidget {
  const _DocumentRow({required this.record, required this.label});

  final AnonymizationRecord record;
  final String label;

  @override
  Widget build(BuildContext context) {
    final icon = switch (record.kind) {
      InputKind.text => Icons.content_paste_rounded,
      InputKind.file => Icons.description_outlined,
      InputKind.image => Icons.photo_camera_outlined,
    };
    return Row(
      children: [
        Icon(icon, size: 20, color: Clay.inkCaption),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClayLabel(label),
              Text(
                record.displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              Text(
                formatWhen(context, record.updatedAt),
                style: Clay.body(12, color: Clay.inkCaption),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Shown instead of the result when the reply does not fit the document.
class _Mismatch extends StatelessWidget {
  const _Mismatch({
    required this.title,
    required this.body,
    required this.actions,
  });

  final String title;
  final String body;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
    decoration: BoxDecoration(
      color: Clay.warningBg,
      borderRadius: BorderRadius.circular(Clay.controlRadius),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              size: 20,
              color: Clay.warningText,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: Clay.body(
                  15,
                  weight: FontWeight.w700,
                  color: Clay.warningText,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          body,
          style: Clay.body(13.5, color: Clay.warningText, height: 1.5),
        ),
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: Wrap(alignment: WrapAlignment.end, children: actions),
        ),
      ],
    ),
  );
}
