import 'package:docudis_ffi/docudis_ffi.dart';
import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/clay_theme.dart';
import 'entity_labels.dart';

/// One value as the findings list shows it: every detection of the same
/// type and text, which are hidden or shown together.
class _Finding {
  _Finding(this.type, this.value);

  final EntityType type;
  final String value;
  final indices = <int>[];
}

/// "Findings": every detected value once, in reading order, with a check
/// box that hides it (checked) or shows it again. Amounts and dates, found
/// but left readable by default, get a switch for all of them at once.
class FindingsPanel extends StatelessWidget {
  const FindingsPanel({
    super.key,
    required this.detections,
    required this.onChanged,
    this.onAlwaysHide,
    this.onNeverHide,
  });

  final List<Detection> detections;

  /// The detections with the ones at these indices set to `hidden`.
  final void Function(Iterable<int> indices, bool hidden) onChanged;

  /// Right-click menu: put a value on the Always hide or Never hide list,
  /// for the next documents.
  final ValueChanged<String>? onAlwaysHide;
  final ValueChanged<String>? onNeverHide;

  List<_Finding> _findings() {
    final byKey = <(EntityType, String), _Finding>{};
    final order = List<int>.generate(detections.length, (i) => i)
      ..sort((a, b) => detections[a].start.compareTo(detections[b].start));
    for (final i in order) {
      final d = detections[i];
      final value = d.value.trim();
      (byKey[(d.type, value)] ??= _Finding(d.type, value)).indices.add(i);
    }
    return byKey.values.toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final findings = _findings();
    bool hidden(_Finding f) => f.indices.every((i) => detections[i].enabled);
    final hiddenCount = findings.where(hidden).length;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Clay.surface,
        border: Border.all(color: Clay.divider),
        borderRadius: BorderRadius.circular(Clay.controlRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
            child: Row(
              children: [
                Text(
                  l10n.findingsTitle,
                  style: Clay.body(
                    12,
                    weight: FontWeight.w700,
                    color: Clay.inkCaption,
                  ),
                ),
                const Spacer(),
                Text(
                  '$hiddenCount / ${findings.length}',
                  style: Clay.body(12, color: Clay.inkPlaceholder),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          for (final (type, label) in [
            (EntityType.amount, l10n.reviewHideAmounts),
            (EntityType.date, l10n.reviewHideDates),
          ])
            if (detections.any((d) => d.type == type))
              _AllOfType(
                label: label,
                value: detections
                    .where((d) => d.type == type)
                    .every((d) => d.enabled),
                onChanged: (on) => onChanged([
                  for (var i = 0; i < detections.length; i++)
                    if (detections[i].type == type) i,
                ], on),
              ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 4),
              itemCount: findings.length,
              itemBuilder: (_, i) {
                final f = findings[i];
                final on = hidden(f);
                return _FindingRow(
                  value: f.value,
                  kind: entityLabel(l10n, f.type),
                  count: f.indices.length,
                  color: entityColors(f.type).accent,
                  hidden: on,
                  onChanged: () => onChanged(f.indices, !on),
                  onMenu: (position) => _menu(context, position, f.value),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

extension on FindingsPanel {
  Future<void> _menu(
    BuildContext context,
    Offset position,
    String value,
  ) async {
    final l10n = AppLocalizations.of(context);
    final always = onAlwaysHide, never = onNeverHide;
    final picked = await showMenu<ValueChanged<String>>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx,
        position.dy,
      ),
      items: [
        if (always != null)
          PopupMenuItem(
            height: 32,
            value: always,
            child: Text(l10n.dictionaryAdd(value)),
          ),
        if (never != null)
          PopupMenuItem(
            height: 32,
            value: never,
            child: Text(l10n.neverHideAdd(value)),
          ),
      ],
    );
    picked?.call(value);
  }
}

class _AllOfType extends StatelessWidget {
  const _AllOfType({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(12, 2, 4, 0),
    child: Row(
      children: [
        Expanded(
          child: Text(label, style: Clay.body(12.5, weight: FontWeight.w500)),
        ),
        Transform.scale(
          scale: 0.7,
          child: Switch(value: value, onChanged: onChanged),
        ),
      ],
    ),
  );
}

/// Check box, type colour, value, what it is and how often it occurs.
/// Shown values are greyed.
class _FindingRow extends StatelessWidget {
  const _FindingRow({
    required this.value,
    required this.kind,
    required this.count,
    required this.color,
    required this.hidden,
    required this.onChanged,
    required this.onMenu,
  });

  final String value;
  final String kind;
  final int count;
  final Color color;
  final bool hidden;
  final VoidCallback onChanged;

  /// Right click, at this global position.
  final ValueChanged<Offset> onMenu;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onSecondaryTapUp: (details) => onMenu(details.globalPosition),
    child: InkWell(
      onTap: onChanged,
      hoverColor: Clay.bg,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(6, 2, 10, 2),
        child: Row(
          children: [
            SizedBox(
              width: 28,
              height: 28,
              child: Checkbox(
                value: hidden,
                onChanged: (_) => onChanged(),
                visualDensity: VisualDensity.compact,
                activeColor: Clay.primary,
              ),
            ),
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(left: 2, right: 8),
              decoration: BoxDecoration(
                color: hidden ? color : Clay.disabled,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value.replaceAll(RegExp(r'\s+'), ' '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Clay.body(
                      13,
                      weight: FontWeight.w500,
                      color: hidden ? Clay.ink : Clay.inkPlaceholder,
                    ),
                  ),
                  Text(
                    count > 1 ? '$kind · ×$count' : kind,
                    style: Clay.body(11, color: Clay.inkCaption),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
