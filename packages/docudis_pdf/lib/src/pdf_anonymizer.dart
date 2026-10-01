part of 'pdf_redactor.dart';

/// A box to paint black on a page that is turned into a picture: four
/// corners, clockwise from top-left, in points from the page's top-left
/// corner as the page is displayed.
typedef PdfQuad = List<Point<double>>;

class PdfAnonymizeResult {
  const PdfAnonymizeResult({required this.bytes, required this.rasterPages});

  final Uint8List bytes;

  /// Zero-based page -> why it went out as a picture with black boxes
  /// instead of as text with placeholders.
  final Map<int, String> rasterPages;
}

/// Runs [anonymizePdfSync] on pdfrx's PDFium worker. pdfrx must be
/// initialized.
Future<PdfAnonymizeResult> anonymizePdf(
  Uint8List pdf, {
  required List<PdfRedaction> redactions,
  Map<int, List<PdfQuad>> scannedPages = const {},
  double rasterDpi = 150,
}) =>
    PdfrxEntryFunctions.instance.compute(
      _anonymizeOnWorker,
      (pdf: pdf, redactions: redactions, scannedPages: scannedPages, rasterDpi: rasterDpi),
    );

PdfAnonymizeResult _anonymizeOnWorker(
  ({
    Uint8List pdf,
    List<PdfRedaction> redactions,
    Map<int, List<PdfQuad>> scannedPages,
    double rasterDpi,
  }) m,
) =>
    anonymizePdfSync(
      getPdfium(modulePath: Pdfrx.pdfiumModulePath),
      m.pdf,
      redactions: m.redactions,
      scannedPages: m.scannedPages,
      rasterDpi: m.rasterDpi,
    );

/// The shareable copy of a PDF: only the page content that was read and
/// reviewed survives.
///
/// - Pages with a text layer lose their images and annotations; the
///   [redactions] are taken out of the text and their labels written in
///   ([redactPdfSync]), with the page's text re-created in reading order so
///   that each label reads where its value was.
/// - [scannedPages] (no text layer, read by OCR), pages whose only text is
///   invisible (an OCR layer over a scan), and pages whose text could not be
///   edited become a [rasterDpi] picture with black boxes over the redacted
///   parts: the given quads, or the redacted characters' boxes.
/// - The pages are copied into a new document, which leaves behind the
///   metadata, bookmarks, attachments and forms.
PdfAnonymizeResult anonymizePdfSync(
  PDFium pdfium,
  Uint8List pdf, {
  required List<PdfRedaction> redactions,
  Map<int, List<PdfQuad>> scannedPages = const {},
  double rasterDpi = 150,
}) {
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
      final raster = <int, String>{};
      final count = pdfium.FPDF_GetPageCount(doc);
      for (var i = 0; i < count; i++) {
        final page = pdfium.FPDF_LoadPage(doc, i);
        if (page == nullptr) throw StateError('PDFium could not load page ${i + 1}');
        try {
          final pageRedactions = byPage[i] ?? const <PdfRedaction>[];
          final scanned = scannedPages[i];
          if (scanned != null) {
            raster[i] = 'scanned';
            job._rasterize(page, scanned, rasterDpi);
            continue;
          }
          // Boxes in device space before anything moves, for the fallback.
          final boxes = job._charQuads(page, pageRedactions);
          if (!job._hasVisibleText(page)) {
            raster[i] = 'text layer is invisible';
            job._rasterize(page, boxes, rasterDpi);
            continue;
          }
          job._strip(page);
          if (pageRedactions.isNotEmpty) job._redactObjects(page, i, pageRedactions, inReadingOrder: true);
          if (pdfium.FPDFPage_GenerateContent(page) == 0) {
            job.failedPages[i] = 'page content could not be regenerated';
          }
          final failure = job.failedPages[i];
          if (failure != null) {
            raster[i] = failure;
            job._rasterize(page, boxes, rasterDpi);
          }
        } finally {
          pdfium.FPDF_ClosePage(page);
        }
      }

      final copy = pdfium.FPDF_CreateNewDocument();
      if (copy == nullptr) throw StateError('PDFium could not create a document');
      try {
        if (pdfium.FPDF_ImportPages(copy, doc, nullptr, 0) == 0) {
          throw StateError('PDFium could not copy the pages');
        }
        return PdfAnonymizeResult(bytes: job._save(copy), rasterPages: raster);
      } finally {
        pdfium.FPDF_CloseDocument(copy);
      }
    } finally {
      pdfium.FPDF_CloseDocument(doc);
    }
  });
}

