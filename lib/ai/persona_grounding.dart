// Historical personas may answer culture questions only from cited culture cards
// (CURRICULUM §4 — CP-§4-29, P5-033).

/// A single sourced claim on a v2 culture card.
class CultureCardClaim {
  final String cardId;
  final int index;
  final String kind;
  final String sourceRef;
  final String text;

  const CultureCardClaim({
    required this.cardId,
    required this.index,
    required this.kind,
    required this.sourceRef,
    required this.text,
  });

  String get claimId => '$cardId#$index';
}

/// Parsed culture card used for persona grounding (claims required).
class CitedCultureCard {
  final String id;
  final String title;
  final List<CultureCardClaim> claims;

  const CitedCultureCard({
    required this.id,
    required this.title,
    required this.claims,
  });

  factory CitedCultureCard.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String? ?? '';
    final title = json['title'] as String? ?? '';
    final rawClaims = json['claims'];
    if (id.isEmpty || rawClaims is! List || rawClaims.isEmpty) {
      throw FormatException('CitedCultureCard requires id and non-empty claims');
    }
    final claims = <CultureCardClaim>[];
    for (var i = 0; i < rawClaims.length; i++) {
      final c = rawClaims[i];
      if (c is! Map) {
        throw FormatException('claims[$i] must be a mapping');
      }
      final map = Map<String, dynamic>.from(c);
      final text = map['text'] as String? ?? '';
      final sourceRef = map['source_ref'] as String? ?? '';
      if (text.isEmpty || sourceRef.isEmpty) {
        throw FormatException('claims[$i] requires text and source_ref');
      }
      claims.add(
        CultureCardClaim(
          cardId: id,
          index: i,
          kind: map['kind'] as String? ?? 'cultural',
          sourceRef: sourceRef,
          text: text,
        ),
      );
    }
    return CitedCultureCard(id: id, title: title, claims: claims);
  }
}

/// Claim-level citation exposed with a grounded persona answer.
class ClaimCitation {
  final String claimId;
  final String cardId;
  final String sourceRef;
  final String claimText;
  final String kind;

  const ClaimCitation({
    required this.claimId,
    required this.cardId,
    required this.sourceRef,
    required this.claimText,
    required this.kind,
  });

  factory ClaimCitation.fromClaim(CultureCardClaim claim) {
    return ClaimCitation(
      claimId: claim.claimId,
      cardId: claim.cardId,
      sourceRef: claim.sourceRef,
      claimText: claim.text,
      kind: claim.kind,
    );
  }
}

enum PersonaGroundingStatus { answered, refused }

/// Outcome of grounding a historical persona turn on culture cards only.
class PersonaGroundingOutcome {
  final PersonaGroundingStatus status;
  final String answerText;
  final List<ClaimCitation> citations;

  const PersonaGroundingOutcome({
    required this.status,
    required this.answerText,
    this.citations = const [],
  });

  bool get isRefusal => status == PersonaGroundingStatus.refused;
}

/// Limits historical persona answers to cited culture-card claims (no invention).
class PersonaCultureGrounding {
  PersonaCultureGrounding._();

  /// Shown when [answerFromCitedCards] finds no supporting claim.
  static const String refusalMessage =
      'I do not have a cited source on that in my dossier, so I cannot answer.';

  static List<CitedCultureCard> parseCards(List<Map<String, dynamic>> raw) {
    return raw.map(CitedCultureCard.fromJson).toList(growable: false);
  }

  /// Picks supporting claims from [allowedCards] for [question]; refuses if none match.
  static PersonaGroundingOutcome answerFromCitedCards({
    required String question,
    required List<CitedCultureCard> allowedCards,
  }) {
    final matched = _rankClaims(question, allowedCards);
    if (matched.isEmpty) {
      return const PersonaGroundingOutcome(
        status: PersonaGroundingStatus.refused,
        answerText: refusalMessage,
        citations: [],
      );
    }
    final citations =
        matched.map(ClaimCitation.fromClaim).toList(growable: false);
    final answerText = matched.map((c) => c.text).join(' ');
    return PersonaGroundingOutcome(
      status: PersonaGroundingStatus.answered,
      answerText: answerText,
      citations: citations,
    );
  }

  /// Ensures [answerText] and [citations] use only claims present on [allowedCards].
  static PersonaGroundingOutcome validateGroundedAnswer({
    required String answerText,
    required List<ClaimCitation> citations,
    required List<CitedCultureCard> allowedCards,
  }) {
    final byId = <String, CultureCardClaim>{};
    for (final card in allowedCards) {
      for (final claim in card.claims) {
        byId[claim.claimId] = claim;
      }
    }
    if (citations.isEmpty) {
      return const PersonaGroundingOutcome(
        status: PersonaGroundingStatus.refused,
        answerText: refusalMessage,
      );
    }
    final resolved = <CultureCardClaim>[];
    for (final cite in citations) {
      final claim = byId[cite.claimId];
      if (claim == null ||
          claim.sourceRef != cite.sourceRef ||
          claim.text != cite.claimText) {
        return const PersonaGroundingOutcome(
          status: PersonaGroundingStatus.refused,
          answerText: refusalMessage,
        );
      }
      resolved.add(claim);
    }
    final expected = resolved.map((c) => c.text).join(' ');
    if (answerText.trim() != expected.trim()) {
      return const PersonaGroundingOutcome(
        status: PersonaGroundingStatus.refused,
        answerText: refusalMessage,
      );
    }
    return PersonaGroundingOutcome(
      status: PersonaGroundingStatus.answered,
      answerText: answerText,
      citations: citations,
    );
  }

  static final RegExp _tokenPattern = RegExp(r"[a-z0-9']+", caseSensitive: false);

  static const Set<String> _stopwords = {
    'the',
    'and',
    'for',
    'that',
    'this',
    'with',
    'from',
    'what',
    'when',
    'where',
    'how',
    'why',
    'who',
    'you',
    'your',
    'about',
    'tell',
    'me',
  };

  static List<CultureCardClaim> _rankClaims(
    String question,
    List<CitedCultureCard> allowedCards,
  ) {
    final tokens = _tokens(question);
    if (tokens.isEmpty) return const [];

    final scored = <CultureCardClaim, int>{};
    for (final card in allowedCards) {
      for (final claim in card.claims) {
        final claimTokens = _tokens(claim.text);
        var score = 0;
        for (final t in tokens) {
          if (claimTokens.contains(t)) score++;
        }
        if (score > 0) {
          final prev = scored[claim];
          if (prev == null || score > prev) {
            scored[claim] = score;
          }
        }
      }
    }
    if (scored.isEmpty) return const [];

    final maxScore = scored.values.reduce((a, b) => a > b ? a : b);
    final best = scored.entries
        .where((e) => e.value == maxScore)
        .map((e) => e.key)
        .toList();
    best.sort((a, b) => a.claimId.compareTo(b.claimId));
    return best;
  }

  static Set<String> _tokens(String text) {
    return _tokenPattern
        .allMatches(text.toLowerCase())
        .map((m) => m.group(0)!)
        .where((t) => t.length >= 3 && !_stopwords.contains(t))
        .toSet();
  }
}
