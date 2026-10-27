import 'package:lingafriq/content/language_pack_catalog.dart';
import 'package:lingafriq/services/pack_download_service.dart';

/// Learner-visible pack state plus lesson list policy (P12-003 AC1).
class LanguagePackSnapshot {
  const LanguagePackSnapshot({
    required this.entry,
    required this.status,
    required this.lessons,
    this.retryAfterChecksumFailure = false,
  });

  final LanguagePackEntry entry;
  final LanguagePackAvailability status;
  final List<Map<String, dynamic>> lessons;
  final bool retryAfterChecksumFailure;

  bool get isReadyForOfflineLessons =>
      status == LanguagePackAvailability.bundled ||
      status == LanguagePackAvailability.installed;
}

/// Resolves CMS lessons from bundled core or an on-disk downloaded pack.
class LanguagePackAccess {
  LanguagePackAccess(this._downloads);

  final PackDownloadService _downloads;

  Future<LanguagePackSnapshot> snapshotFor(String languageKey) async {
    final entry = await _downloads.entryForLanguage(languageKey);
    if (entry == null) {
      throw PackDownloadError('PACK_UNKNOWN_LANGUAGE', languageKey);
    }
    final status = await _downloads.availabilityFor(languageKey);
    if (status == LanguagePackAvailability.notDownloaded ||
        status == LanguagePackAvailability.downloading ||
        status == LanguagePackAvailability.checksumFailed) {
      return LanguagePackSnapshot(
        entry: entry,
        status: status,
        lessons: const [],
        retryAfterChecksumFailure:
            status == LanguagePackAvailability.checksumFailed,
      );
    }
    final manifest = await _downloads.loadInstalledOrBundledManifest(languageKey);
    final lessons = _lessonsFromManifest(manifest);
    return LanguagePackSnapshot(
      entry: entry,
      status: status,
      lessons: lessons,
    );
  }

  static List<Map<String, dynamic>> _lessonsFromManifest(
    Map<String, dynamic>? manifest,
  ) {
    final lessons = manifest?['lessons'];
    if (lessons is! List) return [];
    return lessons
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }
}