extension on _Job {
  /// The redacted characters' boxes as quads in display points.
  List<PdfQuad> _charQuads(FPDF_PAGE page, List<PdfRedaction> redactions) {
    if (redactions.isEmpty) return const [];
    final width = pdfium.FPDF_GetPageWidthF(page), height = pdfium.FPDF_GetPageHeightF(page);
    // PageToDevice rounds to whole units: map onto a fine grid and scale back.
    const grid = 16;
    final w = (width * grid).round(), h = (height * grid).round();
    Point<double> toDisplay(double x, double y) {
      pdfium.FPDF_PageToDevice(page, 0, 0, w, h, 0, x, y, _i, _i + 1);
      return Point(_i[0] / grid, _i[1] / grid);
    }

    final textPage = pdfium.FPDFText_LoadPage(page);
    try {
      final out = <PdfQuad>[];
      final count = pdfium.FPDFText_CountChars(textPage);
      for (final r in redactions) {
        for (var c = max(0, r.start); c < min(r.end, count); c++) {
          if (pdfium.FPDFText_GetCharBox(textPage, c, _d, _d + 1, _d + 2, _d + 3) == 0) continue;
          final (left, right, bottom, top) = (_d[0], _d[1], _d[2], _d[3]);
          if (right <= left || top <= bottom) continue;
          final corners = [
            toDisplay(left, top),
            toDisplay(right, top),
            toDisplay(right, bottom),
            toDisplay(left, bottom),
          ];
          out.add(_axisAligned(corners));
        }
      }
      return out;
    } finally {
      pdfium.FPDFText_ClosePage(textPage);
    }
  }

  /// Whether any text object on the page (or in its forms) is drawn.
  bool _hasVisibleText(FPDF_PAGE page) {
    bool visible(FPDF_PAGEOBJECT o) => switch (pdfium.FPDFPageObj_GetType(o)) {
          FPDF_PAGEOBJ_TEXT =>
            pdfium.FPDFTextObj_GetTextRenderMode(o) != FPDF_TEXT_RENDERMODE.FPDF_TEXTRENDERMODE_INVISIBLE,
          FPDF_PAGEOBJ_FORM => [
              for (var i = 0; i < pdfium.FPDFFormObj_CountObjects(o); i++) pdfium.FPDFFormObj_GetObject(o, i),
            ].any(visible),
          _ => false,
        };
    for (var i = 0; i < pdfium.FPDFPage_CountObjects(page); i++) {
      if (visible(pdfium.FPDFPage_GetObject(page, i))) return true;
    }
    return false;
  }

  /// Removes the page's annotations and every image, also inside forms.
  void _strip(FPDF_PAGE page) {
    for (var i = pdfium.FPDFPage_GetAnnotCount(page) - 1; i >= 0; i--) {
      pdfium.FPDFPage_RemoveAnnot(page, i);
    }
    void stripForm(FPDF_PAGEOBJECT form) {
      for (var i = pdfium.FPDFFormObj_CountObjects(form) - 1; i >= 0; i--) {
        final o = pdfium.FPDFFormObj_GetObject(form, i);
        switch (pdfium.FPDFPageObj_GetType(o)) {
          case FPDF_PAGEOBJ_IMAGE:
            if (pdfium.FPDFFormObj_RemoveObject(form, o) == 0) {
              throw StateError('an image inside a form could not be removed');
            }
            pdfium.FPDFPageObj_Destroy(o);
          case FPDF_PAGEOBJ_FORM:
            stripForm(o);
        }
      }
    }

    for (var i = pdfium.FPDFPage_CountObjects(page) - 1; i >= 0; i--) {
      final o = pdfium.FPDFPage_GetObject(page, i);
      switch (pdfium.FPDFPageObj_GetType(o)) {
        case FPDF_PAGEOBJ_IMAGE:
          pdfium.FPDFPage_RemoveObject(page, o);
          pdfium.FPDFPageObj_Destroy(o);
        case FPDF_PAGEOBJ_FORM:
          stripForm(o);
      }
    }
  }

