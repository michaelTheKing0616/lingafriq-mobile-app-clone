const fs = require('fs');
const path = require('path');

const root = path.join(__dirname, 'lib');
const fileList = [
  'config/url_constants.dart',
  'data/lesson_content_manager.dart',
  'examples/integrated_screen_example.dart',
  'games/gamekit/game_kit.dart',
  'games/proverb_unlocker/proverb_unlocker_models.dart',
  'models/conversation_analytics_model.dart',
  'models/historical_personality_enhanced_model.dart',
  'models/lesson_item_model.dart',
  'models/review_progress_model.dart',
  'models/roleplay_progress_model.dart',
  'models/social_group.dart',
  'models/translation_history_model.dart',
  'models/tutor_progress_model.dart',
  'models/vocabulary_progress_model.dart',
  'screens/examples/errorhandler_integration_example.dart',
  'screens/examples/performance_utilities_example.dart',
  'screens/personalities/personality_chat_screen.dart',
  'screens/personalities/personality_selection_screen.dart',
  'screens/review/gamified_review_screen.dart',
  'services/adaptive_learning_service.dart',
  'services/advanced/smart_recommendations.dart',
  'services/ai/historical_personality_service.dart',
  'services/ai_chat_integration_service.dart',
  'services/ai_chat_services_registry.dart',
  'services/api_rate_limiter.dart',
  'services/api_retry_service.dart',
  'services/auth/biometric_auth.dart',
  'services/auth/biometric_auth_service.dart',
  'services/auth/credential_storage.dart',
  'services/auth/credential_storage_service.dart',
  'services/conversation/conversation_context_manager.dart',
  'services/conversation/conversation_practice_service.dart',
  'services/conversation/dialogue_flow_generator.dart',
  'services/conversation_analytics_service.dart',
  'services/enhanced_tts_service.dart',
  'services/enhanced_voice_service.dart',
  'services/env_config.dart',
  'services/historical_personality_enhanced_service.dart',
  'services/hybrid_polie/batch_processor.dart',
  'services/hybrid_polie/cache_service.dart',
  'services/hybrid_polie/canonical_phrase_service.dart',
  'services/hybrid_polie/ensemble_voting.dart',
  'services/hybrid_polie/hybrid_polie_orchestrator.dart',
  'services/hybrid_polie/model_router.dart',
  'services/hybrid_polie/pronunciation_service.dart',
  'services/hybrid_polie/translation_service.dart',
  'services/learning/adaptive_learning_engine.dart',
  'services/learning/adaptive_learning_service.dart',
  'services/learning/interactive_exercises_service.dart',
  'services/learning/spaced_repetition_service.dart',
  'services/lesson/lesson_item_service.dart',
  'services/lesson_item_verification_service.dart',
  'services/localization/dynamic_localization_service.dart',
  'services/media_import_service.dart',
  'services/monitoring/sentry_service.dart',
  'services/offline/background_sync_service.dart',
  'services/offline/cache_compression.dart',
  'services/offline/cache_encryption.dart',
  'services/offline/cache_eviction.dart',
  'services/offline/conflict_resolution.dart',
  'services/offline/offline_analytics.dart',
  'services/offline/offline_handler.dart',
  'services/offline/offline_service.dart',
  'services/offline/selective_sync.dart',
  'services/offline/sync_operations.dart',
  'services/offline_phrase_pack_manager.dart',
  'services/paywall_service.dart',
  'services/performance/performance_monitor_integrated.dart',
  'services/performance/screen_performance_tracker.dart',
  'services/polie_mention_handler.dart',
  'services/pronunciation_scoring_service.dart',
  'services/review/intelligent_review_service.dart',
  'services/review_progress_service.dart',
  'services/roleplay_progress_service.dart',
  'services/social_learning_service.dart',
  'services/translation/offline_translation_service.dart',
  'services/translation_history_service.dart',
  'services/translation_quality_service.dart',
  'services/tutor_progress_service.dart',
  'services/vocabulary_progress_service.dart',
  'services/voice/advanced_pronunciation_service.dart',
  'services/voice/audio_generation_service.dart',
  'services/voice/enhanced_stt_service.dart',
  'services/voice/pronunciation_analysis_service.dart',
  'services/voice/tone_drill_service.dart',
  'services/voice/tone_error_detection_service.dart',
  'utils/ai_chat_navigation_helper.dart',
  'utils/api_service.dart',
  'utils/api_versioning.dart',
  'utils/batch_processor.dart',
  'utils/certificate_pinning.dart',
  'utils/error_handler.dart',
  'utils/haptic_feedback_helper.dart',
  'utils/integration_helpers.dart',
  'utils/material3_migration_helper.dart',
  'utils/material3_motion.dart',
  'utils/performance_exports.dart',
  'utils/performance_utils.dart',
  'utils/performance_utils_consolidated.dart',
  'utils/print_replacement_helper.dart',
  'utils/rate_limiter.dart',
  'utils/request_batcher.dart',
  'utils/roleplay_session_helper.dart',
  'utils/screen_helpers.dart',
  'utils/screen_integration_helper.dart',
  'utils/security_headers_validator.dart',
  'utils/simple_cache.dart',
  'utils/structured_logger.dart',
  'utils/supported_languages.dart',
  'widgets/gamification/gamification_widgets.dart',
  'widgets/global/error_recovery_widget.dart',
  'widgets/global/graceful_degradation_wrapper.dart',
  'widgets/global/offline_banner.dart',
  'widgets/loading/loading_overlay.dart',
  'widgets/material3/enhanced_card.dart',
  'widgets/material3/haptic_button.dart',
  'widgets/material3/material3_migration_helper.dart',
  'widgets/offline/offline_indicator.dart',
  'widgets/performance/lazy_image.dart',
  'widgets/performance/optimized_list_view.dart',
  'widgets/performance/performance_tracked_widget.dart',
  'widgets/pronunciation/realtime_pronunciation_feedback.dart',
  'widgets/review/review_prompt_widget.dart',
  'widgets/translation_feedback_widget.dart',
];

// For batch_integration_script.dart: replace ALL /// with // in entire file
function fixBatchIntegrationScript() {
  const p = path.join(root, 'utils', 'batch_integration_script.dart');
  if (!fs.existsSync(p)) return 0;
  let content = fs.readFileSync(p, 'utf8');
  if (!content.includes('///')) return 0;
  content = content.replace(/\/\/\//g, '//');
  fs.writeFileSync(p, content);
  return 1;
}

// For other files: replace only the leading block of /// lines (dangling library doc) with //
function fixLeadingDocComment(filePath) {
  if (!fs.existsSync(filePath)) return 0;
  let content = fs.readFileSync(filePath, 'utf8');
  const lines = content.split(/\r?\n/);
  let i = 0;
  let changed = false;
  // Replace all /// in the initial block (/// lines and blank lines only from start)
  while (i < lines.length) {
    const line = lines[i];
    const trimmed = line.trimStart();
    if (trimmed.startsWith('///')) {
      lines[i] = line.replace(/^(\s*)\/\/\//, '$1//');
      changed = true;
      i++;
    } else if (trimmed === '') {
      i++;
    } else {
      break;
    }
  }
  if (!changed) return 0;
  fs.writeFileSync(filePath, lines.join('\n'));
  return 1;
}

let count = 0;
count += fixBatchIntegrationScript();

for (const rel of fileList) {
  if (rel === 'utils/batch_integration_script.dart') continue; // already done
  const fullPath = path.join(root, rel);
  count += fixLeadingDocComment(fullPath);
}

console.log('Files fixed:', count);
