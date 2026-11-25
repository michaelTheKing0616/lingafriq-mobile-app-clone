import 'package:lingafriq/services/placement/checkpoint_service.dart';

/// Lowest scorer confidence that counts as credential evidence.
///
/// A required scorer result below this, or a missing or non-finite one, issues
/// nothing. This floor is not lowered.
const double minimumScorerConfidence = 0.6;

const String _passportContext = 'passport';

/// Evidence recorded for one passed checkpoint.
///
/// [itemIds], [scores], and [calibrated] are parallel and come from the items.
/// No score in [scores] was filled in after the fact.
class EvidenceRecord {
  const EvidenceRecord({
    required this.unitId,
    required this.itemIds,
    required this.scores,
    required this.calibrated,
    required this.proctored,
  });

  final String unitId;
  final List<String> itemIds;
  final List<double> scores;
  final List<bool> calibrated;
  final bool proctored;
}

/// Proctoring applies only to the Passport, and only with explicit consent.
///
/// Any other [context] returns false, including when [consent] is true.
/// [context] must be exactly `passport`.
bool proctoringRequired(String context, bool consent) {
  return context == _passportContext && consent;
}

/// Computes credential evidence, or null when none may be issued.
///
/// Returns null when the checkpoint has no items, any item is uncalibrated or
/// cites a can-do outside the unit, or any score is missing or non-finite.
/// A scorer-required item also needs an available scorer and a finite
/// confidence of at least [minimumScorerConfidence]. A Passport attempt
/// without explicit consent returns null even when the items would otherwise
/// pass. This function does not store the record and does not invent a score.
EvidenceRecord? issueEvidence({
  required UnitCheckpoint checkpoint,
  required String context,
  required bool consent,
}) {
  return _issueEvidence(
    checkpoint: checkpoint,
    context: context,
    consent: consent,
  );
}

EvidenceRecord? _issueEvidence({
  required UnitCheckpoint checkpoint,
  required String context,
  required bool consent,
}) {
  if (context == _passportContext && !consent) return null;
  if (checkpoint.items.isEmpty) return null;

  final itemIds = <String>[];
  final scores = <double>[];
  final calibrated = <bool>[];
  for (final item in checkpoint.items) {
    if (!item.calibrated) return null;
    if (checkpointRejectionReason(item.canDoIds, checkpoint.unitCanDoIds) !=
        null) {
      return null;
    }
    final score = item.score;
    if (score == null || !score.isFinite) return null;
    if (item.scorerRequired) {
      final confidence = item.confidence;
      if (!item.scorerAvailable || confidence == null || !confidence.isFinite) {
        return null;
      }
      if (confidence < minimumScorerConfidence) return null;
    }
    itemIds.add(item.itemId);
    scores.add(score);
    calibrated.add(item.calibrated);
  }

  return EvidenceRecord(
    unitId: checkpoint.unitId,
    itemIds: List<String>.unmodifiable(itemIds),
    scores: List<double>.unmodifiable(scores),
    calibrated: List<bool>.unmodifiable(calibrated),
    proctored: proctoringRequired(context, consent),
  );
}

/// Holds credential evidence for the caller that constructed it.
///
/// There is no shared instance. One owner cannot read another owner's record.
/// A refused attempt returns null and does not replace a record already kept.
class CredentialEvidenceService {
  EvidenceRecord? _record;

  EvidenceRecord? get record => _record;

  EvidenceRecord? issueEvidence({
    required UnitCheckpoint checkpoint,
    required String context,
    required bool consent,
  }) {
    final issued = _issueEvidence(
      checkpoint: checkpoint,
      context: context,
      consent: consent,
    );
    if (issued == null) return null;
    _record = issued;
    return issued;
  }
}
