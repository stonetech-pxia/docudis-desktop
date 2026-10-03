import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:docudis/anonymize/output/docx_redaction.dart';
import 'package:docudis_ffi/docudis_ffi.dart';
import 'package:flutter_test/flutter_test.dart';

const _ns =
    'xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main" '
    'xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" '
    'xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006" '
    'xmlns:wp="http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing" '
    'xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" '
    'xmlns:wps="http://schemas.microsoft.com/office/word/2010/wordprocessingShape" '
    'xmlns:v="urn:schemas-microsoft-com:vml"';

String _run(String text) =>
    '<w:r><w:rPr><w:b/></w:rPr><w:t xml:space="preserve">$text</w:t></w:r>';

/// An invented letter using what Word files carry besides body text.
final _document =
    '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
    '<w:document $_ns><w:body>'
    // The name is split over two runs, as Word often does.
    '<w:p><w:pPr><w:tabs><w:tab w:val="left" w:pos="720"/></w:tabs></w:pPr>'
    '${_run('Dear Mr Thomas ')}${_run('Grant,')}</w:p>'
    '<w:p><w:hyperlink r:id="rId3">${_run('grant@example.com')}</w:hyperlink>'
    '<w:del w:author="Eleanor Whitcombe"><w:r><w:delText>old secret</w:delText></w:r></w:del>'
    '<w:ins w:author="Eleanor Whitcombe">${_run(' today')}</w:ins>'
    '<w:commentRangeStart w:id="0"/>${_run('.')}<w:commentRangeEnd w:id="0"/>'
    '<w:r><w:commentReference w:id="0"/></w:r>'
    '<w:r><w:footnoteReference w:id="1"/></w:r></w:p>'
    '<w:p><w:fldSimple w:instr="HYPERLINK &quot;mailto:hidden@example.com&quot;">${_run('Call us')}</w:fldSimple>'
    '<w:r><w:tab/></w:r><w:moveFrom w:author="x">${_run('moved')}</w:moveFrom>'
    '<w:moveTo w:author="x">${_run('moved')}</w:moveTo></w:p>'
    // A picture, then a text box in its two Word versions.
    '<w:p><w:r><w:drawing><wp:inline><a:graphic><a:graphicData><a:blip r:embed="rId4"/>'
    '</a:graphicData></a:graphic></wp:inline></w:drawing></w:r>'
    '<w:r><mc:AlternateContent><mc:Choice Requires="wps"><w:drawing><wp:anchor><a:graphic>'
    '<a:graphicData><wps:wsp><wps:txbx><w:txbxContent><w:p>${_run('Box: Priya Raman')}</w:p>'
    '</w:txbxContent></wps:txbx></wps:wsp></a:graphicData></a:graphic></wp:anchor></w:drawing>'
    '</mc:Choice><mc:Fallback><w:pict><v:shape><v:textbox><w:txbxContent><w:p>'
    '${_run('Box: Priya Raman')}</w:p></w:txbxContent></v:textbox></v:shape></w:pict>'
    '</mc:Fallback></mc:AlternateContent></w:r></w:p>'
    '<w:sectPr><w:headerReference w:type="default" r:id="rId2"/></w:sectPr>'
    '</w:body></w:document>';

const _rels =
    '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
    '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
    '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>'
    '<Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/header" Target="header1.xml"/>'
    '<Relationship Id="rId3" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/hyperlink" Target="mailto:grant@example.com" TargetMode="External"/>'
    '<Relationship Id="rId4" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/image" Target="media/image1.png"/>'
    '<Relationship Id="rId5" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/settings" Target="settings.xml"/>'
    '</Relationships>';

const _contentTypes =
    '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
    '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">'
    '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>'
    '<Default Extension="xml" ContentType="application/xml"/>'
    '<Default Extension="png" ContentType="image/png"/>'
    '<Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>'
    '<Override PartName="/word/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.styles+xml"/>'
    '<Override PartName="/word/settings.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.settings+xml"/>'
    '<Override PartName="/word/header1.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.header+xml"/>'
    '<Override PartName="/docProps/core.xml" ContentType="application/vnd.openxmlformats-package.core-properties+xml"/>'
    '</Types>';

