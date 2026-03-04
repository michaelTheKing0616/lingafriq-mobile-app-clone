import 'package:lingafriq/learning/learner_model/learner_model_service.dart';
import 'package:lingafriq/config/api_contract.dart';
import 'package:lingafriq/utils/api_service.dart';

/// Social learning layer that transforms tribes from decorative leaderboards
/// into collaborative learning engines.
///
/// Features:
/// - Peer correction workflows (corrections affect learner state)
/// - Tribe-based recall challenges (shared goals, cooperative)
/// - Asynchronous correction queues
/// - Mentorship matching by proficiency gap
/// - Community sentence review
class PeerLearningService {
  final LearnerModelService _learnerModel;

  PeerLearningService({
    LearnerModelService? learnerModel,
  }) : _learnerModel = learnerModel ?? LearnerModelService.instance;

  String _languageFromSkillId(String skillId) {
    final parts = skillId.split('_');
    if (parts.isEmpty) return 'unknown';
    final language = parts.first.trim().toLowerCase();
    return language.isEmpty ? 'unknown' : language;
  }

  /// Submits a peer correction for another learner's response.
  ///
  /// Corrections from peers with higher mastery carry more weight.
  /// This updates the corrected learner's error distribution.
  Future<PeerCorrectionResult> submitCorrection({
    required String correctorId,
    required String targetLearnerId,
    required String skillId,
    required String originalResponse,
    required String correctedResponse,
    required List<String> errorTypeIds,
    String? explanation,
  }) async {
    // Prefer server-authoritative correction workflow when backend is available.
    try {
      await ApiService.initialize();
      final response = await ApiService.post(
        '/api/learning/corrections',
        data: {
          'learnerId': targetLearnerId,
          'language': _languageFromSkillId(skillId),
          'originalText': originalResponse,
          'correctedText': correctedResponse,
          'correctionType': errorTypeIds.isNotEmpty ? errorTypeIds.first : 'grammar',
          'explanation': explanation ?? 'Peer correction',
          'skillId': skillId,
        },
      );
      if (response.statusCode == 201 || response.statusCode == 200) {
        final payload = response.data;
        final correctionData = payload is Map && payload['id'] != null ? payload : payload;
        return PeerCorrectionResult(
          accepted: true,
          reason: 'Correction synced to community review queue.',
          correctorMasteryDelta: 0.02,
          targetMasteryDelta: -0.05,
          correction: PeerCorrection(
            correctionId: correctionData is Map ? correctionData['_id']?.toString() ?? correctionData['id']?.toString() : null,
            correctorId: correctorId,
            targetLearnerId: targetLearnerId,
            skillId: skillId,
            originalResponse: originalResponse,
            correctedResponse: correctedResponse,
            errorTypeIds: errorTypeIds,
            explanation: explanation,
            timestamp: DateTime.now(),
          ),
        );
      }
    } catch (_) {
      // Fall back to local learner-model logic when offline/unavailable.
    }

    final correctorState = _learnerModel.getState(
      learnerId: correctorId,
      skillId: skillId,
    );
    final targetState = _learnerModel.getState(
      learnerId: targetLearnerId,
      skillId: skillId,
    );

    // Corrections only count if the corrector has higher mastery
    final correctorQualified = correctorState.mastery > targetState.mastery + 0.1;

    if (!correctorQualified) {
      return PeerCorrectionResult(
        accepted: false,
        reason: 'Corrector needs higher mastery than the target learner.',
        correctorMasteryDelta: 0,
        targetMasteryDelta: 0,
      );
    }

    // Update target learner's error distribution
    await _learnerModel.recordAttempt(
      learnerId: targetLearnerId,
      skillId: skillId,
      wasCorrect: false,
      errorTypeIds: errorTypeIds,
    );

    return PeerCorrectionResult(
      accepted: true,
      reason: 'Correction accepted and applied.',
      correctorMasteryDelta: 0.02,
      targetMasteryDelta: -0.05,
      correction: PeerCorrection(
        correctorId: correctorId,
        targetLearnerId: targetLearnerId,
        skillId: skillId,
        originalResponse: originalResponse,
        correctedResponse: correctedResponse,
        errorTypeIds: errorTypeIds,
        explanation: explanation,
        timestamp: DateTime.now(),
      ),
    );
  }

