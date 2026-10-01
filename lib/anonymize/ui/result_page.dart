import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/clay_theme.dart';
import '../../theme/clay_widgets.dart';
import '../providers.dart';
import '../storage/anonymization_record.dart';
import 'anonymize_messages.dart';
import 'highlights.dart';
import 'restore_page.dart';
import 'review_page.dart';

/// "Protected copy": the anonymized text ready to hand to an AI, and a look
/// at the original. The pencil opens [ReviewPage] to change what is hidden;
/// the restore icon opens [RestorePage] for the AI's reply.
class ResultPage extends ConsumerStatefulWidget {
  const ResultPage({super.key, required this.recordId});

  final String recordId;

  @override
  ConsumerState<ResultPage> createState() => _ResultPageState();
}

class _ResultPageState extends ConsumerState<ResultPage> {
  bool _showOriginal = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final detail = ref.watch(recordDetailProvider(widget.recordId));
    final loaded = detail.value;

    return ClayPage(
      title: l10n.resultTitle,
      actions: [
        ClayIconButton(
          icon: Icons.edit_outlined,
          tooltip: l10n.reviewTitle,
          onPressed: loaded == null
              ? null
              : () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => ReviewPage(recordId: widget.recordId),
                  ),
                ),
          color: loaded == null ? Clay.inkPlaceholder : Clay.ink,
        ),
        ClayIconButton(
          icon: Icons.settings_backup_restore_rounded,
          tooltip: l10n.restoreTitle,
          onPressed: loaded == null
              ? null
              : () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => RestorePage(recordId: widget.recordId),
                  ),
                ),
          color: loaded == null ? Clay.inkPlaceholder : Clay.ink,
        ),
      ],
      body: detail.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (d) => ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          children: [
            ClaySegmented(
              labels: [l10n.tabAnonymized, l10n.tabOriginal],
              index: _showOriginal ? 1 : 0,
              onChanged: (i) => setState(() => _showOriginal = i == 1),
            ),
            const SizedBox(height: 16),
            if (!_showOriginal) ...[
              ClaySuccessBanner(
                text: l10n.resultBanner(d.record.detectionCount),
              ),
              const SizedBox(height: 16),
            ],
            for (final note in [
              if (d.record.listOnly) l10n.resultListOnlyNote,
              if (!d.record.modelUsed) l10n.noModelNote,
              if (d.document case RecordDocument(redactedPath: null))
                l10n.resultTextOnlyNote,
            ]) ...[ClayWarningNote(text: note), const SizedBox(height: 16)],
            ClayDocumentCard(
              caption: d.record.displayName,
              trailing: Text(
                l10n.detectionCount(d.record.detectionCount),
                style: Clay.body(12, color: Clay.inkPlaceholder),
              ),
              child: SelectableText.rich(
                _showOriginal
                    ? HighlightedText.detections(
                        d.original,
                        d.detections.where((x) => x.enabled).toList(),
                      ).span
                    : HighlightedText.placeholders(d.output),
              ),
            ),
          ],
        ),
      ),
      bottom: loaded == null ? null : _Actions(detail: loaded),
    );
  }
}

/// Copy the text, or save the redacted copy: the PDF or Word file when the
/// input produced one, else the text as a `.txt`.
class _Actions extends StatelessWidget {
  const _Actions({required this.detail});

  final RecordDetail detail;

  Future<void> _save(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final (path, name, mimeType) = switch (detail.document) {
      RecordDocument(:final kind, redactedPath: final path?) => (
        path,
        _withExtension(detail.record.outputFileName, kind.extension),
        kind.mimeType,
      ),
      _ => (detail.outputPath, detail.record.outputFileName, 'text/plain'),
    };
    final saved = await FilePicker.saveFile(
      fileName: name,
      bytes: await File(path).readAsBytes(),
      mimeType: mimeType,
      dialogTitle: l10n.saveFile,
    );
    if (saved != null && context.mounted) showSnack(context, l10n.savedFile);
  }

  /// "report-anonymized.txt" -> "report-anonymized.pdf".
  static String _withExtension(String name, String extension) {
    final dot = name.lastIndexOf('.');
    return '${dot == -1 ? name : name.substring(0, dot)}.$extension';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: detail.output));
              if (context.mounted) showSnack(context, l10n.copied);
            },
            icon: const Icon(Icons.copy_rounded, size: 20),
            label: Text(l10n.copyText),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _save(context),
            icon: const Icon(Icons.save_alt_rounded, size: 20),
            label: Text(l10n.saveFile),
          ),
        ),
      ],
    );
  }
}
