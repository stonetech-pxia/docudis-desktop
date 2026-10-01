import 'package:docudis_ffi/docudis_ffi.dart';

import 'storage/record_store.dart';

/// A piece of text the user hid by hand in the workspace (what the custom
/// dictionary suggests adding), or showed again by hand (what the never-hide
/// list suggests).
class ManualBlock {
  const ManualBlock({required this.value, required this.documents});

  final String value;

  /// How many of the stored documents it was hidden by hand in.
  final int documents;
}

/// How many distinct blocks the "All" page lists.
const maxManualBlocks = 100;

final _space = RegExp(r'\s+');

String _key(String value) => value.toLowerCase();

/// Same floor as propagation: a two-letter Latin term would match too much,
/// a two-character CJK name is common.
bool _longEnough(String v) =>
    v.length >= 3 || (v.length == 2 && v.codeUnits.any((c) => c > 0x7F));

/// What the user hid by hand in the stored records, most recent document
/// first, one entry per distinct text and at most [limit]. Nothing is stored
/// for this: clearing the records clears the list.
///
/// Left out: text already in [dictionary], text too short to be a safe
/// term, and blocks the user has since brought back.
Future<List<ManualBlock>> recentManualBlocks(
  RecordStore store, {
  required List<String> dictionary,
  int limit = maxManualBlocks,
}) => _recent(
  store,
  (d) => d.source == DetectionSource.manual && d.enabled,
  known: dictionary,
  limit: limit,
);

/// What the user showed again by hand in the stored records, most recent
/// document first: names, places, companies or numbers found and then put
/// back in the workspace. Amounts and dates are readable by default and
/// the user's own dictionary terms are theirs, so neither counts. Text
/// already on the [neverHide] list is left out.
Future<List<ManualBlock>> recentRevealed(
  RecordStore store, {
  required List<String> neverHide,
  int limit = maxManualBlocks,
}) => _recent(
  store,
  (d) =>
      !d.enabled &&
      d.source != DetectionSource.manual &&
      d.source != DetectionSource.dictionary &&
      d.type != EntityType.amount &&
      d.type != EntityType.date,
  known: neverHide,
  limit: limit,
);

Future<List<ManualBlock>> _recent(
  RecordStore store,
  bool Function(Detection) pick, {
  required List<String> known,
  required int limit,
}) async {
  final listed = {for (final term in known) _key(term)};
  final values = <String, String>{};
  final documents = <String, int>{};
  for (final record in await store.list()) {
    final inRecord = <String>{};
    for (final d in await store.detections(record.id)) {
      if (!pick(d)) continue;
      final value = d.value.trim().replaceAll(_space, ' ');
      final key = _key(value);
      if (!_longEnough(value) || listed.contains(key) || !inRecord.add(key)) {
        continue;
      }
      values.putIfAbsent(key, () => value);
      documents[key] = (documents[key] ?? 0) + 1;
    }
  }
  return [
    for (final key in values.keys.take(limit))
      ManualBlock(value: values[key]!, documents: documents[key]!),
  ];
}

/// The few blocks worth putting forward: hidden by hand in the most
/// documents first, the most recent first among equals.
List<ManualBlock> mostRepeated(List<ManualBlock> recent, {int limit = 5}) {
  final order = [for (var i = 0; i < recent.length; i++) i]
    ..sort((a, b) {
      final byCount = recent[b].documents.compareTo(recent[a].documents);
      return byCount != 0 ? byCount : a.compareTo(b);
    });
  return [for (final i in order.take(limit)) recent[i]];
}
