import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/ai/pedagogy/error_classifier.dart';
import 'package:lingafriq/learning/core/bkt_mastery.dart';
import 'package:lingafriq/learning/core/hlr_forgetting_curve.dart';
import 'package:lingafriq/learning/game_integration/learning_game.dart';
import 'package:lingafriq/learning/learner_model/error_taxonomy.dart';
import 'package:lingafriq/learning/learner_model/learner_model_service.dart';
import 'package:lingafriq/learning/learner_model/learner_skill_state.dart';
import 'package:lingafriq/learning/learning_engine.dart';
import 'package:lingafriq/learning/pronunciation/persona_pronunciation_service.dart';
import 'package:lingafriq/learning/pronunciation/phoneme_alignment.dart';
import 'package:lingafriq/learning/pronunciation/pronunciation_pipeline.dart';
import 'package:lingafriq/learning/scheduling/difficulty_predictor.dart';
import 'package:lingafriq/learning/scheduling/review_scheduler.dart';
import 'package:lingafriq/learning/skill_graph/dependency_graph.dart';
import 'package:lingafriq/learning/skill_graph/skill_node.dart';
import 'package:lingafriq/learning/skill_graph/skill_registry.dart';
import 'package:shared_preferences/shared_preferences.dart';

SkillNode _skill(String id, {List<String> prerequisites = const [], CefrLevel level = CefrLevel.a1}) {
  return SkillNode(
    id: id,
    name: id,
    description: 'Skill $id',
    type: SkillType.lexical,
    modality: SkillModality.reading,
    languageCode: 'yor',
    prerequisites: prerequisites,
    cefrLevel: level,
    tags: const ['tone'],
    baseDifficulty: 0.4,
  );
}

PhonemeResult _phone(String phoneme, [double confidence = 1]) {
  return PhonemeResult(phoneme: phoneme, confidence: confidence);
}

class _ToneQuiz extends LearningGame with LearningGameMixin {
  @override
  String get gameId => 'tone_quiz';

  @override
  List<String> get targetSkillIds => const ['yo.tone'];

  @override
  GameDifficulty adjustDifficulty(LearnerSkillState state) {
    return getRecommendedDifficulty(learnerId: state.learnerId, skillId: state.skillId);
  }

  @override
  SkillOutcome evaluateResponse(GameResponse response) {
    final correct = response.actual == response.expected;
    return SkillOutcome(
      isCorrect: correct,
      partialCredit: correct ? 1 : 0,
      errorTypeIds: correct ? const [] : const ['tone_substitution'],
      responseTimeSeconds: response.responseTimeSeconds,
      expectedTimeSeconds: response.expectedTimeSeconds,
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    SkillRegistry.instance.clear();
  });

  test('a correct answer raises mastery and a wrong answer does not match it', () {
    const params = BktParams(pL0: 0.1, pT: 0.1, pS: 0.1, pG: 0.2);
    final up = BktMastery.updateMastery(currentMastery: 0.4, wasCorrect: true, params: params);
    final down = BktMastery.updateMastery(currentMastery: 0.4, wasCorrect: false, params: params);
    expect(up, greaterThan(0.4));
    expect(down, lessThan(up));
    expect(up, inInclusiveRange(0, 1));

    final path = BktMastery.batchUpdate(
      initialMastery: 0.2,
      responses: const [true, false, true],
      params: params,
    );
    expect(path, hasLength(3));
    expect(path.last, greaterThan(path.first));

    expect(BktMastery.predictCorrectProbability(mastery: 1, params: params), closeTo(0.9, 0.001));
    expect(BktMastery.opportunitiesToMastery(currentMastery: 0.99, params: params), 0);
    expect(BktMastery.opportunitiesToMastery(currentMastery: 0.2, params: params), greaterThan(0));
    expect(BktMastery.isMastered(0.95), isTrue);
    expect(BktMastery.isMastered(0.5), isFalse);
    expect(BktMastery.informationGain(mastery: 0.4, params: params), greaterThanOrEqualTo(0));
    expect(params.copyWith(pT: 0.2).pT, 0.2);
    expect(params.toJson()['pL0'], 0.1);
  });

