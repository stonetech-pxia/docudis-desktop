import 'dart:convert';
import 'dart:io';

import 'package:pdfrx/pdfrx.dart';

import '../output/document_redaction.dart';
import '../output/docx_redaction.dart';
import 'input_source.dart';

/// Extracted text, plus the source of a PDF / Word document, which is
/// redacted as a copy of itself.
class Extraction {
  const Extraction(this.text, {this.document});

  final String text;

  /// The document [text] came from; [pdf] says where each page's text is.
  final ({String path, DocumentKind kind, PdfLayout? pdf})? document;
}

/// Turns any [InputSource] into plain text. Everything runs on this
/// computer.
class TextExtractor {
  static const textExtensions = {'txt', 'md', 'csv', 'text', 'log'};
  static const imageExtensions = {'jpg', 'jpeg', 'png', 'webp', 'heic', 'bmp'};

  /// Extensions the file picker offers. Pictures are offered so that
  /// picking one explains that text recognition is not there yet.
  static const pickableExtensions = [
    'txt', 'md', 'csv', 'pdf', 'docx', //
    'jpg', 'jpeg', 'png', 'webp', 'heic',
  ];

  Future<Extraction> extract(InputSource source) async {
    final result = await switch (source) {
      TextInput(:final text) => Future.value(Extraction(text)),
      FileInput() => _fromFile(source),
    };
    if (result.text.trim().isEmpty) {
      throw const UnsupportedInputException('empty');
    }
    return result;
  }

  Future<Extraction> _fromFile(FileInput file) async {
    final ext = file.extension;
    if (textExtensions.contains(ext)) {
      return Extraction(await _readText(file.path));
    }
    if (imageExtensions.contains(ext)) {
      throw const UnsupportedInputException('ocr');
    }
    if (ext == 'pdf') return _pdf(file.path);
    if (ext == 'docx') return _docx(file.path);
    throw const UnsupportedInputException('extension');
  }

  Future<String> _readText(String path) async {
    final bytes = await File(path).readAsBytes();
    try {
      return utf8.decode(bytes);
    } on FormatException {
      return latin1.decode(bytes);
    }
  }

  /// The text layer of every page. A PDF without one (a scan) needs OCR;
  /// scanned pages inside a text PDF are left out for now.
  Future<Extraction> _pdf(String path) async {
    await ensurePdfrx();
    final doc = await PdfDocument.openFile(path);
    try {
      final buffer = StringBuffer();
      final pages = <PdfPageSpan>[];
      for (final page in doc.pages) {
        final offset = buffer.length;
        final text = (await page.loadText())?.fullText ?? '';
        if (text.trim().isNotEmpty) {
          buffer
            ..writeln(text)
            ..writeln();
        }
        pages.add(
          PdfPageSpan(
            offset: offset,
            length: text.trim().isEmpty ? 0 : text.length,
          ),
        );
      }
      if (buffer.toString().trim().isEmpty && doc.pages.isNotEmpty) {
        throw const UnsupportedInputException('ocr');
      }
      return Extraction(
        buffer.toString(),
        document: (path: path, kind: DocumentKind.pdf, pdf: PdfLayout(pages)),
      );
    } finally {
      await doc.dispose();
    }
  }

  Future<Extraction> _docx(String path) async {
    final String text;
    try {
      text = docxText(await File(path).readAsBytes());
    } on FormatException {
      throw const UnsupportedInputException('extension');
    }
    return Extraction(
      text,
      document: (path: path, kind: DocumentKind.docx, pdf: null),
    );
  }
}
