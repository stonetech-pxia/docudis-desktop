// The whole flow in the real app, with the bundled Rust libraries and the
// installed NER model (tool/prepare_native.sh, tool/fetch_models.sh):
//
//   flutter test integration_test/flow_test.dart -d macos
//   flutter test integration_test/flow_test.dart -d windows
//
// Records and the dictionary lists go to a temporary folder, not the
// app's own. On Windows the run also checks that the app opened no
// network socket all along.

import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:docudis/anonymize/input/input_source.dart';
import 'package:docudis_ffi/docudis_ffi.dart' show EntityType;
import 'package:docudis/anonymize/output/docx_redaction.dart';
import 'package:docudis/anonymize/providers.dart';
import 'package:docudis/anonymize/storage/record_store.dart';
import 'package:docudis/anonymize/ui/findings_panel.dart';
import 'package:docudis/app.dart';
import 'package:docudis/preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' hide TextInput;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fixtures/letter_pdf.dart';
import 'network_monitor.dart';

const _pasted =
    "Hi, I'm Sarah Meyer from Lyon. Call me on +33 6 12 34 56 78 or write to "
    'sarah.meyer@example.fr. My IBAN is FR76 3000 6000 0112 3456 7890 189.';

late Directory _records;

Future<ProviderContainer> _pumpApp(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({'app_locale': 'en'});
  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(
        await SharedPreferences.getInstance(),
      ),
      recordStoreProvider.overrideWithValue(RecordStore(root: _records)),
      appSupportDirectoryProvider.overrideWith((ref) async => _records),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const DocudisApp()),
  );
  await tester.pumpAndSettle();
  return container;
}