  test('recall is one half after one half-life and success lengthens memory', () {
    expect(
      HlrForgettingCurve.recallProbability(elapsedDays: 4, halfLifeDays: 4),
      closeTo(0.5, 0.001),
    );
    expect(HlrForgettingCurve.recallProbability(elapsedDays: 0, halfLifeDays: 4), 1);
    expect(HlrForgettingCurve.recallProbability(elapsedDays: 3, halfLifeDays: 0), 0);

    final longer = HlrForgettingCurve.updateHalfLife(
      currentHalfLifeDays: 2,
      wasSuccessful: true,
    );
    final shorter = HlrForgettingCurve.updateHalfLife(
      currentHalfLifeDays: 2,
      wasSuccessful: false,
      errorSeverity: 1,
    );
    expect(longer, greaterThan(2));
    expect(shorter, lessThan(2));
    expect(HlrForgettingCurve.optimalReviewDays(halfLifeDays: 4, targetProbability: 0.5), closeTo(4, 0.001));
    expect(HlrForgettingCurve.reviewsToTarget(currentHalfLife: 8, targetHalfLife: 4), 0);
    expect(HlrForgettingCurve.reviewsToTarget(currentHalfLife: 1, targetHalfLife: 4, alpha: 0), -1);
    expect(
      HlrForgettingCurve.reviewsToTarget(currentHalfLife: 1, targetHalfLife: 4),
      greaterThan(0),
    );
    expect(
      HlrForgettingCurve.reviewUrgency(elapsedDays: 0, halfLifeDays: 10),
      0,
    );
    expect(
      HlrForgettingCurve.reviewUrgency(elapsedDays: 20, halfLifeDays: 1),
      greaterThan(0),
    );
  });

  test('a skill stays locked until its prerequisite is mastered', () {
    final graph = SkillDependencyGraph()
      ..addSkills([
        _skill('greet'),
        _skill('tone', prerequisites: ['greet'], level: CefrLevel.a2),
      ]);
    expect(graph.rootSkills.map((s) => s.id), ['greet']);
    expect(graph.leafSkills.map((s) => s.id), ['tone']);
    expect(graph.getAvailableSkills({}).map((s) => s.id), ['greet']);
    expect(graph.getAvailableSkills({'greet'}).map((s) => s.id), contains('tone'));
    expect(graph.topologicalOrder, ['greet', 'tone']);
    expect(graph.pathToSkill('tone'), ['greet', 'tone']);
    expect(graph.getPrerequisites('tone').single.id, 'greet');
    expect(graph.getDependents('greet').single.id, 'tone');
    expect(graph.getAllPrerequisites('tone'), {'greet'});
    expect(graph.skillsByDepth[0]!.single.id, 'greet');
    expect(graph.validate(), isEmpty);
    expect(graph.nodeCount, 2);

    final broken = SkillDependencyGraph()..addSkill(_skill('orphan', prerequisites: ['missing']));
    expect(broken.validate(), isNotEmpty);

    final cycle = SkillDependencyGraph()
      ..addSkills([
        _skill('a', prerequisites: ['b']),
        _skill('b', prerequisites: ['a']),
      ]);
    expect(cycle.validate(), isNotEmpty);

    final restored = SkillDependencyGraph.fromJson(graph.toJson());
    expect(restored.getSkill('tone')!.cefrLevel, CefrLevel.a2);
  });

  test('registry filters by level and rejects an unknown type name as lexical', () async {
    final registry = SkillRegistry.instance;
    await registry.initialize();
    expect(registry.isInitialized, isTrue);
    registry.registerSkills('yor', [
      _skill('greet'),
      _skill('tone', prerequisites: ['greet'], level: CefrLevel.b1),
    ]);
    expect(registry.registeredLanguages, {'yor'});
    expect(registry.getSkills('yor', cefrLevel: CefrLevel.a1).single.id, 'greet');
    expect(registry.getRootSkills('yor').single.id, 'greet');
    expect(registry.findSkill('tone')!.name, 'tone');
    expect(registry.getAvailableSkills('yor', {}).single.id, 'greet');
    expect(registry.getSkillsByType('yor')[SkillType.lexical], isNotEmpty);
    expect(registry.getSkillsByCefrLevel('yor')[CefrLevel.b1]!.single.id, 'tone');
    expect(registry.validateAll(), isEmpty);

    final parsed = SkillNode.fromJson({
      'id': 'x',
      'name': 'X',
      'languageCode': 'yor',
      'type': 'not-a-type',
      'modality': 'not-a-mode',
      'cefrLevel': 'nope',
    });
    expect(parsed.type, SkillType.lexical);
    expect(parsed.modality, SkillModality.mixed);
    expect(parsed.cefrLevel.displayName, contains('A1'));
    expect(CefrLevel.b2.isAtLeast(CefrLevel.a2), isTrue);
    expect(parsed.isRootSkill, isTrue);
    expect(_skill('greet'), _skill('greet', prerequisites: ['other']));
  });

