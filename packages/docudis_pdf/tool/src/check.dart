import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:docudis_pdf/docudis_pdf.dart';
import 'package:pdfrx_engine/pdfrx_engine.dart';

const _renderScale = 2.0;

/// What a tool decided to take out of a document.
class Plan {
  final redactions = <PdfRedaction>[];

  /// Removed strings, lowercase: none may be left in the output's text.
  final secrets = <String>{};

  /// Page -> where text is replaced; the rendering may differ only there.
  final masks = <int, List<PdfRect>>{};

  void add(int pageIndex, PdfPageRawText text, int start, int end, String label) {
    redactions.add(PdfRedaction(pageIndex: pageIndex, start: start, end: end, label: label));
    secrets.add(text.fullText.substring(start, end).toLowerCase());
    // Neighbours on one line are joined, so the space between two words
    // (which has no box) is masked too.
    final mask = masks.putIfAbsent(pageIndex, () => []);
    for (var i = start; i < end; i++) {
      final r = text.charRects[i];
      final next = i + 1 < end ? text.charRects[i + 1] : r;
      final sameLine = next.bottom < r.top && next.top > r.bottom;
      mask.add(sameLine ? r.merge(next) : r);
    }
  }
}

/// Redacts [input] as planned, writes it to [outPath], and checks the result:
/// the secrets must be gone from the extracted text, and the pages must look
/// the same everywhere except where text was replaced.
///
/// With [share], makes the app's shareable copy instead ([anonymizePdf]:
/// images and annotations removed, text in reading order, pictures of the
/// pages that cannot be edited); those pages are reported, not failed.
Future<bool> redactAndCheck(
  Uint8List input,
  PdfDocument original,
  Plan plan,
  String outPath, {
  bool share = false,
}) async {
  stdout.writeln('${plan.redactions.length} span(s) on ${plan.masks.length} page(s)');
  final Uint8List bytes;
  var ok = true;
  if (share) {
    final result = await anonymizePdf(input, redactions: plan.redactions);
    bytes = result.bytes;
    result.rasterPages.forEach((page, why) => stdout.writeln('PICTURE page ${page + 1}: $why'));
  } else {
    final result = await redactPdf(input, plan.redactions);
    bytes = result.bytes;
    stdout.writeln('removed ${result.removedObjects} text object(s), '
        're-created ${result.rebuiltRuns} run(s)');
    result.failedPages.forEach((page, why) => stdout.writeln('FAILED page ${page + 1}: $why'));
    ok = result.failedPages.isEmpty;
  }
  File(outPath).writeAsBytesSync(bytes);
  stdout.writeln('${input.length} -> ${bytes.length} bytes');

  final redacted = await PdfDocument.openData(bytes, sourceName: 'redacted');
  for (var i = 0; i < redacted.pages.length; i++) {
    final text = ((await redacted.pages[i].loadText())?.fullText ?? '').toLowerCase();
    for (final secret in plan.secrets) {
      if (text.contains(secret)) {
        ok = false;
        stdout.writeln('LEAK page ${i + 1}: "$secret" is still in the text');
      }
    }
    if (!plan.masks.containsKey(i)) continue;
    stdout.writeln('page ${i + 1}: ${await _diff(original.pages[i], redacted.pages[i], plan.masks[i]!)}');
  }
  await redacted.dispose();
  stdout.writeln(ok ? 'OK' : 'NOT OK');
  return ok;
}

/// Compares the two renderings outside [masks].
Future<String> _diff(PdfPage a, PdfPage b, List<PdfRect> masks) async {
  final ia = (await a.render(fullWidth: a.width * _renderScale, fullHeight: a.height * _renderScale))!;
  final ib = (await b.render(fullWidth: b.width * _renderScale, fullHeight: b.height * _renderScale))!;
  try {
    if (ia.width != ib.width || ia.height != ib.height) return 'page size changed';
    final masked = List.filled(ia.width * ia.height, false);
    for (final r in masks) {
      // A label's brackets reach above and below lowercase letters.
      final pad = 2 + 0.4 * (r.top - r.bottom);
      final x0 = max(0, ((r.left - 2) * _renderScale).floor());
      final x1 = min(ia.width, ((r.right + 2) * _renderScale).ceil());
      final y0 = max(0, ((a.height - r.top - pad) * _renderScale).floor());
      final y1 = min(ia.height, ((a.height - r.bottom + pad) * _renderScale).ceil());
      for (var y = y0; y < y1; y++) {
        masked.fillRange(y * ia.width + x0, y * ia.width + x1, true);
      }
    }
    var changed = 0;
    var left = ia.width, top = ia.height, right = 0, bottom = 0;
    for (var p = 0; p < masked.length; p++) {
      if (masked[p]) continue;
      var delta = 0;
      for (var ch = 0; ch < 3; ch++) {
        delta = max(delta, (ia.pixels[p * 4 + ch] - ib.pixels[p * 4 + ch]).abs());
      }
      if (delta <= 48) continue;
      changed++;
      final x = p % ia.width, y = p ~/ ia.width;
      left = min(left, x);
      right = max(right, x);
      top = min(top, y);
      bottom = max(bottom, y);
    }
    if (changed == 0) return 'rendering identical outside the redactions';
    String pt(int v) => (v / _renderScale).toStringAsFixed(0);
    return '$changed pixel(s) differ outside the redactions, '
        'within x ${pt(left)}..${pt(right)}, y ${pt(top)}..${pt(bottom)} pt from top-left';
  } finally {
    ia.dispose();
    ib.dispose();
  }
}