Uint8List _docx() {
  final a = Archive();
  void add(String name, String content) =>
      a.addFile(ArchiveFile.string(name, content));
  add('[Content_Types].xml', _contentTypes);
  add(
    '_rels/.rels',
    '<?xml version="1.0" encoding="UTF-8"?><Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
        '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>'
        '<Relationship Id="rId2" Type="http://schemas.openxmlformats.org/package/2006/relationships/metadata/core-properties" Target="docProps/core.xml"/>'
        '</Relationships>',
  );
  add('word/document.xml', _document);
  add('word/_rels/document.xml.rels', _rels);
  add('word/styles.xml', '<?xml version="1.0"?><w:styles $_ns/>');
  add(
    'word/settings.xml',
    '<?xml version="1.0"?><w:settings $_ns><w:attachedTemplate r:id="rId1"/>'
        '<w:docVars><w:docVar w:name="client" w:val="Eleanor Whitcombe"/></w:docVars>'
        '<w:defaultTabStop w:val="720"/></w:settings>',
  );
  add(
    'word/header1.xml',
    '<?xml version="1.0"?><w:hdr $_ns><w:p>${_run('Eleanor Whitcombe, 14 Harbour Lane')}</w:p></w:hdr>',
  );
  add('word/media/image1.png', 'not really a png');
  add(
    'docProps/core.xml',
    '<cp:coreProperties xmlns:cp="x"><dc:creator xmlns:dc="y">Eleanor Whitcombe</dc:creator></cp:coreProperties>',
  );
  return Uint8List.fromList(ZipEncoder().encodeBytes(a));
}

Detection _span(String text, String value, EntityType type) {
  final start = text.indexOf(value);
  expect(start, isNot(-1), reason: value);
  return Detection(
    type: type,
    value: value,
    start: start,
    end: start + value.length,
    confidence: 1,
    detector: 'test',
    source: DetectionSource.manual,
  );
}

/// The Rust core built by tool/prepare_native.sh (.ps1 on Windows), when it
/// is there.
final _library = File(
  Platform.isWindows
      ? 'build/native/windows/docudis_capi.dll'
      : 'build/native/macos/libdocudis_capi.dylib',
);

final DocudisCore core = DocudisCore.open(_library.absolute.path);

final Object _skip = _library.existsSync()
    ? false
    : 'needs the Rust core: run tool/prepare_native.sh';

void main() {
  test('reads the body once, in order, without what was never visible', () {
    expect(
      docxText(_docx()),
      'Dear Mr Thomas Grant,\n'
      'grant@example.com today.\n'
      'Call us\tmoved\n'
      'Box: Priya Raman\n\n',
    );
  });

  test('a file without document relationships is redacted too', () {
    final a = Archive()
      ..addFile(ArchiveFile.string('[Content_Types].xml', _contentTypes))
      ..addFile(ArchiveFile.string('word/document.xml', _document));
    final source = Uint8List.fromList(ZipEncoder().encodeBytes(a));
    final text = docxText(source);
    final result = core.anonymize(text, [
      _span(text, 'Thomas Grant', EntityType.person),
    ]);

    expect(docxText(redactDocx(source, result.replacements)), result.text);
  }, skip: _skip);

  test('the copy says what the output says and carries nothing else', () {
    final source = _docx();
    final text = docxText(source);
    final result = core.anonymize(text, [
      _span(text, 'Thomas Grant', EntityType.person),
      _span(text, 'grant@example.com', EntityType.email),
      _span(text, 'Priya Raman', EntityType.person),
    ]);
    final copy = redactDocx(source, result.replacements);

    expect(docxText(copy), result.text);
    final archive = ZipDecoder().decodeBytes(copy);
    expect(archive.files.map((f) => f.name).toSet(), {
      '[Content_Types].xml',
      '_rels/.rels',
      'word/document.xml',
      'word/_rels/document.xml.rels',
      'word/styles.xml',
      'word/settings.xml',
    });
    final everything = archive.files
        .map((f) => utf8.decode(f.content))
        .join('\n');
    for (final gone in [
      'Whitcombe',
      'Grant',
      'Priya',
      'example.com',
      'old secret',
      'header',
      'r:embed',
      'mailto',
    ]) {
      expect(everything, isNot(contains(gone)), reason: gone);
    }
    // Formatting and the text box survive; the box is there once.
    final document = utf8.decode(
      archive.findFile('word/document.xml')!.content,
    );
    expect(document, contains('<w:b/>'));
    expect('[PERSON_2]'.allMatches(document), hasLength(1));
    expect(document, contains('<w:sectPr/>'));
  }, skip: _skip);
}
