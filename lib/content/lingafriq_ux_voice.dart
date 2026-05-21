import 'dart:math';

/// Centralized UX copy aligned with LingAfriq brand voice:
/// warm, culturally grounded, confidence-protecting.
class LingAfriqUxVoice {
  LingAfriqUxVoice._();

  static final Random _random = Random();

  // ─── Quiz feedback ───────────────────────────────────────────────────

  static const List<String> quizCorrect = [
    'That sounded natural.',
    'You got the meaning right.',
    'Native speakers would say it just like that.',
    'Excellent rhythm.',
  ];

  static const List<String> quizClose = [
    'You\'re very close.',
    'Native speakers would phrase it slightly differently.',
    'Nice try — the meaning is right. Let\'s refine the phrasing.',
    'Almost there — one small adjustment.',
  ];

  static const List<String> quizIncorrect = [
    'Let\'s try that once more together.',
    'Not quite — listen again, then give it another go.',
    'Close — hear how a native speaker would say it.',
  ];

  static String quizFeedback({required bool isCorrect, bool? nearMiss}) {
    if (isCorrect) return _pick(quizCorrect);
    if (nearMiss == true) return _pick(quizClose);
    return _pick(quizIncorrect);
  }

  // ─── Lesson completion ─────────────────────────────────────────────────

  static String lessonCompleteMessage(double accuracy) {
    if (accuracy >= 90) {
      return 'You\'re building real conversational confidence.';
    }
    if (accuracy >= 75) {
      return 'That lesson moved you forward — well done.';
    }
    if (accuracy >= 55) {
      return 'Every session strengthens memory. Keep going.';
    }
    return 'Your journey is still active — a short review keeps momentum alive.';
  }

  static String lessonShareText(int xp) =>
      'I just completed a lesson on LingAfriq and earned $xp XP. Join me in learning African languages with culture.';

  // ─── Streak & retention ────────────────────────────────────────────────

  static const List<String> streakRecovery = [
    'Your learning momentum is still alive.',
    'Even a short practice session keeps fluency active.',
    'Let\'s continue where you left off.',
  ];

  static const List<String> dailyPractice = [
    'A quick 5-minute practice keeps your fluency active.',
    'Today\'s conversation challenge is ready.',
    'Your pronunciation streak is getting stronger.',
  ];

  // ─── Empty & loading ───────────────────────────────────────────────────

  static const String emptyLessons =
      'Your learning library is waiting to grow. Complete your next lesson to unlock new conversations.';

  static const List<String> loadingHints = [
    'Preparing your pronunciation coach…',
    'Loading cultural insights…',
    'Analyzing conversational rhythm…',
  ];

  // ─── Errors ────────────────────────────────────────────────────────────

  static const String connectionError =
      'We couldn\'t connect right now. Your lesson progress is safe — let\'s try again.';

  static const String audioProcessingDelay =
      'Audio is taking a little longer than expected. Hang tight.';

  // ─── Games ─────────────────────────────────────────────────────────────

  static const String gameEncouragement =
      'Speak boldly before you speak perfectly.';

  static String gameRoundResult(bool won) => won
      ? 'Strong round — you\'re sounding more natural.'
      : 'Good effort — native rhythm comes with repetition.';

  static String _pick(List<String> options) =>
      options[_random.nextInt(options.length)];
}
