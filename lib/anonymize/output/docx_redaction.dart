import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;
import 'package:xml/xml.dart';

const _w = 'http://schemas.openxmlformats.org/wordprocessingml/2006/main';
const _mc = 'http://schemas.openxmlformats.org/markup-compatibility/2006';
const _r =
    'http://schemas.openxmlformats.org/officeDocument/2006/relationships';
const _pr = 'http://schemas.openxmlformats.org/package/2006/relationships';
const _ct = 'http://schemas.openxmlformats.org/package/2006/content-types';
const _officeDocument =
    'http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument';

/// The body text of a `.docx` in reading order, and which `w:t` element
/// each piece came from, so edits to the text can be made to the file.
///
/// Only the main document part is read. Tracked deletions, moved-from text,
/// field instructions and `mc:Fallback` copies (the old-Word duplicate of a
/// text box) are skipped; [redactDocx] removes them from the file.
class DocxText {
  DocxText._(this.text, this._runs);

  final String text;
  final List<({XmlElement t, int start})> _runs;

  factory DocxText.read(XmlDocument document) {
    final out = StringBuffer();
    final runs = <({XmlElement t, int start})>[];
    void walk(XmlElement node) {
      for (final child in node.childElements) {
        final ns = child.name.namespaceUri, local = child.name.local;
        if (ns == _mc && local == 'Fallback') continue;
        if (ns == _w) {
          switch (local) {
            case 't':
              runs.add((t: child, start: out.length));
              out.write(child.innerText);
              continue;
            case 'tab':
              out.write('\t');
              continue;
            case 'br' || 'cr':
              out.writeln();
              continue;
            case 'pPr' ||
                'rPr' ||
                'sectPr' ||
                'del' ||
                'moveFrom' ||
                'instrText':
              continue;
          }
        }
        walk(child);
        if (ns == _w && local == 'p') out.writeln();
      }
    }

    walk(document.rootElement);
    return DocxText._(out.toString(), runs);
  }

  /// Makes the edits of `anonymize().replacements` to the `w:t` elements:
  /// each replaced range loses its characters, and its placeholder goes
  /// where the first of them was.
  void apply(List<({int start, int end, String placeholder})> replacements) {
    final pending = [...replacements]
      ..sort((a, b) => a.start.compareTo(b.start));
    final written = <int>{};
    var first = 0;
    for (final run in _runs) {
      final text = run.t.innerText;
      final start = run.start, end = start + text.length;
      while (first < pending.length && pending[first].end <= start) {
        first++;
      }
      final out = StringBuffer();
      var cursor = start;
      var changed = false;
      for (var i = first; i < pending.length && pending[i].start < end; i++) {
        final r = pending[i];
        if (r.end <= start) continue;
        if (r.start > cursor) {
          out.write(text.substring(cursor - start, r.start - start));
        }
        if (written.add(i)) out.write(r.placeholder);
        cursor = r.end.clamp(cursor, end);
        changed = true;
      }
      if (!changed) continue;
      out.write(text.substring(cursor - start));
      run.t.children
        ..clear()
        ..add(XmlText(out.toString()));
      run.t.setAttribute('xml:space', 'preserve');
    }
  }
}

/// Plain text of a `.docx` file, as the review page shows it.
String docxText(Uint8List bytes) =>
    DocxText.read(_documentXml(ZipDecoder().decodeBytes(bytes))).text;

XmlDocument _documentXml(Archive archive) {
  final entry = archive.findFile('word/document.xml');
  if (entry == null) {
    throw const FormatException('word/document.xml is missing');
  }
  return XmlDocument.parse(utf8.decode(entry.content));
}

/// Part types kept next to the document: they style it and hold no text.
const _keptTypes = {
  'styles',
  'stylesWithEffects',
  'numbering',
  'fontTable',
  'settings',
  'webSettings',
  'theme',
};

/// The shareable copy of a `.docx`: the [replacements] made to the body
/// text, and everything the review page did not show taken out, so it
/// cannot leak: headers and footers, footnotes, comments, tracked changes,
/// pictures, charts and embedded objects, hyperlink targets, field
/// instructions, custom XML, document properties and the thumbnail. Text
/// boxes stay (their text was read). Styles, numbering, fonts and theme are
/// kept; the file is rebuilt from those parts only.
Uint8List redactDocx(
  Uint8List source,
  List<({int start, int end, String placeholder})> replacements,
) {
  final archive = ZipDecoder().decodeBytes(source);
  final document = _documentXml(archive);
  DocxText.read(document).apply(replacements);
  _cleanBody(document);

  // document.xml's relationships, minus everything but the styling parts.
  // The part is optional: files from some generators have none.
  final relsPart = archive.findFile('word/_rels/document.xml.rels');
  final rels = XmlDocument.parse(
    relsPart == null
        ? '<Relationships xmlns="$_pr"/>'
        : utf8.decode(relsPart.content),
  );
  final keptParts = <String>{'word/document.xml'};
  final keptIds = <String>{};
  for (final rel in rels.rootElement.childElements.toList()) {
    final type = p.url.basename(rel.getAttribute('Type') ?? '');
    final external = rel.getAttribute('TargetMode') == 'External';
    if (!external && _keptTypes.contains(type)) {
      keptIds.add(rel.getAttribute('Id')!);
      keptParts.add(
        p.url.normalize(p.url.join('word', rel.getAttribute('Target')!)),
      );
    } else {
      rel.remove();
    }
  }
  _dropDanglingReferences(document, keptIds);

  final out = Archive();
  void add(String name, String content) =>
      out.addFile(ArchiveFile.string(name, content));
  add('[Content_Types].xml', _contentTypes(archive, keptParts));
  add(
    '_rels/.rels',
    '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<Relationships xmlns="$_pr"><Relationship Id="rId1" Type="$_officeDocument" '
        'Target="word/document.xml"/></Relationships>',
  );
  add('word/document.xml', document.toXmlString());
  add('word/_rels/document.xml.rels', rels.toXmlString());
  for (final name in keptParts) {
    if (name == 'word/document.xml') continue;
    final entry = archive.findFile(name);
    if (entry == null) continue;
    final xml = XmlDocument.parse(utf8.decode(entry.content));
    _cleanPart(p.url.basename(name), xml);
    add(name, xml.toXmlString());
  }
  return Uint8List.fromList(ZipEncoder().encodeBytes(out));
}

