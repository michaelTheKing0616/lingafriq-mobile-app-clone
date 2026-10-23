/// A failure the learner can see. It is not a score and it is not a reply.
class LingAfriqFailure implements Exception {
  const LingAfriqFailure(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => message;
}

const pronunciationUnavailable = LingAfriqFailure(
  'pronunciation_unavailable',
  'Pronunciation scoring is unavailable. Nothing was scored.',
);

const personaUnavailable = LingAfriqFailure(
  'persona_unavailable',
  'The persona could not reply. Try again.',
);

const syncNotPersisted = LingAfriqFailure(
  'sync_not_persisted',
  'The write was not stored.',
);