/// Pumps until [finder] shows up: the model and Rust run on other isolates.
Future<void> _waitFor(WidgetTester tester, Finder finder) async {
  for (var i = 0; i < 600 && finder.evaluate().isEmpty; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  expect(finder, findsWidgets);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  NetworkMonitor? network;
  setUpAll(() async {
    if (Platform.isWindows) network = await NetworkMonitor.start();
  });

  setUp(() async {
    _records = await Directory.systemTemp.createTemp('docudis-records-');
  });
  tearDown(() => _records.delete(recursive: true));

  testWidgets('paste, anonymize, review and restore', (tester) async {
    final container = await _pumpApp(tester);
    expect(
      await container.read(nerNameProvider.future),
      isNotNull,
      reason: 'the NER model should be installed and load',
    );

    await Clipboard.setData(const ClipboardData(text: _pasted));
    await tester.tap(find.text('Paste'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Anonymize'));
    await _waitFor(tester, find.byType(FindingsPanel));
    await tester.pumpAndSettle();

    final records = await container.read(recordsProvider.future);
    expect(records, hasLength(1));
    final detail = await container.read(
      recordDetailProvider(records.single.id).future,
    );
    expect(detail.record.modelUsed, isTrue);
    final output = detail.output;
    for (final value in [
      'Sarah Meyer',
      '+33 6 12 34 56 78',
      'sarah.meyer@example.fr',
      'FR76 3000 6000 0112 3456 7890 189',
    ]) {
      expect(output, isNot(contains(value)), reason: value);
    }
    expect(output, contains('[PERSON_1]'));
    expect(output, contains('[EMAIL_1]'));

    // Show the e-mail again: untick it in the findings.
    await tester.tap(
      find.descendant(
        of: find.byType(FindingsPanel),
        matching: find.text('sarah.meyer@example.fr'),
      ),
    );
    var edited = detail;
    for (var i = 0; i < 50; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      edited = await container.read(
        recordDetailProvider(detail.record.id).future,
      );
      if (edited.output.contains('sarah.meyer@example.fr')) break;
    }
    expect(edited.output, contains('sarah.meyer@example.fr'));
    expect(edited.output, contains('[PERSON_1]'));

    // Restore an AI reply on the restore page.
    await tester.tap(find.text('Restore reply'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextField),
      'Dear [PERSON_1], I will call [PHONE_1] tomorrow.',
    );
    await _waitFor(tester, find.textContaining('Dear Sarah Meyer'));
  });

  testWidgets('the dictionary lists change what is hidden', (tester) async {
    final container = await _pumpApp(tester);
    final service = container.read(anonymizeServiceProvider);
    Future<String> run() async {
      final record = await service.process(const TextInput(_pasted));
      return (await container.read(recordStoreProvider).load(record.id)).output;
    }

    // Hide only this list: the listed word, nothing else.
    await container.read(dictionaryProvider.notifier).add('Lyon');
    await container.read(listOnlyProvider.notifier).set(true);
    var output = await run();
    expect(output, isNot(contains('Lyon')));
    expect(output, contains('Sarah Meyer'));
    expect(output, contains('sarah.meyer@example.fr'));

    // Never hide: back to everything, but Lyon stays readable.
    await container.read(listOnlyProvider.notifier).set(false);
    await container.read(dictionaryProvider.notifier).remove('Lyon');
    await container.read(neverHideProvider.notifier).add('Lyon');
    output = await run();
    expect(output, contains('Lyon'));
    expect(output, isNot(contains('Sarah Meyer')));

    // Text hidden by hand comes back as a suggestion for Always hide.
    container.invalidate(recordsProvider);
    final records = await container.read(recordsProvider.future);
    final detail = await container
        .read(recordStoreProvider)
        .load(records.first.id);
    final start = detail.original.indexOf('IBAN');
    await container.read(reviewControllerProvider.notifier).apply(
      detail.record.id,
      [
        ...detail.detections,
        service.manualDetection(
          detail.original,
          start,
          start + 4,
          EntityType.custom,
        ),
      ],
    );
    container.invalidate(recordsProvider);
    final suggested = await container.read(manualBlocksProvider.future);
    expect(suggested.map((b) => b.value), contains('IBAN'));
  });

  testWidgets('a PDF and a Word file come back redacted', (tester) async {
    final container = await _pumpApp(tester);
    final service = container.read(anonymizeServiceProvider);

    final pdfPath = '${_records.path}/letter.pdf';
    await File(pdfPath).writeAsBytes(base64Decode(letterPdfBase64));
    final pdfRecord = await service.process(
      FileInput(path: pdfPath, name: 'letter.pdf'),
    );
    final pdf = await container.read(recordStoreProvider).load(pdfRecord.id);
    expect(pdf.output, isNot(contains('Eleanor Whitcombe')));
    expect(pdf.output, isNot(contains('eleanor.whitcombe@example.org')));
    final redactedPdf = pdf.document?.redactedPath;
    expect(redactedPdf, isNotNull);
    final doc = await PdfDocument.openFile(redactedPdf!);
    try {
      final text = (await doc.pages.first.loadText())?.fullText ?? '';
      expect(text, isNot(contains('Whitcombe')));
      expect(text, contains('[PERSON_1]'));
    } finally {
      await doc.dispose();
    }

    final docxPath = '${_records.path}/note.docx';
    await File(docxPath).writeAsBytes(_docx());
    final docxRecord = await service.process(
      FileInput(path: docxPath, name: 'note.docx'),
    );
    final docx = await container.read(recordStoreProvider).load(docxRecord.id);
    final redactedDocx = docx.document?.redactedPath;
    expect(redactedDocx, isNotNull);
    final text = docxText(await File(redactedDocx!).readAsBytes());
    expect(text, isNot(contains('Sarah Meyer')));
    expect(text, isNot(contains('sarah.meyer@example.fr')));
    expect(text, contains('[EMAIL_1]'));
  });

  // Last, so it covers every test above.
  test(
    'the app opened no network socket',
    () async => expect(await network!.stop(), isEmpty),
    skip: Platform.isWindows ? false : 'reads the Windows socket tables',
  );
}

/// A minimal Word file holding [_pasted].
Uint8List _docx() {
  const w = 'http://schemas.openxmlformats.org/wordprocessingml/2006/main';
  final archive = Archive()
    ..addFile(
      ArchiveFile.string(
        '[Content_Types].xml',
        '<?xml version="1.0" encoding="UTF-8"?>'
            '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">'
            '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>'
            '<Default Extension="xml" ContentType="application/xml"/>'
            '<Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>'
            '</Types>',
      ),
    )
    ..addFile(
      ArchiveFile.string(
        '_rels/.rels',
        '<?xml version="1.0" encoding="UTF-8"?>'
            '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
            '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>'
            '</Relationships>',
      ),
    )
    ..addFile(
      ArchiveFile.string(
        'word/document.xml',
        '<?xml version="1.0" encoding="UTF-8"?>'
            '<w:document xmlns:w="$w"><w:body><w:p><w:r><w:t xml:space="preserve">'
            '$_pasted</w:t></w:r></w:p></w:body></w:document>',
      ),
    );
  return Uint8List.fromList(ZipEncoder().encodeBytes(archive));
}
