import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/config/api_contract.dart';

/// Smoke: critical learning + mentor paths stay aligned with backend mounts
/// (`node-backend-safe-push/src/contracts/mobileApiContract.ts`).
void main() {
  test('Learning v2, sync v2, packs, micro-mentors path strings', () {
    expect(ApiContract.syncV2.delta, '/api/v2/sync/delta');
    expect(ApiContract.syncV2.preferences, '/api/v2/sync/preferences');
    expect(ApiContract.syncV2.outboxPush, '/api/v2/sync/outbox/push');
    expect(ApiContract.contentPacks.manifest('yo'), '/api/v2/content-packs/yo/manifest');
    expect(ApiContract.learningV2.speakMissionEvaluate, '/api/v2/learning/speak-mission/evaluate');
    expect(ApiContract.learningV2.codeSwitchSession, '/api/v2/learning/code-switch/session');
    expect(ApiContract.learningV2.registerCoach, '/api/v2/learning/register-coach');
    expect(ApiContract.learningV2.toneTrainer, '/api/v2/learning/tone-trainer/evaluate');
    expect(ApiContract.learningV2.livingDictionaryEntries, '/api/v2/learning/living-dictionary/entries');
    expect(ApiContract.learningV2.classroomSchoolDashboard, '/api/v2/classroom/school/dashboard');
    expect(ApiContract.classroom.v2Roster('t1'), '/api/v2/classroom/t1/roster');
    expect(ApiContract.classroom.v2Privacy('t1'), '/api/v2/classroom/t1/privacy');
    expect(ApiContract.classroom.v2Assignments('t1'), '/api/v2/classroom/t1/assignments');
    expect(ApiContract.microMentorsV2.mentors, '/api/v2/micro-mentors/mentors');
    expect(ApiContract.microMentorsV2.mentorsMe, '/api/v2/micro-mentors/mentors/me');
    expect(ApiContract.learningV2.passportSessions, '/api/v2/passport/sessions');
    expect(ApiContract.learningV2.passportVerify('abc'), '/api/v2/passport/verify/abc');
    expect(ApiContract.contentPacks.verify('yo'), '/api/v2/content-packs/yo/verify');
  });
}
