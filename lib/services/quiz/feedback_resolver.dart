/// Post-answer feedback: correct form, optional audio, optional distractor rationale.
class FeedbackInput {
  const FeedbackInput({
    required this.itemId,
    required this.correct,
    required this.correctForm,
    this.audioRef,
    this.rationale,
  });

  final String itemId;
  final bool correct;
  final String correctForm;
  final String? audioRef;
  final String? rationale;
}

class ItemFeedback {
  const ItemFeedback({
    required this.phase,
    required this.correctForm,
    this.audioRef,
    this.rationale,
    required this.flagged,
  });

  final String phase;
  final String correctForm;
  final String? audioRef;
  final String? rationale;
  final bool flagged;
}

/// In-memory validator report; constructed by the caller (not a global singleton).
class RationaleReport {
  final _flagged = <String>{};

  void flag(String itemId) => _flagged.add(itemId);

  bool contains(String itemId) => _flagged.contains(itemId);
}

class FeedbackCopy {
  FeedbackCopy._();

  static const correctForm = 'Correct form';
  static const why = 'Why';
}

String? _keptAudioRef(String? audioRef) {
  if (audioRef == null || audioRef.trim().isEmpty) return null;
  return audioRef;
}

ItemFeedback resolveFeedback(FeedbackInput input, RationaleReport report) {
  final audioRef = _keptAudioRef(input.audioRef);
  final correctForm = input.correctForm;

  if (input.correct) {
    return ItemFeedback(
      phase: 'correct',
      correctForm: correctForm,
      audioRef: audioRef,
      rationale: null,
      flagged: false,
    );
  }

  final rationale = input.rationale;
  if (rationale != null && rationale.trim().isNotEmpty) {
    return ItemFeedback(
      phase: 'wrong',
      correctForm: correctForm,
      audioRef: audioRef,
      rationale: rationale,
      flagged: false,
    );
  }

  report.flag(input.itemId);
  return ItemFeedback(
    phase: 'no-rationale',
    correctForm: correctForm,
    audioRef: audioRef,
    rationale: null,
    flagged: true,
  );
}
