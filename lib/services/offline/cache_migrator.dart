/// Upgrade policy for cached records.
///
/// A `gcm1` record is kept. Anything else is discarded so the caller rebuilds
/// it. The discarded bytes are not decrypted and are not returned.
class CacheMigration {
  const CacheMigration.kept(this.record) : discarded = false;

  const CacheMigration.discarded()
      : record = null,
        discarded = true;

  final String? record;
  final bool discarded;
}

class CacheMigrator {
  static CacheMigration migrateRecord(String stored) {
    final parts = stored.split(':');
    if (parts.length == 3 &&
        parts[0] == 'gcm1' &&
        parts[1].isNotEmpty &&
        parts[2].isNotEmpty) {
      return CacheMigration.kept(stored);
    }
    return const CacheMigration.discarded();
  }
}
