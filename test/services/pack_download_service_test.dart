import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/content/language_pack_access.dart';
import 'package:lingafriq/content/language_pack_catalog.dart';
import 'package:lingafriq/services/pack_download_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tmp;
  late List<int> hausaBytes;
  late LanguagePackCatalog catalog;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('pack_dl_');
    final repoRoot = Directory.current.path.contains('lingafriq-mobile-app-clone')
        ? Directory.current.path
        : '${Directory.current.path}/lingafriq-mobile-app-clone';
    final hausaFile = File('$repoRoot/assets/data/cms_manifests/2/manifest.json');
    hausaBytes = await hausaFile.readAsBytes();
    final digest = sha256.convert(hausaBytes).toString();
    catalog = LanguagePackCatalog(
      schemaVersion: 1,
      chunkBytes: 65536,
      coreLanguageIds: ['1'],
      languages: [
        const LanguagePackEntry(
          id: '1',
          languageKey: 'yoruba',
          displayName: 'Yoruba',
          bundled: true,
        ),
        LanguagePackEntry(
          id: '2',
          languageKey: 'hausa',
          displayName: 'Hausa',
          bundled: false,
          packUrl: 'https://cdn.test/hausa.manifest',
          sha256: digest,
          sizeBytes: hausaBytes.length,
        ),
      ],
    );
  });

  tearDown(() async {
    if (await tmp.exists()) {
      await tmp.delete(recursive: true);
    }
  });

  PackDownloadService service({
    required PackChunkFetcher fetcher,
    int maxRetries = 3,
  }) {
    return PackDownloadService(
      packRoot: tmp,
      maxRetries: maxRetries,
      chunkFetcher: fetcher,
      catalogLoader: () async => catalog,
    );
  }

  test('catalog parse and sha256 helper', () {
    final cat = LanguagePackCatalog.parse('''
{"schemaVersion":1,"chunkBytes":1024,"coreLanguageIds":["1"],"languages":[]}
''');
    expect(cat.chunkBytes, 1024);
    expect(sha256HexOfBytes(utf8.encode('a')), isNotEmpty);
  });

  test('offline fresh install: core bundled, hausa notDownloaded with empty lessons',
      () async {
    final svc = service(
      fetcher: (_, __, ___) async =>
          PackChunkResponse(bytes: [], totalSize: 0),
    );
    expect(
      await svc.availabilityFor('yoruba'),
      LanguagePackAvailability.bundled,
    );

    final access = LanguagePackAccess(svc);
    final missing = await access.snapshotFor('hausa');
    expect(missing.status, LanguagePackAvailability.notDownloaded);
    expect(missing.lessons, isEmpty);
  });

  test('resume completes after simulated network drop', () async {
    var calls = 0;
    final fetcher = (String url, int offset, int length) async {
      calls++;
      if (calls == 1) {
        final first = hausaBytes.sublist(0, hausaBytes.length ~/ 2);
        return PackChunkResponse(
          bytes: first,
          totalSize: hausaBytes.length,
        );
      }
      if (calls == 2) {
        throw const SocketException('network reset');
      }
      final rest = hausaBytes.sublist(hausaBytes.length ~/ 2);
      return PackChunkResponse(bytes: rest, totalSize: hausaBytes.length);
    };

    final svc = service(fetcher: fetcher, maxRetries: 4);
    await svc.downloadPack('hausa');
    expect(await svc.availabilityFor('hausa'),
        LanguagePackAvailability.installed);

    final access = LanguagePackAccess(svc);
    final snap = await access.snapshotFor('hausa');
    expect(snap.lessons.length, greaterThan(10));
  });

  test('checksum mismatch purges pack and surfaces retry', () async {
    final bad = List<int>.from(hausaBytes)..[0] = (hausaBytes[0] + 1) % 256;
    final fetcher = (_, __, ___) async => PackChunkResponse(
          bytes: bad,
          totalSize: bad.length,
        );
    final svc = service(fetcher: fetcher);
    expect(
      () => svc.downloadPack('hausa'),
      throwsA(
        predicate((e) =>
            e is PackDownloadError && e.code == 'PACK_CHECKSUM_MISMATCH'),
      ),
    );
    expect(await svc.availabilityFor('hausa'),
        LanguagePackAvailability.notDownloaded);
  });

  test('retries exhausted yields PackDownloadError', () async {
    final svc = service(
      fetcher: (_, __, ___) async {
        throw const SocketException('down');
      },
      maxRetries: 2,
    );
    expect(
      () => svc.downloadPack('hausa'),
      throwsA(
        predicate((e) =>
            e is PackDownloadError && e.code == 'PACK_RETRIES_EXHAUSTED'),
      ),
    );
  });

  test('installed pack opens offline without fetcher', () async {
    final fetcher = (_, offset, length) async {
      final end = (offset + length).clamp(0, hausaBytes.length);
      return PackChunkResponse(
        bytes: hausaBytes.sublist(offset, end),
        totalSize: hausaBytes.length,
      );
    };
    final svc = service(fetcher: fetcher);
    await svc.downloadPack('hausa');

    final offline = PackDownloadService(
      packRoot: tmp,
      catalogLoader: () async => catalog,
      chunkFetcher: (_, __, ___) async {
        throw StateError('network should not be used');
      },
    );
    final manifest = await offline.loadInstalledOrBundledManifest('hausa');
    expect(manifest?['totalLessons'], greaterThan(20));
  });
}
