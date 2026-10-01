import 'package:docudis_ffi/docudis_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/clay_theme.dart';
import '../../theme/clay_widgets.dart';
import '../engine/native_libraries.dart';
import '../providers.dart';
import 'highlights.dart';

/// "Change what is hidden": the document as the AI will read it, with every
/// replaced value shown as its placeholder.
///
/// One gesture only. Tap a placeholder and the real value comes back; tap
/// any other piece of text — a name, a number, a whole CJK clause — and it
/// becomes a placeholder. Every tap is saved to the record right away, so
/// there is nothing to confirm.
///
/// Amounts and dates are found but left readable by default; when the
/// document has some, a switch above it hides or shows all of them at once.
class ReviewPage extends ConsumerStatefulWidget {
  const ReviewPage({super.key, required this.recordId});

  final String recordId;

  @override
  ConsumerState<ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends ConsumerState<ReviewPage> {
  /// Local edits; null until the user taps something.
  List<Detection>? _edited;

  final _textKey = GlobalKey();
  _Document? _document;

  /// Replaces the record's detections with [next] and re-anonymizes in
  /// place. Propagation runs here too, so what the page shows is what the
  /// record stores.
  void _commit(String original, List<Detection> next) {
    final merged = core.merge(original, next);
    setState(() => _edited = merged);
    ref.read(reviewControllerProvider.notifier).apply(widget.recordId, merged);
  }

  /// Hides or shows every detection of [type] at once.
  void _setAll(
    String original,
    List<Detection> current,
    EntityType type,
    bool hidden,
  ) {
    _commit(original, [
      for (final d in current) d.type == type ? d.copyWith(enabled: hidden) : d,
    ]);
  }

  void _handleTap(String original, List<Detection> current, Offset global) {
    final document = _document;
    final box = _textKey.currentContext?.findRenderObject() as RenderBox?;
    if (document == null || box == null) return;
    final painter = TextPainter(
      text: document.span,
      textDirection: TextDirection.ltr,
      textScaler: MediaQuery.textScalerOf(context),
    )..layout(maxWidth: box.size.width);
    final tapped = painter
        .getPositionForOffset(box.globalToLocal(global))
        .offset;
    painter.dispose();

    // Tapping the right half of a glyph lands on the offset after it.
    final hit = document.at(tapped) ?? document.at(tapped - 1);
    if (hit == null) return;
    final (piece, offset) = hit;

    // A placeholder: put the real value back.
    if (piece.detection case final index?) {
      _commit(original, [
        for (var i = 0; i < current.length; i++)
          i == index ? current[i].copyWith(enabled: false) : current[i],
      ]);
      return;
    }
    // Something the user put back earlier: hide it again.
    final off = current.indexWhere(
      (d) => !d.enabled && offset >= d.start && offset < d.end,
    );
    if (off != -1) {
      _commit(original, [
        for (var i = 0; i < current.length; i++)
          i == off ? current[i].copyWith(enabled: true) : current[i],
      ]);
      return;
    }
    // Plain text: hide the chunk the tap landed in.
    final chunk = document.chunkAt(offset);
    if (chunk == null) return;
    _commit(original, [
      ...current,
      ref
          .read(anonymizeServiceProvider)
          .manualDetection(original, chunk.start, chunk.end, EntityType.custom),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final detail = ref.watch(recordDetailProvider(widget.recordId));
    final current = _edited ?? detail.value?.detections ?? const <Detection>[];

    return ClayPage(
      title: l10n.reviewTitle,
      body: detail.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (d) {
          final document = _document = _Document.of(d.original, current, d.map);
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            children: [
              Text(
                l10n.reviewHint,
                style: Clay.body(14, color: Clay.inkMuted, height: 1.5),
              ),
              for (final (type, label) in [
                (EntityType.amount, l10n.reviewHideAmounts),
                (EntityType.date, l10n.reviewHideDates),
              ])
                if (current.any((x) => x.type == type))
                  _HideAllSwitch(
                    label: label,
                    value: current
                        .where((x) => x.type == type)
                        .every((x) => x.enabled),
                    onChanged: (hidden) =>
                        _setAll(d.original, current, type, hidden),
                  ),
              const SizedBox(height: 16),
              ClayDocumentCard(
                caption: d.record.displayName,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapUp: (details) =>
                      _handleTap(d.original, current, details.globalPosition),
                  child: RichText(
                    key: _textKey,
                    text: document.span,
                    textScaler: MediaQuery.textScalerOf(context),
                  ),
                ),
              ),
            ],
          );
        },
      ),
      bottom: ClayLockNote(
        child: Text.rich(
          HighlightedText.placeholders(
            l10n.reviewNote,
            style: Clay.body(12, color: Clay.inkCaption, height: 1.4),
            monoSize: 11.5,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

/// "Hide all amounts" / "Hide all dates": on when every one of them is hidden.
class _HideAllSwitch extends StatelessWidget {
  const _HideAllSwitch({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => MergeSemantics(
    child: Row(
      children: [
        Expanded(
          child: Text(label, style: Clay.body(15, weight: FontWeight.w600)),
        ),
        Switch(value: value, onChanged: onChanged),
      ],
    ),
  );
}

/// One stretch of the rendered text: either a placeholder standing in for
/// the detection at index [detection], or a run of the original text.
class _Piece {
  const _Piece({
    required this.start,
    required this.end,
    required this.originalStart,
    this.detection,
  });

  /// Offsets into the rendered text.
  final int start;
  final int end;

  /// Where this piece starts in the original text.
  final int originalStart;

  final int? detection;
}

/// The rendered document: what gets painted, plus what a tap on it means.
class _Document {
  _Document._(this.span, this._pieces, this._chunks);

  final TextSpan span;
  final List<_Piece> _pieces;
  final List<TextChunk> _chunks;

  /// Enabled detections become their placeholders, everything else stays as
  /// written. The text comes from `core.anonymize` with the record's stored
  /// [map], as `AnonymizeService.reapply` makes it, so the page and the
  /// stored output agree and a tap never renumbers the other placeholders.
  factory _Document.of(
    String original,
    List<Detection> detections,
    PlaceholderMap map,
  ) {
    final base = Clay.body(15, height: 1.75);
    final mono = Clay.mono(13).copyWith(backgroundColor: Clay.primaryTint);
    final result = core.anonymize(original, detections, previous: map);
    final children = <InlineSpan>[];
    final pieces = <_Piece>[];
    final taken = <Detection>[];
    var cursor = 0;
    var painted = 0;

    void plain(int from, int to) {
      if (to <= from) return;
      children.add(TextSpan(text: original.substring(from, to)));
      pieces.add(
        _Piece(start: painted, end: painted + (to - from), originalStart: from),
      );
      painted += to - from;
    }

    for (final r in result.replacements) {
      final index = detections.indexWhere(
        (d) => d.enabled && d.start <= r.start && r.end <= d.end,
      );
      plain(cursor, r.start);
      children.add(TextSpan(text: r.placeholder, style: mono));
      pieces.add(
        _Piece(
          start: painted,
          end: painted + r.placeholder.length,
          originalStart: r.start,
          detection: index == -1 ? null : index,
        ),
      );
      painted += r.placeholder.length;
      cursor = r.end;
      if (index != -1) taken.add(detections[index]);
    }
    plain(cursor, original.length);

    return _Document._(
      TextSpan(style: base, children: children),
      pieces,
      core.chunk(original, taken: taken),
    );
  }

  /// The piece at [offset] in the rendered text, with the matching offset
  /// in the original text.
  (_Piece, int)? at(int offset) {
    for (final piece in _pieces) {
      if (offset >= piece.start && offset < piece.end) {
        return (piece, piece.originalStart + (offset - piece.start));
      }
    }
    return null;
  }

  /// The one-tap chunk around [offset] in the original text.
  TextChunk? chunkAt(int offset) {
    for (final chunk in _chunks) {
      if (chunk.contains(offset)) return chunk;
    }
    return null;
  }
}
