import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/services/gamification/competence_gamification.dart';

void main() {
  final gamification = CompetenceGamification();

  test('tap with no evidence yields zero XP', () {
    expect(
      gamification.computeEvidenceXp(kind: EvidenceXpKind.none),
      0,
    );
  });

  test('early spaced recall preview is less than on schedule', () {
    final scheduled = DateTime.utc(2026, 10, 27, 12);
    final onTime = gamification.computeEvidenceXp(
      kind: EvidenceXpKind.spacedRecall,
      itemId: 'w1',
      difficulty: 'medium',
      scheduledRecallAt: scheduled,
      recalledAt: scheduled.add(const Duration(seconds: 1)),
    );
    final early = gamification.computeEvidenceXp(
      kind: EvidenceXpKind.spacedRecall,
      itemId: 'w1',
      difficulty: 'medium',
      scheduledRecallAt: scheduled,
      recalledAt: scheduled.subtract(const Duration(days: 3)),
    );
    expect(onTime, EvidenceXpRules.spacedRecallOnSchedule);
    expect(early, lessThan(onTime));
  });

  test('easy repeats diminish to zero at cap', () {
    final first = gamification.computeEvidenceXp(
      kind: EvidenceXpKind.spacedRecall,
      itemId: 'e1',
      difficulty: 'easy',
      sameDayEasyRepeatIndex: 0,
    );
    final later = gamification.computeEvidenceXp(
      kind: EvidenceXpKind.spacedRecall,
      itemId: 'e1',
      difficulty: 'easy',
      sameDayEasyRepeatIndex: 1,
    );
    final zero = gamification.computeEvidenceXp(
      kind: EvidenceXpKind.spacedRecall,
      itemId: 'e1',
      difficulty: 'easy',
      sameDayEasyRepeatIndex: EvidenceXpRules.easyRepeatZeroFromIndex,
    );
    expect(later, lessThan(first));
    expect(zero, 0);
  });
}