  /// Fetches community correction tasks for moderation/review.
  Future<CommunityCorrectionsPage> fetchCommunityCorrections({
    String? language,
    int limit = 20,
    int page = 1,
  }) async {
    await ApiService.initialize();
    final normalizedLimit = limit < 1 ? 1 : (limit > 100 ? 100 : limit);
    final normalizedPage = page < 1 ? 1 : page;
    final normalizedLanguage = language?.trim();

    final response = await ApiService.get(
      ApiContract.url(ApiContract.learning.corrections),
      queryParameters: {
        'scope': 'community',
        if (normalizedLanguage != null && normalizedLanguage.isNotEmpty)
          'language': normalizedLanguage,
        'limit': normalizedLimit,
        'page': normalizedPage,
      },
    );

    if (response.statusCode != 200 || response.data == null) {
      throw Exception('Failed to fetch community corrections');
    }

    final payload = response.data;
    if (payload is! Map) {
      throw Exception('Unexpected community corrections payload');
    }

    final rawCorrections = payload['corrections'];
    final correctionList = rawCorrections is List ? rawCorrections : const [];
    final items = correctionList
        .whereType<Map>()
        .map((item) => CommunityCorrectionFeedItem.fromJson(
              Map<String, dynamic>.from(item),
            ))
        .toList();

    return CommunityCorrectionsPage(
      corrections: items,
      total: (payload['total'] as num?)?.toInt() ?? items.length,
      page: (payload['page'] as num?)?.toInt() ?? normalizedPage,
      limit: (payload['limit'] as num?)?.toInt() ?? normalizedLimit,
    );
  }

  /// Votes on a correction in the backend community queue.
  Future<CommunityCorrectionFeedItem> voteOnCorrection({
    required String correctionId,
    required bool isUpvote,
  }) async {
    if (correctionId.trim().isEmpty) {
      throw Exception('correctionId is required');
    }

    await ApiService.initialize();
    final response = await ApiService.post(
      ApiContract.url(ApiContract.learning.correctionVote(correctionId)),
      data: {'vote': isUpvote ? 'up' : 'down'},
    );

    if ((response.statusCode != 200 && response.statusCode != 201) ||
        response.data == null) {
      throw Exception('Failed to submit correction vote');
    }

    final payload = response.data;
    if (payload is! Map) {
      throw Exception('Unexpected correction vote payload');
    }
    return CommunityCorrectionFeedItem.fromJson(Map<String, dynamic>.from(payload));
  }

  /// Generates a cooperative recall challenge for a tribe.
  ///
  /// Challenge: each member gets different skills from the same domain.
  /// The tribe succeeds only if ALL members recall their items.
  TribeRecallChallenge generateTribeChallenge({
    required String tribeId,
    required List<String> memberIds,
    required String languageCode,
    int itemsPerMember = 3,
  }) {
    final assignments = <String, List<ChallengeItem>>{};

    for (final memberId in memberIds) {
      final recs = _learnerModel.getRecommendations(
        learnerId: memberId,
        languageCode: languageCode,
        count: itemsPerMember,
      );

      assignments[memberId] = recs.map((r) {
        final state = r.state;
        return ChallengeItem(
          skillId: r.skillId,
          difficulty: state?.mastery ?? 0.5,
          isReview: r.reason == RecommendationReason.dueForReview,
        );
      }).toList();
    }

    // Tribe success threshold: 70% of all items correct
    final totalItems = memberIds.length * itemsPerMember;
    final requiredCorrect = (totalItems * 0.7).ceil();

    return TribeRecallChallenge(
      tribeId: tribeId,
      memberAssignments: assignments,
      requiredCorrect: requiredCorrect,
      totalItems: totalItems,
      expiresAt: DateTime.now().add(const Duration(hours: 24)),
      reward: TribeChallengeReward(
        xpPerMember: 50,
        masteryBonus: 0.03,
        description: 'Tribe Recall Challenge',
      ),
    );
  }

  /// Matches a learner with an optimal mentor.
  ///
  /// Ideal mentor gap: 20-40% mastery above the learner.
  /// Too close = no learning. Too far = no relevance.
  MentorMatch? findMentor({
    required String learnerId,
    required String skillId,
    required List<String> candidateIds,
  }) {
    final learnerState = _learnerModel.getState(
      learnerId: learnerId,
      skillId: skillId,
    );

    MentorMatch? bestMatch;
    double bestScore = 0;

    for (final candidateId in candidateIds) {
      if (candidateId == learnerId) continue;

      final candidateState = _learnerModel.getState(
        learnerId: candidateId,
        skillId: skillId,
      );

      final gap = candidateState.mastery - learnerState.mastery;

      // Ideal gap: 0.2 to 0.4
      if (gap < 0.15 || gap > 0.6) continue;

      final score = 1.0 - ((gap - 0.3).abs() / 0.3);

      if (score > bestScore) {
        bestScore = score;
        bestMatch = MentorMatch(
          mentorId: candidateId,
          learnerId: learnerId,
          skillId: skillId,
          masteryGap: gap,
          matchScore: score,
        );
      }
    }

    return bestMatch;
  }

  /// Creates a community sentence review queue.
  ///
  /// Learners submit sentences, community votes on correctness,
  /// best corrections get highlighted.
  CommunitySentenceReview createReviewItem({
    required String authorId,
    required String skillId,
    required String sentence,
    required String languageCode,
  }) {
    return CommunitySentenceReview(
      id: '${authorId}_${DateTime.now().millisecondsSinceEpoch}',
      authorId: authorId,
      skillId: skillId,
      sentence: sentence,
      languageCode: languageCode,
      corrections: [],
      votes: {},
      createdAt: DateTime.now(),
    );
  }

