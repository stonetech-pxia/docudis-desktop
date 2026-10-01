import 'dart:ffi';
import 'dart:math';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:pdfium_dart/pdfium_dart.dart';
import 'package:pdfrx_engine/pdfrx_engine.dart';

part 'pdf_anonymizer.dart';

/// A run of characters to take out of one page.
class PdfRedaction {
  const PdfRedaction({
    required this.pageIndex,
    required this.start,
    required this.end,
    this.label,
  });

  /// Zero-based page.
  final int pageIndex;

  /// PDFium character range on that page, [end] exclusive. These are the
  /// indices of pdfrx's `PdfPage.loadText()`: `fullText[i]` / `charRects[i]`.
  final int start;
  final int end;

  /// Written where the removed text started, in standard Helvetica, so it
  /// must be plain Latin text. Null leaves a gap.
  final String? label;
}

class PdfRedactionResult {
  const PdfRedactionResult({
    required this.bytes,
    required this.failedPages,
    required this.removedObjects,
    required this.rebuiltRuns,
  });

  /// The new PDF. Pages in [failedPages] are NOT safe in it.
  final Uint8List bytes;

  /// Zero-based page -> why its text could not be removed cleanly. The
  /// caller must redact those pages another way (rasterize the original).
  final Map<int, String> failedPages;

  /// Text objects deleted, and surviving words re-created next to them.
  final int removedObjects;
  final int rebuiltRuns;
}

/// Runs [redactPdfSync] on pdfrx's PDFium worker, the only thread allowed to
/// touch PDFium. pdfrx must be initialized (`pdfrxInitialize` /
/// `pdfrxFlutterInitialize`).
Future<PdfRedactionResult> redactPdf(Uint8List pdf, List<PdfRedaction> redactions) =>
    PdfrxEntryFunctions.instance.compute(_onWorker, (pdf: pdf, redactions: redactions));

PdfRedactionResult _onWorker(({Uint8List pdf, List<PdfRedaction> redactions}) m) =>
    redactPdfSync(getPdfium(modulePath: Pdfrx.pdfiumModulePath), m.pdf, m.redactions);

/// Deletes the text objects holding the redacted characters from the page
/// content and saves a fresh (non-incremental) copy, so the characters are
/// gone from the file rather than covered.
///
/// A PDF text object is often a whole line. When only part of one is
/// redacted, the object is deleted and its other words are re-created one
/// by one with the same font, size, colour and position.
///
/// Only page text is handled: text inside images, annotations, form fields,
/// bookmarks and metadata is left as is.
PdfRedactionResult redactPdfSync(PDFium pdfium, Uint8List pdf, List<PdfRedaction> redactions) {
  return using((arena) {
    final data = arena<Uint8>(pdf.length);
    data.asTypedList(pdf.length).setAll(0, pdf);
    final doc = pdfium.FPDF_LoadMemDocument64(data.cast(), pdf.length, nullptr);
    if (doc == nullptr) throw StateError('PDFium could not open the document');
    try {
      final job = _Job(pdfium, doc, arena);
      final byPage = <int, List<PdfRedaction>>{};
      for (final r in redactions) {
        byPage.putIfAbsent(r.pageIndex, () => []).add(r);
      }
      for (final entry in byPage.entries) {
        job.redactPage(entry.key, entry.value);
      }
      return PdfRedactionResult(
        bytes: job.save(),
        failedPages: job.failedPages,
        removedObjects: job.removedObjects,
        rebuiltRuns: job.rebuiltRuns,
      );
    } finally {
      pdfium.FPDF_CloseDocument(doc);
    }
  });
}

class _Char {
  _Char(this.index);

  final int index;
  late int unicode;
  late int object;
  late double left, right, bottom, top, originX, originY;
  bool hit = false;
  bool mapError = false;

  bool get isSpace => unicode <= 0x20 || unicode == 0xA0;
}

class _Failure implements Exception {
  const _Failure(this.reason);
  final String reason;
}

class _Job {
  _Job(this.pdfium, this.doc, this.arena)
      : _d = arena<Double>(4),
        _f = arena<Float>(4),
        _u = arena<UnsignedInt>(4),
        _i = arena<Int>(2),
        _m = arena<FS_MATRIX>();

  final PDFium pdfium;
  final FPDF_DOCUMENT doc;
  final Arena arena;
  final Pointer<Double> _d;
  final Pointer<Float> _f;
  final Pointer<UnsignedInt> _u;
  final Pointer<Int> _i;
  final Pointer<FS_MATRIX> _m;

