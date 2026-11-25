import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/services/content/pack_updater.dart';

Uint8List _bytes(String text) => Uint8List.fromList(utf8.encode(text));

Map<String, dynamic> _manifest(String version, String objectHash) {
  return {
    'format': 'lingafriq.content_pack.v2',
    'version': version,
    'built_at': '2026-10-26T12:00:00Z',
    'objects': [
      {'stable_id': 'yo.lex.a', 'kind': 'lexeme', 'sha256': objectHash},
    ],
    'blobs': [],
  };
}

InstalledContentPack _installedV1() {
  final payload = {'id': 'yo.lex.a', 'text': 'a'};
  final objectHash = objectContentHash(payload);
  final objectPath = 'objects/$objectHash.json';
  return InstalledContentPack(
    languageCode: 'yo',
    version: '1.0.0',
    manifest: _manifest('1.0.0', objectHash),
    signatureB64: 'sig-v1',
    publicKeyB64: 'pk',
    files: {
      objectPath: _bytes(jsonEncode(payload)),
      'manifest.json': _bytes(jsonEncode(_manifest('1.0.0', objectHash))),
      'signature.txt': _bytes('sig-v1'),
      'public_key.txt': _bytes('pk'),
    },
  );
}

void main() {
  test('applyPackDiff replaces changed object and keeps protected files', () {
    final installed = _installedV1();
    final payloadV2 = {'id': 'yo.lex.a', 'text': 'b'};
    final hashV2 = objectContentHash(payloadV2);
    final pathV2 = 'objects/$hashV2.json';
    final diff = PackDiffHashes(
      added: [hashV2],
      removed: [objectContentHash({'id': 'yo.lex.a', 'text': 'a'})],
      changed: [hashV2],
    );
    final merged = applyPackDiff(
      installed.files,
      diff,
      {pathV2: _bytes(jsonEncode(payloadV2))},
    );
    expect(utf8.decode(merged[pathV2]!), contains('"b"'));
    expect(merged.containsKey('manifest.json'), isTrue);
  });

  test('mergeDiffIntoPack rejects tampered signature', () async {
    final installed = _installedV1();
    final payloadV2 = {'id': 'yo.lex.a', 'text': 'b'};
    final hashV2 = objectContentHash(payloadV2);
    final pathV2 = 'objects/$hashV2.json';
    final download = PackDiffDownload(
      fromVersion: '1.0.0',
      toVersion: '1.0.1',
      diff: PackDiffHashes(added: [hashV2], removed: [], changed: [hashV2]),
      blobs: [
        PackDiffBlob(
          path: pathV2,
          sha256: hashV2,
          data: _bytes(jsonEncode(payloadV2)),
        ),
      ],
      manifest: _manifest('1.0.1', hashV2),
      signatureB64: 'bad-sig',
      publicKeyB64: 'pk',
    );
    final updater = PackUpdater(
      languageCode: 'yo',
      verifySignature: (_, __, ___) => false,
    );
    updater.installPack(installed);
    final result = await updater.applyDiffDownload(download);
    expect(result, isNull);
    expect(updater.state.phase, PackUpdaterPhase.error);
    expect(updater.state.error?.code, 'PACK_SIGNATURE_INVALID');
    expect(updater.installed?.version, '1.0.0');
  });

  test('mergeDiffIntoPack applies verified diff and bumps version', () async {
    final installed = _installedV1();
    final payloadV2 = {'id': 'yo.lex.a', 'text': 'b'};
    final hashV2 = objectContentHash(payloadV2);
    final pathV2 = 'objects/$hashV2.json';
    final download = PackDiffDownload(
      fromVersion: '1.0.0',
      toVersion: '1.0.1',
      diff: PackDiffHashes(added: [hashV2], removed: [], changed: [hashV2]),
      blobs: [
        PackDiffBlob(
          path: pathV2,
          sha256: hashV2,
          data: _bytes(jsonEncode(payloadV2)),
        ),
      ],
      manifest: _manifest('1.0.1', hashV2),
      signatureB64: 'good-sig',
      publicKeyB64: 'pk',
    );
    final updater = PackUpdater(
      languageCode: 'yo',
      verifySignature: (_, __, ___) => true,
    );
    updater.installPack(installed);
    final updated = await updater.applyDiffDownload(download);
    expect(updated?.version, '1.0.1');
    expect(updater.state.phase, PackUpdaterPhase.ready);
    expect(utf8.decode(updated!.files[pathV2]!), contains('"b"'));
  });

  test('interrupted download leaves installed pack unchanged', () async {
    final installed = _installedV1();
    final updater = PackUpdater(
      languageCode: 'yo',
      verifySignature: (_, __, ___) => true,
      fetchDiff: (_, __, ___) async {
        throw PackUpdateError('PACK_DOWNLOAD_FAILED', 'network reset');
      },
    );
    updater.installPack(installed);
    final result = await updater.updateToVersion('1.0.1');
    expect(result, isNull);
    expect(updater.installed?.version, '1.0.0');
    expect(updater.state.error?.code, 'PACK_DOWNLOAD_FAILED');
  });
}
