import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:docudis_ffi/docudis_ffi.dart';
import 'package:docudis_ner_ffi/docudis_ner_ffi.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'native_libraries.dart';

/// Every installed NER model. Each one runs on the whole text; the core
/// merges their spans with the rules' (`detections` of the v1 request).
class NerModels {
  NerModels._(this.models);

  /// Model folders under `<app support>/models`, each holding `model.json`
  /// and the files it names (installed by tool/fetch_models.sh for now).
  static const folders = ['xlmr_ner_docudis', 'openai_privacy_filter'];

  final List<NerModel> models;

  /// Loads every installed model. A missing folder is skipped; throws when
  /// none is installed or one fails to load.
  static Future<NerModels> load() async {
    final support = await getApplicationSupportDirectory();
    final models = <NerModel>[];
    for (final folder in folders) {
      final dir = p.join(support.path, 'models', folder);
      if (!await File(p.join(dir, 'model.json')).exists()) continue;
      models.add(await NerModel.load(dir));
    }
    if (models.isEmpty) {
      throw StateError('no NER model under ${p.join(support.path, 'models')}');
    }
    return NerModels._(models);
  }

  /// `ner:<name>` of each model, joined with ` + `.
  String get name => models.map((m) => m.name).join(' + ');

  /// Every model's detections in [text], in UTF-16 offsets.
  Future<List<Detection>> detect(String text) async => [
    for (final model in models) ...await model.detect(text),
  ];
}

/// One NER model, through the Rust docudis-ner library and ONNX Runtime.
///
/// Loaded once into native memory and identified by its address; loading
/// and inference run on background isolates so the window keeps drawing.
class NerModel {
  NerModel._(this.name, this._address);

  /// Loads the model in [dir], or throws when it cannot be loaded.
  static Future<NerModel> load(String dir) async {
    final specJson = await File(p.join(dir, 'model.json')).readAsString();
    final spec = (jsonDecode(specJson) as Map).cast<String, Object?>();
    final modelPath = p.join(dir, spec['model']! as String);
    final tokenizerPath = p.join(
      dir,
      (spec['tokenizer']! as Map)['file']! as String,
    );
    final library = NativeLibraries.ner;
    final onnxRuntime = NativeLibraries.onnxRuntime;
    final address = await Isolate.run(
      () => DocudisNerNative.open(library)
          .load(
            onnxRuntimeLibrary: onnxRuntime,
            spec: spec,
            modelPath: modelPath,
            tokenizerPath: tokenizerPath,
          )
          .address,
    );
    return NerModel._('ner:${spec['name']}', address);
  }

  final String name;
  final int _address;

  /// The model's detections in [text], in UTF-16 offsets.
  Future<List<Detection>> detect(String text) async {
    final address = _address;
    final library = NativeLibraries.ner;
    final found = await Isolate.run(
      () => DocudisNerNative.open(library).model(address).detect(text),
    );
    return [for (final json in found) Detection.fromJson(json)];
  }
}
