/// Centralized constants for content schema versioning.
///
/// Bumping any of these constants triggers cache invalidation in the loaders
/// that consume them (e.g. [CurriculumService], [GameScenarioLoader],
/// [ContentPackService]).
class ContentSchemaVersions {
  ContentSchemaVersions._();

  /// Current major version of all content shipped under `assets/data` and
  /// served by the backend `/content-packs` endpoint.
  static const int currentSchemaVersion = 2;

  /// Minimum schema version the app will still read without forcing a
  /// re-download from the backend. Below this, loaders MUST refuse the bundle
  /// and request a fresh copy.
  static const int minimumSchemaVersion = 1;

  /// Bundled v4 curriculum semver. Bump when assets change so caches refresh.
  static const String curriculumBundleVersion = '4.0.0';

  /// Bundled game content semver.
  static const String gameContentBundleVersion = '2.0.0';

  /// Audio manifest semver.
  static const String audioManifestVersion = '2.0.0';

  /// Asset paths to the canonical JSON Schemas (used by the offline validator
  /// in debug builds and by `tool/validate_content_schemas.dart` in CI).
  static const String contentPackManifestSchemaPath =
      'schemas/v2/content_pack_manifest.schema.json';
  static const String curriculumBundleSchemaPath =
      'schemas/v2/curriculum_bundle.schema.json';
  static const String gameContentSchemaPath =
      'schemas/v2/game_content.schema.json';
  static const String audioManifestSchemaPath =
      'schemas/v2/audio_manifest.schema.json';

  /// Returns true when [version] is compatible with the current major.
  static bool isAccepted(int version) =>
      version >= minimumSchemaVersion && version <= currentSchemaVersion;
}
