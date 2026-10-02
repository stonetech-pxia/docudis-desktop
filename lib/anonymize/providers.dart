import 'dart:convert';
import 'dart:io';

import 'package:docudis_ffi/docudis_ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../preferences.dart';
import 'anonymize_service.dart';
import 'input/input_source.dart';
import 'input/text_extractor.dart';
import 'manual_blocks.dart';
import 'storage/anonymization_record.dart';
import 'storage/record_store.dart';

/// The folder for the app's own files (`<app support>`); tests point it
/// at a temporary one.
final appSupportDirectoryProvider = FutureProvider<Directory>(
  (ref) => getApplicationSupportDirectory(),
);

/// A list of terms, newest first, kept in `<app support>/<fileName>` like
/// the records, and left alone by "Clear data on this device".
abstract class TermListNotifier extends AsyncNotifier<List<String>> {
  @protected
  String get fileName;

  @override
  Future<List<String>> build() => read();

  Future<File> _file() async => File(
    p.join((await ref.read(appSupportDirectoryProvider.future)).path, fileName),
  );

  @protected
  Future<List<String>> read() async {
    final file = await _file();
    if (!await file.exists()) return const [];
    return (jsonDecode(await file.readAsString()) as List<dynamic>)
        .cast<String>();
  }

  @protected
  Future<void> write(List<String> terms) async =>
      (await _file()).writeAsString(jsonEncode(terms), flush: true);

  Future<void> add(String term) async {
    final t = term.trim();
    final terms = await future;
    if (t.isEmpty || terms.contains(t)) return;
    state = AsyncData([t, ...terms]);
    await write(state.requireValue);
  }

  Future<void> remove(String term) async {
    final terms = await future;
    state = AsyncData(terms.where((t) => t != term).toList());
    await write(state.requireValue);
  }
}

/// The custom dictionary ("Always hide"): text hidden in every document.
///
/// "Hide only this list" never outlives an empty list: taking the last word
/// off switches it off, and so does the first word added to an empty list,
/// so it never comes back on without the user asking for it again.
class DictionaryNotifier extends TermListNotifier {
  @override
  String get fileName => 'dictionary.json';

  @override
  Future<void> add(String term) async {
    if ((await future).isEmpty) {
      await ref.read(listOnlyProvider.notifier).set(false);
    }
    await super.add(term);
  }

  @override
  Future<void> remove(String term) async {
    await super.remove(term);
    if (state.requireValue.isEmpty) {
      await ref.read(listOnlyProvider.notifier).set(false);
    }
  }
}

final dictionaryProvider =
    AsyncNotifierProvider<DictionaryNotifier, List<String>>(
      DictionaryNotifier.new,
    );

const _listOnlyKey = 'list_only';

/// "Hide only this list": a run with a non-empty dictionary then uses the
/// list alone, without the model, the rules or the bundled lists. Off by
/// default; kept in SharedPreferences.
class ListOnlyNotifier extends Notifier<bool> {
  @override
  bool build() =>
      ref.watch(sharedPreferencesProvider).getBool(_listOnlyKey) ?? false;

  Future<void> set(bool on) async {
    state = on;
    await ref.read(sharedPreferencesProvider).setBool(_listOnlyKey, on);
  }
}

final listOnlyProvider = NotifierProvider<ListOnlyNotifier, bool>(
  ListOnlyNotifier.new,
);

/// "Never hide": public names left readable in every document.
class NeverHideNotifier extends TermListNotifier {
  @override
  String get fileName => 'never_hide.json';
}

final neverHideProvider =
    AsyncNotifierProvider<NeverHideNotifier, List<String>>(
      NeverHideNotifier.new,
    );

final recordStoreProvider = Provider<RecordStore>((ref) => RecordStore());

final anonymizeServiceProvider = Provider<AnonymizeService>((ref) {
  return AnonymizeService(
    store: ref.watch(recordStoreProvider),
    extractor: TextExtractor(),
    dictionaryTerms: () => ref.read(dictionaryProvider.future),
    neverHideTerms: () => ref.read(neverHideProvider.future),
    listOnly: () => ref.read(listOnlyProvider),
  );
});

