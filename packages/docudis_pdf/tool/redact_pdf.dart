// Redacts every occurrence of the given terms in a PDF, matched as plain
// substrings (so a fragment of a word can be tried), and checks the result.
// See anonymize_pdf.dart for the run driven by the detection engine.
//
//   dart run tool/redact_pdf.dart <in.pdf> <out.pdf> <term> [<term> ...]
//
// PDFium comes from the PDFIUM_PATH environment variable, or from
// pdfium_dart's build hook.

import 'dart:io';

import 'package:pdfrx_engine/pdfrx_engine.dart';

import 'src/check.dart';

Future<void> main(List<String> args) async {
  if (args.length < 3) {
    stderr.writeln('usage: redact_pdf <in.pdf> <out.pdf> <term> [<term> ...]');
    exit(64);
  }
  final input = File(args[0]).readAsBytesSync();
  final terms = args.skip(2).map((t) => t.toLowerCase()).toList();
  await pdfrxInitialize();

  final original = await PdfDocument.openData(input, sourceName: 'original');
  final plan = Plan();
  for (final page in original.pages) {
    final text = (await page.loadText())!;
    final haystack = text.fullText.toLowerCase();
    for (var t = 0; t < terms.length; t++) {
      for (var at = haystack.indexOf(terms[t]); at != -1; at = haystack.indexOf(terms[t], at + 1)) {
        plan.add(page.pageNumber - 1, text, at, at + terms[t].length, '[REDACTED_${t + 1}]');
      }
    }
  }
  exit(await redactAndCheck(input, original, plan, args[1]) ? 0 : 1);
}
