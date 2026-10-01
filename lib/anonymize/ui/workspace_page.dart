import 'dart:io';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:docudis_ffi/docudis_ffi.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' hide TextInput;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/clay_theme.dart';
import '../../theme/desk_widgets.dart';
import '../engine/native_libraries.dart';
import '../input/input_source.dart';
import '../input/text_extractor.dart';
import '../providers.dart';
import '../storage/anonymization_record.dart';
import 'anonymize_messages.dart';
import 'document_panes.dart';
import 'findings_panel.dart';
import 'restore_page.dart';

IconData fileIcon(String extension) => switch (extension) {
  'pdf' => Icons.picture_as_pdf_outlined,
  'doc' || 'docx' => Icons.description_outlined,
  'txt' || 'md' || 'csv' || 'text' || 'log' => Icons.article_outlined,
  'jpg' || 'jpeg' || 'png' || 'webp' || 'heic' || 'bmp' => Icons.image_outlined,
  _ => Icons.insert_drive_file_outlined,
};

/// The Protect tab as a desktop workspace: a toolbar, the original on the
/// left and the anonymized text on the right, the findings beside them and
/// a status bar underneath.
///
/// With no record open, the left pane is an editor: type or paste text, or
/// open / drop a file, then Anonymize. With one open (just made, or picked
/// in History or the recent list), clicking the original or the findings
/// changes what is hidden; every change is saved to the record at once.
class WorkspacePage extends ConsumerStatefulWidget {
  const WorkspacePage({super.key});

  @override
  ConsumerState<WorkspacePage> createState() => _WorkspacePageState();
}

class _WorkspacePageState extends ConsumerState<WorkspacePage> {
  final _editor = TextEditingController();
  FileInput? _file;
  bool _dragging = false;

  /// Edits not saved back yet, for the record [_editedFor].
  List<Detection>? _edited;
  String? _editedFor;

  /// Languages of the open record's text, for the status bar.
  ({String id, List<String> languages})? _languages;

  static final _mod = Platform.isMacOS ? '⌘' : 'Ctrl+';

  @override
  void initState() {
    super.initState();
    // Load the NER model now so the first run is as fast as the rest.
    ref.read(anonymizeServiceProvider).warmUp();
  }

  @override
  void dispose() {
    _editor.dispose();
    super.dispose();
  }

  bool get _busy => ref.read(processControllerProvider).isLoading;

  String? get _recordId => ref.read(openRecordProvider);

  void _startOver({String text = '', FileInput? file}) {
    ref.read(openRecordProvider.notifier).close();
    setState(() {
      _editor.text = text;
      _file = file;
    });
  }

  Future<void> _paste() async {
    if (_busy) return;
    final text = (await Clipboard.getData(Clipboard.kTextPlain))?.text;
    if (!mounted) return;
    if (text == null || text.trim().isEmpty) {
      showSnack(context, AppLocalizations.of(context).clipboardEmpty);
      return;
    }
    _startOver(text: text);
  }

