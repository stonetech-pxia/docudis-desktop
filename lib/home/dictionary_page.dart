import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../anonymize/manual_blocks.dart';
import '../anonymize/providers.dart';
import '../l10n/app_localizations.dart';
import '../theme/clay_theme.dart';
import '../theme/clay_widgets.dart';

/// Switches "Hide only this list"; it goes on only once the user has read
/// what stays visible.
Future<void> setListOnly(BuildContext context, WidgetRef ref, bool on) async {
  if (on) {
    final l10n = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        scrollable: true,
        title: Text(l10n.listOnlyConfirmTitle),
        content: Text(l10n.listOnlyConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.listOnlyConfirmAction),
          ),
        ],
      ),
    );
    if (ok != true) return;
  }
  await ref.read(listOnlyProvider.notifier).set(on);
}

/// Dictionary tab: "Always hide" and "Never hide" side by side. Each has a
/// field to add a term, the terms, and what the user hid (or showed again)
/// by hand lately, one click from the list. "Hide only this list" sits with
/// Always hide and stays locked while that list is empty.
class DictionaryPage extends ConsumerWidget {
  const DictionaryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final always = ref.watch(dictionaryProvider).value ?? const <String>[];
    final never = ref.watch(neverHideProvider).value ?? const <String>[];
    final hidden = mostRepeated(
      ref.watch(manualBlocksProvider).value ?? const <ManualBlock>[],
      limit: maxManualBlocks,
    );
    final shown = mostRepeated(
      ref.watch(revealedBlocksProvider).value ?? const <ManualBlock>[],
      limit: maxManualBlocks,
    );
    final listOnly = ref.watch(listOnlyProvider) && always.isNotEmpty;

    final alwaysPanel = _ListPanel(
      title: l10n.dictionaryTitle,
      hint: l10n.dictionaryHint,
      inputHint: l10n.dictionaryInputHint,
      terms: always,
      chip: Clay.primaryTint,
      chipText: Clay.primaryPressed,
      empty: l10n.dictionaryEmpty,
      suggestedTitle: l10n.dictionarySuggested,
      suggested: hidden,
      removeLabel: l10n.dictionaryRemove,
      addLabel: l10n.dictionaryAdd,
      onAdd: ref.read(dictionaryProvider.notifier).add,
      onRemove: ref.read(dictionaryProvider.notifier).remove,
      header: _ListOnlyRow(
        value: listOnly,
        onChanged: always.isEmpty
            ? null
            : (on) => setListOnly(context, ref, on),
      ),
    );
    final neverPanel = _ListPanel(
      title: l10n.neverHideTitle,
      hint: l10n.neverHideHint,
      inputHint: l10n.neverHideInputHint,
      terms: never,
      chip: Clay.secondaryTint,
      chipText: Clay.secondaryText,
      empty: l10n.neverHideEmpty,
      suggestedTitle: l10n.neverHideSuggested,
      suggested: shown,
      removeLabel: l10n.neverHideRemove,
      addLabel: l10n.neverHideAdd,
      onAdd: ref.read(neverHideProvider.notifier).add,
      onRemove: ref.read(neverHideProvider.notifier).remove,
    );

    return ClayPage(
      title: l10n.navDictionary,
      showBack: false,
      body: Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
        child: LayoutBuilder(
          builder: (context, box) => box.maxWidth >= 760
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: alwaysPanel),
                    const SizedBox(width: 10),
                    Expanded(child: neverPanel),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: alwaysPanel),
                    const SizedBox(height: 10),
                    Expanded(child: neverPanel),
                  ],
                ),
        ),
      ),
    );
  }
}

/// One list: title and explanation, an optional [header] row, the add
/// field, the terms as removable rows, and the suggestions with an add
/// button each.
class _ListPanel extends StatelessWidget {
  const _ListPanel({
    required this.title,
    required this.hint,
    required this.inputHint,
    required this.terms,
    required this.chip,
    required this.chipText,
    required this.empty,
    required this.suggestedTitle,
    required this.suggested,
    required this.removeLabel,
    required this.addLabel,
    required this.onAdd,
    required this.onRemove,
    this.header,
  });