  /// Per page: drawing order by object address, and the opaque rectangles.
  final _order = <int, int>{};
  final _covers = <({int order, double left, double bottom, double right, double top})>[];

  final failedPages = <int, String>{};
  var removedObjects = 0;
  var rebuiltRuns = 0;

  FPDF_FONT _labelFont = nullptr;

  void redactPage(int pageIndex, List<PdfRedaction> redactions) {
    final page = pdfium.FPDF_LoadPage(doc, pageIndex);
    if (page == nullptr) {
      failedPages[pageIndex] = 'page could not be loaded';
      return;
    }
    try {
      _redactObjects(page, pageIndex, redactions);
      if (pdfium.FPDFPage_GenerateContent(page) == 0) {
        failedPages[pageIndex] = 'page content could not be regenerated';
      }
    } finally {
      pdfium.FPDF_ClosePage(page);
    }
  }

  /// The object edits of [redactPage] on a page that is already loaded; the
  /// caller regenerates its content.
  ///
  /// With [inReadingOrder], every text object on the page is re-created, not
  /// only the redacted ones, each label where its text was. New objects can
  /// only go at the end of the page content, and text extractors (what an AI
  /// app reads) follow content order: re-creating only some objects would
  /// move those lines, and all labels, after the rest of the page. Text that
  /// is hidden, clipped or cannot be re-created stays where it is.
  void _redactObjects(
    FPDF_PAGE page,
    int pageIndex,
    List<PdfRedaction> redactions, {
    bool inReadingOrder = false,
  }) {
    final chars = _readChars(page, redactions);
    _scanDrawingOrder(page);
    final labels = <int, FPDF_PAGEOBJECT>{};
    try {
      // Labels first: they copy size and colour from objects deleted below.
      for (final (i, r) in redactions.indexed) {
        final label = r.label == null ? null : _label(r, chars);
        if (label != null) labels[i] = label;
      }
      final byObject = <int, List<_Char>>{};
      for (final c in chars) {
        byObject.putIfAbsent(c.object, () => []).add(c);
      }
      for (final entry in byObject.entries) {
        final object = FPDF_PAGEOBJECT.fromAddress(entry.key);
        final hit = entry.value.any((c) => c.hit);
        if (!hit &&
            (!inReadingOrder ||
                entry.value.any((c) => c.mapError) ||
                _visibleShare(object, entry.value) < 0.9 ||
                !_order.containsKey(entry.key))) {
          continue;
        }
        _replaceObject(page, entry.key, entry.value, redactions, labels);
      }
      for (final label in labels.values) {
        pdfium.FPDFPage_InsertObject(page, label);
      }
      labels.clear();
    } on _Failure catch (e) {
      failedPages[pageIndex] = e.reason;
      labels.values.forEach(pdfium.FPDFPageObj_Destroy);
    }
  }

  /// Every character that belongs to a text object (PDFium's synthesized
  /// spaces and line breaks do not), with the redacted ones marked.
  List<_Char> _readChars(FPDF_PAGE page, List<PdfRedaction> redactions) {
    final textPage = pdfium.FPDFText_LoadPage(page);
    try {
      final out = <_Char>[];
      final count = pdfium.FPDFText_CountChars(textPage);
      for (var i = 0; i < count; i++) {
        if (pdfium.FPDFText_IsGenerated(textPage, i) == 1) continue;
        final object = pdfium.FPDFText_GetTextObject(textPage, i);
        if (object == nullptr) continue;
        final c = _Char(i)
          ..unicode = pdfium.FPDFText_GetUnicode(textPage, i)
          ..object = object.address
          ..hit = redactions.any((r) => r.start <= i && i < r.end)
          ..mapError = pdfium.FPDFText_HasUnicodeMapError(textPage, i) == 1;
        pdfium.FPDFText_GetCharBox(textPage, i, _d, _d + 1, _d + 2, _d + 3);
        c
          ..left = _d[0]
          ..right = _d[1]
          ..bottom = _d[2]
          ..top = _d[3];
        pdfium.FPDFText_GetCharOrigin(textPage, i, _d, _d + 1);
        c
          ..originX = _d[0]
          ..originY = _d[1];
        out.add(c);
      }
      return out;
    } finally {
      pdfium.FPDFText_ClosePage(textPage);
    }
  }

