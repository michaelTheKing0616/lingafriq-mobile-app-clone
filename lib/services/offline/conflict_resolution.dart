// Conflict Resolution - Handles data conflicts during offline sync
// Implements Last-Write-Wins and custom conflict resolution strategies

enum ConflictResolutionStrategy {
  lastWriteWins,
  serverWins,
  clientWins,
  merge,
  manual,
}

class ConflictResolution {
  /// Resolve conflict between local and server data
  static Map<String, dynamic> resolve({
    required Map<String, dynamic> localData,
    required Map<String, dynamic> serverData,
    required ConflictResolutionStrategy strategy,
    DateTime? localTimestamp,
    DateTime? serverTimestamp,
  }) {
    switch (strategy) {
      case ConflictResolutionStrategy.lastWriteWins:
        return _lastWriteWins(
          localData,
          serverData,
          localTimestamp,
          serverTimestamp,
        );
      case ConflictResolutionStrategy.serverWins:
        return serverData;
      case ConflictResolutionStrategy.clientWins:
        return localData;
      case ConflictResolutionStrategy.merge:
        return _merge(localData, serverData);
      case ConflictResolutionStrategy.manual:
        // Return both for manual resolution
        return {
          'local': localData,
          'server': serverData,
          'requires_manual_resolution': true,
        };
    }
  }

  /// Last write wins strategy
  static Map<String, dynamic> _lastWriteWins(
    Map<String, dynamic> local,
    Map<String, dynamic> server,
    DateTime? localTs,
    DateTime? serverTs,
  ) {
    if (localTs == null && serverTs == null) {
      return server; // Default to server if no timestamps
    }
    if (localTs == null) return server;
    if (serverTs == null) return local;
    
    return localTs.isAfter(serverTs) ? local : server;
  }

  /// Merge strategy - combines both datasets
  static Map<String, dynamic> _merge(
    Map<String, dynamic> local,
    Map<String, dynamic> server,
  ) {
    final merged = Map<String, dynamic>.from(server);
    local.forEach((key, value) {
      if (!merged.containsKey(key)) {
        merged[key] = value;
      } else if (value is Map && merged[key] is Map) {
        merged[key] = _merge(
          value as Map<String, dynamic>,
          merged[key] as Map<String, dynamic>,
        );
      }
    });
    return merged;
  }
}

/// Service wrapper for ConflictResolution
class ConflictResolutionService {
  static final ConflictResolutionService _instance = ConflictResolutionService._internal();
  factory ConflictResolutionService() => _instance;
  ConflictResolutionService._internal();

  Future<void> initialize() async {
    // ConflictResolution uses static methods, no initialization needed
  }
}

