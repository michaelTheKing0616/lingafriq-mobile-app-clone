import 'dart:convert';
import 'dart:io';

import 'package:encrypt/encrypt.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/services/offline/cache_encryption.dart';
import 'package:lingafriq/services/offline/cache_migrator.dart';

void main() {
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  test('gcm round trip uses a fresh nonce and verifies the tag', () async {
    const secret = 'yoruba-cache-secret';
    final first = await CacheEncryption.encrypt(secret);
    final second = await CacheEncryption.encrypt(secret);

    expect(first.startsWith('gcm1:'), isTrue);
    expect(first.split(':')[1], isNot(second.split(':')[1]));
    expect(await CacheEncryption.decrypt(first), secret);
    expect(await CacheEncryption.decrypt(second), secret);
  });

  test('a flipped ciphertext bit throws and returns no data', () async {
    const secret = 'do-not-return-this';
    final stored = await CacheEncryption.encrypt(secret);
    final parts = stored.split(':');
    final bytes = base64Decode(parts[2]);
    bytes[0] = bytes[0] ^ 0x01;
    final tampered = '${parts[0]}:${parts[1]}:${base64Encode(bytes)}';

    Object? thrown;
    try {
      await CacheEncryption.decrypt(tampered);
    } catch (error) {
      thrown = error;
    }

    expect(thrown, isA<CacheIntegrityException>());
    expect((thrown as CacheIntegrityException).code, 'cache_integrity_failed');
    expect(thrown.toString().contains(secret), isFalse);
  });

  test('a legacy record is discarded and never returned', () async {
    const secret = 'legacy-plaintext';
    final key = Key.fromSecureRandom(32);
    final iv = IV.fromSecureRandom(16);
    final legacy = Encrypter(AES(key)).encrypt(secret, iv: iv);
    final stored = '${iv.base64}:${legacy.base64}';

    final migration = CacheMigrator.migrateRecord(stored);
    expect(migration.discarded, isTrue);
    expect(migration.record, isNull);

    await expectLater(
      CacheEncryption.decrypt(stored),
      throwsA(
        isA<CacheIntegrityException>().having(
          (error) => error.toString().contains(secret),
          'hides the old payload',
          isFalse,
        ),
      ),
    );
  });

  test('the cache encryption file does not select the package default mode', () {
    final source = File('lib/services/offline/cache_encryption.dart').readAsStringSync();
    expect(source.contains('AESMode.gcm'), isTrue);
    expect(source.contains('AESMode.sic'), isFalse);
    expect(source.contains('AESMode.ctr'), isFalse);
    expect(source.contains('SIC'), isFalse);
    expect(source.contains('CTR'), isFalse);
  });
}
