/// Typed operations accepted by `POST /api/v2/sync/outbox/push`.
/// Keep in sync with `ALLOWED_TYPES` in `syncV2.controller.ts` (node-backend).
const Set<String> kSyncOutboxOperationTypes = {
  'progress_metrics_merge',
  'telemetry_events',
  'noop',
  'game_srs_upsert_many',
  'ai_chat_srs_upsert_many',
  'chat_draft_upsert',
  'chat_draft_delete',
  'classroom_attendance_checkin',
  'phrase_dna_attempt_submit',
  'micro_mentor_session_request',
  'micro_mentor_rubric_submit',
  'gamification_sync',
  'game_session_sync',
  'game_srs_sync',
  'ai_chat_history_sync',
  'ai_chat_srs_sync',
  'progress_sync',
  'onboarding_sync',
  'telemetry_sync',
  'learning_event',
};

bool isValidSyncOutboxOperationType(String type) =>
    kSyncOutboxOperationTypes.contains(type);
