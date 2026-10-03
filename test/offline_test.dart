// Docudis must never talk to the network. These checks stop code that
// could from creeping in; integration_test/flow_test.dart checks that the
// running app opens no socket on Windows.

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

/// Dart code that reaches the network, or hands a URL to something that
/// does.
final _networkApi = RegExp(
  r'''import\s+['"](package:(http|http2|dio|grpc|web_socket|web_socket_channel)/|dart:html)'''
  r'|\b(HttpClient|HttpServer|RawSocket|RawSecureSocket|RawServerSocket|SecureSocket|SecureServerSocket|ServerSocket|RawDatagramSocket|WebSocket)\s*[.(]'
  r'|\bSocket\s*\.\s*(connect|startConnect)'
  r'|\bInternetAddress\s*\.\s*lookup'
  r'|\b(openUri|launchUrl|launchUrlString|createHttpClient)\b',
);

/// The app's own files that may use [_networkApi], and why.
const _reviewedAppFiles = {
  'lib/home/settings_page.dart':
      'opens the privacy policy and contact links in the browser',
};

/// Dependencies whose code matches [_networkApi], and why that is fine.
/// A package not listed here fails the test: review it before adding it.
const _reviewedPackages = {
  'http': 'only reached through pdfrx openUri, which the app never calls',
  'pdfrx': 'passes openUri on to pdfrx_engine; the app opens files',
  'pdfrx_engine': 'downloads only in PdfDocument.openUri; the app opens files',
  'url_launcher': 'hands links to the browser; only the settings page does',
  'url_launcher_platform_interface': 'url_launcher',
  'url_launcher_windows': 'url_launcher',
  'url_launcher_macos': 'url_launcher',
  'url_launcher_linux': 'url_launcher',
  'url_launcher_android': 'url_launcher',
  'url_launcher_ios': 'url_launcher',
  'url_launcher_web': 'url_launcher',
  'pdfium_dart':
      'its build hook downloads PDFium at build time, not in the app',
  'package_info_plus': 'only its web implementation fetches version.json',
  'flutter': 'NetworkImage and asset bundles; the app loads neither',
  'sky_engine': 'the Dart SDK itself (dart:io, dart:html)',
  'web': 'browser APIs; not compiled into the Windows or macOS app',
  'dbus': 'Linux only',
  'flutter_test': 'tests only',
  'flutter_driver': 'tests only',
  'integration_test': 'tests only',
  'fuchsia_remote_debug_protocol': 'tests only',
  'vm_service': 'tests only',
  'webdriver': 'tests only',
  'package_config': 'tests only',
};

/// Crates that exist to talk to the network.
const _networkCrates = {
  'reqwest', 'hyper', 'ureq', 'curl', 'isahc', 'attohttpc', 'surf', 'h2', //
  'quinn', 'tungstenite', 'native-tls', 'rustls', 'openssl', 'hf-hub',
};

/// Windows libraries that open sockets or speak HTTP.
const _networkDlls = {
  'ws2_32.dll', 'wsock32.dll', 'mswsock.dll', 'winhttp.dll', 'wininet.dll', //
  'urlmon.dll', 'dnsapi.dll', 'iphlpapi.dll', 'websocket.dll', 'webio.dll',
  'httpapi.dll',
};

/// Bundled binaries that link [_networkDlls], and why.
const _reviewedBinaries = {
  'flutter_windows.dll':
      "the Flutter engine's dart:io; the Dart code checks above cover its use",
};

/// [source] without comments, which often show network code as examples.
String _code(String source) => source
    .replaceAll(RegExp(r'/\*.*?\*/', dotAll: true), '')
    .replaceAll(RegExp(r'^\s*//.*$', multiLine: true), '');

bool _usesNetwork(File file) =>
    _networkApi.hasMatch(_code(file.readAsStringSync()));

Iterable<File> _dartFiles(String dir) =>
    Directory(dir)
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'));

