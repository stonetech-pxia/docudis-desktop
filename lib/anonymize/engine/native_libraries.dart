import 'dart:io';

import 'package:docudis_ffi/docudis_ffi.dart';
import 'package:docudis_ner_ffi/docudis_ner_ffi.dart';
import 'package:path/path.dart' as p;

/// Where the app's own native libraries are: in `Contents/Frameworks` of
/// the macOS bundle (copied there by the Xcode build from
/// `build/native/macos`, see tool/prepare_native.sh), next to the `.exe` on
/// Windows, where the loader looks first.
abstract final class NativeLibraries {
  static String get core => _bundled(DocudisNative.defaultLibraryName);

  static String get ner => _bundled(DocudisNerNative.defaultLibraryName);

  static String get onnxRuntime =>
      _bundled(Platform.isWindows ? 'onnxruntime.dll' : 'libonnxruntime.dylib');

  static String _bundled(String name) => Platform.isMacOS
      ? p.join(
          p.dirname(p.dirname(Platform.resolvedExecutable)),
          'Frameworks',
          name,
        )
      : name;
}

DocudisCore? _core;

/// The Rust core, opened once per isolate.
DocudisCore get core => _core ??= DocudisCore.open(NativeLibraries.core);
