import 'package:flutter/material.dart';

/// Ordered local-data migrations. A failed step restores the snapshot
/// taken before the run and leaves the stored schema version unchanged.
class SchemaMigrationFailure implements Exception {
  final String code;
  final int fromVersion;
  final int toVersion;
  final Object cause;

  const SchemaMigrationFailure({
    required this.code,
    required this.fromVersion,
    required this.toVersion,
    required this.cause,
  });

  String get recoveryMessage =>
      'Local data could not move from schema $fromVersion to $toVersion. Your saved data was left unchanged.';

  @override
  String toString() => '$code: $recoveryMessage ($cause)';
}

abstract class SchemaStore {
  int get schemaVersion;
  Future<void> setSchemaVersion(int version);
  Map<String, Object?> snapshot();
  Future<void> restore(Map<String, Object?> snapshot);
}

class LocalSchemaMigrator {
  const LocalSchemaMigrator({
    required this.targetVersion,
    required this.steps,
  });

  final int targetVersion;
  final Map<int, Future<void> Function(SchemaStore store)> steps;

  Future<void> migrate(SchemaStore store) async {
    final original = store.snapshot();
    final start = store.schemaVersion;
    var version = start;
    try {
      while (version < targetVersion) {
        final next = version + 1;
        final step = steps[next];
        if (step == null) {
          throw StateError('missing migration to schema $next');
        }
        await step(store);
        version = next;
        await store.setSchemaVersion(version);
      }
    } catch (error) {
      try {
        await store.restore(original);
        await store.setSchemaVersion(start);
      } catch (restoreError) {
        throw SchemaMigrationFailure(
          code: 'schema_migration_failed',
          fromVersion: start,
          toVersion: targetVersion,
          cause: restoreError,
        );
      }
      throw SchemaMigrationFailure(
        code: 'schema_migration_failed',
        fromVersion: start,
        toVersion: targetVersion,
        cause: error,
      );
    }
  }
}

class SchemaRecoveryApp extends StatelessWidget {
  const SchemaRecoveryApp({super.key, required this.failure});

  final SchemaMigrationFailure failure;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(failure.code, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                Text(failure.recoveryMessage),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
