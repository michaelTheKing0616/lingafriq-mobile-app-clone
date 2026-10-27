import 'package:lingafriq/models/hearts_system_model.dart';

/// P10-913 — Client-side ethical gamification guardrails (Elevation §12.3).
class GamificationGuardrails {
  GamificationGuardrails._();

  static const List<String> spendableCurrencyKeys = ['cowries'];

  /// Core lessons never consume hearts or energy outside an active Challenge run.
  static bool coreLessonEconomyGateActive(HeartsState state) => state.heartsApply;

  static bool coreLessonMayProceed(HeartsState state) => state.hasHearts;

  static bool flashcardDefaultIsSolo({
    required bool challengeRunActive,
    required int peerCount,
  }) {
    return !challengeRunActive && peerCount == 0;
  }
}