/// The loaded NER models' names ("xlm-roberta-base-ner-docudis +
/// openai-privacy-filter"); null when there is none and only rules and
/// lists run.
final nerNameProvider = FutureProvider<String?>((ref) async {
  final model = await ref.watch(anonymizeServiceProvider).nerModel();
  return model?.name.replaceAll('ner:', '');
});

/// The record open in the workspace; null for a new, empty document.
/// History and the recent list open records here.
class OpenRecordNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void open(String id) => state = id;

  void close() => state = null;
}

final openRecordProvider = NotifierProvider<OpenRecordNotifier, String?>(
  OpenRecordNotifier.new,
);

/// History list, newest first. Invalidate after any write.
final recordsProvider = FutureProvider<List<AnonymizationRecord>>(
  (ref) => ref.watch(recordStoreProvider).list(),
);

/// What the user hid by hand lately and has not put in the dictionary yet.
/// Follows the records, so it refreshes after an edit or a clear.
final manualBlocksProvider = FutureProvider<List<ManualBlock>>((ref) async {
  final store = ref.watch(recordStoreProvider);
  final records = ref.watch(recordsProvider.future);
  final dictionary = ref.watch(dictionaryProvider.future);
  await records;
  return recentManualBlocks(store, dictionary: await dictionary);
});

/// What the user showed again by hand lately and has not put on the
/// never-hide list yet.
final revealedBlocksProvider = FutureProvider<List<ManualBlock>>((ref) async {
  final store = ref.watch(recordStoreProvider);
  final records = ref.watch(recordsProvider.future);
  final neverHide = ref.watch(neverHideProvider.future);
  await records;
  return recentRevealed(store, neverHide: await neverHide);
});

final recordDetailProvider = FutureProvider.family<RecordDetail, String>(
  (ref, id) => ref.watch(recordStoreProvider).load(id),
);

/// Every record's sent text and key, to tell which record a pasted AI reply
/// answers ([DocudisCore.replyCheck]). Built when the restore page opens.
final replyCandidatesProvider =
    FutureProvider.autoDispose<Map<String, ReplyCandidate>>((ref) async {
      final store = ref.watch(recordStoreProvider);
      final records = await ref.watch(recordsProvider.future);
      final candidates = <String, ReplyCandidate>{};
      for (final record in records) {
        try {
          final (:output, :map) = await store.outputAndKey(record.id);
          candidates[record.id] = ReplyCandidate(output: output, map: map);
        } on Exception catch (e) {
          // Unreadable or half-deleted: the others still count.
          debugPrint('Record ${record.id} left out of the reply check: $e');
        }
      }
      return candidates;
    });

/// Runs one input through the service. Result = the new record id.
class ProcessController extends Notifier<AsyncValue<String?>> {
  @override
  AsyncValue<String?> build() => const AsyncData(null);

  Future<String?> run(InputSource source) async {
    if (state.isLoading) return null;
    state = const AsyncLoading();
    final next = await AsyncValue.guard(
      () => ref.read(anonymizeServiceProvider).process(source),
    );
    state = next.whenData((r) => r.id);
    if (next.hasValue) ref.invalidate(recordsProvider);
    return next.value?.id;
  }

  void reset() => state = const AsyncData(null);
}

final processControllerProvider =
    NotifierProvider<ProcessController, AsyncValue<String?>>(
      ProcessController.new,
    );

/// Toggling spans on the review page. Every tap saves, so a request that
/// arrives while one is running replaces it instead of being dropped.
class ReviewController extends Notifier<AsyncValue<void>> {
  List<Detection>? _pending;
  bool _running = false;

  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<void> apply(String id, List<Detection> detections) async {
    _pending = detections;
    if (_running) return;
    _running = true;
    state = const AsyncLoading();
    while (_pending != null) {
      final next = _pending!;
      _pending = null;
      state = await AsyncValue.guard(() async {
        await ref.read(anonymizeServiceProvider).reapply(id, next);
      });
      ref.invalidate(recordDetailProvider(id));
      ref.invalidate(recordsProvider);
    }
    _running = false;
  }
}

final reviewControllerProvider =
    NotifierProvider<ReviewController, AsyncValue<void>>(ReviewController.new);
