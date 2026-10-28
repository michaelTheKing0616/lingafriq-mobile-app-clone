/// Local SQLite schema is newer than this app build understands.
class SchemaNewerThanAppException implements Exception {
  const SchemaNewerThanAppException({
    required this.storedVersion,
    required this.appVersion,
  });

  final int storedVersion;
  final int appVersion;

  @override
  String toString() =>
      'schema_newer_than_app: stored=$storedVersion app=$appVersion';
}
