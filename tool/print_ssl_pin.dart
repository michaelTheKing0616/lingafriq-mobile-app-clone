// Print TLS leaf certificate DER SHA-256 pins for a host.
//
// Usage:
//   dart run tool/print_ssl_pin.dart admin.lingafriq.com 443
//
// Output pins are formatted exactly as expected by `CERTIFICATE_PIN_HASHES`:
//   sha256/<base64(sha256(der))>
//
// Notes:
// - This matches the app's pinning implementation in `lib/utils/certificate_pinning.dart`.
// - For safe rotation, compute pins for BOTH the current cert and the upcoming cert, then
//   set `CERTIFICATE_PIN_HASHES` as a comma-separated list before the server switches.

import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

Future<void> main(List<String> args) async {
  if (args.isEmpty || args.length > 2) {
    stderr.writeln('Usage: dart run tool/print_ssl_pin.dart <host> [port]');
    exitCode = 64;
    return;
  }

  final host = args[0].trim();
  if (host.isEmpty) {
    stderr.writeln('Host is required.');
    exitCode = 64;
    return;
  }

  final port = args.length == 2 ? int.tryParse(args[1].trim()) ?? 443 : 443;

  final socket = await SecureSocket.connect(
    host,
    port,
    onBadCertificate: (_) => true, // allow inspection even if chain validation fails locally
  );

  try {
    final leaf = socket.peerCertificate;
    if (leaf == null) {
      stderr.writeln('No peer certificate received.');
      exitCode = 1;
      return;
    }

    final der = leaf.der;
    final digest = sha256.convert(der);
    final b64 = base64.encode(digest.bytes);
    final pin = 'sha256/$b64';

    stdout.writeln('host=$host port=$port');
    stdout.writeln('subject=${leaf.subject}');
    stdout.writeln('issuer=${leaf.issuer}');
    stdout.writeln('startValidity=${leaf.startValidity}');
    stdout.writeln('endValidity=${leaf.endValidity}');
    stdout.writeln('CERTIFICATE_PIN_HASHES=$pin');
  } finally {
    await socket.close();
  }
}
