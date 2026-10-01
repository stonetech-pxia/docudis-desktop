import 'package:docudis_ffi/docudis_ffi.dart';
import 'package:flutter/material.dart';

import '../../theme/clay_theme.dart';
import '../engine/native_libraries.dart';
import 'highlights.dart';

/// The original text with every detection tinted by type, struck through
/// when it is shown again. A click on a detection hides or shows it; a
/// click on plain text hides the one-tap chunk there.
class OriginalView extends StatefulWidget {
  const OriginalView({
    super.key,
    required this.text,
    required this.detections,
    required this.onToggle,
    required this.onHide,
  });

  final String text;
  final List<Detection> detections;

  /// The detection at this index was clicked.
  final ValueChanged<int> onToggle;

  /// Plain text was clicked: hide `text[start, end)`.
  final void Function(int start, int end) onHide;

  @override
  State<OriginalView> createState() => _OriginalViewState();
}

class _OriginalViewState extends State<OriginalView> {
  final _textKey = GlobalKey();

  static final _style = Clay.body(14, height: 1.7);

  void _tap(TextSpan span, Offset global) {
    final box = _textKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final painter = TextPainter(
      text: span,
      textDirection: TextDirection.ltr,
      textScaler: MediaQuery.textScalerOf(context),
    )..layout(maxWidth: box.size.width);
    final offset = painter
        .getPositionForOffset(box.globalToLocal(global))
        .offset;
    painter.dispose();

    final detections = widget.detections;
    // Clicking the right half of a glyph lands on the offset after it.
    for (final at in [offset, offset - 1]) {
      final hit = detections.indexWhere((d) => at >= d.start && at < d.end);
      if (hit != -1) return widget.onToggle(hit);
    }
    final chunks = core.chunk(
      widget.text,
      taken: detections.where((d) => d.enabled),
    );
    for (final at in [offset, offset - 1]) {
      for (final chunk in chunks) {
        if (chunk.contains(at)) return widget.onHide(chunk.start, chunk.end);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final span = HighlightedText.detections(
      widget.text,
      widget.detections,
      style: _style,
    ).span;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapUp: (details) => _tap(span, details.globalPosition),
          child: RichText(
            key: _textKey,
            text: span,
            textScaler: MediaQuery.textScalerOf(context),
          ),
        ),
      ),
    );
  }
}

/// The anonymized text, placeholders in mono on a terracotta tint;
/// selectable, to copy part of it.
class AnonymizedView extends StatelessWidget {
  const AnonymizedView({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
    child: SelectableText.rich(
      HighlightedText.placeholders(
        text,
        style: Clay.body(14, height: 1.7),
        monoSize: 12.5,
      ),
    ),
  );
}