  test('a tonal family includes tone errors and a clean attempt fades them', () {
    final tonal = ErrorTaxonomy.errorsForLanguageFamily(LanguageFamily.tonal);
    expect(tonal.map((e) => e.id), contains('tone_flattening'));
    expect(ErrorTaxonomy.errorsForLanguageFamily(LanguageFamily.bantu).length, greaterThan(tonal.length));
    expect(ErrorType.byId('phoneme_substitution')!.severity, 0.6);
    expect(ErrorType.byId('no-such'), isNull);

    final severe = ErrorTaxonomy.weightedSeverity({'phoneme_deletion': 1});
    expect(severe, closeTo(1, 0.001));
    expect(ErrorTaxonomy.weightedSeverity({}), 0);
    expect(ErrorTaxonomy.weightedSeverity({'no-such': 1}), 0);
    expect(ErrorTaxonomy.topErrors({'a': 0.2, 'b': 0.9}).first.key, 'b');
    expect(ErrorTaxonomy.errorEntropy({}), 0);
    expect(ErrorTaxonomy.errorEntropy({'phoneme_substitution': 1, 'phoneme_deletion': 1}), greaterThan(0));

    final recorded = const ErrorDistribution(rates: {}, totalObservations: 0)
        .recordError('tone_substitution')
        .recordClean();
    expect(recorded.totalObservations, 2);
    expect(recorded.dominantError, 'tone_substitution');
    expect(recorded.toJson()['totalObservations'], 2);
  });

  test('recording a correct attempt increases the streak and a miss clears it', () {
    final start = LearnerSkillState.initial(skillId: 'yo.tone', learnerId: 'ada');
    final hit = start.recordAttempt(wasCorrect: true, responseTimeSeconds: 2, expectedTimeSeconds: 5);
    expect(hit.totalAttempts, 1);
    expect(hit.successfulAttempts, 1);
    expect(hit.currentStreak, 1);
    expect(hit.mastery, greaterThan(start.mastery));
    expect(hit.accuracy, 1);

    final miss = hit.recordAttempt(
      wasCorrect: false,
      errorTypeIds: const ['tone_substitution'],
      responseTimeSeconds: 8,
      expectedTimeSeconds: 4,
    );
    expect(miss.currentStreak, 0);
    expect(miss.dominantErrorType, 'tone_substitution');
    expect(miss.mastery, lessThan(hit.mastery));
    expect(miss.copyWith(mastery: 0.2).mastery, 0.2);
    expect(miss.toJson()['skillId'], 'yo.tone');
    expect(miss.isDueForReview, isA<bool>());
    expect(miss.nextOptimalReview.isAfter(miss.lastRecall.subtract(const Duration(days: 1))), isTrue);
  });

  test('the learner model recommends a root skill and exports the attempt', () async {
    SkillRegistry.instance.registerSkills('yor', [_skill('greet'), _skill('tone', prerequisites: ['greet'])]);
    final model = LearnerModelService.instance;
    final before = model.getRecommendations(learnerId: 'ada', languageCode: 'yor');
    expect(before.map((r) => r.skillId), contains('greet'));
    expect(before.map((r) => r.skillId), isNot(contains('tone')));
    expect(before.first.reason, RecommendationReason.newSkill);

    final state = await model.recordAttempt(
      learnerId: 'ada',
      skillId: 'greet',
      wasCorrect: true,
      responseTimeSeconds: 3,
    );
    expect(state.skillId, 'greet');
    expect(model.getMasteredSkillIds('ada', 'yor'), isEmpty);
    final recs = model.getRecommendations(learnerId: 'ada', languageCode: 'yor');
    expect(recs.map((r) => r.skillId), isNot(contains('tone')));
    expect(recs.where((r) => r.reason == RecommendationReason.newSkill), isEmpty);

    final metrics = model.getCognitiveMetrics(learnerId: 'ada', languageCode: 'yor');
    expect(metrics.masteryRatio, inInclusiveRange(0, 1));
    expect(metrics.toJson()['averageMastery'], metrics.averageMastery);

    final payload = model.exportForSync('ada');
    expect(payload['states'], isNotEmpty);
    await model.importFromSync(payload);
    expect(model.getState(learnerId: 'ada', skillId: 'greet').totalAttempts, greaterThan(0));
  });