  /// Deletes text object [address] and re-creates the words of it that are
  /// not redacted. The label of a redaction that starts in it (taken out of
  /// [labels]) goes in where the redacted text was.
  void _replaceObject(
    FPDF_PAGE page,
    int address,
    List<_Char> chars,
    List<PdfRedaction> redactions,
    Map<int, FPDF_PAGEOBJECT> labels,
  ) {
    final object = FPDF_PAGEOBJECT.fromAddress(address);
    // Word runs to re-create, and labels, in text order.
    final pieces = <({List<_Char>? run, FPDF_PAGEOBJECT? label})>[];
    var run = <_Char>[];
    for (final c in chars) {
      if (c.hit || c.isSpace) {
        if (run.isNotEmpty) pieces.add((run: run, label: null));
        run = [];
      } else {
        run.add(c);
      }
      if (c.hit) {
        final i = redactions.indexWhere((r) => r.start <= c.index && c.index < r.end);
        final label = labels.remove(i);
        if (label != null) pieces.add((run: null, label: label));
      }
    }
    if (run.isNotEmpty) pieces.add((run: run, label: null));

    final created = <FPDF_PAGEOBJECT>[];
    var runs = 0;
    try {
      for (final piece in pieces) {
        if (piece.label case final label?) {
          created.add(label);
        } else {
          final rebuilt = _rebuild(object, piece.run!);
          created.addAll(rebuilt);
          runs += rebuilt.length;
        }
      }
      // Fails for text nested in a form XObject: it is not the page's own.
      if (pdfium.FPDFPage_RemoveObject(page, object) == 0) {
        throw const _Failure('text is inside a form XObject');
      }
    } on _Failure {
      created.forEach(pdfium.FPDFPageObj_Destroy);
      rethrow;
    }
    // The new objects hold the font, so the old one can go now.
    pdfium.FPDFPageObj_Destroy(object);
    for (final o in created) {
      pdfium.FPDFPage_InsertObject(page, o);
    }
    removedObjects++;
    rebuiltRuns += runs;
  }

  /// [run] as a new text object styled like [source]. PDFium does not expose
  /// character spacing, so a run that comes out at the wrong width is
  /// rebuilt one character at a time, each placed at its own origin.
  List<FPDF_PAGEOBJECT> _rebuild(FPDF_PAGEOBJECT source, List<_Char> run) {
    // A new object is drawn on top of the page and unclipped, so text that
    // was hidden must not come back, and text that a clip cuts through is
    // not attempted.
    final visible = _visibleShare(source, run);
    if (visible < 0.1) return [];
    if (visible < 0.9) throw const _Failure('text is partly clipped');
    if (run.any((c) => c.mapError)) {
      throw const _Failure('font has no usable Unicode map');
    }
    pdfium.FPDFTextObj_GetFontSize(source, _f);
    final size = _f[0];
    final object = pdfium.FPDFPageObj_CreateTextObj(doc, pdfium.FPDFTextObj_GetFont(source), size);
    if (object == nullptr) throw const _Failure('text object could not be created');
    var ok = _setText(object, String.fromCharCodes(run.map((c) => c.unicode)));

    pdfium.FPDFPageObj_GetMatrix(source, _m);
    _m.ref
      ..e = run.first.originX
      ..f = run.first.originY;
    final scale = sqrt(_m.ref.a * _m.ref.a + _m.ref.b * _m.ref.b);
    pdfium.FPDFPageObj_SetMatrix(object, _m);
    if (pdfium.FPDFPageObj_GetFillColor(source, _u, _u + 1, _u + 2, _u + 3) == 1) {
      pdfium.FPDFPageObj_SetFillColor(object, _u[0], _u[1], _u[2], _u[3]);
    }
    pdfium.FPDFTextObj_SetTextRenderMode(object, pdfium.FPDFTextObj_GetTextRenderMode(source));

    ok = ok && pdfium.FPDFPageObj_GetBounds(object, _f, _f + 1, _f + 2, _f + 3) == 1;
    final tolerance = 0.3 * size * scale;
    final left = run.map((c) => c.left).reduce(min);
    final right = run.map((c) => c.right).reduce(max);
    if (ok && (_f[0] - left).abs() <= tolerance && (_f[2] - right).abs() <= tolerance) {
      return [object];
    }
    pdfium.FPDFPageObj_Destroy(object);
    if (run.length == 1) throw const _Failure('a character could not be re-created in place');
    return [for (final c in run) ..._rebuild(source, [c])];
  }