  Future<void> _open() async {
    if (_busy) return;
    final picked = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: TextExtractor.pickableExtensions,
    );
    final path = picked?.path;
    if (picked == null || path == null || !mounted) return;
    _startOver(
      file: FileInput(path: path, name: picked.name),
    );
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
    _startOver(file: input);
  }

  Future<void> _anonymize() async {
    if (_busy || _recordId != null) return;
    final l10n = AppLocalizations.of(context);
    final InputSource? source =
        _file ?? (_editor.text.trim().isEmpty ? null : TextInput(_editor.text));
    if (source == null) {
      showSnack(context, l10n.errorNoText);
      return;
    }
    final id = await ref.read(processControllerProvider.notifier).run(source);
    if (!mounted) return;
    if (id == null) {
      final err = ref.read(processControllerProvider).error;
      if (err != null) showSnack(context, processErrorMessage(l10n, err));
      return;
    }
    ref.read(openRecordProvider.notifier).open(id);
    setState(() {
      _editor.clear();
      _file = null;
    });
  }

  /// Saves [next] as the open record's detections, merged as the core does
  /// (overlaps resolved, values propagated).
  void _commit(String id, String original, List<Detection> next) {
    final merged = core.merge(original, next);
    setState(() {
      _edited = merged;
      _editedFor = id;
    });
    ref.read(reviewControllerProvider.notifier).apply(id, merged);
  }

  Future<void> _copy(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) showSnack(context, AppLocalizations.of(context).copied);
  }

  Future<void> _save(RecordDetail detail) async {
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
    if (saved != null && mounted) showSnack(context, l10n.savedFile);
  }

  /// "report-anonymized.txt" -> "report-anonymized.pdf".
  static String _withExtension(String name, String extension) {
    final dot = name.lastIndexOf('.');
    return '${dot == -1 ? name : name.substring(0, dot)}.$extension';
  }

  void _restore() {
    final id = _recordId;
    if (id == null) return;
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => RestorePage(recordId: id)));
  }

  List<String> _languagesOf(String id, String text) {
    final known = _languages;
    if (known != null && known.id == id) return known.languages;
    final languages = core.languages(text);
    _languages = (id: id, languages: languages);
    return languages;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final busy = ref.watch(processControllerProvider).isLoading;
    final model = ref.watch(nerNameProvider);
    final id = ref.watch(openRecordProvider);
    final detail = id == null ? null : ref.watch(recordDetailProvider(id));
    final loaded = detail?.value;
    if (_editedFor != id) {
      _edited = null;
      _editedFor = id;
    }
    final detections = _edited ?? loaded?.detections ?? const <Detection>[];
    final output = loaded == null
        ? null
        : core
              .anonymize(loaded.original, detections, previous: loaded.map)
              .text;

    void toggle(Iterable<int> indices, bool hidden) {
      final d = loaded!;
      final set = indices.toSet();
      _commit(d.record.id, d.original, [
        for (var i = 0; i < detections.length; i++)
          set.contains(i)
              ? detections[i].copyWith(enabled: hidden)
              : detections[i],
      ]);
    }

    final noModel = loaded != null
        ? !loaded.record.modelUsed
        : model.hasValue && model.value == null;
    final notes = [
      if (loaded?.record.listOnly ?? false) l10n.resultListOnlyNote,
      if (noModel) l10n.noModelNote,
      if (loaded?.document case RecordDocument(redactedPath: null))
        l10n.resultTextOnlyNote,
    ];

    final original = DocumentPane(
      caption: l10n.tabOriginal,
      trailing: loaded == null ? null : _Caption(loaded.record.displayName),
      child: switch ((loaded, _file)) {
        (final RecordDetail d, _) => OriginalView(
          text: d.original,
          detections: detections,
          onToggle: (i) => toggle([i], !detections[i].enabled),
          onHide: (start, end) => _commit(d.record.id, d.original, [
            ...detections,
            ref
                .read(anonymizeServiceProvider)
                .manualDetection(d.original, start, end, EntityType.custom),
          ]),
        ),
        (null, final FileInput file) => _StagedFile(
          file: file,
          onRemove: () => setState(() => _file = null),
        ),
        _ =>
          id != null
              ? const Center(child: CircularProgressIndicator())
              : _Editor(controller: _editor, hint: l10n.editorHint),
      },
    );

    final anonymized = DocumentPane(
      caption: l10n.tabAnonymized,
      trailing: loaded == null
          ? null
          : _Caption(
              l10n.detectionCount(detections.where((d) => d.enabled).length),
            ),
      child: output == null
          ? Center(
              child: Text(
                l10n.anonymizedEmpty,
                style: Clay.body(13, color: Clay.inkPlaceholder),
              ),
            )
          : AnonymizedView(text: output),
    );

    final findings = loaded == null
        ? null
        : FindingsPanel(
            detections: detections,
            onChanged: toggle,
            onAlwaysHide: ref.read(dictionaryProvider.notifier).add,
            onNeverHide: ref.read(neverHideProvider.notifier).add,
          );

    final shortcuts = <ShortcutActivator, VoidCallback>{
      for (final meta in [true, false]) ...{
        SingleActivator(LogicalKeyboardKey.keyO, meta: meta, control: !meta):
            _open,
        SingleActivator(LogicalKeyboardKey.keyN, meta: meta, control: !meta):
            _startOver,
        SingleActivator(LogicalKeyboardKey.keyV, meta: meta, control: !meta):
            _paste,
        SingleActivator(LogicalKeyboardKey.enter, meta: meta, control: !meta):
            _anonymize,
        SingleActivator(LogicalKeyboardKey.keyR, meta: meta, control: !meta):
            _restore,
        if (loaded != null) ...{
          SingleActivator(
            LogicalKeyboardKey.keyS,
            meta: meta,
            control: !meta,
          ): () =>
              _save(loaded),
          SingleActivator(
            LogicalKeyboardKey.keyC,
            meta: meta,
            control: !meta,
            shift: true,
          ): () =>
              _copy(output!),
        },
      },
    };

    return CallbackShortcuts(
      bindings: shortcuts,
      child: Focus(
        autofocus: true,
        child: DropTarget(
          onDragEntered: (_) => setState(() => _dragging = true),
          onDragExited: (_) => setState(() => _dragging = false),
          onDragDone: _drop,
          child: Scaffold(
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DeskToolbar(
                  leading: [
                    DeskTool(
                      icon: Icons.note_add_outlined,
                      label: l10n.toolbarNew,
                      shortcut: '${_mod}N',
                      onPressed: busy ? null : _startOver,
                    ),
                    DeskTool(
                      icon: Icons.folder_open_outlined,
                      label: l10n.toolbarOpen,
                      shortcut: '${_mod}O',
                      onPressed: busy ? null : _open,
                    ),
                    DeskTool(
                      icon: Icons.content_paste_rounded,
                      label: l10n.paste,
                      shortcut: '${_mod}V',
                      onPressed: busy ? null : _paste,
                    ),
                    DeskTool(
                      icon: Icons.shield_outlined,
                      label: l10n.anonymizeButton,
                      shortcut: '$_mod↩',
                      primary: true,
                      onPressed: busy || id != null ? null : _anonymize,
                    ),
                  ],
                  trailing: [
                    DeskTool(
                      icon: Icons.copy_rounded,
                      label: l10n.copy,
                      shortcut: '$_mod⇧C',
                      onPressed: output == null ? null : () => _copy(output),
                    ),
                    DeskTool(
                      icon: Icons.save_alt_rounded,
                      label: l10n.saveFile,
                      shortcut: '${_mod}S',
                      onPressed: loaded == null ? null : () => _save(loaded),
                    ),
                    DeskTool(
                      icon: Icons.settings_backup_restore_rounded,
                      label: l10n.restoreReply,
                      shortcut: '${_mod}R',
                      onPressed: loaded == null ? null : _restore,
                    ),
                  ],
                ),
                SizedBox(
                  height: 2,
                  child: busy
                      ? const LinearProgressIndicator(minHeight: 2)
                      : null,
                ),
                for (final note in notes) DeskNoteBar(text: note),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: LayoutBuilder(
                      builder: (context, box) {
                        final panes = Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: _DropHighlight(
                                on: _dragging,
                                child: original,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(child: anonymized),
                            if (findings != null && box.maxWidth >= 900) ...[
                              const SizedBox(width: 10),
                              SizedBox(width: 240, child: findings),
                            ],
                          ],
                        );
                        if (findings == null || box.maxWidth >= 900) {
                          return panes;
                        }
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(child: panes),
                            const SizedBox(height: 10),
                            SizedBox(height: 200, child: findings),
                          ],
                        );
                      },
                    ),
                  ),
                ),
                _StatusBar(
                  children: [
                    const Icon(
                      Icons.lock_outline_rounded,
                      size: 13,
                      color: Clay.secondaryText,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        l10n.homeCaption,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Clay.body(11.5, color: Clay.secondaryText),
                      ),
                    ),
                    if (loaded != null)
                      _StatusItem(
                        l10n.statusLanguages(
                          _languagesOf(
                            loaded.record.id,
                            loaded.original,
                          ).join(', '),
                        ),
                      ),
                    _StatusItem(switch (model) {
                      AsyncData(value: final name?) => l10n.statusModel(name),
                      AsyncData() => l10n.statusNoModel,
                      _ => '…',
                    }),
                    const Spacer(),
                    if (loaded != null)
                      Flexible(child: _StatusItem(l10n.savedToHistory)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Caption extends StatelessWidget {
  const _Caption(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Flexible(
    child: Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: Clay.body(12, color: Clay.inkPlaceholder),
    ),
  );
}

class _StatusBar extends StatelessWidget {
  const _StatusBar({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      color: Clay.surface,
      border: Border(top: BorderSide(color: Clay.divider)),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      child: Row(children: children),
    ),
  );
}

class _StatusItem extends StatelessWidget {
  const _StatusItem(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 16),
    child: Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: Clay.body(11.5, color: Clay.inkCaption),
    ),
  );
}

