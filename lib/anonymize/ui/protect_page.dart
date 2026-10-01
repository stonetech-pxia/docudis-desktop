import 'dart:async';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' hide TextInput;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/clay_theme.dart';
import '../../theme/clay_widgets.dart';
import '../input/input_source.dart';
import '../input/text_extractor.dart';
import '../providers.dart';
import 'anonymize_messages.dart';
import 'result_page.dart';

/// Shortens [text] for the staged preview: the whole text when it is short,
/// otherwise the first [headChars] characters, an ellipsis, and the last
/// [tailWords] words (or the last 20 characters for text without spaces).
String compactPreview(String text, {int headChars = 150, int tailWords = 6}) {
  final flat = text.trim();
  if (flat.length <= headChars + 40) return flat;
  var head = flat.substring(0, headChars);
  final cut = head.lastIndexOf(RegExp(r'\s'));
  if (cut > headChars ~/ 2) head = head.substring(0, cut);
  final words = flat.split(RegExp(r'\s+'));
  var tail = words.length > tailWords
      ? words.sublist(words.length - tailWords).join(' ')
      : '';
  if (tail.isEmpty || tail.length > 60) tail = flat.substring(flat.length - 20);
  return '${head.trimRight()} … $tail';
}

IconData fileIcon(String extension) => switch (extension) {
  'pdf' => Icons.picture_as_pdf_outlined,
  'doc' || 'docx' => Icons.description_outlined,
  'txt' || 'md' || 'csv' || 'text' || 'log' => Icons.article_outlined,
  'jpg' || 'jpeg' || 'png' || 'webp' || 'heic' || 'bmp' => Icons.image_outlined,
  _ => Icons.insert_drive_file_outlined,
};

/// Protect tab: a headline, then the two ways in — paste text (also with
/// the paste shortcut) and upload a document (also by dropping it on the
/// window). Picking an input stages it on the page (preview, cancel,
/// anonymize).
class ProtectPage extends ConsumerStatefulWidget {
  const ProtectPage({super.key});

  @override
  ConsumerState<ProtectPage> createState() => _ProtectPageState();
}

class _ProtectPageState extends ConsumerState<ProtectPage> {
  InputSource? _staged;
  bool _dragging = false;

  @override
  void initState() {
    super.initState();
    // Load the NER model now so the first run is as fast as the rest.
    ref.read(anonymizeServiceProvider).warmUp();
  }

  bool get _busy => ref.read(processControllerProvider).isLoading;