  /// The label for [r], sized like the text it replaces, in the room that
  /// text leaves on its first line: its own width plus the free space after
  /// it, up to the next character that stays (or the right edge of the
  /// page's text). A label too wide for that room is first set in narrower
  /// letters, down to 70% of their width, and made smaller only after that:
  /// shrunk to the width of a short name, "[PERSON_1]" could hardly be read.
  /// Null when [r] hit nothing visible.
  FPDF_PAGEOBJECT? _label(PdfRedaction r, List<_Char> chars) {
    final hits = chars.where((c) => r.start <= c.index && c.index < r.end).toList();
    if (hits.isEmpty) return null;
    final first = hits.first;
    final source = FPDF_PAGEOBJECT.fromAddress(first.object);
    pdfium.FPDFTextObj_GetFontSize(source, _f);
    pdfium.FPDFPageObj_GetMatrix(source, _m);
    final size = _f[0] * sqrt(_m.ref.c * _m.ref.c + _m.ref.d * _m.ref.d);
    final line = hits.where((c) => (c.originY - first.originY).abs() < size / 2).toList();
    if (_visibleShare(source, line) < 0.1) return null;
    final left = line.map((c) => c.left).reduce(min);
    final width = line.map((c) => c.right).reduce(max) - left;
    final end = left + width;
    final next = chars
        .where((c) =>
            !c.isSpace &&
            (c.index < r.start || c.index >= r.end) &&
            (c.originY - first.originY).abs() < size / 2 &&
            c.left >= end - 0.01)
        .map((c) => c.left)
        .fold(double.infinity, min);
    final textRight = chars.where((c) => !c.isSpace).map((c) => c.right).fold(end, max);
    final room = max(width, next.isFinite ? next - size * 0.25 - left : textRight - left);

    if (_labelFont == nullptr) {
      _labelFont = pdfium.FPDFText_LoadStandardFont(doc, 'Helvetica'.toNativeUtf8(allocator: arena).cast());
    }
    final object = pdfium.FPDFPageObj_CreateTextObj(doc, _labelFont, size);
    if (object == nullptr || !_setText(object, r.label!)) {
      throw const _Failure('label could not be created');
    }
    pdfium.FPDFPageObj_GetBounds(object, _f, _f + 1, _f + 2, _f + 3);
    final natural = _f[2] - _f[0];
    // Never wider than its room, so it cannot run into the neighbours.
    final squeeze = min(1.0, room / natural);
    _m.ref
      ..a = squeeze
      ..b = 0
      ..c = 0
      ..d = min(1.0, squeeze / 0.7)
      ..e = left
      ..f = first.originY;
    pdfium.FPDFPageObj_SetMatrix(object, _m);
    if (pdfium.FPDFPageObj_GetFillColor(source, _u, _u + 1, _u + 2, _u + 3) == 1) {
      pdfium.FPDFPageObj_SetFillColor(object, _u[0], _u[1], _u[2], _u[3]);
    }
    // Hidden text (an OCR or accessibility layer) gets a hidden label.
    pdfium.FPDFTextObj_SetTextRenderMode(object, pdfium.FPDFTextObj_GetTextRenderMode(source));
    return object;
  }

  /// Records the drawing order of the page's objects and which of them are
  /// opaque filled rectangles: those hide whatever was drawn before them.
  /// (HTML-to-PDF converters leave whole off-screen blocks under one.)
  void _scanDrawingOrder(FPDF_PAGE page) {
    _order.clear();
    _covers.clear();
    final count = pdfium.FPDFPage_CountObjects(page);
    for (var i = 0; i < count; i++) {
      final object = pdfium.FPDFPage_GetObject(page, i);
      _order[object.address] = i;
      if (!_isOpaqueRectangle(object)) continue;
      pdfium.FPDFPageObj_GetBounds(object, _f, _f + 1, _f + 2, _f + 3);
      _covers.add((order: i, left: _f[0], bottom: _f[1], right: _f[2], top: _f[3]));
    }
  }

