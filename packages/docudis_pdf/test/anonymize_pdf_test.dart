// The shareable copy of a PDF (anonymizePdf). test/fixtures/letter.pdf is an
// invented letter printed to PDF on macOS (cupsfilter).
//
//   dart test
import 'dart:ffi';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:docudis_pdf/docudis_pdf.dart';
import 'package:ffi/ffi.dart';
import 'package:pdfium_dart/pdfium_dart.dart';
import 'package:pdfrx_engine/pdfrx_engine.dart';
import 'package:test/test.dart';

late Uint8List letter;

/// The fixture's own Producer entry (macOS Quartz).
late String producer;

/// [text]'s character range on page 1 of [pdf], as pdfrx numbers it.
Future<PdfRedaction> find(Uint8List pdf, String text, {String? label}) async {
  final doc = await PdfDocument.openData(pdf);
  try {
    final full = (await doc.pages[0].loadText())!.fullText;
    final start = full.indexOf(text);
    expect(start, isNot(-1), reason: '"$text" not in the page text');
    return PdfRedaction(pageIndex: 0, start: start, end: start + text.length, label: label);
  } finally {
    await doc.dispose();
  }
}

Future<String> pageText(Uint8List pdf) async {
  final doc = await PdfDocument.openData(pdf);
  try {
    return (await doc.pages[0].loadText())?.fullText ?? '';
  } finally {
    await doc.dispose();
  }
}

/// The box pdfrx gives [text] on page 1 of [pdf].
Future<PdfRect> boxOf(Uint8List pdf, String text) async {
  final doc = await PdfDocument.openData(pdf);
  try {
    final t = (await doc.pages[0].loadText())!;
    final start = t.fullText.indexOf(text);
    expect(start, isNot(-1), reason: '"$text" not in the page text');
    var box = t.charRects[start];
    for (var i = start + 1; i < start + text.length; i++) {
      box = box.merge(t.charRects[i]);
    }
    return box;
  } finally {
    await doc.dispose();
  }
}

/// Object types on page 1, the Producer entry and the annotation count.
Future<({List<int> types, String producer, int annots})> inspect(Uint8List pdf) =>
    PdfrxEntryFunctions.instance.compute(_inspect, pdf);

({List<int> types, String producer, int annots}) _inspect(Uint8List pdf) => using((arena) {
      final pdfium = getPdfium(modulePath: Pdfrx.pdfiumModulePath);
      final data = arena<Uint8>(pdf.length)..asTypedList(pdf.length).setAll(0, pdf);
      final doc = pdfium.FPDF_LoadMemDocument64(data.cast(), pdf.length, nullptr);
      final page = pdfium.FPDF_LoadPage(doc, 0);
      final types = [
        for (var i = 0; i < pdfium.FPDFPage_CountObjects(page); i++)
          pdfium.FPDFPageObj_GetType(pdfium.FPDFPage_GetObject(page, i)),
      ];
      final annots = pdfium.FPDFPage_GetAnnotCount(page);
      final buffer = arena<Uint16>(256);
      final n = pdfium.FPDF_GetMetaText(doc, 'Producer'.toNativeUtf8(allocator: arena).cast(), buffer.cast(), 512);
      final producer = n <= 2 ? '' : String.fromCharCodes(buffer.asTypedList(n ~/ 2 - 1));
      pdfium.FPDF_ClosePage(page);
      pdfium.FPDF_CloseDocument(doc);
      return (types: types, producer: producer, annots: annots);
    });

/// [pdf] with a grey 40x40 pt image and a link annotation added to page 1.
Uint8List _withImageAndLink(Uint8List pdf) => using((arena) {
      final pdfium = getPdfium(modulePath: Pdfrx.pdfiumModulePath);
      final data = arena<Uint8>(pdf.length)..asTypedList(pdf.length).setAll(0, pdf);
      final doc = pdfium.FPDF_LoadMemDocument64(data.cast(), pdf.length, nullptr);
      final page = pdfium.FPDF_LoadPage(doc, 0);
      final bitmap = pdfium.FPDFBitmap_Create(40, 40, 0);
      pdfium.FPDFBitmap_FillRect(bitmap, 0, 0, 40, 40, 0xFF808080);
      final image = pdfium.FPDFPageObj_NewImageObj(doc);
      pdfium.FPDFImageObj_SetBitmap(nullptr, 0, image, bitmap);
      pdfium.FPDFImageObj_SetMatrix(image, 40, 0, 0, 40, 400, 700);
      pdfium.FPDFPage_InsertObject(page, image);
      final annot = pdfium.FPDFPage_CreateAnnot(page, FPDF_ANNOT_LINK);
      pdfium.FPDFPage_CloseAnnot(annot);
      pdfium.FPDFPage_GenerateContent(page);
      pdfium.FPDFBitmap_Destroy(bitmap);
      pdfium.FPDF_ClosePage(page);
      final out = <int>[];
      final write = NativeCallable<Int Function(Pointer<FPDF_FILEWRITE>, Pointer<Void>, UnsignedLong)>.isolateLocal(
        (Pointer<FPDF_FILEWRITE> self, Pointer<Void> data, int size) {
          out.addAll(data.cast<Uint8>().asTypedList(size));
          return 1;
        },
        exceptionalReturn: 0,
      );
      final fileWrite = arena<FPDF_FILEWRITE>();
      fileWrite.ref
        ..version = 1
        ..WriteBlock = write.nativeFunction;
      pdfium.FPDF_SaveAsCopy(doc, fileWrite, FPDF_NO_INCREMENTAL);
      write.close();
      pdfium.FPDF_CloseDocument(doc);
      return Uint8List.fromList(out);
    });

