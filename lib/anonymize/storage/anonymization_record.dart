import 'package:docudis_ffi/docudis_ffi.dart';

import '../output/document_redaction.dart';

enum InputKind { text, file, image }

/// Metadata of one processed input (`meta.json`). The heavy parts live in
/// sibling files: `original.txt`, `detections.json`, `output.txt`.
class AnonymizationRecord {
  const AnonymizationRecord({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.kind,
    required this.sourceName,
    required this.outputFileName,
    required this.detectionCount,
    required this.preview,
    this.title,
    this.listOnly = false,
    this.modelUsed = true,
  });

  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final InputKind kind;

  /// Original file name for [InputKind.file], null otherwise.
  final String? sourceName;

  /// Name used when sharing the `.txt`.
  final String outputFileName;

  /// Number of enabled detections.
  final int detectionCount;

  /// First ~120 characters of the anonymized text, for list rows.
  final String preview;

  /// Name in History: the user's rename, else the first line of the text
  /// for pasted text and photos, whose [sourceName] says nothing. Null for
  /// documents, which go by their file name, and for records made before
  /// titles existed.
  final String? title;

  /// Made with "Hide only this list": only the Always hide list was looked
  /// for, nothing else. The result page says so.
  final bool listOnly;

  /// Whether the NER model ran. Without it only the rules, lists and
  /// dictionary looked for values, and names are easily missed; the result
  /// page says so. Records from before this field count as with.
  final bool modelUsed;

  /// What History, the result page and Restore call this record.
  String get displayName => title ?? sourceName ?? outputFileName;

  Map<String, Object?> toJson() => {
    'id': id,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'kind': kind.name,
    'sourceName': sourceName,
    'outputFileName': outputFileName,
    'detectionCount': detectionCount,
    'preview': preview,
    'title': title,
    'listOnly': listOnly,
    'modelUsed': modelUsed,
  };

  factory AnonymizationRecord.fromJson(Map<String, Object?> j) =>
      AnonymizationRecord(
        id: j['id'] as String,
        createdAt: DateTime.parse(j['createdAt'] as String),
        updatedAt: DateTime.parse(j['updatedAt'] as String),
        kind: InputKind.values.byName(j['kind'] as String),
        sourceName: j['sourceName'] as String?,
        outputFileName: j['outputFileName'] as String,
        detectionCount: j['detectionCount'] as int,
        preview: j['preview'] as String,
        title: j['title'] as String?,
        listOnly: j['listOnly'] as bool? ?? false,
        modelUsed: j['modelUsed'] as bool? ?? true,
      );
}

final _hasWord = RegExp(r'[\p{L}\p{N}]', unicode: true);
final _space = RegExp(r'\s+');

/// "Subject:" and its translations, as e-mail clients write it.
final _subject = RegExp(
  r'^(?:subject|asunto|objet|oggetto|betreff|assunto|onderwerp|主题|主題|件名)\s*[:：]\s*',
  caseSensitive: false,
);

/// The time stamp a chat export puts in front of each message:
/// "[24/09/2026, 07:58:12] ", "24/09/2026, 07:58 - ", "[09:12, 23/9/2026] ".
final _chatStamp = RegExp(
  r'^\[?(?:\d{1,4}[./-]\d{1,2}[./-]\d{1,4},?\s+\d{1,2}[:.]\d{2}(?:[:.]\d{2})?(?:\s?[ap]\.?\s?m\.?)?'
  r'|\d{1,2}[:.]\d{2}(?:[:.]\d{2})?(?:\s?[ap]\.?\s?m\.?)?,?\s+\d{1,4}[./-]\d{1,2}[./-]\d{1,4})\]?\s*(?:-\s+)?',
  caseSensitive: false,
);

/// What a pasted text or a photo is called in History: an e-mail's subject
/// when one of its first lines has one ("Re: Deposit - 14 Harbour Lane"),
/// else the first line with a word in it, without a chat time stamp in
/// front ("Lucía Fabra: Buenos días…", "BULLETIN DE PAIE"). At most 60
/// characters. The record keeps the original on this computer anyway.
String? titleFromText(String text) {
  final lines = [
    for (final line in text.split('\n'))
      if (line.replaceAll(_space, ' ').trim() case final flat
          when _hasWord.hasMatch(flat))
        flat,
  ];
  if (lines.isEmpty) return null;
  String? subject;
  for (final line in lines.take(8)) {
    final label = _subject.firstMatch(line);
    if (label != null && _hasWord.hasMatch(line.substring(label.end))) {
      subject = line.substring(label.end);
      break;
    }
  }
  final first = lines.first.replaceFirst(_chatStamp, '');
  final title = subject ?? (_hasWord.hasMatch(first) ? first : lines.first);
  final runes = title.runes.toList();
  return runes.length <= 60
      ? title
      : '${String.fromCharCodes(runes.take(60)).trimRight()}…';
}

/// Everything about one record, loaded from its directory.
class RecordDetail {
  const RecordDetail({
    required this.record,
    required this.original,
    required this.output,
    required this.detections,
    required this.map,
    required this.outputPath,
    this.document,
  });

  final AnonymizationRecord record;
  final String original;
  final String output;
  final List<Detection> detections;
  final PlaceholderMap map;
  final String outputPath;

  /// For a PDF or Word file: the stored source and its redacted copy.
  final RecordDocument? document;
}

class RecordDocument {
  const RecordDocument({
    required this.kind,
    required this.sourcePath,
    required this.redactedPath,
    this.pdf,
  });

  final DocumentKind kind;
  final String sourcePath;
  final PdfLayout? pdf;

  /// The redacted copy; null when it could not be made (the text still
  /// goes out as a `.txt` then).
  final String? redactedPath;
}
