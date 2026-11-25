import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/services/network/pinning_client.dart';

void main() {
  const current = 'sha256/currentpin';
  const next = 'sha256/nextpin';

  test('a leaf that matches neither pin fails with certificate_pin_mismatch', () {
    expect(
      () => LeafPinCheck.allows(pins: const [current, next], leafPin: 'sha256/other', host: 'lingafriq.com'),
      throwsA(
        isA<CertificatePinException>().having((error) => error.toString(), 'code', CertificatePinException.code),
      ),
    );
  });

  test('the backup pin keeps the connection open after the primary rotates', () {
    expect(
      LeafPinCheck.allows(pins: const [current, next], leafPin: next, host: 'lingafriq.com'),
      isTrue,
    );
    expect(
      LeafPinCheck.allows(pins: const [current, next], leafPin: current, host: 'lingafriq.com'),
      isTrue,
    );
  });

  test('no configured pin leaves the connection open', () {
    expect(
      LeafPinCheck.allows(pins: LeafPinCheck.parsePins(''), leafPin: 'sha256/other', host: 'lingafriq.com'),
      isTrue,
    );
    expect(LeafPinCheck.parsePins(' $current , $next '), [current, next]);
  });
}