  test('matching phonemes score higher than a deletion', () {
    final match = PhonemeAlignment.align(
      expected: [_phone('o'), _phone('k')],
      actual: [_phone('o'), _phone('k')],
    );
    final deleted = PhonemeAlignment.align(
      expected: [_phone('o'), _phone('k')],
      actual: [_phone('o')],
    );
    final extra = PhonemeAlignment.align(
      expected: [_phone('o')],
      actual: [_phone('o'), _phone('k')],
    );
    final swapped = PhonemeAlignment.align(
      expected: [_phone('o')],
      actual: [_phone('u')],
    );
    expect(match.overallScore, greaterThan(deleted.overallScore));
    expect(match.matchCount, 2);
    expect(deleted.deletionCount, greaterThan(0));
    expect(extra.insertionCount, greaterThan(0));
    expect(swapped.substitutionCount, 1);
    expect(PhonemeAlignment.align(expected: [], actual: []).overallScore, 1);
    expect(PhonemeAlignment.align(expected: [], actual: [_phone('a')]).overallScore, 0);

    final heat = PhonemeAlignment.generateHeatmap(swapped);
    expect(heat.single.score, lessThan(1));
    expect(match.toJson()['overallScore'], match.overallScore);
  });

  test('the pronunciation pipeline records a miss and builds a drill for it', () async {
    final pipeline = PronunciationPipeline();
    final result = await pipeline.evaluate(
      learnerId: 'bola',
      skillId: 'yo.phone',
      expectedPhonemes: [_phone('o'), _phone('k')],
      actualPhonemes: [_phone('u')],
      responseTimeSeconds: 4,
    );
    expect(result.overallScore, lessThan(1));
    expect(result.toJson()['overallScore'], result.overallScore);

    final fromText = await pipeline.evaluateFromText(
      learnerId: 'bola',
      skillId: 'yo.phone',
      expectedText: 'oko',
      actualText: 'oko',
      expectedPhonemeStrings: const ['o', 'k', 'o'],
    );
    expect(fromText.overallScore, inInclusiveRange(0, 1));

    await LearnerModelService.instance.recordAttempt(
      learnerId: 'bola',
      skillId: 'yo.phone',
      wasCorrect: false,
      errorTypeIds: const [
        'phoneme_substitution',
        'tone_flattening',
        'phoneme_deletion',
        'nasalization_missing',
        'vowel_length',
      ],
    );
    final drills = pipeline.generateTargetedDrills(learnerId: 'bola', skillId: 'yo.phone');
    expect(drills.map((d) => d.type), contains(DrillType.minimalPair));
    await LearnerModelService.instance.recordAttempt(
      learnerId: 'bola',
      skillId: 'yo.tone-drill',
      wasCorrect: false,
      errorTypeIds: const ['tone_flattening'],
    );
    final toneDrills = pipeline.generateTargetedDrills(learnerId: 'bola', skillId: 'yo.tone-drill');
    expect(toneDrills.single.type, DrillType.toneContour);
  });

  test('a new skill starts easy and a streak raises the next challenge', () async {
    final fresh = DifficultyPredictor.predictForSkill('kemi', 'yo.new');
    expect(fresh.level, 0.2);
    expect(fresh.confidence, 0.3);

    final model = LearnerModelService.instance;
    for (var i = 0; i < 4; i++) {
      await model.recordAttempt(
        learnerId: 'kemi',
        skillId: 'yo.streak',
        wasCorrect: true,
        responseTimeSeconds: 2,
        expectedTimeSeconds: 5,
      );
    }
    final raised = DifficultyPredictor.predictForSkill('kemi', 'yo.streak');
    expect(raised.level, greaterThan(fresh.level));
    final batch = DifficultyPredictor.predictForSession('kemi', ['yo.new', 'yo.streak']);
    expect(batch, hasLength(2));

    SkillRegistry.instance.registerSkills('yor', [_skill('greet')]);
    final next = DifficultyPredictor.suggestNextChallenge('kemi', 'yor');
    expect(next.skillId, isNotEmpty);
  });

