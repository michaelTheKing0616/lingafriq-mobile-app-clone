import '../../models/lesson_item_model.dart';

/// A real Yoruba greeting used when practice opens with no lesson argument.
///
/// The tone pattern is what [ToneDrillService] needs in order to build a drill.
LessonItem practiceLessonFromRoute(Object? arguments) {
  if (arguments is LessonItem) return arguments;
  return LessonItem(
    id: 'practice-bawo',
    language: 'Yoruba',
    languageCode: 'yo',
    level: 'A1',
    category: 'greeting',
    type: 'pronunciation',
    text: 'bawo',
    ipa: 'bāwò',
    translation: 'hello',
    tonePattern: const <String>['low', 'high'],
    difficulty: 0.4,
    qualityScore: 1,
  );
}
