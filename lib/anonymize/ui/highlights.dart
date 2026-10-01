import 'package:docudis_ffi/docudis_ffi.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../theme/clay_theme.dart';

/// `[PERSON_1]`-style placeholders as the engine writes them.
final placeholderPattern = RegExp(r'\[[A-Z][A-Z_]*_\d+\]');

/// Rich text for the three document views: detections over the original,
/// placeholders in the anonymized copy, restored values in an AI reply.
class HighlightedText {
  HighlightedText._(this.span, this._recognizers);

  final TextSpan span;
  final List<GestureRecognizer> _recognizers;

  /// Call when the span is no longer rendered.
  void dispose() {
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();
  }

  static TextStyle _base(TextStyle? style) =>
      style ?? Clay.body(15, height: 1.75);

  /// Original text with every detection tinted by type; disabled ones are
  /// struck through. [onTap] receives the index into [detections].
  factory HighlightedText.detections(
    String text,
    List<Detection> detections, {
    TextStyle? style,
    void Function(int index)? onTap,
  }) {
    final base = _base(style);
    final order = List<int>.generate(detections.length, (i) => i)
      ..sort((a, b) => detections[a].start.compareTo(detections[b].start));
    final children = <InlineSpan>[];
    final recognizers = <GestureRecognizer>[];
    var cursor = 0;
    for (final i in order) {
      final d = detections[i];
      if (d.start < cursor || d.end > text.length) continue;
      if (d.start > cursor) {
        children.add(TextSpan(text: text.substring(cursor, d.start)));
      }
      TapGestureRecognizer? recognizer;
      if (onTap != null) {
        recognizer = TapGestureRecognizer()..onTap = () => onTap(i);
        recognizers.add(recognizer);
      }
      final colors = entityColors(d.type);
      children.add(
        TextSpan(
          text: text.substring(d.start, d.end),
          recognizer: recognizer,
          style: d.enabled
              ? base.copyWith(
                  backgroundColor: colors.background,
                  color: colors.foreground,
                  fontWeight: FontWeight.w500,
                  fontVariations: const [FontVariation.weight(500)],
                  decoration: TextDecoration.underline,
                  decorationColor: colors.accent,
                  decorationThickness: 2,
                )
              : base.copyWith(
                  backgroundColor: Clay.disabled,
                  color: Clay.inkCaption,
                  decoration: TextDecoration.lineThrough,
                  decorationColor: Clay.inkCaption,
                ),
        ),
      );
      cursor = d.end;
    }
    if (cursor < text.length) {
      children.add(TextSpan(text: text.substring(cursor)));
    }
    return HighlightedText._(
      TextSpan(style: base, children: children),
      recognizers,
    );
  }

  /// Anonymized copy with each placeholder set in mono on a terracotta tint.
  static TextSpan placeholders(
    String text, {
    TextStyle? style,
    double monoSize = 13,
  }) {
    final base = _base(style);
    final mono = Clay.mono(monoSize)
        .copyWith(backgroundColor: Clay.primaryTint);
    final children = <InlineSpan>[];
    var cursor = 0;
    for (final m in placeholderPattern.allMatches(text)) {
      if (m.start > cursor) {
        children.add(TextSpan(text: text.substring(cursor, m.start)));
      }
      children.add(TextSpan(text: m.group(0), style: mono));
      cursor = m.end;
    }
    if (cursor < text.length) {
      children.add(TextSpan(text: text.substring(cursor)));
    }
    return TextSpan(style: base, children: children);
  }

  /// Restored reply with every known original value tinted sage. Also
  /// returns how many distinct values were found in [text].
  static (TextSpan, int) restored(
    String text,
    Iterable<String> originals, {
    TextStyle? style,
  }) {
    final base = _base(style);
    final sorted = originals.where((o) => o.isNotEmpty).toList()
      ..sort((a, b) => b.length.compareTo(a.length));
    final ranges = <(int, int)>[];
    var found = 0;
    for (final o in sorted) {
      var hit = false;
      var from = 0;
      while (true) {
        final idx = text.indexOf(o, from);
        if (idx < 0) break;
        from = idx + o.length;
        if (ranges.any((r) => idx < r.$2 && from > r.$1)) continue;
        ranges.add((idx, from));
        hit = true;
      }
      if (hit) found++;
    }
    ranges.sort((a, b) => a.$1.compareTo(b.$1));
    final highlight = base.copyWith(
      backgroundColor: Clay.secondaryTint,
      color: Clay.secondaryText,
      fontWeight: FontWeight.w500,
      fontVariations: const [FontVariation.weight(500)],
    );
    final children = <InlineSpan>[];
    var cursor = 0;
    for (final (start, end) in ranges) {
      if (start > cursor) {
        children.add(TextSpan(text: text.substring(cursor, start)));
      }
      children.add(
        TextSpan(text: text.substring(start, end), style: highlight),
      );
      cursor = end;
    }
    if (cursor < text.length) {
      children.add(TextSpan(text: text.substring(cursor)));
    }
    return (TextSpan(style: base, children: children), found);
  }
}
