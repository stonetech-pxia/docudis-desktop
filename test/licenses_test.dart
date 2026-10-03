import 'package:docudis/licenses.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'the licenses page lists the native libraries and bundled files',
    () async {
      registerBundledLicenses();
      final packages = <String>{
        await for (final entry in LicenseRegistry.licenses) ...entry.packages,
      };
      expect(
        packages,
        containsAll([
          'docudis-core',
          'docudis-ner',
          'ort',
          'lingua',
          'ONNX Runtime',
          'PDFium',
          'Docudis name-recognition model',
          'Sora font',
          'Karla font',
        ]),
      );
    },
  );
}
