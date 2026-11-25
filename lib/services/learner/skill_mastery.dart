import 'mastery_event.dart';

/// Beta-Binomial estimate for one skill.
///
/// The starting prior is Beta(1, 1). [mean] is `alpha / (alpha + beta)`.
class SkillMastery {
  const SkillMastery({
    required this.skillId,
    required this.alpha,
    required this.beta,
  });

  final String skillId;
  final double alpha;
  final double beta;

  double get mean => alpha / (alpha + beta);
}

/// On-device per-skill mastery.
///
/// Updates run in memory from [MasteryEvent] only. This type does not call
/// the network and does not store age, an advertising identifier, or a
/// marketing profile.
class SkillMasteryModel {
  static const double priorAlpha = 1;
  static const double priorBeta = 1;
  static const double _slowResponseSeconds = 30;
  static const double _slowResponseBeta = 0.25;

  static const Set<String> _forbiddenRecordKeys = {
    'advertisingid',
    'adid',
    'marketing',
    'profile',
    'email',
    'name',
    'age',
  };

  final Map<String, SkillMastery> _bySkill = {};

  /// Folds [event] into the skill it names.
  ///
  /// An unknown skill starts at the prior. [MasteryEvent.sessionLengthSeconds]
  /// is left on the event and does not change alpha or beta.
  ///
  /// Throws [ArgumentError] when the skill id is empty.
  void update(MasteryEvent event) {
    final skillId = _requireSkillId(event.skillId);
    final current =
        _bySkill[skillId] ??
        SkillMastery(skillId: skillId, alpha: priorAlpha, beta: priorBeta);
    var alpha = current.alpha;
    var beta = current.beta;

    final correct = event.correct;
    if (correct == true) {
      alpha += 1;
    } else if (correct == false) {
      beta += 1;
    }

    if (event.hintUsed) {
      beta += 1;
    }

    final pronunciation = _unitScore(event.pronunciationScore);
    if (pronunciation != null) {
      alpha += pronunciation;
      beta += 1 - pronunciation;
    }
    final tone = _unitScore(event.toneScore);
    if (tone != null) {
      alpha += tone;
      beta += 1 - tone;
    }

    final responseTime = event.responseTimeSeconds;
    if (responseTime != null && responseTime > _slowResponseSeconds) {
      beta += _slowResponseBeta;
    }

    if (event.droppedOff) {
      beta += 1;
    }

    _bySkill[skillId] = SkillMastery(
      skillId: skillId,
      alpha: alpha,
      beta: beta,
    );
  }

  /// Current estimate. A skill that has never been updated returns the prior.
  ///
  /// Throws [ArgumentError] when [skillId] is empty.
  SkillMastery estimate(String skillId) {
    final id = _requireSkillId(skillId);
    return _bySkill[id] ??
        SkillMastery(skillId: id, alpha: priorAlpha, beta: priorBeta);
  }

  /// Sets every stored skill back to alpha 1, beta 1.
  void reset() {
    final ids = _bySkill.keys.toList();
    for (final skillId in ids) {
      _bySkill[skillId] = SkillMastery(
        skillId: skillId,
        alpha: priorAlpha,
        beta: priorBeta,
      );
    }
  }

  /// Skill estimates for storage.
  ///
  /// When [under16] is true the map is skill id, alpha, beta, and mean only.
  /// Age is not stored. Session length is not copied into this record.
  /// The same skill-only shape is returned when [under16] is false, because
  /// this model has no advertising identifier or marketing profile.
  ///
  /// Throws [StateError] when [under16] is true and the record is not
  /// skill estimates only.
  Map<String, Object?> toRecord({required bool under16}) {
    final skills = <Map<String, Object?>>[
      for (final skill in _estimatesInOrder())
        <String, Object?>{
          'skillId': skill.skillId,
          'alpha': skill.alpha,
          'beta': skill.beta,
          'mean': skill.mean,
        },
    ];
    final record = <String, Object?>{'skills': skills};
    if (under16) {
      _ensureSkillEstimatesOnly(record);
    }
    return record;
  }

  Iterable<SkillMastery> _estimatesInOrder() {
    final ids = _bySkill.keys.toList()..sort();
    return [for (final id in ids) _bySkill[id]!];
  }

  String _requireSkillId(String skillId) {
    if (skillId.isEmpty) {
      throw ArgumentError.value(skillId, 'skillId', 'Skill id is required');
    }
    return skillId;
  }

  /// A finite score in [0, 1]. Null, non-finite, and out-of-range scores are
  /// ignored. They are not replaced with 0.5.
  double? _unitScore(double? score) {
    if (score == null || !score.isFinite || score < 0 || score > 1) {
      return null;
    }
    return score;
  }

  void _ensureSkillEstimatesOnly(Map<String, Object?> record) {
    const allowedTop = {'skills'};
    const allowedSkill = {'skillId', 'alpha', 'beta', 'mean'};
    if (record.length != 1 || !record.keys.every(allowedTop.contains)) {
      throw StateError('Under-16 mastery record must be skill estimates only');
    }
    final skills = record['skills'];
    if (skills is! List<Map<String, Object?>>) {
      throw StateError('Under-16 mastery record must list skill estimates');
    }
    for (final skill in skills) {
      if (skill.length != allowedSkill.length ||
          !skill.keys.every(allowedSkill.contains)) {
        throw StateError('Under-16 skill estimate has an unexpected field');
      }
      if (skill['skillId'] is! String) {
        throw StateError('Under-16 skill estimate is missing its skill id');
      }
    }
    _rejectForbiddenKeys(record);
  }

  void _rejectForbiddenKeys(Object? node) {
    if (node is Map) {
      for (final entry in node.entries) {
        final key = entry.key;
        if (key is String && _forbiddenRecordKeys.contains(key.toLowerCase())) {
          throw StateError('Mastery record cannot contain $key');
        }
        _rejectForbiddenKeys(entry.value);
      }
      return;
    }
    if (node is List) {
      for (final item in node) {
        _rejectForbiddenKeys(item);
      }
    }
  }
}
