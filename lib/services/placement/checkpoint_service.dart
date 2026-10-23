/// Unit checkpoint assembly.
///
/// An item is kept only when its can-do ids are a non-empty subset of the
/// unit's can-do statements. Anything else is omitted and reported. Calibration
/// and scoring are decided later, when credential evidence is issued.
library;

/// One checkpoint item and the can-dos it claims to measure.
class CheckpointItem {
  const CheckpointItem({
    required this.itemId,
    required this.canDoIds,
    required this.calibrated,
    required this.score,
    required this.confidence,
    required this.scorerRequired,
    required this.scorerAvailable,
  });

  final String itemId;
  final List<String> canDoIds;
  final bool calibrated;

  /// A score already produced by a real grader or scorer. Never invented here.
  final double? score;

  /// Scorer confidence, present only when a scorer actually returned one.
  final double? confidence;
  final bool scorerRequired;
  final bool scorerAvailable;
}

/// A unit checkpoint whose items all map onto [unitCanDoIds].
class UnitCheckpoint {
  const UnitCheckpoint({
    required this.unitId,
    required this.unitCanDoIds,
    required this.items,
  });

  final String unitId;
  final List<String> unitCanDoIds;
  final List<CheckpointItem> items;
}

/// An item [buildCheckpoint] refused to put on the unit.
class CheckpointRejection {
  const CheckpointRejection({
    required this.itemId,
    required this.canDoIds,
    required this.reason,
  });

  /// The item cited no can-do, so it does not map the unit.
  static const String emptyCanDos = 'empty_can_dos';

  /// At least one cited can-do is not one of the unit's can-dos.
  static const String outsideUnit = 'outside_unit';

  final String itemId;
  final List<String> canDoIds;
  final String reason;
}

/// A built checkpoint plus every item that was left out.
class CheckpointBuild {
  const CheckpointBuild({required this.checkpoint, required this.rejected});

  final UnitCheckpoint checkpoint;
  final List<CheckpointRejection> rejected;
}

/// Why [canDoIds] cannot sit on a unit that teaches [unitCanDoIds].
///
/// An empty list is refused even though it is a mathematical subset: an item
/// with no can-do does not map the unit. Null means every id belongs to the unit.
String? checkpointRejectionReason(
  List<String> canDoIds,
  List<String> unitCanDoIds,
) {
  if (canDoIds.isEmpty) return CheckpointRejection.emptyCanDos;
  final allowed = unitCanDoIds.toSet();
  for (final canDoId in canDoIds) {
    if (!allowed.contains(canDoId)) return CheckpointRejection.outsideUnit;
  }
  return null;
}

CheckpointItem _copyItem(CheckpointItem item) {
  return CheckpointItem(
    itemId: item.itemId,
    canDoIds: List<String>.unmodifiable(item.canDoIds),
    calibrated: item.calibrated,
    score: item.score,
    confidence: item.confidence,
    scorerRequired: item.scorerRequired,
    scorerAvailable: item.scorerAvailable,
  );
}

/// Builds a checkpoint from [items], keeping input order.
///
/// Items whose can-dos are empty or not a subset of [unitCanDoIds] are omitted
/// and listed on [CheckpointBuild.rejected]. Uncalibrated items that do map are
/// kept; issuing evidence is what refuses them.
CheckpointBuild buildCheckpoint({
  required String unitId,
  required List<String> unitCanDoIds,
  required List<CheckpointItem> items,
}) {
  final kept = <CheckpointItem>[];
  final rejected = <CheckpointRejection>[];
  for (final item in items) {
    final reason = checkpointRejectionReason(item.canDoIds, unitCanDoIds);
    if (reason != null) {
      rejected.add(
        CheckpointRejection(
          itemId: item.itemId,
          canDoIds: List<String>.unmodifiable(item.canDoIds),
          reason: reason,
        ),
      );
      continue;
    }
    kept.add(_copyItem(item));
  }
  return CheckpointBuild(
    checkpoint: UnitCheckpoint(
      unitId: unitId,
      unitCanDoIds: List<String>.unmodifiable(unitCanDoIds),
      items: List<CheckpointItem>.unmodifiable(kept),
    ),
    rejected: List<CheckpointRejection>.unmodifiable(rejected),
  );
}
