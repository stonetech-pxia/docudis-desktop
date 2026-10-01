import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/clay_theme.dart';
import '../../theme/clay_widgets.dart';
import '../providers.dart';
import '../storage/anonymization_record.dart';
import 'dates.dart';
import 'result_page.dart';

/// History tab: every record, newest first.
class HistoryPage extends ConsumerWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final records = ref.watch(recordsProvider);
    final hasRecords = records.value?.isNotEmpty ?? false;
    return ClayPage(
      title: l10n.historyTitle,
      showBack: false,
      actions: [
        ClayIconButton(
          icon: Icons.delete_sweep_outlined,
          tooltip: l10n.deleteAll,
          onPressed: hasRecords ? () => _deleteAll(context, ref) : null,
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
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                itemCount: list.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (_, i) => RecordCard(record: list[i]),
              ),
      ),
    );
  }

  Future<void> _deleteAll(BuildContext context, WidgetRef ref) async {
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
    ref.invalidate(recordsProvider);
  }
}

enum _RecordAction { rename, delete }

/// One History row: what it is, when, how much was hidden, and a menu to
/// rename or delete it.
class RecordCard extends ConsumerWidget {
  const RecordCard({super.key, required this.record});

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
    ref.invalidate(recordsProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final (icon, color) = switch (record.kind) {
      InputKind.text => (Icons.content_paste_rounded, Clay.primary),
      InputKind.file => (Icons.description_outlined, Clay.secondary),
      InputKind.image => (Icons.photo_camera_outlined, Clay.tertiary),
    };
    final when = formatWhen(context, record.updatedAt);
    return ClayCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 4, 14),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ResultPage(recordId: record.id),
        ),
      ),
      child: Row(
        children: [
          ClayIconTile(icon: icon, color: color, size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.displayName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 2),
                Text(
                  '$when · ${l10n.detectionCount(record.detectionCount)}',
                  style: Clay.body(12, color: Clay.inkCaption),
                ),
                if (record.preview.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    record.preview,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Clay.body(13, color: Clay.inkMuted),
                  ),
                ],
              ],
            ),
          ),
          PopupMenuButton<_RecordAction>(
            tooltip: l10n.moreActions,
            icon: const Icon(Icons.more_vert_rounded, color: Clay.inkCaption),
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
        textCapitalization: TextCapitalization.sentences,
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