  Future<void> _confirm() async {
    final source = _staged;
    if (source == null) return;
    final l10n = AppLocalizations.of(context);
    unawaited(showClayProgressDialog(context, l10n.processing));
    final id = await ref.read(processControllerProvider.notifier).run(source);
    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pop();
    if (id == null) {
      final err = ref.read(processControllerProvider).error;
      if (err != null) showSnack(context, processErrorMessage(l10n, err));
      return;
    }
    setState(() => _staged = null);
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => ResultPage(recordId: id)));
  }

  Future<void> _paste() async {
    if (_busy) return;
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (!mounted) return;
    final text = data?.text;
    if (text == null || text.trim().isEmpty) {
      showSnack(context, AppLocalizations.of(context).clipboardEmpty);
      return;
    }
    setState(() => _staged = TextInput(text));
  }

  Future<void> _pickFile() async {
    if (_busy) return;
    final picked = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: TextExtractor.pickableExtensions,
    );
    final path = picked?.path;
    if (picked == null || path == null || !mounted) return;
    setState(() => _staged = FileInput(path: path, name: picked.name));
  }

  void _drop(DropDoneDetails details) {
    setState(() => _dragging = false);
    if (_busy || details.files.isEmpty) return;
    final file = details.files.first;
    final input = FileInput(path: file.path, name: file.name);
    if (!TextExtractor.pickableExtensions.contains(input.extension)) {
      showSnack(
        context,
        processErrorMessage(
          AppLocalizations.of(context),
          const UnsupportedInputException('extension'),
        ),
      );
      return;
    }
    setState(() => _staged = input);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final busy = ref.watch(processControllerProvider).isLoading;
    final modelMissing = ref.watch(nerReadyProvider).value == false;
    final staged = _staged;

    final header = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.homeHeadline,
          style: Clay.heading(27, letterSpacing: -0.54, height: 1.18),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            const Icon(
              Icons.lock_outline_rounded,
              size: 15,
              color: Clay.secondaryText,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                l10n.homeCaption,
                style: Clay.body(
                  14,
                  weight: FontWeight.w500,
                  color: Clay.secondaryText,
                ),
              ),
            ),
          ],
        ),
      ],
    );

    final entries = staged == null
        ? IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _EntryCard(
                    icon: Icons.content_paste_rounded,
                    title: l10n.inputPasteText,
                    primary: true,
                    onTap: busy ? null : _paste,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _EntryCard(
                    icon: Icons.upload_file_outlined,
                    title: l10n.inputPickFile,
                    subtitle: l10n.dropHint,
                    highlighted: _dragging,
                    onTap: busy ? null : _pickFile,
                  ),
                ),
              ],
            ),
          )
        : _StagedCard(
            source: staged,
            confirmLabel: l10n.anonymizeButton,
            onConfirm: busy ? null : _confirm,
            onCancel: () => setState(() => _staged = null),
          );

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyV, meta: true): _paste,
        const SingleActivator(LogicalKeyboardKey.keyV, control: true): _paste,
      },
      child: Focus(
        autofocus: true,
        child: DropTarget(
          onDragEntered: (_) => setState(() => _dragging = true),
          onDragExited: (_) => setState(() => _dragging = false),
          onDragDone: _drop,
          child: Scaffold(
            body: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(32, 36, 32, 32),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 640),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        header,
                        const SizedBox(height: 32),
                        AnimatedSwitcher(
                          duration: Clay.motion,
                          switchInCurve: Clay.motionCurve,
                          switchOutCurve: Clay.motionCurve,
                          child: entries,
                        ),
                        if (modelMissing) ...[
                          const SizedBox(height: 16),
                          ClayWarningNote(text: l10n.noModelNote),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Paste (terracotta) or upload (cream): icon tile, title, and for upload
/// the drop hint. The upload card lights up while a file is dragged over
/// the window.
class _EntryCard extends StatelessWidget {
  const _EntryCard({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.primary = false,
    this.highlighted = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final bool primary;
  final bool highlighted;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = primary ? Colors.white : Clay.ink;
    return ClayCard(
      color: primary
          ? Clay.primary
          : highlighted
          ? Clay.secondaryTint
          : Clay.surface,
      border: highlighted
          ? Border.all(color: Clay.secondary, width: 1.5)
          : null,
      padding: const EdgeInsets.all(20),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClayIconTile(
            icon: icon,
            color: primary ? const Color(0x33FFFFFF) : Clay.secondary,
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: Clay.heading(18, weight: FontWeight.w600, color: foreground),
          ),
          if (subtitle case final subtitle?) ...[
            const SizedBox(height: 4),
            Text(subtitle, style: Clay.body(13, color: Clay.inkCaption)),
          ],
        ],
      ),
    );
  }
}

/// The staged text or file: icon, cancel, preview, Anonymize button.
class _StagedCard extends StatelessWidget {
  const _StagedCard({
    required this.source,
    required this.confirmLabel,
    required this.onConfirm,
    required this.onCancel,
  });

  final InputSource source;
  final String confirmLabel;
  final VoidCallback? onConfirm;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final (icon, color, preview) = switch (source) {
      TextInput(:final text) => (
        Icons.content_paste_rounded,
        Clay.primary,
        Text(
          compactPreview(text),
          maxLines: 6,
          overflow: TextOverflow.ellipsis,
          style: Clay.body(14, color: Clay.inkMuted, height: 1.45),
        ) as Widget,
      ),
      FileInput(:final name, :final extension) => (
        Icons.upload_file_outlined,
        Clay.secondary,
        Row(
          children: [
            Icon(fileIcon(extension), size: 30, color: Clay.secondary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Clay.body(14, weight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    };
    return ClayCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              ClayIconTile(icon: icon, color: color),
              const Spacer(),
              ClayIconButton(
                icon: Icons.close_rounded,
                tooltip: l10n.cancel,
                color: Clay.inkMuted,
                onPressed: onCancel,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            constraints: const BoxConstraints(maxHeight: 164),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Clay.bg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: preview,
          ),
          const SizedBox(height: 14),
          FilledButton(onPressed: onConfirm, child: Text(confirmLabel)),
        ],
      ),
    );
  }
}