  bool _isOpaqueRectangle(FPDF_PAGEOBJECT object) {
    if (pdfium.FPDFPageObj_GetType(object) != FPDF_PAGEOBJ_PATH) return false;
    if (pdfium.FPDFPath_GetDrawMode(object, _i, _i + 1) == 0 || _i[0] == FPDF_FILLMODE_NONE) return false;
    if (pdfium.FPDFPageObj_GetFillColor(object, _u, _u + 1, _u + 2, _u + 3) == 0 || _u[3] != 255) return false;
    if (pdfium.FPDFPageObj_HasTransparency(object) == 1) return false;
    final clip = pdfium.FPDFPageObj_GetClipPath(object);
    if (clip != nullptr && pdfium.FPDFClipPath_CountPaths(clip) > 0) return false;
    pdfium.FPDFPageObj_GetMatrix(object, _m);
    if (_m.ref.b != 0 || _m.ref.c != 0) return false;
    final segments = pdfium.FPDFPath_CountSegments(object);
    if (segments < 4 || segments > 5) return false;
    final xs = <double>{}, ys = <double>{};
    for (var s = 0; s < segments; s++) {
      final segment = pdfium.FPDFPath_GetPathSegment(object, s);
      if (pdfium.FPDFPathSegment_GetType(segment) == FPDF_SEGMENT_BEZIERTO) return false;
      pdfium.FPDFPathSegment_GetPoint(segment, _f, _f + 1);
      xs.add(_f[0]);
      ys.add(_f[1]);
    }
    return xs.length == 2 && ys.length == 2;
  }

  /// The share (0..1) of the area of [chars] that can be seen: 0 under an
  /// opaque rectangle drawn after [source], otherwise what [source]'s clip
  /// path lets through. Each clip path counts as its bounding box, which is
  /// exact for rectangular clips.
  double _visibleShare(FPDF_PAGEOBJECT source, List<_Char> chars) {
    final left = chars.map((c) => c.left).reduce(min);
    final right = chars.map((c) => c.right).reduce(max);
    final bottom = chars.map((c) => c.bottom).reduce(min);
    final top = chars.map((c) => c.top).reduce(max);
    final area = (right - left) * (top - bottom);
    if (area <= 0) return 1;
    final order = _order[source.address];
    if (order != null &&
        _covers.any((c) =>
            c.order > order && c.left <= left && c.right >= right && c.bottom <= bottom && c.top >= top)) {
      return 0;
    }

    var l = left, r = right, b = bottom, t = top;
    final clip = pdfium.FPDFPageObj_GetClipPath(source);
    final paths = clip == nullptr ? 0 : pdfium.FPDFClipPath_CountPaths(clip);
    for (var p = 0; p < paths; p++) {
      final segments = pdfium.FPDFClipPath_CountPathSegments(clip, p);
      if (segments <= 0) continue;
      var pl = double.infinity, pr = -double.infinity, pb = double.infinity, pt = -double.infinity;
      for (var s = 0; s < segments; s++) {
        pdfium.FPDFPathSegment_GetPoint(pdfium.FPDFClipPath_GetPathSegment(clip, p, s), _f, _f + 1);
        pl = min(pl, _f[0]);
        pr = max(pr, _f[0]);
        pb = min(pb, _f[1]);
        pt = max(pt, _f[1]);
      }
      l = max(l, pl);
      r = min(r, pr);
      b = max(b, pb);
      t = min(t, pt);
    }
    return max(0, r - l) * max(0, t - b) / area;
  }

  bool _setText(FPDF_PAGEOBJECT object, String text) {
    final units = text.codeUnits;
    final buffer = arena<UnsignedShort>(units.length + 1);
    for (var i = 0; i < units.length; i++) {
      buffer[i] = units[i];
    }
    buffer[units.length] = 0;
    return pdfium.FPDFText_SetText(object, buffer) == 1;
  }

  Uint8List save() => _save(doc);

  Uint8List _save(FPDF_DOCUMENT doc) {
    final out = BytesBuilder();
    final write = NativeCallable<Int Function(Pointer<FPDF_FILEWRITE>, Pointer<Void>, UnsignedLong)>.isolateLocal(
      (Pointer<FPDF_FILEWRITE> self, Pointer<Void> data, int size) {
        out.add(data.cast<Uint8>().asTypedList(size));
        return 1;
      },
      exceptionalReturn: 0,
    );
    try {
      final fileWrite = arena<FPDF_FILEWRITE>();
      fileWrite.ref
        ..version = 1
        ..WriteBlock = write.nativeFunction;
      if (pdfium.FPDF_SaveAsCopy(doc, fileWrite, FPDF_NO_INCREMENTAL) == 0) {
        throw StateError('PDFium could not save the document');
      }
    } finally {
      write.close();
    }
    return out.takeBytes();
  }
}
