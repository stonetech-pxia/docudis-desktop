import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';

import 'package:ffi/ffi.dart';

/// Watches the sockets this process owns, from a background isolate that
/// reads Windows' TCP and UDP tables every few milliseconds, so a test can
/// check that the app opened none.
///
/// A connection that opens and closes between two reads can slip through;
/// the reads are frequent enough to catch anything that waits on a network
/// reply. Loopback listeners already open when watching starts are the
/// Dart VM service the test driver talks to: they, and loopback connections
/// to them, do not count.
class NetworkMonitor {
  NetworkMonitor._(this._isolate, this._replies);

  final Isolate _isolate;
  final StreamIterator<Object?> _replies;

  static Future<NetworkMonitor> start() async {
    if (!Platform.isWindows) {
      throw UnsupportedError('NetworkMonitor reads the Windows socket tables');
    }
    final replies = ReceivePort();
    final isolate = await Isolate.spawn(_watch, (replies.sendPort, pid));
    final monitor = NetworkMonitor._(isolate, StreamIterator(replies));
    // The first reply is the watcher's command port, once it has noted the
    // listeners already open.
    await monitor._replies.moveNext();
    return monitor;
  }

  /// Stops watching and returns every socket seen, one line each.
  Future<List<String>> stop() async {
    (_replies.current! as SendPort).send(null);
    await _replies.moveNext();
    final seen = (_replies.current! as List).cast<String>();
    await _replies.cancel();
    _isolate.kill();
    return seen;
  }
}

Future<void> _watch((SendPort, int) args) async {
  final (results, pid) = args;
  final tables = _SocketTables();
  final allowed = {
    for (final socket in tables.read(pid))
      if (socket.listening && socket.loopback) socket.localPort,
  };
  final commands = ReceivePort();
  results.send(commands.sendPort);
  var stopping = false;
  commands.listen((_) => stopping = true);

  final seen = <String>{};
  while (!stopping) {
    for (final socket in tables.read(pid)) {
      if (socket.loopback && allowed.contains(socket.localPort)) continue;
      seen.add(socket.description);
    }
    await Future<void>.delayed(const Duration(milliseconds: 2));
  }
  results.send(seen.toList()..sort());
}

class _Socket {
  _Socket(
    this.description,
    this.localPort,
    this.loopback, {
    this.listening = false,
  });

  final String description;
  final int localPort;
  final bool listening;

  /// Bound to, and if connected talking to, a loopback address.
  final bool loopback;
}

typedef _GetTableNative = Uint32 Function(
  Pointer<Uint8>,
  Pointer<Uint32>,
  Int32,
  Uint32,
  Int32,
  Uint32,
);
typedef _GetTable = int Function(
  Pointer<Uint8>,
  Pointer<Uint32>,
  int,
  int,
  int,
  int,
);

/// GetExtendedTcpTable / GetExtendedUdpTable from iphlpapi.dll.
class _SocketTables {
  _SocketTables() {
    final iphlpapi = DynamicLibrary.open('iphlpapi.dll');
    _tcp = iphlpapi.lookupFunction<_GetTableNative, _GetTable>(
      'GetExtendedTcpTable',
    );
    _udp = iphlpapi.lookupFunction<_GetTableNative, _GetTable>(
      'GetExtendedUdpTable',
    );
  }

  static const _afInet = 2, _afInet6 = 23;
  static const _tcpTableOwnerPidAll = 5, _udpTableOwnerPid = 1;
  static const _tcpStates = [
    '?', 'CLOSED', 'LISTEN', 'SYN_SENT', 'SYN_RCVD', 'ESTABLISHED', //
    'FIN_WAIT1', 'FIN_WAIT2', 'CLOSE_WAIT', 'CLOSING', 'LAST_ACK',
    'TIME_WAIT', 'DELETE_TCB',
  ];

  late final _GetTable _tcp;
  late final _GetTable _udp;

  List<_Socket> read(int pid) => [
    ..._rows(_tcp, _afInet, _tcpTableOwnerPidAll, 24, (row) {
      if (row.u32(20) != pid) return null;
      return _tcpSocket(
        row.ipv4(4),
        row.port(8),
        row.ipv4(12),
        row.port(16),
        row.u32(0),
      );
    }),
    ..._rows(_tcp, _afInet6, _tcpTableOwnerPidAll, 56, (row) {
      if (row.u32(52) != pid) return null;
      return _tcpSocket(
        row.ipv6(0),
        row.port(20),
        row.ipv6(24),
        row.port(44),
        row.u32(48),
      );
    }),
    ..._rows(_udp, _afInet, _udpTableOwnerPid, 12, (row) {
      if (row.u32(8) != pid) return null;
      return _udpSocket(row.ipv4(0), row.port(4));
    }),
    ..._rows(_udp, _afInet6, _udpTableOwnerPid, 28, (row) {
      if (row.u32(24) != pid) return null;
      return _udpSocket(row.ipv6(0), row.port(20));
    }),
  ];

  _Socket _tcpSocket(
    InternetAddress local,
    int localPort,
    InternetAddress remote,
    int remotePort,
    int state,
  ) {
    final listening = state == 2;
    return _Socket(
      'tcp ${local.address}:$localPort -> '
      '${listening ? '*' : '${remote.address}:$remotePort'} '
      '${state < _tcpStates.length ? _tcpStates[state] : state}',
      localPort,
      local.isLoopback && (listening || remote.isLoopback),
      listening: listening,
    );
  }

  _Socket _udpSocket(InternetAddress local, int localPort) =>
      _Socket('udp ${local.address}:$localPort', localPort, local.isLoopback);

  /// Reads one table and maps each row of [rowSize] bytes.
  List<_Socket> _rows(
    _GetTable get,
    int family,
    int tableClass,
    int rowSize,
    _Socket? Function(_Row row) map,
  ) {
    final size = calloc<Uint32>();
    var buffer = nullptr.cast<Uint8>();
    try {
      // Returns ERROR_INSUFFICIENT_BUFFER (122) with the size needed; the
      // table can grow between the two calls.
      var status = 122;
      while (status == 122) {
        calloc.free(buffer);
        size.value += 1024;
        buffer = calloc<Uint8>(size.value);
        status = get(buffer, size, 0, family, tableClass, 0);
      }
      if (status != 0) throw OSError('reading the socket table', status);
      final count = buffer.cast<Uint32>().value;
      return [
        for (var i = 0; i < count; i++) ?map(_Row(buffer + 4 + i * rowSize)),
      ];
    } finally {
      calloc.free(buffer);
      calloc.free(size);
    }
  }
}

/// One row of a socket table.
extension type _Row(Pointer<Uint8> at) {
  int u32(int offset) => (at + offset).cast<Uint32>().value;

  /// A port: the low 16 bits, in network byte order.
  int port(int offset) {
    final value = u32(offset);
    return (value & 0xff) << 8 | (value >> 8) & 0xff;
  }

  InternetAddress ipv4(int offset) => InternetAddress.fromRawAddress(
    at.asTypedList(offset + 4).sublist(offset),
  );

  InternetAddress ipv6(int offset) => InternetAddress.fromRawAddress(
    at.asTypedList(offset + 16).sublist(offset),
  );
}