  /// Replaces the page's content with a picture of it, black over [quads].
  void _rasterize(FPDF_PAGE page, List<PdfQuad> quads, double dpi) {
    final width = pdfium.FPDF_GetPageWidthF(page), height = pdfium.FPDF_GetPageHeightF(page);
    final scale = dpi / 72;
    final w = max(1, (width * scale).round()), h = max(1, (height * scale).round());
    final bitmap = pdfium.FPDFBitmap_Create(w, h, 0);
    if (bitmap == nullptr) throw StateError('PDFium could not allocate a ${w}x$h bitmap');
    try {
      pdfium.FPDFBitmap_FillRect(bitmap, 0, 0, w, h, 0xFFFFFFFF);
      pdfium.FPDF_RenderPageBitmap(bitmap, page, 0, 0, w, h, 0, 0);
      final stride = pdfium.FPDFBitmap_GetStride(bitmap);
      final pixels = pdfium.FPDFBitmap_GetBuffer(bitmap).cast<Uint8>().asTypedList(stride * h);
      for (final q in quads) {
        _fillQuad(pixels, stride, w, h, [for (final p in q) Point(p.x * scale, p.y * scale)]);
      }

      for (var i = pdfium.FPDFPage_GetAnnotCount(page) - 1; i >= 0; i--) {
        pdfium.FPDFPage_RemoveAnnot(page, i);
      }
      for (var i = pdfium.FPDFPage_CountObjects(page) - 1; i >= 0; i--) {
        final o = pdfium.FPDFPage_GetObject(page, i);
        pdfium.FPDFPage_RemoveObject(page, o);
        pdfium.FPDFPageObj_Destroy(o);
      }
      // The picture is already upright and cropped: the page becomes exactly it.
      pdfium.FPDFPage_SetRotation(page, 0);
      pdfium.FPDFPage_SetMediaBox(page, 0, 0, width, height);
      pdfium.FPDFPage_SetCropBox(page, 0, 0, width, height);
      final image = pdfium.FPDFPageObj_NewImageObj(doc);
      if (image == nullptr || pdfium.FPDFImageObj_SetBitmap(nullptr, 0, image, bitmap) == 0) {
        throw StateError('PDFium could not create the page picture');
      }
      pdfium.FPDFImageObj_SetMatrix(image, width, 0, 0, height, 0, 0);
      pdfium.FPDFPage_InsertObject(page, image);
      if (pdfium.FPDFPage_GenerateContent(page) == 0) {
        throw StateError('PDFium could not write the page picture');
      }
    } finally {
      pdfium.FPDFBitmap_Destroy(bitmap);
    }
  }
}

/// [corners] (in any order) as an upright rectangle, clockwise from top-left.
PdfQuad _axisAligned(List<Point<double>> corners) {
  final xs = corners.map((c) => c.x), ys = corners.map((c) => c.y);
  final l = xs.reduce(min), r = xs.reduce(max), t = ys.reduce(min), b = ys.reduce(max);
  return [Point(l, t), Point(r, t), Point(r, b), Point(l, b)];
}

/// Paints the quad black into a BGRx [pixels] buffer, grown on every side by
/// a sixth of its height (at least 2 px) so anti-aliased glyph edges never
/// show. Corners are clockwise from top-left, so 0->1 runs along the text
/// and 0->3 down across it.
void _fillQuad(Uint8List pixels, int stride, int w, int h, List<Point<double>> q) {
  if (q.length != 4) return;
  Point<double> unit(Point<double> v) {
    final length = v.magnitude;
    return length == 0 ? const Point(0, 0) : Point(v.x / length, v.y / length);
  }

  final along = unit(q[1] - q[0]), down = unit(q[3] - q[0]);
  final bleed = max(2.0, (q[3] - q[0]).magnitude / 6);
  final a = along * bleed, d = down * bleed;
  final p = [q[0] - a - d, q[1] + a - d, q[2] + a + d, q[3] - a + d];

  final top = max(0, p.map((c) => c.y).reduce(min).floor());
  final bottom = min(h - 1, p.map((c) => c.y).reduce(max).ceil());
  for (var y = top; y <= bottom; y++) {
    final cy = y + 0.5;
    var left = double.infinity, right = double.negativeInfinity;
    for (var e = 0; e < 4; e++) {
      final p0 = p[e], p1 = p[(e + 1) % 4];
      if ((p0.y <= cy && p1.y > cy) || (p1.y <= cy && p0.y > cy)) {
        final x = p0.x + (cy - p0.y) / (p1.y - p0.y) * (p1.x - p0.x);
        left = min(left, x);
        right = max(right, x);
      }
    }
    if (left > right) continue;
    final x0 = max(0, left.floor()), x1 = min(w - 1, right.ceil());
    // Black, alpha untouched (FPDFBitmap_Create without alpha is BGRx).
    for (var x = x0; x <= x1; x++) {
      final o = y * stride + x * 4;
      pixels[o] = 0;
      pixels[o + 1] = 0;
      pixels[o + 2] = 0;
    }
  }
}
