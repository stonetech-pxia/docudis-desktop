import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/clay_theme.dart';
import '../../theme/clay_widgets.dart';
import '../providers.dart';
import '../storage/anonymization_record.dart';
import 'dates.dart';

enum _Column { name, kind, found, updated }

/// History tab: every record in a table, newest first by default; a click
/// on a header sorts by that column, a click on a row opens the record in
/// the workspace.
class HistoryPage extends ConsumerStatefulWidget {
  const HistoryPage({super.key});

  @override
  ConsumerState<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends ConsumerState<HistoryPage> {
  _Column _sortBy = _Column.updated;
  bool _ascending = false;

  void _sort(_Column column) => setState(() {
    if (_sortBy == column) {
      _ascending = !_ascending;
    } else {
      _sortBy = column;
      _ascending = column == _Column.name;
    }
  });

  List<AnonymizationRecord> _sorted(List<AnonymizationRecord> records) {
    int compare(AnonymizationRecord a, AnonymizationRecord b) =>
        switch (_sortBy) {
          _Column.name => a.displayName.toLowerCase().compareTo(
            b.displayName.toLowerCase(),
          ),
          _Column.kind => a.kind.index.compareTo(b.kind.index),
          _Column.found => a.detectionCount.compareTo(b.detectionCount),
          _Column.updated => a.updatedAt.compareTo(b.updatedAt),
        };
    return [...records]
      ..sort((a, b) => _ascending ? compare(a, b) : compare(b, a));
  }

  Future<void> _deleteAll() async {
    final l10n = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteAllConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.deleteAll),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(recordStoreProvider).deleteAll();
    ref.read(openRecordProvider.notifier).close();
    ref.invalidate(recordsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final records = ref.watch(recordsProvider);
    final hasRecords = records.value?.isNotEmpty ?? false;
    final sorted = _sorted(records.value ?? const []);
    Widget header(_Column column, String label, {int flex = 1}) => Expanded(
      flex: flex,
      child: InkWell(
        onTap: () => _sort(column),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 7),
          child: Row(
            children: [
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: Clay.body(
                    12,
                    weight: FontWeight.w700,
                    color: Clay.inkCaption,
                  ),
                ),
              ),
              if (_sortBy == column)
                Icon(
                  _ascending
                      ? Icons.arrow_drop_up_rounded
                      : Icons.arrow_drop_down_rounded,
                  size: 18,
                  color: Clay.inkCaption,
                ),
            ],
          ),
        ),
      ),
    );

    return ClayPage(
      title: l10n.historyTitle,
      showBack: false,
      actions: [
        ClayIconButton(
          icon: Icons.delete_sweep_outlined,
          tooltip: l10n.deleteAll,
          onPressed: hasRecords ? _deleteAll : null,
          color: hasRecords ? Clay.ink : Clay.inkPlaceholder,
        ),
      ],
      body: records.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (list) => list.isEmpty
            ? Center(
                child: Text(
                  l10n.historyEmpty,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              )
            : Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Clay.surface,
                    border: Border.all(color: Clay.divider),
                    borderRadius: BorderRadius.circular(Clay.controlRadius),
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 12, right: 40),
                        child: Row(
                          children: [
                            header(
                              _Column.name,
                              l10n.historyColumnName,
                              flex: 5,
                            ),
                            header(
                              _Column.kind,
                              l10n.historyColumnType,
                              flex: 1,
                            ),
                            header(
                              _Column.found,
                              l10n.historyColumnFound,
                              flex: 1,
                            ),
                            header(
                              _Column.updated,
                              l10n.historyColumnUpdated,
                              flex: 2,
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      Expanded(
                        child: ListView.separated(
                          itemCount: sorted.length,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (_, i) => RecordRow(record: sorted[i]),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}

enum _RecordAction { rename, delete }

/// One History row: name with its kind's icon and a preview, kind, how many
/// values were hidden, when; a menu to rename or delete it.
class RecordRow extends ConsumerWidget {
  const RecordRow({super.key, required this.record});

  final AnonymizationRecord record;

  Future<void> _rename(BuildContext context, WidgetRef ref) async {
    final name = await showDialog<String>(
      context: context,
      builder: (_) => _RenameDialog(initial: record.displayName),
    );
    final title = name?.trim() ?? '';
    if (title.isEmpty || title == record.displayName) return;
    await ref.read(recordStoreProvider).rename(record.id, title);
    ref
      ..invalidate(recordsProvider)
      ..invalidate(recordDetailProvider(record.id));
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteRecordConfirm),
        // The time as well: copies of one file share its name.
        content: Text(
          '${record.displayName}\n${formatWhen(context, record.updatedAt)}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(recordStoreProvider).delete(record.id);
    if (ref.read(openRecordProvider) == record.id) {
      ref.read(openRecordProvider.notifier).close();
    }
    ref.invalidate(recordsProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final (icon, color, kind) = switch (record.kind) {
      InputKind.text => (Icons.notes_rounded, Clay.primary, l10n.kindText),
      InputKind.file => (
        Icons.description_outlined,
        Clay.secondary,
        l10n.kindFile,
      ),
      InputKind.image => (Icons.image_outlined, Clay.tertiary, l10n.kindFile),
    };
    final cell = Clay.body(12.5, color: Clay.inkMuted);
    return InkWell(
      hoverColor: Clay.bg,
      onTap: () => ref.read(openRecordProvider.notifier).open(record.id),
      child: Padding(
        padding: const EdgeInsets.only(left: 12, right: 4),
        child: SizedBox(
          height: 46,
          child: Row(
            children: [
              Expanded(
                flex: 5,
                child: Row(
                  children: [
                    Icon(icon, size: 16, color: color),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            record.displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Clay.body(13, weight: FontWeight.w700),
                          ),
                          if (record.preview.isNotEmpty)
                            Text(
                              record.preview,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Clay.body(11.5, color: Clay.inkCaption),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(flex: 1, child: Text(kind, style: cell)),
              Expanded(
                flex: 1,
                child: Text('${record.detectionCount}', style: cell),
              ),
              Expanded(
                flex: 2,
                child: Text(formatWhen(context, record.updatedAt), style: cell),
              ),
              PopupMenuButton<_RecordAction>(
                tooltip: l10n.moreActions,
                iconSize: 18,
                icon: const Icon(
                  Icons.more_horiz_rounded,
                  color: Clay.inkCaption,
                ),
                onSelected: (action) => switch (action) {
                  _RecordAction.rename => _rename(context, ref),
                  _RecordAction.delete => _delete(context, ref),
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: _RecordAction.rename,
                    child: Text(l10n.rename),
                  ),
                  PopupMenuItem(
                    value: _RecordAction.delete,
                    child: Text(l10n.delete),
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

/// The new name, or nothing when cancelled. Owns its text field's
/// controller, which lives until the dialog has finished closing.
class _RenameDialog extends StatefulWidget {
  const _RenameDialog({required this.initial});

  final String initial;

  @override
  State<_RenameDialog> createState() => _RenameDialogState();
}

class _RenameDialogState extends State<_RenameDialog> {
  late final _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.rename),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLength: 80,
        onSubmitted: (v) => Navigator.pop(context, v),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          child: Text(l10n.save),
        ),
      ],
    );
  }
}
