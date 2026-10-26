/// Spiral exposure plan for A1 lexemes (P5-018, CURRICULUM §4).
library;

/// Pedagogical phase for a single lexeme touchpoint in a unit.
enum ExposurePhase {
  input('input'),
  controlledPractice('controlled_practice'),
  speaking('speaking'),
  review('review');

  const ExposurePhase(this.storageValue);
  final String storageValue;

  static ExposurePhase? fromStorage(String? raw) {
    if (raw == null || raw.isEmpty) {
      return null;
    }
    for (final phase in ExposurePhase.values) {
      if (phase.storageValue == raw) {
        return phase;
      }
    }
    return null;
  }
}

/// Minimum exposures per lexeme across units (CURRICULUM §4).
const int kMinSpiralExposures = 6;

/// Ordered phases for the first six spiral touches (two full input cycles).
const List<ExposurePhase> kSpiralExposurePhaseOrder = [
  ExposurePhase.input,
  ExposurePhase.controlledPractice,
  ExposurePhase.speaking,
  ExposurePhase.review,
  ExposurePhase.input,
  ExposurePhase.controlledPractice,
];

abstract final class SpiralPlanCodes {
  static const spiralShortfall = 'SpiralShortfall';
  static const insufficientUnits = 'INSUFFICIENT_UNITS';
  static const phaseOrder = 'PHASE_ORDER';
}

class SpiralPlanFailure implements Exception {
  SpiralPlanFailure(this.code, this.message, {this.lexemeIds = const []});

  final String code;
  final String message;
  final List<String> lexemeIds;

  @override
  String toString() => '$code: $message';
}

class SpiralExposureSlot {
  const SpiralExposureSlot({
    required this.lexemeId,
    required this.unitKey,
    required this.phase,
    required this.sequence,
  });

  final String lexemeId;
  final String unitKey;
  final ExposurePhase phase;
  final int sequence;

  Map<String, Object> toJson() => {
        'lexeme_id': lexemeId,
        'unit_key': unitKey,
        'phase': phase.storageValue,
        'sequence': sequence,
      };

  static SpiralExposureSlot? fromJson(Map<String, dynamic> raw) {
    final lexemeId = raw['lexeme_id'] as String?;
    final unitKey = raw['unit_key'] as String?;
    final phase = ExposurePhase.fromStorage(raw['phase'] as String?);
    final sequence = raw['sequence'];
    if (lexemeId == null || unitKey == null || phase == null || sequence is! int) {
      return null;
    }
    return SpiralExposureSlot(
      lexemeId: lexemeId,
      unitKey: unitKey,
      phase: phase,
      sequence: sequence,
    );
  }
}

/// Plans six unit-spread exposures per lexeme with spiral phase order.
List<SpiralExposureSlot> planLexemeExposures({
  required String lexemeId,
  required int lexemeIndex,
  required List<String> unitKeys,
}) {
  if (unitKeys.length < kMinSpiralExposures) {
    throw SpiralPlanFailure(
      SpiralPlanCodes.insufficientUnits,
      'need at least $kMinSpiralExposures A1 units, got ${unitKeys.length}',
    );
  }
  final slots = <SpiralExposureSlot>[];
  for (var seq = 0; seq < kMinSpiralExposures; seq++) {
    final unitKey = unitKeys[(lexemeIndex + seq) % unitKeys.length];
    slots.add(
      SpiralExposureSlot(
        lexemeId: lexemeId,
        unitKey: unitKey,
        phase: kSpiralExposurePhaseOrder[seq],
        sequence: seq + 1,
      ),
    );
  }
  return slots;
}

Map<String, int> exposureCountsByLexeme(Iterable<SpiralExposureSlot> exposures) {
  final counts = <String, int>{};
  for (final row in exposures) {
    counts[row.lexemeId] = (counts[row.lexemeId] ?? 0) + 1;
  }
  return counts;
}

List<ExposurePhase> phasesForLexeme(
  Iterable<SpiralExposureSlot> exposures,
  String lexemeId,
) {
  final picked = exposures
      .where((row) => row.lexemeId == lexemeId)
      .map((row) => (row.sequence, row.phase))
      .toList();
  picked.sort((a, b) => a.$1.compareTo(b.$1));
  return picked.map((pair) => pair.$2).toList();
}

/// Raises [SpiralPlanFailure] with code [SpiralPlanCodes.spiralShortfall] when under minimum.
void lintSpiralExposures({
  required Iterable<SpiralExposureSlot> exposures,
  required int expectedLexemeCount,
  int minExposures = kMinSpiralExposures,
}) {
  final counts = exposureCountsByLexeme(exposures);
  final shortfall = <String>[];
  for (final entry in counts.entries) {
    if (entry.value < minExposures) {
      shortfall.add(entry.key);
    }
  }
  if (expectedLexemeCount > counts.length) {
    shortfall.add('__missing__${expectedLexemeCount - counts.length}');
  }
  if (shortfall.isNotEmpty) {
    throw SpiralPlanFailure(
      SpiralPlanCodes.spiralShortfall,
      '${shortfall.length} lexeme(s) below $minExposures exposures',
      lexemeIds: shortfall,
    );
  }
  for (final lexemeId in counts.keys) {
    final phases = phasesForLexeme(exposures, lexemeId);
    if (phases.length < 4) {
      continue;
    }
    final head = phases.take(4).toList();
    const expectedHead = [
      ExposurePhase.input,
      ExposurePhase.controlledPractice,
      ExposurePhase.speaking,
      ExposurePhase.review,
    ];
    if (!_phaseListsEqual(head, expectedHead)) {
      throw SpiralPlanFailure(
        SpiralPlanCodes.phaseOrder,
        '$lexemeId: expected input→controlled_practice→speaking→review',
      );
    }
  }
}

bool _phaseListsEqual(List<ExposurePhase> a, List<ExposurePhase> b) {
  if (a.length != b.length) {
    return false;
  }
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) {
      return false;
    }
  }
  return true;
}

Map<String, Object> buildSpiralPlanDocument({
  required String lang,
  required List<String> lexemeIds,
  required List<String> unitKeys,
}) {
  final exposures = <SpiralExposureSlot>[];
  for (var index = 0; index < lexemeIds.length; index++) {
    exposures.addAll(
      planLexemeExposures(
        lexemeId: lexemeIds[index],
        lexemeIndex: index,
        unitKeys: unitKeys,
      ),
    );
  }
  lintSpiralExposures(
    exposures: exposures,
    expectedLexemeCount: lexemeIds.length,
  );
  return {
    'card': 'P5-018',
    'lang': lang,
    'level': 'A1',
    'min_exposures': kMinSpiralExposures,
    'exposure_phases': kSpiralExposurePhaseOrder.map((p) => p.storageValue).toList(),
    'units': unitKeys,
    'lexeme_count': lexemeIds.length,
    'exposures': exposures.map((e) => e.toJson()).toList(),
  };
}
