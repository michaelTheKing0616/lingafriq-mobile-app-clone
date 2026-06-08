import 'dart:async';

import 'package:flutter/foundation.dart';

import 'content_schema_validator.dart';
import 'content_schema_versions.dart';

/// Runtime hook that loaders call to validate decoded content against the
/// bundled v2 JSON schemas in `assets/schemas/v2/`.
///
/// In **debug builds** structural defects are surfaced via [debugPrint] and a
/// caller-supplied `onIssue` callback so they show up loudly in the IDE
/// console. In **release builds** the hook is a no-op — production users
/// never pay the validation cost, and we never gate behavior on it. The CI
/// gate (`tool/validate_content_schemas.dart`) is the source of truth for
/// "this commit may not regress content quality".
class ContentValidationHooks {
  ContentValidationHooks._();

  /// Cached parsed schemas (keyed by asset path) so we don't re-decode on
  /// every loader invocation. Validators are immutable and safe to share.
  static final Map<String, Future<ContentSchemaValidator>> _cache = {};

  /// Returns true if runtime validation should execute. Off in release, off
  /// in profile mode, on in debug.
  static bool get isEnabled => kDebugMode;

  /// Loads (and memoizes) a validator for [assetPath].
  static Future<ContentSchemaValidator> _validatorFor(String assetPath) {
    return _cache.putIfAbsent(
      assetPath,
      () => ContentSchemaValidator.loadAsset(assetPath),
    );
  }

  /// Validates [data] against the schema at [assetPath].
  ///
  /// * [label] is a human-readable identifier (e.g. "Yoruba A1 manifest")
  ///   used in log output.
  /// * [onIssue] is invoked once per [SchemaIssue] discovered — wire it to
  ///   `logger.warn` or your structured logger of choice.
  /// * Validation is always best-effort: schema-load failures and other
  ///   internal errors are swallowed so a broken schema cannot crash the
  ///   app at runtime.
  static Future<SchemaValidationResult> validate({
    required String assetPath,
    required dynamic data,
    String label = '',
    void Function(SchemaIssue issue)? onIssue,
  }) async {
    if (!isEnabled) return SchemaValidationResult.ok();
    try {
      final validator = await _validatorFor(assetPath);
      final result = validator.validate(data);
      if (result.issues.isNotEmpty) {
        final tag = label.isEmpty ? assetPath : label;
        debugPrint(
          '[ContentSchema] $tag: ${result.issues.length} issue(s) — '
          'first: ${result.issues.first}',
        );
        if (onIssue != null) {
          for (final issue in result.issues) {
            onIssue(issue);
          }
        }
      }
      return result;
    } catch (e, st) {
      debugPrint('[ContentSchema] validator failed for $assetPath: $e\n$st');
      return SchemaValidationResult.errors(<SchemaIssue>[
        SchemaIssue('', 'validator failure: $e'),
      ]);
    }
  }

  /// Validates a curriculum bundle ([Curriculum.fromMap] input).
  static Future<SchemaValidationResult> validateCurriculumBundle(
    Map<String, dynamic> bundle, {
    String label = '',
  }) =>
      validate(
        assetPath: ContentSchemaVersions.curriculumBundleSchemaPath,
        data: bundle,
        label: label.isEmpty ? 'curriculum bundle' : label,
      );

  /// Validates a per-language content pack manifest.
  static Future<SchemaValidationResult> validateContentPackManifest(
    Map<String, dynamic> manifest, {
    String label = '',
  }) =>
      validate(
        assetPath: ContentSchemaVersions.contentPackManifestSchemaPath,
        data: manifest,
        label: label.isEmpty ? 'content pack manifest' : label,
      );

  /// Validates a game content bundle.
  static Future<SchemaValidationResult> validateGameContent(
    Map<String, dynamic> game, {
    String label = '',
  }) =>
      validate(
        assetPath: ContentSchemaVersions.gameContentSchemaPath,
        data: game,
        label: label.isEmpty ? 'game_content' : label,
      );

  /// Validates the audio manifest.
  static Future<SchemaValidationResult> validateAudioManifest(
    Map<String, dynamic> manifest, {
    String label = '',
  }) =>
      validate(
        assetPath: ContentSchemaVersions.audioManifestSchemaPath,
        data: manifest,
        label: label.isEmpty ? 'audio manifest' : label,
      );

  /// Clears the cached validator for [assetPath] (or all of them). Useful in
  /// tests that load multiple bundles.
  @visibleForTesting
  static void resetCache([String? assetPath]) {
    if (assetPath == null) {
      _cache.clear();
    } else {
      _cache.remove(assetPath);
    }
  }
}
