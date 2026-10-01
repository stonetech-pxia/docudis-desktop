/// What the user handed us: pasted text or a file.
sealed class InputSource {
  const InputSource();
}

/// Text pasted or typed directly.
class TextInput extends InputSource {
  const TextInput(this.text);

  final String text;
}

/// A file picked from disk (txt/md/csv, pdf, docx, or an image).
class FileInput extends InputSource {
  const FileInput({required this.path, required this.name});

  /// Local, readable path.
  final String path;

  /// Display name with extension.
  final String name;

  String get extension {
    final dot = name.lastIndexOf('.');
    return dot == -1 ? '' : name.substring(dot + 1).toLowerCase();
  }
}

/// Thrown when a file type or content cannot be turned into text.
class UnsupportedInputException implements Exception {
  const UnsupportedInputException(this.reason);

  /// Machine-readable reason: `extension`, `empty`, or `ocr` (a picture or
  /// a scanned PDF, which needs text recognition the desktop app does not
  /// have yet).
  final String reason;

  @override
  String toString() => 'UnsupportedInputException($reason)';
}
