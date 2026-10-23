import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/services/passport/credential_evidence_service.dart';
import 'package:lingafriq/services/placement/checkpoint_service.dart';

void main() {
  group('P2-056 checkpoint evidence', () {
    CheckpointItem sample({
      required String itemId,
      required List<String> canDoIds,
      bool calibrated = true,
      double? score = 1.0,
      double? confidence,
      bool scorerRequired = false,
      bool scorerAvailable = false,
    }) {
      return CheckpointItem(
        itemId: itemId,
        canDoIds: canDoIds,
        calibrated: calibrated,
        score: score,
        confidence: confidence,
        scorerRequired: scorerRequired,
        scorerAvailable: scorerAvailable,
      );
    }

    UnitCheckpoint lessonPass() {
      return buildCheckpoint(
        unitId: 'unit-1',
        unitCanDoIds: const ['greet', 'ask'],
        items: [
          sample(
            itemId: 'listen',
            canDoIds: const ['greet'],
            score: 1.0,
            confidence: 0.1,
          ),
          sample(itemId: 'match', canDoIds: const ['ask'], score: 0.0),
        ],
      ).checkpoint;
    }

    UnitCheckpoint speaking({
      double? confidence = 0.95,
      bool scorerAvailable = true,
      double? score = 0.8,
    }) {
      return buildCheckpoint(
        unitId: 'unit-1',
        unitCanDoIds: const ['greet'],
        items: [
          sample(
            itemId: 'speak',
            canDoIds: const ['greet'],
            score: score,
            confidence: confidence,
            scorerRequired: true,
            scorerAvailable: scorerAvailable,
          ),
        ],
      ).checkpoint;
    }

    void expectUnstored(
      UnitCheckpoint checkpoint, {
      String context = 'lesson',
      bool consent = false,
    }) {
      final service = CredentialEvidenceService();
      expect(
        issueEvidence(
          checkpoint: checkpoint,
          context: context,
          consent: consent,
        ),
        isNull,
      );
      expect(
        service.issueEvidence(
          checkpoint: checkpoint,
          context: context,
          consent: consent,
        ),
        isNull,
      );
      expect(service.record, isNull);
    }

    test(
      'an item whose can-do is outside the unit is left out of the checkpoint',
      () {
        final built = buildCheckpoint(
          unitId: 'unit-1',
          unitCanDoIds: const ['greet', 'ask'],
          items: [
            sample(itemId: 'greet-item', canDoIds: const ['greet']),
            sample(itemId: 'mixed', canDoIds: const ['greet', 'fly']),
            sample(itemId: 'ask-item', canDoIds: const ['ask']),
          ],
        );

        expect(built.checkpoint.items.map((entry) => entry.itemId).toList(), [
          'greet-item',
          'ask-item',
        ]);
        expect(built.rejected, hasLength(1));
        expect(built.rejected.single.itemId, 'mixed');
        expect(built.rejected.single.canDoIds, ['greet', 'fly']);
        expect(built.rejected.single.reason, CheckpointRejection.outsideUnit);
      },
    );

    test("a built checkpoint's items all cite unit can-dos", () {
      final unitCanDoIds = <String>['greet', 'ask'];
      final greetIds = <String>['greet'];
      final built = buildCheckpoint(
        unitId: 'unit-1',
        unitCanDoIds: unitCanDoIds,
        items: [
          sample(itemId: 'both', canDoIds: const ['greet', 'ask']),
          CheckpointItem(
            itemId: 'greet-item',
            canDoIds: greetIds,
            calibrated: true,
            score: 1.0,
            confidence: null,
            scorerRequired: false,
            scorerAvailable: false,
          ),
          sample(itemId: 'blank', canDoIds: const []),
          sample(itemId: 'outside', canDoIds: const ['fly']),
        ],
      );
      unitCanDoIds.clear();
      greetIds.add('fly');

      expect(built.checkpoint.unitCanDoIds, ['greet', 'ask']);
      expect(built.checkpoint.items.map((entry) => entry.itemId).toList(), [
        'both',
        'greet-item',
      ]);
      for (final entry in built.checkpoint.items) {
        expect(entry.canDoIds, isNotEmpty);
        expect(entry.canDoIds, everyElement(isIn(['greet', 'ask'])));
      }
      expect(
        built.checkpoint.items
            .singleWhere((entry) => entry.itemId == 'greet-item')
            .canDoIds,
        ['greet'],
      );
      expect(built.rejected.map((entry) => entry.reason).toList(), [
        CheckpointRejection.emptyCanDos,
        CheckpointRejection.outsideUnit,
      ]);
    });

    test(
      'a passed calibrated checkpoint with no scorer requirement stores item ids, scores, and calibrated true',
      () {
        final checkpoint = lessonPass();
        final pure = issueEvidence(
          checkpoint: checkpoint,
          context: 'lesson',
          consent: false,
        );
        final owner = CredentialEvidenceService();
        expect(owner.record, isNull);
        final stored = owner.issueEvidence(
          checkpoint: checkpoint,
          context: 'lesson',
          consent: false,
        );

        expect(stored, isNotNull);
        expect(owner.record, same(stored));
        expect(stored!.unitId, 'unit-1');
        expect(stored.itemIds, ['listen', 'match']);
        expect(stored.scores, [1.0, 0.0]);
        expect(stored.calibrated, [true, true]);
        expect(stored.proctored, isFalse);
        expect(pure!.itemIds, stored.itemIds);
        expect(pure.scores, stored.scores);
        expect(pure.calibrated, stored.calibrated);
        expect(pure.proctored, isFalse);
        expect(CredentialEvidenceService().record, isNull);
      },
    );

    test('one uncalibrated item issues no evidence', () {
      final built = buildCheckpoint(
        unitId: 'unit-1',
        unitCanDoIds: const ['greet', 'ask'],
        items: [
          sample(itemId: 'ok', canDoIds: const ['greet'], score: 1.0),
          sample(
            itemId: 'raw',
            canDoIds: const ['ask'],
            calibrated: false,
            score: 1.0,
          ),
        ],
      );

      expect(built.checkpoint.items.map((entry) => entry.itemId).toList(), [
        'ok',
        'raw',
      ]);
      expectUnstored(built.checkpoint);
    });

    test('scorerRequired with scorerAvailable false issues no evidence', () {
      final checkpoint = speaking(confidence: 0.95, scorerAvailable: false);
      expect(checkpoint.items.single.scorerRequired, isTrue);
      expect(checkpoint.items.single.score, 0.8);
      expectUnstored(checkpoint);
    });

    test('a non-passport context is not proctored', () {
      expect(proctoringRequired('lesson', true), isFalse);
      expect(proctoringRequired('review', true), isFalse);
      expect(proctoringRequired('review', false), isFalse);

      final checkpoint = lessonPass();
      final service = CredentialEvidenceService();
      final stored = service.issueEvidence(
        checkpoint: checkpoint,
        context: 'review',
        consent: false,
      );
      final consented = issueEvidence(
        checkpoint: checkpoint,
        context: 'review',
        consent: true,
      );

      expect(stored, isNotNull);
      expect(stored!.proctored, isFalse);
      expect(stored.proctored, proctoringRequired('review', false));
      expect(service.record!.proctored, isFalse);
      expect(consented!.proctored, isFalse);
    });

    test('passport with consent false issues no evidence', () {
      expect(proctoringRequired('passport', false), isFalse);
      expectUnstored(speaking(), context: 'passport', consent: false);
    });

    test(
      'passport with consent true and a valid checkpoint stores proctored true',
      () {
        expect(proctoringRequired('passport', true), isTrue);
        final checkpoint = speaking();
        final service = CredentialEvidenceService();
        final stored = service.issueEvidence(
          checkpoint: checkpoint,
          context: 'passport',
          consent: true,
        );

        expect(stored, isNotNull);
        expect(service.record, same(stored));
        expect(stored!.unitId, 'unit-1');
        expect(stored.itemIds, ['speak']);
        expect(stored.scores, [0.8]);
        expect(stored.calibrated, [true]);
        expect(stored.proctored, isTrue);
        expect(stored.proctored, proctoringRequired('passport', true));
      },
    );

    test('a required scorer without a real result issues no evidence', () {
      expect(minimumScorerConfidence, 0.6);
      expectUnstored(speaking(confidence: null));
      expectUnstored(speaking(confidence: 0.59));
      expectUnstored(speaking(confidence: double.nan));
      expectUnstored(speaking(confidence: double.infinity));
      expectUnstored(speaking(confidence: double.negativeInfinity));
      expectUnstored(speaking(score: null));
      expectUnstored(speaking(score: double.nan));
      expectUnstored(
        buildCheckpoint(
          unitId: 'unit-1',
          unitCanDoIds: const ['greet'],
          items: [
            sample(itemId: 'listen', canDoIds: const ['greet'], score: null),
          ],
        ).checkpoint,
      );
    });

    test('confidence at 0.6 with an available scorer stores evidence', () {
      final checkpoint = speaking(confidence: 0.6, score: 0.75);
      final service = CredentialEvidenceService();
      final stored = service.issueEvidence(
        checkpoint: checkpoint,
        context: 'lesson',
        consent: false,
      );

      expect(stored, isNotNull);
      expect(service.record, same(stored));
      expect(stored!.itemIds, ['speak']);
      expect(stored.scores, [0.75]);
      expect(stored.calibrated, [true]);
      expect(stored.proctored, isFalse);
    });

    test('a checkpoint that does not map the unit issues no evidence', () {
      final built = buildCheckpoint(
        unitId: 'unit-1',
        unitCanDoIds: const ['greet'],
        items: [
          sample(itemId: 'fly-item', canDoIds: const ['fly']),
        ],
      );
      expect(built.checkpoint.items, isEmpty);
      expectUnstored(built.checkpoint);
      expectUnstored(
        UnitCheckpoint(
          unitId: 'unit-1',
          unitCanDoIds: const ['greet'],
          items: [
            sample(itemId: 'fly-item', canDoIds: const ['fly']),
          ],
        ),
      );
    });

    test('a refused attempt does not erase evidence already kept', () {
      final service = CredentialEvidenceService();
      final kept = service.issueEvidence(
        checkpoint: lessonPass(),
        context: 'lesson',
        consent: false,
      );
      expect(kept, isNotNull);
      expect(
        service.issueEvidence(
          checkpoint: speaking(scorerAvailable: false),
          context: 'lesson',
          consent: false,
        ),
        isNull,
      );
      expect(service.record, same(kept));
    });
  });
}
