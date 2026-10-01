import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:docudis_ffi/docudis_ffi.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../output/document_redaction.dart';
import 'anonymization_record.dart';

/// One directory per record under `<app support>/records/<id>/`, the same
/// layout as the Android app's. Plain files, not encrypted (as on Android).
class RecordStore {
  /// [root] replaces `<app support>/records`, for tests.
  RecordStore({this._root});

  Directory? _root;

  Future<Directory> _rootDir() async {
    final cached = _root;
    if (cached != null) return cached;
    final support = await getApplicationSupportDirectory();
    final dir = Directory(p.join(support.path, 'records'));
    await dir.create(recursive: true);
    return _root = dir;
  }

  Directory _dirFor(Directory root, String id) =>
      Directory(p.join(root.path, id));

  Future<List<AnonymizationRecord>> list() async {
    final root = await _rootDir();
    final records = <AnonymizationRecord>[];
    await for (final entry in root.list()) {
      if (entry is! Directory) continue;
      final meta = File(p.join(entry.path, 'meta.json'));
      if (!await meta.exists()) continue;
      try {
        records.add(
          AnonymizationRecord.fromJson(
            (jsonDecode(await meta.readAsString()) as Map)
                .cast<String, Object?>(),
          ),
        );
      } on FormatException {
        // Skip a half-written record rather than break the whole list.
      }
    }
    records.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return records;
  }

  Future<RecordDetail> load(String id) async {
    final dir = _dirFor(await _rootDir(), id);
    final meta = AnonymizationRecord.fromJson(
      (jsonDecode(
        await File(p.join(dir.path, 'meta.json')).readAsString(),
      ) as Map).cast<String, Object?>(),
    );
    final original = await File(p.join(dir.path, 'original.txt'))
        .readAsString();
    final output = await File(p.join(dir.path, 'output.txt')).readAsString();
    final det = (jsonDecode(
      await File(p.join(dir.path, 'detections.json')).readAsString(),
    ) as Map).cast<String, Object?>();
    final documentFile = File(p.join(dir.path, 'document.json'));
    RecordDocument? document;
    if (await documentFile.exists()) {
      final j = (jsonDecode(await documentFile.readAsString()) as Map)
          .cast<String, Object?>();
      final kind = DocumentKind.values.byName(j['kind'] as String);
      final redacted = File(p.join(dir.path, 'redacted.${kind.extension}'));
      document = RecordDocument(
        kind: kind,
        sourcePath: p.join(dir.path, j['source'] as String),
        redactedPath: await redacted.exists() ? redacted.path : null,
        pdf: j['pdf'] == null
            ? null
            : PdfLayout.fromJson(j['pdf'] as List<dynamic>),
      );
    }
    return RecordDetail(
      record: meta,
      original: original,
      output: output,
      detections: [
        for (final d in det['detections'] as List<dynamic>)
          Detection.fromJson((d as Map).cast<String, Object?>()),
      ],
      map: PlaceholderMap.fromJson(jsonEncode(det['map'])),
      outputPath: p.join(dir.path, 'output.txt'),
      document: document,
    );
  }

  /// The text a record sent and the key that restores it, without the
  /// rest: enough to tell which record an AI reply answers.
  Future<({String output, PlaceholderMap map})> outputAndKey(String id) async {
    final dir = _dirFor(await _rootDir(), id);
    final det = (jsonDecode(
      await File(p.join(dir.path, 'detections.json')).readAsString(),
    ) as Map).cast<String, Object?>();
    return (
      output: await File(p.join(dir.path, 'output.txt')).readAsString(),
      map: PlaceholderMap.fromJson(jsonEncode(det['map'])),
    );
  }

  /// Only the detections of a record, without its texts or image.
  Future<List<Detection>> detections(String id) async {
    final dir = _dirFor(await _rootDir(), id);
    final det = (jsonDecode(
      await File(p.join(dir.path, 'detections.json')).readAsString(),
    ) as Map).cast<String, Object?>();
    return [
      for (final d in det['detections'] as List<dynamic>)
        Detection.fromJson((d as Map).cast<String, Object?>()),
    ];
  }

  Future<void> save({
    required AnonymizationRecord record,
    required String original,
    required String output,
    required List<Detection> detections,
    required PlaceholderMap map,
    ({String sourcePath, DocumentKind kind, PdfLayout? pdf})? document,
    Uint8List? redactedDocument,
  }) async {
    final dir = _dirFor(await _rootDir(), record.id);
    await dir.create(recursive: true);
    if (document != null) {
      final name = 'source.${document.kind.extension}';
      final target = p.join(dir.path, name);
      if (document.sourcePath != target) {
        await File(document.sourcePath).copy(target);
      }
      await File(p.join(dir.path, 'document.json')).writeAsString(
        jsonEncode({
          'kind': document.kind.name,
          'source': name,
          if (document.pdf != null) 'pdf': document.pdf!.toJson(),
        }),
        flush: true,
      );
      final redacted = File(
        p.join(dir.path, 'redacted.${document.kind.extension}'),
      );
      if (redactedDocument != null) {
        await redacted.writeAsBytes(redactedDocument, flush: true);
      } else if (await redacted.exists()) {
        await redacted.delete();
      }
    }
    await File(p.join(dir.path, 'original.txt'))
        .writeAsString(original, flush: true);
    await File(p.join(dir.path, 'output.txt'))
        .writeAsString(output, flush: true);
    await File(p.join(dir.path, 'detections.json')).writeAsString(
      jsonEncode({
        'detections': [for (final d in detections) d.toJson()],
        'map': jsonDecode(map.toJson()),
      }),
      flush: true,
    );
    // meta.json last: its presence marks the record as complete.
    await File(p.join(dir.path, 'meta.json'))
        .writeAsString(jsonEncode(record.toJson()), flush: true);
  }

  /// Gives a record the name History shows; nothing else changes, not even
  /// its place in the list.
  Future<void> rename(String id, String title) async {
    final file = File(p.join(_dirFor(await _rootDir(), id).path, 'meta.json'));
    final meta = (jsonDecode(await file.readAsString()) as Map)
        .cast<String, Object?>();
    await file.writeAsString(
      jsonEncode({...meta, 'title': title}),
      flush: true,
    );
  }

  Future<void> delete(String id) async {
    final dir = _dirFor(await _rootDir(), id);
    if (await dir.exists()) await dir.delete(recursive: true);
  }

  /// Deletes all but the [keep] most recently updated records.
  Future<void> prune(int keep) async {
    final records = await list();
    for (final record in records.skip(keep)) {
      await delete(record.id);
    }
  }

  Future<void> deleteAll() async {
    final root = await _rootDir();
    if (await root.exists()) await root.delete(recursive: true);
    _root = null;
  }
}
