import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/ai/personas/teacher_assignment.dart';

PersonaChapterCatalogEntry? _yaaChapter(String questId, int chapterIndex) {
  if (questId != 'yaa_asantewaa_golden_stool') return null;
  const entries = {
    1: PersonaChapterCatalogEntry(
      questId: 'yaa_asantewaa_golden_stool',
      personaId: 'yaa_asantewaa',
      chapterIndex: 1,
      chapterId: 'kumasi_messenger',
      canDoId: 'persona.yaa.ch1.honorific_greeting',
      canDoStatementEn:
          'I can greet an elder with appropriate honorifics in a guided Twi scene.',
    ),
  };
  return entries[chapterIndex];
}

void main() {
  group('P11-021 teacher assignment', () {
    test('verified class gate', () {
      expect(
        isVerifiedClassroom(isClassroom: true, classroomCode: 'ROOM1'),
        isTrue,
      );
      expect(
        isVerifiedClassroom(isClassroom: true, classroomCode: ''),
        isFalse,
      );
    });

    test('recipients limited to enrolled students', () {
      final payload = buildPersonaChapterAssignment(
        questId: 'yaa_asantewaa_golden_stool',
        chapterIndex: 1,
        enrolledStudentUserIds: ['s1', 's2'],
        targetStudentUserIds: ['s1', 'other'],
        catalogLookup: _yaaChapter,
      );
      expect(payload, isNotNull);
      expect(payload!.recipientUserIds, ['s1']);
    });

    test('can-do mapping on graded turn', () {
      final grade = gradePersonaTurn(
        turnId: 'turn-1',
        questId: 'yaa_asantewaa_golden_stool',
        chapterIndex: 1,
        outcome: CanDoEvidenceStatus.met,
        evidence: const PersonaTurnEvidence(
          kind: 'speech_score',
          detail: 'honorific branch',
        ),
        chapter: _yaaChapter('yaa_asantewaa_golden_stool', 1),
      );
      expect(grade!.canDoId, 'persona.yaa.ch1.honorific_greeting');
    });

    test('under-13 persona policy', () {
      expect(
        personaTurnRequiresUnder13Policy(
          personaAgeTierFromBirthYear(birthYear: 2015, nowYear: 2026),
        ),
        isTrue,
      );
    });

    test('assignment payload round-trip', () {
      const payload = PersonaChapterAssignmentPayload(
        questId: 'yaa_asantewaa_golden_stool',
        personaId: 'yaa_asantewaa',
        chapterIndex: 2,
        chapterId: 'the_demand',
        canDoId: 'persona.yaa.ch2.demand_comprehension',
        canDoStatementEn: 'Comprehension can-do',
        recipientUserIds: ['s1'],
      );
      final body = payload.toAssignmentBody(title: 'Chapter 2');
      final parsed = PersonaChapterAssignmentPayload.fromAssignmentJson({
        'payload': body['payload'],
      });
      expect(parsed?.chapterIndex, 2);
      expect(parsed?.recipientUserIds, ['s1']);
    });
  });
}
