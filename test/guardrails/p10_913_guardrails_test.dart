import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/gamification/gamification_guardrails.dart';
import 'package:lingafriq/models/hearts_system_model.dart';
import 'package:lingafriq/screens/village/flashcard_focus_screen.dart';

void main() {
  test('AC1 spendable currency keys list only Cowries', () {
    expect(GamificationGuardrails.spendableCurrencyKeys, ['cowries']);
  });

  test('AC3/AC4 core lessons proceed with zero hearts when challenge run inactive', () {
    final state = HeartsState(
      currentHearts: 0,
      challengeModeEnabled: true,
      challengeRunActive: false,
    );
    expect(GamificationGuardrails.coreLessonEconomyGateActive(state), isFalse);
    expect(GamificationGuardrails.coreLessonMayProceed(state), isTrue);
  });

  test('AC6 default flashcard roster is solo without fake co-learners', () {
    const roster = FlashcardGroupStudyRoster.solo();
    expect(roster.mode, FlashcardStudyMode.solo);
    expect(roster.peers, isEmpty);
    expect(
      GamificationGuardrails.flashcardDefaultIsSolo(
        challengeRunActive: false,
        peerCount: roster.peers.length,
      ),
      isTrue,
    );
    expect(
      flashcardRosterFromApi({'ok': false}).peers,
      isEmpty,
    );
  });
}
