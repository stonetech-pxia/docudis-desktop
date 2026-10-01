import 'dart:isolate';

import 'package:docudis_ffi/docudis_ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import 'engine/native_libraries.dart';
import 'engine/ner_model.dart';
import 'input/input_source.dart';
import 'input/text_extractor.dart';
import 'output/document_redaction.dart';
import 'storage/anonymization_record.dart';
import 'storage/record_store.dart';

/// Orchestrates extract -> detect -> anonymize -> store, and the later
/// edits (toggle spans, restore replies). Detection, merging and
/// anonymization all run in the Rust core.
class AnonymizeService {
  AnonymizeService({
    required this.store,
    required this.extractor,
    required this.dictionaryTerms,
    required this.neverHideTerms,
    required this.listOnly,
  });

  final RecordStore store;
  final TextExtractor extractor;

  /// Current global dictionary; read at each run.
  final Future<List<String>> Function() dictionaryTerms;

  /// Current never-hide list; read at each run.
  final Future<List<String>> Function() neverHideTerms;

  /// "Hide only this list"; read at each run.
  final bool Function() listOnly;

  Future<NerModel?>? _ner;

  /// Loads the model once. A failure is logged and the model is skipped:
  /// the rules, lists and dictionary still run.
  Future<NerModel?> nerModel() => _ner ??= () async {
    try {
      final model = await NerModel.load();
      debugPrint('[anonymize] NER ready (${model.name})');
      return model;
    } catch (e, st) {
      debugPrint('NER model unavailable, rules only: $e\n$st');
      return null;
    }
  }();

  /// Pre-warms the model so the first run is not slower than the rest.
  Future<void> warmUp() => nerModel();

  static void _log(String stage, Stopwatch sw) =>
      debugPrint('[anonymize] $stage at ${sw.elapsedMilliseconds} ms');

  Future<AnonymizationRecord> process(InputSource source) async {
    final sw = Stopwatch()..start();
    final extraction = await extractor.extract(source);
    final original = extraction.text;
    _log('extracted ${original.length} chars', sw);
    final dictionary = await dictionaryTerms();
    // "Hide only this list": the list alone. An empty list never counts, it
    // would hide nothing.
    final listOnly = this.listOnly() && dictionary.isNotEmpty;
    final ner = listOnly ? null : await nerModel();
    final modelDetections = ner == null
        ? const <Detection>[]
        : await ner.detect(original);
    _log('model found ${modelDetections.length} spans', sw);
    final neverHide = await neverHideTerms();
    final (:detections, :result) = listOnly
        ? await _listOnly(original, dictionary)
        : await _detect(original, modelDetections, dictionary, neverHide);
    _log('detection done (${detections.length} spans)', sw);
    final document = extraction.document;
    final redactedDocument = document == null
        ? null
        : await _redactDocument(
            document.kind,
            document.path,
            document.pdf,
            result,
          );
    if (document != null) _log('${document.kind.name} redacted', sw);
    final now = DateTime.now();
    final record = AnonymizationRecord(
      id: '${now.millisecondsSinceEpoch}',
      createdAt: now,
      updatedAt: now,
      kind: switch (source) {
        TextInput() => InputKind.text,
        FileInput() => InputKind.file,
      },
      sourceName: switch (source) {
        TextInput() => null,
        FileInput(:final name) => name,
      },
      outputFileName: _outputName(source, now),
      detectionCount: detections.where((d) => d.enabled).length,
      preview: _preview(result.text),
      title: source is FileInput ? null : titleFromText(original),
      listOnly: listOnly,
      modelUsed: listOnly || ner != null,
    );
    await store.save(
      record: record,
      original: original,
      output: result.text,
      detections: detections,
      map: result.map,
      document: document == null
          ? null
          : (sourcePath: document.path, kind: document.kind, pdf: document.pdf),
      redactedDocument: redactedDocument,
    );
    await store.prune(maxRecords);
    return record;
  }

  /// Language identification picks the rule packs; the rules, bundled
  /// lists and dictionary then run with the model's spans, and the result
  /// is anonymized. On a background isolate: rules over a long document
  /// take a moment. Static, so the isolate gets only these arguments.
  static Future<({List<Detection> detections, AnonymizedText result})> _detect(
    String text,
    List<Detection> modelDetections,
    List<String> dictionary,
    List<String> neverHide,
  ) => Isolate.run(() {
    final languages = core.languages(text);
    final regions = core.regions(languages, text);
    return core.process(
      text,
      regions: regions,
      dictionary: dictionary,
      neverHide: neverHide,
      includeBundledLists: true,
      detections: modelDetections,
    );
  });