/// Elements whose content was never read or is not wanted in the copy.
const _dropped = {
  'del', 'moveFrom', // tracked changes: the old text
  'commentRangeStart', 'commentRangeEnd', 'commentReference',
  'footnoteReference', 'endnoteReference',
  'headerReference', 'footerReference',
  'object', 'altChunk', 'subDoc', 'dataBinding',
  'fldChar', 'instrText', // field codes; the field's shown result stays
};

/// Elements replaced by their children.
const _unwrapped = {
  'hyperlink',
  'fldSimple',
  'ins',
  'moveTo',
  'smartTag',
  'customXml',
};

void _cleanBody(XmlDocument document) {
  final remove = <XmlElement>[];
  final unwrap = <XmlElement>[];
  for (final e in document.descendantElements) {
    final ns = e.name.namespaceUri, local = e.name.local;
    if (ns == _mc && local == 'Fallback') {
      remove.add(e);
    } else if (ns == _w && _dropped.contains(local)) {
      remove.add(e);
    } else if (ns == _w && _unwrapped.contains(local)) {
      unwrap.add(e);
    } else if (ns == _w &&
        (local == 'drawing' || local == 'pict') &&
        !_isPlainTextBox(e)) {
      remove.add(e);
    }
  }
  for (final e in remove) {
    if (e.parent != null) e.remove();
  }
  // Innermost first, so a nested wrapper is emptied before its parent moves.
  for (final e in unwrap.reversed) {
    final parent = e.parent;
    if (parent == null) continue;
    final children = e.children.toList();
    for (final c in children) {
      c.remove();
    }
    parent.children.insertAll(parent.children.indexOf(e), children);
    e.remove();
  }
}

/// A shape that is only a text box: it has text content and points at no
/// other part (no picture, chart or linked file).
bool _isPlainTextBox(XmlElement shape) =>
    shape.descendantElements.any(
      (e) => e.name.namespaceUri == _w && e.name.local == 'txbxContent',
    ) &&
    !shape.descendantElements.any(
      (e) => e.attributes.any((a) => a.name.namespaceUri == _r),
    );

/// Removes any element still pointing at a relationship that was dropped,
/// so Word does not report the file as damaged.
void _dropDanglingReferences(XmlDocument document, Set<String> keptIds) {
  final dangling = document.descendantElements
      .where(
        (e) => e.attributes.any(
          (a) => a.name.namespaceUri == _r && !keptIds.contains(a.value),
        ),
      )
      .toList();
  for (final e in dangling) {
    if (e.parent != null) e.remove();
  }
}

/// Clears what a styling part can hold besides styling.
void _cleanPart(String name, XmlDocument xml) {
  final drop = switch (name) {
    'settings.xml' => {
      'attachedTemplate',
      'docVars',
      'mailMerge',
      'rsids',
      'footnotePr',
      'endnotePr',
    },
    'numbering.xml' => {'numPicBullet', 'lvlPicBulletId'},
    'fontTable.xml' => {
      'embedRegular',
      'embedBold',
      'embedItalic',
      'embedBoldItalic',
    },
    _ => const <String>{},
  };
  final remove = xml.descendantElements
      .where(
        (e) =>
            (e.name.namespaceUri == _w && drop.contains(e.name.local)) ||
            e.attributes.any((a) => a.name.namespaceUri == _r),
      )
      .toList();
  for (final e in remove) {
    if (e.parent != null) e.remove();
  }
}

/// The original content types, listing only the parts that are kept.
String _contentTypes(Archive archive, Set<String> keptParts) {
  final xml = XmlDocument.parse(
    utf8.decode(archive.findFile('[Content_Types].xml')!.content),
  );
  for (final o
      in xml.rootElement.findElements('Override', namespaceUri: _ct).toList()) {
    final part = (o.getAttribute('PartName') ?? '').replaceFirst('/', '');
    if (!keptParts.contains(part)) o.remove();
  }
  return xml.toXmlString();
}