/// The left pane before anything is anonymized: a plain text editor.
class _Editor extends StatelessWidget {
  const _Editor({required this.controller, required this.hint});

  final TextEditingController controller;
  final String hint;

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    expands: true,
    maxLines: null,
    textAlignVertical: TextAlignVertical.top,
    style: Clay.body(14, height: 1.7),
    decoration: InputDecoration(
      hintText: hint,
      filled: false,
      border: InputBorder.none,
      enabledBorder: InputBorder.none,
      focusedBorder: InputBorder.none,
      contentPadding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
    ),
  );
}

/// A file waiting to be anonymized: its icon and name, and a way to drop it.
class _StagedFile extends StatelessWidget {
  const _StagedFile({required this.file, required this.onRemove});

  final FileInput file;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) => Center(
    child: Container(
      constraints: const BoxConstraints(maxWidth: 360),
      padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
      decoration: BoxDecoration(
        color: Clay.bg,
        borderRadius: BorderRadius.circular(Clay.controlRadius),
      ),
      child: Row(
        children: [
          Icon(fileIcon(file.extension), size: 26, color: Clay.secondary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              file.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Clay.body(13.5, weight: FontWeight.w500),
            ),
          ),
          IconButton(
            tooltip: AppLocalizations.of(context).cancel,
            icon: const Icon(Icons.close_rounded, size: 16),
            onPressed: onRemove,
          ),
        ],
      ),
    ),
  );
}

/// Outlines the pane in sage while a file is dragged over the window.
class _DropHighlight extends StatelessWidget {
  const _DropHighlight({required this.on, required this.child});

  final bool on;
  final Widget child;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: Clay.motion,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(Clay.controlRadius + 2),
      border: Border.all(
        color: on ? Clay.secondary : Colors.transparent,
        width: 2,
      ),
    ),
    child: child,
  );
}