  final String title;
  final String hint;
  final String inputHint;
  final List<String> terms;
  final Color chip;
  final Color chipText;
  final String empty;
  final String suggestedTitle;
  final List<ManualBlock> suggested;
  final String Function(String term) removeLabel;
  final String Function(String term) addLabel;
  final Future<void> Function(String term) onAdd;
  final Future<void> Function(String term) onRemove;
  final Widget? header;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Clay.surface,
        border: Border.all(color: Clay.divider),
        borderRadius: BorderRadius.circular(Clay.controlRadius),
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        children: [
          Row(
            children: [
              Text(title, style: Clay.heading(14, weight: FontWeight.w600)),
              const SizedBox(width: 8),
              Text(
                l10n.dictionaryWords(terms.length),
                style: Clay.body(12, color: Clay.inkPlaceholder),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(hint, style: Clay.body(12.5, color: Clay.inkMuted, height: 1.5)),
          ?header,
          const SizedBox(height: 10),
          _TermField(
            hint: inputHint,
            button: l10n.dictionaryAddButton,
            onAdd: onAdd,
          ),
          const SizedBox(height: 10),
          if (terms.isEmpty && suggested.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                empty,
                style: Clay.body(12.5, color: Clay.inkCaption),
              ),
            ),
          if (terms.isNotEmpty)
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final term in terms)
                  _Term(
                    label: term,
                    tooltip: removeLabel(term),
                    background: chip,
                    foreground: chipText,
                    onRemove: () => onRemove(term),
                  ),
              ],
            ),
          if (suggested.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              suggestedTitle,
              style: Clay.body(
                12,
                weight: FontWeight.w700,
                color: Clay.inkCaption,
              ),
            ),
            const SizedBox(height: 4),
            for (final block in suggested)
              _Suggestion(
                block: block,
                tooltip: addLabel(block.value),
                onAdd: () => onAdd(block.value),
              ),
          ],
        ],
      ),
    );
  }
}

class _ListOnlyRow extends StatelessWidget {
  const _ListOnlyRow({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.listOnlyTitle,
                  style: Clay.body(13, weight: FontWeight.w700),
                ),
                Text(
                  onChanged == null
                      ? l10n.listOnlyNeedsWords
                      : l10n.listOnlyHint,
                  style: Clay.body(12, color: Clay.inkCaption),
                ),
              ],
            ),
          ),
          Transform.scale(
            scale: 0.75,
            child: Switch(value: value, onChanged: onChanged),
          ),
        ],
      ),
    );
  }
}

/// A text field with an Add button; Enter adds too.
class _TermField extends StatefulWidget {
  const _TermField({
    required this.hint,
    required this.button,
    required this.onAdd,
  });

  final String hint;
  final String button;
  final Future<void> Function(String term) onAdd;

  @override
  State<_TermField> createState() => _TermFieldState();
}

class _TermFieldState extends State<_TermField> {
  final _controller = TextEditingController();
  final _focus = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    final term = _controller.text.trim();
    if (term.isEmpty) return;
    await widget.onAdd(term);
    _controller.clear();
    _focus.requestFocus();
  }

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: SizedBox(
          height: 32,
          child: TextField(
            controller: _controller,
            focusNode: _focus,
            onSubmitted: (_) => _add(),
            style: Clay.body(13),
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: Clay.body(13, color: Clay.inkPlaceholder),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 8,
              ),
            ),
          ),
        ),
      ),
      const SizedBox(width: 8),
      FilledButton(
        onPressed: _add,
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 32),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          textStyle: Clay.body(12.5, weight: FontWeight.w700),
        ),
        child: Text(widget.button),
      ),
    ],
  );
}

/// A term on the list: a tinted chip with a remove cross.
class _Term extends StatelessWidget {
  const _Term({
    required this.label,
    required this.tooltip,
    required this.background,
    required this.foreground,
    required this.onRemove,
  });

  final String label;
  final String tooltip;
  final Color background;
  final Color foreground;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.only(left: 10, right: 2),
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(6),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: Clay.body(12.5, weight: FontWeight.w700, color: foreground),
          ),
        ),
        IconButton(
          tooltip: tooltip,
          onPressed: onRemove,
          icon: Icon(Icons.close_rounded, size: 14, color: foreground),
          constraints: const BoxConstraints.tightFor(width: 24, height: 26),
          padding: EdgeInsets.zero,
        ),
      ],
    ),
  );
}

/// A suggestion row: the text, how many documents it came up in, and a
/// button to put it on the list.
class _Suggestion extends StatelessWidget {
  const _Suggestion({
    required this.block,
    required this.tooltip,
    required this.onAdd,
  });

  final ManualBlock block;
  final String tooltip;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onAdd,
    hoverColor: Clay.bg,
    borderRadius: BorderRadius.circular(6),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              block.value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Clay.body(13),
            ),
          ),
          Text(
            AppLocalizations.of(context).blockDocuments(block.documents),
            style: Clay.body(11.5, color: Clay.inkCaption),
          ),
          Tooltip(
            message: tooltip,
            child: const Padding(
              padding: EdgeInsets.only(left: 6),
              child: Icon(Icons.add_rounded, size: 16, color: Clay.primary),
            ),
          ),
        ],
      ),
    ),
  );
}