  /// Only the dictionary terms: no rule pack (an empty category selection
  /// leaves out even the universal one), no bundled lists, no model.
  static Future<({List<Detection> detections, AnonymizedText result})>
  _listOnly(String text, List<String> dictionary) => Isolate.run(() {
    final response = core.native.process({
      'text': text,
      'regions': <String>[],
      'selection': {'categories': <String>[]},
      'dictionary': dictionary,
      'never_hide': <String>[],
      'include_bundled_lists': false,
      'detections': <Object?>[],
    });
    List<Map<String, Object?>> rows(String key) => [
      for (final row in response[key]! as List<Object?>)
        (row! as Map).cast<String, Object?>(),
    ];
    return (
      detections: [for (final d in rows('detections')) Detection.fromJson(d)],
      result: AnonymizedText(
        text: response['text']! as String,
        map: PlaceholderMap([
          for (final e in rows('mappings')) MappingEntry.fromJson(e),
        ]),
        replacements: [
          for (final r in rows('replacements'))
            (
              start: r['start']! as int,
              end: r['end']! as int,
              placeholder: r['placeholder']! as String,
            ),
        ],
      ),
    );
  });

  /// The redacted copy of a PDF or Word file, or null when it cannot be
  /// made: the record then hands out its text, as a `.txt`.
  static Future<Uint8List?> _redactDocument(
    DocumentKind kind,
    String sourcePath,
    PdfLayout? pdf,
    AnonymizedText result,
  ) async {
    try {
      return await redactDocument(
        kind: kind,
        sourcePath: sourcePath,
        pdf: pdf,
        result: result,
      );
    } catch (e, st) {
      debugPrint('Redacted ${kind.name} unavailable, text only: $e\n$st');
      return null;
    }
  }

  /// Records kept on this computer; the oldest go first.
  static const maxRecords = 100;

  /// Re-generates the output after the user enabled/disabled spans or added
  /// a manual one. Updates the record in place.
  Future<RecordDetail> reapply(String id, List<Detection> detections) async {
    final detail = await store.load(id);
    final merged = core.merge(detail.original, detections);
    final result = core.anonymize(
      detail.original,
      merged,
      previous: detail.map,
    );
    final document = detail.document;
    final redactedDocument = document == null
        ? null
        : await _redactDocument(
            document.kind,
            document.sourcePath,
            document.pdf,
            result,
          );
    final record = AnonymizationRecord(
      id: detail.record.id,
      createdAt: detail.record.createdAt,
      updatedAt: DateTime.now(),
      kind: detail.record.kind,
      sourceName: detail.record.sourceName,
      outputFileName: detail.record.outputFileName,
      detectionCount: merged.where((d) => d.enabled).length,
      preview: _preview(result.text),
      title: detail.record.title,
      listOnly: detail.record.listOnly,
      modelUsed: detail.record.modelUsed,
    );
    await store.save(
      record: record,
      original: detail.original,
      output: result.text,
      detections: merged,
      map: result.map,
      document: document == null
          ? null
          : (
              sourcePath: document.sourcePath,
              kind: document.kind,
              pdf: document.pdf,
            ),
      redactedDocument: redactedDocument,
    );
    return store.load(id);
  }

  /// A span the user selected by hand in the original text.
  Detection manualDetection(
    String original,
    int start,
    int end,
    EntityType type,
  ) => Detection(
    type: type,
    value: original.substring(start, end),
    start: start,
    end: end,
    confidence: 1,
    detector: 'manual',
    source: DetectionSource.manual,
  );

  /// Puts real values back into text (an AI reply) that contains this
  /// record's placeholders. Not stored.
  Future<String> restore(String id, String text) async {
    final detail = await store.load(id);
    return core.restore(text, detail.map);
  }

  static String _outputName(InputSource source, DateTime now) {
    if (source is FileInput) {
      final dot = source.name.lastIndexOf('.');
      final base = dot == -1 ? source.name : source.name.substring(0, dot);
      return '$base-anonymized.txt';
    }
    return 'docudis-${DateFormat('yyyyMMdd-HHmm').format(now)}.txt';
  }

  static String _preview(String text) {
    final flat = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    return flat.length <= 120 ? flat : '${flat.substring(0, 120)}…';
  }
}