  test('review sessions put due skills ahead of a locked skill', () async {
    SkillRegistry.instance.registerSkills('yor', [
      _skill('greet'),
      _skill('tone', prerequisites: ['greet']),
    ]);
    final model = LearnerModelService.instance;
    final past = DateTime.now().subtract(const Duration(days: 10));
    await model.importFromSync({
      'learnerId': 'tunde',
      'states': {
        'greet': LearnerSkillState(
          skillId: 'greet',
          learnerId: 'tunde',
          mastery: 0.4,
          halfLifeDays: 0.2,
          lastRecall: past,
          lastPractice: past,
        ).toJson(),
      },
    });

    final scheduler = ReviewScheduler(learnerModel: model, maxSessionItems: 6);
    final due = scheduler.getDueReviews(learnerId: 'tunde', languageCode: 'yor');
    expect(due.single.skillId, 'greet');
    expect(due.single.daysSinceReview, greaterThanOrEqualTo(9));

    final session = scheduler.generateSession(learnerId: 'tunde', languageCode: 'yor');
    expect(session.itemCount, greaterThan(0));
    expect(session.reviewCount, greaterThan(0));
    expect(session.items.first.type, ReviewSessionItemType.review);
    expect(session.learnerId, 'tunde');
    expect(scheduler.shouldStopSession(recentResults: const [false, false, false, false, false]), isTrue);
    expect(scheduler.shouldStopSession(recentResults: const [true, true]), isFalse);
    expect(scheduler.nextSessionTime(learnerId: 'empty', languageCode: 'yor'), isA<DateTime>());
    expect(scheduler.predictReviewLoad(learnerId: 'tunde', daysFromNow: 30), greaterThan(0));
    expect(due.single.toJson()['skillId'], 'greet');
  });

  test('a persona drill uses that persona vocabulary and a wrong answer is not correct', () async {
    final persona = PersonaPronunciationService();
    final drills = persona.generateDrills(personaId: 'mandela_nelson', learnerId: 'zola');
    expect(drills, isNotEmpty);
    expect(drills.first.category, DrillCategory.vocabulary);
    expect(persona.generateDrills(personaId: 'missing', learnerId: 'zola'), isEmpty);

    final scored = await persona.evaluateTextInPersonaContext(
      personaId: 'mandela_nelson',
      learnerId: 'zola',
      skillId: 'xh.greet',
      expectedText: 'molo',
      actualText: 'molo',
      expectedPhonemeStrings: const ['m', 'o', 'l', 'o'],
    );
    expect(scored.overallScore, inInclusiveRange(0, 1));
    expect(scored.personaId, 'mandela_nelson');
  });

  test('a game records a wrong tone and then recommends a harder round after three hits', () async {
    final game = _ToneQuiz();
    final wrong = game.evaluateResponse(const GameResponse(
      skillId: 'yo.tone',
      expected: 'ọ̀rẹ́',
      actual: 'ore',
      responseTimeSeconds: 6,
    ));
    expect(wrong.isCorrect, isFalse);
    final state = await game.recordGameResponse(
      learnerId: 'femi',
      skillId: 'yo.tone',
      outcome: wrong,
    );
    expect(state.successfulAttempts, 0);

    for (var i = 0; i < 3; i++) {
      await game.recordGameResponse(
        learnerId: 'femi',
        skillId: 'yo.tone',
        outcome: const SkillOutcome(isCorrect: true, responseTimeSeconds: 2, expectedTimeSeconds: 5),
      );
    }
    final difficulty = game.adjustDifficulty(
      LearnerModelService.instance.getState(learnerId: 'femi', skillId: 'yo.tone'),
    );
    expect(difficulty.level, greaterThan(0));
    expect(difficulty.suggestedTimeLimit, greaterThan(0));
    expect(difficulty.shouldIncrease(const SkillOutcome(isCorrect: true)), isA<bool>());
    expect(difficulty.toJson()['level'], difficulty.level);

    final ended = GameSessionResult(
      gameId: game.gameId,
      learnerId: 'femi',
      languageCode: 'yor',
      skillIds: game.targetSkillIds,
      outcomes: [wrong, const SkillOutcome(isCorrect: true)],
      startedAt: DateTime.utc(2026, 1, 1),
      endedAt: DateTime.utc(2026, 1, 1, 0, 2),
    );
    expect(ended.accuracy, 0.5);
    expect(ended.duration.inMinutes, 2);
    expect(ended.allErrorTypes, contains('tone_substitution'));
  });
}