  /// Submits a vote on a community review.
  void voteOnReview({
    required CommunitySentenceReview review,
    required String voterId,
    required bool isCorrect,
    String? suggestedCorrection,
  }) {
    review.votes[voterId] = isCorrect;
    if (suggestedCorrection != null) {
      review.corrections.add(CommunityCorrection(
        correctorId: voterId,
        suggestion: suggestedCorrection,
        timestamp: DateTime.now(),
      ));
    }
  }
}

// ─── Data classes ──────────────────────────────────────────────────

class PeerCorrectionResult {
  final bool accepted;
  final String reason;
  final double correctorMasteryDelta;
  final double targetMasteryDelta;
  final PeerCorrection? correction;

  const PeerCorrectionResult({
    required this.accepted,
    required this.reason,
    required this.correctorMasteryDelta,
    required this.targetMasteryDelta,
    this.correction,
  });
}

class PeerCorrection {
  final String? correctionId;
  final String correctorId;
  final String targetLearnerId;
  final String skillId;
  final String originalResponse;
  final String correctedResponse;
  final List<String> errorTypeIds;
  final String? explanation;
  final DateTime timestamp;

  const PeerCorrection({
    this.correctionId,
    required this.correctorId,
    required this.targetLearnerId,
    required this.skillId,
    required this.originalResponse,
    required this.correctedResponse,
    required this.errorTypeIds,
    this.explanation,
    required this.timestamp,
  });
}

class TribeRecallChallenge {
  final String tribeId;
  final Map<String, List<ChallengeItem>> memberAssignments;
  final int requiredCorrect;
  final int totalItems;
  final DateTime expiresAt;
  final TribeChallengeReward reward;

  const TribeRecallChallenge({
    required this.tribeId,
    required this.memberAssignments,
    required this.requiredCorrect,
    required this.totalItems,
    required this.expiresAt,
    required this.reward,
  });
}

class ChallengeItem {
  final String skillId;
  final double difficulty;
  final bool isReview;

  const ChallengeItem({
    required this.skillId,
    required this.difficulty,
    required this.isReview,
  });
}

class TribeChallengeReward {
  final int xpPerMember;
  final double masteryBonus;
  final String description;

  const TribeChallengeReward({
    required this.xpPerMember,
    required this.masteryBonus,
    required this.description,
  });
}

class MentorMatch {
  final String mentorId;
  final String learnerId;
  final String skillId;
  final double masteryGap;
  final double matchScore;

  const MentorMatch({
    required this.mentorId,
    required this.learnerId,
    required this.skillId,
    required this.masteryGap,
    required this.matchScore,
  });
}

class CommunitySentenceReview {
  final String id;
  final String authorId;
  final String skillId;
  final String sentence;
  final String languageCode;
  final List<CommunityCorrection> corrections;
  final Map<String, bool> votes;
  final DateTime createdAt;

  CommunitySentenceReview({
    required this.id,
    required this.authorId,
    required this.skillId,
    required this.sentence,
    required this.languageCode,
    required this.corrections,
    required this.votes,
    required this.createdAt,
  });

  double get correctnessScore {
    if (votes.isEmpty) return 0.5;
    final correct = votes.values.where((v) => v).length;
    return correct / votes.length;
  }
}

class CommunityCorrection {
  final String correctorId;
  final String suggestion;
  final DateTime timestamp;

  const CommunityCorrection({
    required this.correctorId,
    required this.suggestion,
    required this.timestamp,
  });
}

class CommunityCorrectionsPage {
  final List<CommunityCorrectionFeedItem> corrections;
  final int total;
  final int page;
  final int limit;

  const CommunityCorrectionsPage({
    required this.corrections,
    required this.total,
    required this.page,
    required this.limit,
  });
}

class CommunityCorrectionFeedItem {
  final String id;
  final String language;
  final String originalText;
  final String correctedText;
  final String status;
  final int upvotes;
  final int downvotes;

  const CommunityCorrectionFeedItem({
    required this.id,
    required this.language,
    required this.originalText,
    required this.correctedText,
    required this.status,
    required this.upvotes,
    required this.downvotes,
  });

  CommunityCorrectionFeedItem copyWith({
    String? id,
    String? language,
    String? originalText,
    String? correctedText,
    String? status,
    int? upvotes,
    int? downvotes,
  }) {
    return CommunityCorrectionFeedItem(
      id: id ?? this.id,
      language: language ?? this.language,
      originalText: originalText ?? this.originalText,
      correctedText: correctedText ?? this.correctedText,
      status: status ?? this.status,
      upvotes: upvotes ?? this.upvotes,
      downvotes: downvotes ?? this.downvotes,
    );
  }

  factory CommunityCorrectionFeedItem.fromJson(Map<String, dynamic> json) {
    return CommunityCorrectionFeedItem(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      language: (json['language'] ?? '').toString(),
      originalText: (json['originalText'] ?? '').toString(),
      correctedText: (json['correctedText'] ?? '').toString(),
      status: (json['status'] ?? 'pending').toString(),
      upvotes: (json['upvotes'] as num?)?.toInt() ?? 0,
      downvotes: (json['downvotes'] as num?)?.toInt() ?? 0,
    );
  }
}
