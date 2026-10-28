library ai_chat_provider_groq;

import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/utils/transport_error_policy.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'base_provider.dart';
import 'api_provider.dart';
import 'user_provider.dart';
import 'package:lingafriq/services/learning/fsrs6_scheduler.dart';
import 'package:lingafriq/services/learning/memory_state.dart';
import 'package:lingafriq/services/learning_engine_bridge.dart';
import '../config/url_constants.dart';
import '../utils/diacritics_enforcer.dart';
import '../data/roleplay_dataset.dart';
import '../services/hybrid_polie/hybrid_polie_orchestrator.dart';
import '../services/telemetry_service.dart';
import '../services/env_config.dart';
import '../services/error/typed_errors.dart';
import '../utils/supported_languages.dart';
import '../services/ai/conversation_context_manager.dart';
import '../services/ai/conversation_practice_enhancer.dart';
import '../services/error/error_recovery_service.dart';
import '../services/monitoring/performance_analytics.dart';
import '../utils/structured_logger.dart';
import '../utils/api_service.dart';
import 'package:lingafriq/services/offline/persisted_outbox_service.dart';
import 'package:lingafriq/providers/dio_provider.dart';
import 'package:lingafriq/services/ai_gateway_client.dart';
import 'package:lingafriq/features/ai_chat/providers/groq_chat_models.dart';

export 'package:lingafriq/features/ai_chat/providers/groq_chat_models.dart';

part 'package:lingafriq/features/ai_chat/providers/groq_chat_fields.dart';
part 'package:lingafriq/features/ai_chat/providers/groq_chat_persistence.dart';
part 'package:lingafriq/features/ai_chat/providers/groq_chat_provider_mixin_1.dart';
part 'package:lingafriq/features/ai_chat/providers/groq_chat_stream_helpers.dart';
part 'package:lingafriq/features/ai_chat/providers/groq_chat_provider_mixin_2.dart';
part 'package:lingafriq/features/ai_chat/providers/groq_chat_provider_mixin_3.dart';
final groqChatProvider = NotifierProvider<GroqChatProvider, BaseProviderState>(() => GroqChatProvider());

class GroqChatProvider extends Notifier<BaseProviderState>
    with BaseProviderMixin, GroqChatFieldsMixin, GroqChatPersistenceMixin, GroqChatProviderMixin1, GroqChatStreamHelpers, GroqChatProviderMixin2, GroqChatProviderMixin3 {}
