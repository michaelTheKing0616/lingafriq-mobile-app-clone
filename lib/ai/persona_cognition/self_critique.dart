// Self-critique result types — evaluation runs on the gateway (P6-018).

class SelfCritiqueResult {
  final bool passedCritique;
  final String? revisedReply;
  final List<String> issues;

  const SelfCritiqueResult({
    required this.passedCritique,
    this.revisedReply,
    this.issues = const [],
  });
}
