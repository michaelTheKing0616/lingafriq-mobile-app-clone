import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

String leafDerSha256Pin(List<int> derBytes) {
  final digest = sha256.convert(derBytes);
  return 'sha256/${base64.encode(digest.bytes)}';
}

void main() {
  test('leaf DER pin matches known SHA-256 base64 format', () {
    const der = <int>[0x30, 0x03, 0x01, 0x01, 0x01]; // tiny fake DER fragment
    final pin = leafDerSha256Pin(der);

    expect(pin, startsWith('sha256/'));
    final b64 = pin.substring('sha256/'.length);
    expect(() => base64.decode(b64), returnsNormally);
  });
}