void main() {
  setUpAll(() async {
    await pdfrxInitialize();
    letter = await PdfrxEntryFunctions.instance
        .compute(_withImageAndLink, File('test/fixtures/letter.pdf').readAsBytesSync());
    final before = await inspect(letter);
    expect(before.types, contains(FPDF_PAGEOBJ_IMAGE));
    expect(before.annots, 1);
    producer = before.producer;
    expect(producer, contains('macOS'));
  });

  test('text pages: values become labels; images, links and metadata go', () async {
    final result = await anonymizePdf(letter, redactions: [
      await find(letter, 'Eleanor Whitcombe', label: '[PERSON_1]'),
      await find(letter, 'eleanor.whitcombe@example.org', label: '[EMAIL_1]'),
      await find(letter, 'GB29 NWBK 6016 1331 9268 19', label: '[IBAN_1]'),
    ]);
    expect(result.rasterPages, isEmpty);
    final text = await pageText(result.bytes);
    expect(text, isNot(contains('Whitcombe')));
    expect(text, isNot(contains('NWBK')));
    expect(text, contains('[PERSON_1]'));
    expect(text, contains('[IBAN_1]'));
    expect(text, contains('Dear Mr Thomas Grant'));
    // Labels read where their values were, not after the rest of the page.
    expect(
      text.replaceAll(RegExp(r'\s+'), ' ').trim(),
      startsWith('Dr [PERSON_1] 14 Harbour Lane, Bristol BS1 4QA [EMAIL_1] +44 7700 900123 '
          'Dear Mr Thomas Grant, Your account [IBAN_1] was credited'),
    );
    final after = await inspect(result.bytes);
    expect(after.types, isNot(contains(FPDF_PAGEOBJ_IMAGE)));
    expect(after.annots, 0);
    // PDFium signs its own copy; the original entries are gone.
    expect(after.producer, isNot(producer));
  });

  test('a label takes the room its line has, and never reaches the next word', () async {
    // Labels used to shrink to the width of what they replace: "[PERSON_1]" over a
    // short name was barely readable (2026-09-26).
    final result = await anonymizePdf(letter, redactions: [
      await find(letter, 'Whitcombe', label: '[PERSON_1]'), // ends its line
      await find(letter, 'Thomas', label: '[PERSON_2]'), // "Grant," follows
    ]);
    final name = await boxOf(letter, 'Whitcombe');
    final label = await boxOf(result.bytes, '[PERSON_1]');
    expect(label.left, closeTo(name.left, 1));
    expect(label.right - label.left, greaterThan((name.right - name.left) * 1.02),
        reason: 'not squeezed into the width of the name');
    final grant = await boxOf(result.bytes, 'Grant');
    final label2 = await boxOf(result.bytes, '[PERSON_2]');
    expect(label2.right, lessThanOrEqualTo(grant.left));
  });

  test('scanned pages become a picture with black boxes', () async {
    final doc = await PdfDocument.openData(letter);
    final page = doc.pages[0];
    final raw = (await page.loadText())!;
    final start = raw.fullText.indexOf('Eleanor Whitcombe');
    // The name's box in display points from the top-left, like OCR boxes.
    var box = raw.charRects[start];
    for (var i = start + 1; i < start + 'Eleanor Whitcombe'.length; i++) {
      box = box.merge(raw.charRects[i]);
    }
    final height = page.height;
    await doc.dispose();
    final quad = [
      Point(box.left, height - box.top),
      Point(box.right, height - box.top),
      Point(box.right, height - box.bottom),
      Point(box.left, height - box.bottom),
    ];

    final result = await anonymizePdf(letter, redactions: const [], scannedPages: {0: [quad]});
    expect(result.rasterPages, {0: 'scanned'});
    expect((await inspect(result.bytes)).types, [FPDF_PAGEOBJ_IMAGE]);
    expect((await pageText(result.bytes)).trim(), isEmpty);

    final out = await PdfDocument.openData(result.bytes);
    final image = (await out.pages[0].render(fullWidth: out.pages[0].width, fullHeight: out.pages[0].height))!;
    int grey(double x, double y) {
      final o = (y.round() * image.width + x.round()) * 4;
      return image.pixels[o] + image.pixels[o + 1] + image.pixels[o + 2];
    }

    final cx = (box.left + box.right) / 2, cy = height - (box.top + box.bottom) / 2;
    expect(grey(cx, cy), 0, reason: 'the name is under a black box');
    expect(grey(cx, cy + 60), greaterThan(600), reason: 'below it the page is white');
    image.dispose();
    await out.dispose();
  });
}