void main() {
  test('the app code uses no network API', () {
    final found = [
      for (final dir in ['lib', 'packages/docudis_pdf/lib'])
        for (final file in _dartFiles(dir))
          if (_usesNetwork(file)) p.posix.joinAll(p.split(file.path)),
    ];
    expect(found.toSet(), _reviewedAppFiles.keys.toSet());
  });

  test('every dependency with network code has been reviewed', () {
    final config = File('.dart_tool/package_config.json');
    final packages = (jsonDecode(config.readAsStringSync())['packages'] as List)
        .cast<Map<String, Object?>>();
    final found = <String>{};
    for (final package in packages) {
      final name = package['name']! as String;
      if (name == 'docudis' || name == 'docudis_pdf') continue;
      var root = config.uri.resolve(package['rootUri']! as String);
      if (!root.path.endsWith('/')) root = root.replace(path: '${root.path}/');
      final lib = Directory.fromUri(
        root.resolve(package['packageUri'] as String? ?? 'lib/'),
      );
      if (!lib.existsSync()) continue;
      if (_dartFiles(lib.path).any(_usesNetwork)) found.add(name);
    }
    expect(found.difference(_reviewedPackages.keys.toSet()), isEmpty);
  });

  test('the native libraries pull in no network crate', () {
    final lock = jsonDecode(File('tool/native.lock.json').readAsStringSync());
    final cargoLocks = [
      for (final (name, key) in [
        ('docudis-core', 'docudis_core'),
        ('docudis-ner', 'docudis_ner'),
      ])
        File(
          'build/native-cache/src/$name-${lock[key]['revision']}/Cargo.lock',
        ),
    ].where((f) => f.existsSync()).toList();
    if (cargoLocks.isEmpty) {
      markTestSkipped('no sources: run tool/prepare_native.sh (.ps1)');
      return;
    }
    final crates = {
      for (final file in cargoLocks)
        for (final m in RegExp(
          r'^name = "(.+)"$',
          multiLine: true,
        ).allMatches(file.readAsStringSync()))
          m[1]!,
    };
    expect(crates.intersection(_networkCrates), isEmpty);
  });

  test('no bundled Windows binary links a network library', () {
    final binaries = _windowsBinaries();
    if (binaries.isEmpty) {
      markTestSkipped('no Windows build: run tool/prepare_native.ps1');
      return;
    }
    final found = <String, Set<String>>{};
    for (final file in binaries) {
      final name = p.basename(file.path).toLowerCase();
      final network = peImports(file.readAsBytesSync())
          .intersection(_networkDlls);
      if (network.isNotEmpty && !_reviewedBinaries.containsKey(name)) {
        found[name] = network;
      }
    }
    expect(found, isEmpty);
  });

  // Windows uploads ETW events only from providers in Microsoft's telemetry
  // group. The official ONNX Runtime joins it; a build with --no_telemetry
  // (tool/prepare_native.ps1) does not.
  test('no bundled Windows binary joins the Microsoft telemetry group', () {
    final binaries = _windowsBinaries();
    if (binaries.isEmpty) {
      markTestSkipped('no Windows build: run tool/prepare_native.ps1');
      return;
    }
    expect([
      for (final file in binaries)
        if (_contains(file.readAsBytesSync(), _telemetryGroup))
          p.basename(file.path),
    ], isEmpty);
  });
}

/// {4f50731a-89cf-4782-b3e0-dce8c90476ba}, Microsoft's telemetry provider
/// group, as it is laid out in memory.
const _telemetryGroup = [
  0x1a, 0x73, 0x50, 0x4f, 0xcf, 0x89, 0x82, 0x47, //
  0xb3, 0xe0, 0xdc, 0xe8, 0xc9, 0x04, 0x76, 0xba,
];

/// The DLLs and executables of the Windows build that exist.
List<File> _windowsBinaries() => [
  for (final dir in [
    'build/native/windows',
    'build/windows/x64/runner/Release',
    'build/windows/x64/runner/Debug',
  ])
    if (Directory(dir).existsSync())
      ...Directory(dir)
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.dll') || f.path.endsWith('.exe')),
];

bool _contains(Uint8List bytes, List<int> pattern) {
  for (
    var at = bytes.indexOf(pattern.first);
    at >= 0 && at <= bytes.length - pattern.length;
    at = bytes.indexOf(pattern.first, at + 1)
  ) {
    var i = 1;
    while (i < pattern.length && bytes[at + i] == pattern[i]) {
      i++;
    }
    if (i == pattern.length) return true;
  }
  return false;
}

/// The DLLs a PE file imports, lower-cased, delay-loaded ones included.
Set<String> peImports(Uint8List bytes) {
  final data = ByteData.sublistView(bytes);
  int u16(int at) => data.getUint16(at, Endian.little);
  int u32(int at) => data.getUint32(at, Endian.little);

  final pe = u32(0x3c);
  final sections = u16(pe + 6);
  final optional = pe + 24;
  final directories = optional + (u16(optional) == 0x20b ? 112 : 96);
  final sectionTable = optional + u16(pe + 20);

  int offset(int rva) {
    for (var i = 0; i < sections; i++) {
      final s = sectionTable + i * 40;
      final start = u32(s + 12);
      final size = u32(s + 8) > u32(s + 16) ? u32(s + 8) : u32(s + 16);
      if (rva >= start && rva < start + size) return rva - start + u32(s + 20);
    }
    throw FormatException('RVA $rva is outside every section');
  }

  String name(int rva) {
    final start = offset(rva);
    final end = bytes.indexOf(0, start);
    return ascii.decode(bytes.sublist(start, end)).toLowerCase();
  }

  final names = <String>{};
  // Import table: 20-byte descriptors, the DLL name's RVA at 12.
  final imports = u32(directories + 8);
  if (imports != 0) {
    for (var at = offset(imports); u32(at + 12) != 0; at += 20) {
      names.add(name(u32(at + 12)));
    }
  }
  // Delay-load table: 32-byte descriptors, the DLL name's RVA at 4.
  final delayed = u32(directories + 13 * 8);
  if (delayed != 0) {
    for (var at = offset(delayed); u32(at + 4) != 0; at += 32) {
      names.add(name(u32(at + 4)));
    }
  }
  return names;
}
