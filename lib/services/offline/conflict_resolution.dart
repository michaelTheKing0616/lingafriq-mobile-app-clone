// Conflict Resolution - Handles data conflicts during offline sync
// Implements Last-Write-Wins, learning-aware, and custom strategies.
//
// For learner model data, conflicts are resolved by most recent
// successful recall (learning-aware), not last write wins.

enum ConflictResolutionStrategy {
  lastWriteWins,
  serverWins,
  clientWins,
  merge,
  manual,

  /// Learning-aware: resolves by most recent successful recall,
  /// then by higher mastery, then by more attempts.
  /// Use for learner skill state data.
  learningAware,
}

class ConflictResolution {
  /// Resolve conflict between local and server data.
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
      case ConflictResolutionStrategy.learningAware:
        return _learningAwareResolve(localData, serverData);
      case ConflictResolutionStrategy.manual:
        return {
          'local': localData,
          'server': serverData,
          'requires_manual_resolution': true,
        };
    }
  }

  /// Determines the appropriate strategy for a data type.
  ///
  /// Learning data uses learning-aware resolution.
  /// Other data uses last-write-wins.
  static ConflictResolutionStrategy strategyForDataType(String dataType) {
    switch (dataType) {
      case 'learner_state':
      case 'skill_mastery':
      case 'error_distribution':
      case 'review_schedule':
        return ConflictResolutionStrategy.learningAware;
      case 'progress':
      case 'game_session':
        return ConflictResolutionStrategy.merge;
      case 'profile':
      case 'settings':
        return ConflictResolutionStrategy.lastWriteWins;
      default:
        return ConflictResolutionStrategy.lastWriteWins;
    }
  }

  /// Last write wins strategy.
  static Map<String, dynamic> _lastWriteWins(
    Map<String, dynamic> local,
    Map<String, dynamic> server,
    DateTime? localTs,
    DateTime? serverTs,
  ) {
    if (localTs == null && serverTs == null) {
      return server;
    }
    if (localTs == null) return server;
    if (serverTs == null) return local;

    return localTs.isAfter(serverTs) ? local : server;
  }

  /// Learning-aware conflict resolution.
  ///
  /// Priority order:
  /// 1. Most recent successful recall (learning evidence)
  /// 2. Higher mastery probability
  /// 3. More total attempts (more data)
  /// 4. Most recent practice (fallback)
  static Map<String, dynamic> _learningAwareResolve(
    Map<String, dynamic> local,
    Map<String, dynamic> server,
  ) {
    // Extract learning-specific timestamps
    final localRecall = _parseDateTime(local['lastRecall']);
    final serverRecall = _parseDateTime(server['lastRecall']);

    // 1. Most recent successful recall wins
    if (localRecall != null && serverRecall != null) {
      if (localRecall.isAfter(serverRecall)) return local;
      if (serverRecall.isAfter(localRecall)) return server;
    } else if (localRecall != null) {
      return local;
    } else if (serverRecall != null) {
      return server;
    }

    // 2. Higher mastery
    final localMastery = (local['mastery'] as num?)?.toDouble() ?? 0.0;
    final serverMastery = (server['mastery'] as num?)?.toDouble() ?? 0.0;
    if ((localMastery - serverMastery).abs() > 0.05) {
      return localMastery > serverMastery ? local : server;
    }

    // 3. More attempts (more data points)
    final localAttempts = (local['totalAttempts'] as num?)?.toInt() ?? 0;
    final serverAttempts = (server['totalAttempts'] as num?)?.toInt() ?? 0;
    if (localAttempts != serverAttempts) {
      return localAttempts > serverAttempts ? local : server;
    }

    // 4. Merge error distributions (union of knowledge)
    final merged = Map<String, dynamic>.from(server);
    final localErrors = local['errorDistribution'] as Map<String, dynamic>?;
    final serverErrors = server['errorDistribution'] as Map<String, dynamic>?;
    if (localErrors != null && serverErrors != null) {
      merged['errorDistribution'] = _mergeErrorDistributions(
        localErrors,
        serverErrors,
      );
    }

    // 5. Take the higher half-life (more stable memory)
    final localHL = (local['halfLifeDays'] as num?)?.toDouble() ?? 0;
    final serverHL = (server['halfLifeDays'] as num?)?.toDouble() ?? 0;
    merged['halfLifeDays'] = localHL > serverHL ? localHL : serverHL;

    return merged;
  }

  /// Merges two error distribution vectors.
  /// Takes the maximum rate for each error type (conservative estimate).
  static Map<String, dynamic> _mergeErrorDistributions(
    Map<String, dynamic> local,
    Map<String, dynamic> server,
  ) {
    final localRates = local['rates'] as Map<String, dynamic>? ?? {};
    final serverRates = server['rates'] as Map<String, dynamic>? ?? {};

    final mergedRates = Map<String, dynamic>.from(serverRates);
    for (final entry in localRates.entries) {
      final localRate = (entry.value as num?)?.toDouble() ?? 0;
      final serverRate = (mergedRates[entry.key] as num?)?.toDouble() ?? 0;
      mergedRates[entry.key] = localRate > serverRate ? localRate : serverRate;
    }

    final localObs = (local['totalObservations'] as num?)?.toInt() ?? 0;
    final serverObs = (server['totalObservations'] as num?)?.toInt() ?? 0;

    return {
      'rates': mergedRates,
      'totalObservations': localObs > serverObs ? localObs : serverObs,
    };
  }

  /// Merge strategy — combines both datasets recursively.
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

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (_) {
        return null;
      }
    }
    return null;
  }
}

/// Service wrapper for ConflictResolution.
class ConflictResolutionService {
  static final ConflictResolutionService _instance =
      ConflictResolutionService._internal();
  factory ConflictResolutionService() => _instance;
  ConflictResolutionService._internal();

  Future<void> initialize() async {
    // ConflictResolution uses static methods, no initialization needed
  }
}

