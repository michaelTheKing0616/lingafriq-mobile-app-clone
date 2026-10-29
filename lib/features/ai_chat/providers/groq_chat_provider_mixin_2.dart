part of 'package:lingafriq/providers/ai_chat_provider_groq.dart';

mixin GroqChatProviderMixin2 on GroqChatStreamHelpers {
  Map<String, dynamic>? _parseJsonSafely(String jsonStr) {
    try {
      return jsonDecode(jsonStr) as Map<String, dynamic>?;
    } catch (e) {
      logger.error('JSON parse error', tag: 'ai-chat', error: e, context: {'preview': jsonStr.substring(0, jsonStr.length > 100 ? 100 : jsonStr.length)});
      // Try to extract partial data if possible
      try {
        // Remove problematic characters and try again
        final cleaned = jsonStr.replaceAll(RegExp(r'[\x00-\x1F]'), '');
        return jsonDecode(cleaned) as Map<String, dynamic>?;
      } catch (_) {
        return null;
      }
    }
  }

  Stream<String> sendMessageStream(String userMessage, {String? systemPromptOverride}) async* {
    final messageStartTime = DateTime.now();

    // Enhanced input validation and sanitization
    final sanitizedMessage = _sanitizeInput(userMessage);
    if (sanitizedMessage.trim().isEmpty) {
      throw Exception('Message cannot be empty');
    }

    // Validate message length (prevent extremely long messages)
    if (sanitizedMessage.length > 2000) {
      throw Exception('Message is too long. Please keep it under 2000 characters.');
    }

    _currentStreamCancel?.call();
    final cancelToken = CancelToken();
    _currentStreamCancel = () => cancelToken.cancel();

    final userMsg = ChatMessage(
      role: 'user',
      content: sanitizedMessage,
      timestamp: DateTime.now(),
    );
    _messages.add(userMsg);
    
    // Track roleplay turns
    if (_mode == PolieMode.roleplay) {
      _roleplayTurnCount++;
      // Detect branching choices (A, B, C or similar patterns)
      final branchPattern = RegExp(r'\b([ABC]|option\s+[123]|choice\s+[123])\b', caseSensitive: false);
      if (branchPattern.hasMatch(sanitizedMessage)) {
        final match = branchPattern.firstMatch(sanitizedMessage);
        if (match != null) {
          _roleplayBranches.add(match.group(1) ?? '');
        }
      }
    }
    
    state = state.copyWith();
    await _saveChatHistory();

    state = state.copyWith(isLoading: true);
    
    // Use system prompt override if provided (for content generation)
    var effectiveSystemPrompt = systemPromptOverride ?? _systemPrompt;
    
    // Enhance system prompt with conversation practice features
    final conversationId = '${_mode}_${_selectedLanguage}_$_sourceLanguage';
    final flowState = _practiceEnhancer.analyzeConversationFlow(
      messages: _messages.map((m) => {'role': m.role, 'content': m.content}).toList(),
      currentMessage: sanitizedMessage,
    );
    
    if (effectiveSystemPrompt != null && effectiveSystemPrompt.isNotEmpty) {
      final previousContext = _contextManager.getConversationInsights(conversationId);
      effectiveSystemPrompt = _practiceEnhancer.getEnhancedPrompt(
        conversationId: conversationId,
        flowState: flowState,
        basePrompt: effectiveSystemPrompt,
        currentTopic: previousContext['topics']?.isNotEmpty == true 
            ? (previousContext['topics'] as List).first 
            : null,
        userLevel: previousContext['user_level'] as String?,
        previousContext: previousContext.isNotEmpty ? previousContext : null,
      );
    }
    
    // Use Hybrid Polie if enabled and appropriate for the task
    if (_useHybridPolie && _hybridOrchestrator != null) {
      // Check if we should use hybrid routing
      final shouldUseHybrid = _mode == PolieMode.translation || 
                             _mode == PolieMode.tutor ||
                             _mode == PolieMode.vocab;
      
      if (shouldUseHybrid) {
        try {
          final hybridResponse = await _hybridOrchestrator!.orchestrate(
            userMessage: userMessage,
            mode: _mode,
            targetLanguage: _selectedLanguage,
            sourceLanguage: _sourceLanguage,
            groqProvider: this as GroqChatProvider,
            onTelemetry: (response, {required elapsedMs}) async {
              try {
                final telemetry = ref.read(telemetryServiceProvider);
                await telemetry.trackHybridPolieResponse(
                  mode: _mode.name,
                  language: _selectedLanguage,
                  modelUsed: response.model,
                  responseTimeMs: elapsedMs,
                  confidence: response.confidence,
                  diacriticsCorrected: response.diacriticsCorrected,
                  needsNativeReview: response.needsNativeReview,
                );
              } catch (e) {
                logger.error('Hybrid Polie telemetry failed', tag: 'ai-chat', error: e);
              }
            },
          );
          
          // Stream the response word by word for natural feel
          final words = hybridResponse.output.split(' ');
          for (int i = 0; i < words.length; i++) {
            if (_userInterrupt) {
              state = state.copyWith(isLoading: false);
              return;
            }
            
            final chunk = i == 0 ? words[i] : ' ${words[i]}';
            yield chunk;
            await Future.delayed(const Duration(milliseconds: 30)); // Natural typing speed
          }
          
          // Log telemetry if diacritics were corrected
          if (hybridResponse.diacriticsCorrected) {
            logger.info('Hybrid Polie: Diacritics corrected', tag: 'ai-chat', context: {'model': hybridResponse.model});
          }
          
          // Add assistant message
          final assistantMsg = ChatMessage(
            role: 'assistant',
            content: hybridResponse.output,
            timestamp: DateTime.now(),
          );
          _messages.add(assistantMsg);
          state = state.copyWith();
          await _saveChatHistory();
          
          // Save conversation context
          await _contextManager.saveConversationContext(
            conversationId: conversationId,
            messages: _messages.map((m) => {'role': m.role, 'content': m.content}).toList(),
          );
          
          // Add tutor prompts if in tutor mode
          if (_tutorMode && !_userInterrupt) {
            final reviewWord = _dueReview();
            if (reviewWord != null) {
              final tutorCue = "Review time! Translate '$reviewWord' to $_selectedLanguage.";
              yield "\n\n$tutorCue";
            } else {
              final tutorCue = _adaptiveTutorPrompt(_selectedLanguage);
              if (!hybridResponse.output.trim().endsWith("?") &&
                  !hybridResponse.output.toLowerCase().contains("your turn") &&
                  !hybridResponse.output.toLowerCase().contains("now you try")) {
                yield "\n\n$tutorCue";
              }
            }
          }
          
          _turn = ConversationTurn.user;
          state = state.copyWith(isLoading: false);
          return;
        } catch (e) {
          logger.warn('Hybrid Polie failed, falling back to standard mode', tag: 'ai-chat', error: e);

        }
      }
    }

    int retryCount = 0;
    int modelIndex = 0;

    while (true) {
      try {
        _turn = ConversationTurn.ai;
        _userInterrupt = false;

        // Try different model names if previous one failed
        final currentModel = GroqChatFieldsMixin._legacyModelLabels[modelIndex];

        // Ensure system prompt is not empty (use override if provided)
        final systemPrompt = (systemPromptOverride ?? _systemPrompt)?.trim() ?? 'You are Polie, a helpful AI language assistant for African languages.';
        
        // Build messages array - CRITICAL: Gateway API format
        // Groq expects:
        // - messages: array of {role: "user"|"assistant", content: string}
        // - system messages are passed separately (not in messages array for some models)
        // - For Groq, we can include system in messages array, but it's cleaner to pass separately
        
        var messagesList = <Map<String, dynamic>>[];
        
        // Filter messages by current mode and language to create scoped chat bodies
        // This ensures each mode × language combination has its own conversation history
        final scopedMessages = _messages.where((msg) {
          // Only include user and assistant messages (system is handled separately)
          return msg.content.trim().isNotEmpty && 
                 (msg.role == 'user' || msg.role == 'assistant');
        }).toList();
        
        // Add conversation messages, filtering out empty ones and ensuring valid roles
        for (final msg in scopedMessages) {
          final content = msg.content.trim();
          if (content.isNotEmpty) {
            // Ensure role is valid (user or assistant) - Groq only accepts these roles in messages array
            final role = (msg.role == 'user' || msg.role == 'assistant') 
                ? msg.role 
                : 'user';
            
            // Ensure content is a string and not null
            final contentStr = content.toString();
            if (contentStr.isNotEmpty && contentStr.length <= 100000) { // Groq has content length limits
              messagesList.add({
                "role": role,
                "content": contentStr,
              });
            }
          }
        }
        
        // CRITICAL: Ensure we have at least one user message (the current one)
        // The current user message should be the last one
        final currentUserMessage = sanitizedMessage.trim();
        if (currentUserMessage.isNotEmpty) {
          // Check if the last message is already this user message
          final lastMessage = messagesList.isNotEmpty ? messagesList.last : null;
          if (lastMessage == null || 
              lastMessage["role"] != "user" || 
              lastMessage["content"] != currentUserMessage) {
            // Add current user message
            messagesList.add({
              "role": "user",
              "content": currentUserMessage,
            });
          }
        }
        
        // Validate we have at least one user message
        final hasUserMessage = messagesList.any((m) => m["role"] == "user");
        if (messagesList.isEmpty || !hasUserMessage) {
          throw Exception('No valid messages to send. Please enter a message.');
        }
        
        // Final validation: Ensure all messages have required fields and correct types
        for (int i = 0; i < messagesList.length; i++) {
          final msg = messagesList[i];
          if (msg["role"] == null || msg["content"] == null) {
            throw Exception('Invalid message format at index $i: missing role or content');
          }
          if (msg["role"] is! String) {
            throw Exception('Invalid message format at index $i: role must be a string');
          }
          if (msg["content"] is! String) {
            // Convert to string if it's not already
            msg["content"] = msg["content"].toString();
          }
          final contentStr = msg["content"] as String;
          if (contentStr.isEmpty) {
            throw Exception('Invalid message format at index $i: content cannot be empty');
          }
          // Ensure role is valid (only user or assistant in messages array)
          if (msg["role"] != "user" && msg["role"] != "assistant") {
            throw Exception('Invalid message format at index $i: role must be "user" or "assistant"');
          }
        }
        
        // Ensure messages array is not empty after validation
        if (messagesList.isEmpty) {
          throw Exception('No valid messages after validation. Please try again.');
        }
        
        // Enhance conversation context with intelligent management
        final enhancedMessagesList = await _contextManager.getConversationContext(
          conversationId: conversationId,
          currentMessages: messagesList,
          systemPrompt: effectiveSystemPrompt ?? '',
          maxTokens: 2000, // Groq token limit consideration
        );
        
        // Use enhanced context (which may include summary)
        // Extract messages from enhanced context (excluding system prompt as it's added separately)
        messagesList = enhancedMessagesList
            .where((m) => m['role'] != 'system')
            .toList();
        
        // Limit messages array to last 20 messages (to avoid token limits)
        // Groq has token limits, so we keep recent conversation context
        if (messagesList.length > 20) {
          messagesList.removeRange(0, messagesList.length - 20);
        }
        
        // Update effective system prompt if enhanced context added a summary
        final enhancedSystemPrompt = enhancedMessagesList
            .where((m) => m['role'] == 'system')
            .map((m) => m['content'] as String)
            .join('\n\n');
        if (enhancedSystemPrompt.isNotEmpty) {
          effectiveSystemPrompt = enhancedSystemPrompt;
        }

        String output = '';
        try {
          final messagesForGateway = messagesList
              .map((m) => {
                    'role': m['role'] as String,
                    'content': m['content'] as String,
                  })
              .toList();
          await for (final delta in _gateway.streamChatTokens(
            messages: messagesForGateway,
            mode: _gatewayMode,
            temperature: _temperatureForMode(),
            maxTokens: _maxTokensForMode(),
            language: _targetLanguage,
            languageCode: SupportedLanguages.getLanguageCode(_targetLanguage),
            sourceLanguage: SupportedLanguages.getLanguageCode(_sourceLanguage),
            targetLanguage: SupportedLanguages.getLanguageCode(_targetLanguage),
            cefr: _cefrInfo.level,
            cancelToken: cancelToken,
          )) {
            if (_userInterrupt) {
              state = state.copyWith(isLoading: false);
              return;
            }
            output += delta;
            yield delta;
          }
        } on AiGatewayException catch (e) {
          throw Exception(AiGatewayClient.userMessageFor(e, body: e.body));
        }

        // Evaluate user performance and feed learning engine
        _lastResponseTime = DateTime.now().difference(messageStartTime).inMilliseconds / 1000.0;
        if (_messages.length >= 2) {
          final lastUser = _messages[_messages.length - 2].content;
          _evaluateUser(lastUser, output);
        }

        // Add tutor prompt if enabled
        if (_tutorMode && !_userInterrupt) {
          final reviewWord = _dueReview();
          if (reviewWord != null) {
            final tutorCue = "Review time! Translate '$reviewWord' to $_selectedLanguage.";
            output += "\n\n$tutorCue";
            yield "\n\n$tutorCue";
          } else {
            final tutorCue = _adaptiveTutorPrompt(_selectedLanguage);
            if (!output.trim().endsWith("?") &&
                !output.toLowerCase().contains("your turn") &&
                !output.toLowerCase().contains("now you try")) {
              output += "\n\n$tutorCue";
              yield "\n\n$tutorCue";
            }
          }
        }

        _turn = ConversationTurn.user;
        state = state.copyWith(isLoading: false);

        // Enhanced diacritics enforcement with metadata and audit logging
        final modeConstrainedOutput = _applyModeOutputContract(output);
        final diacriticsResult = DiacriticsEnforcer.enforceWithMetadata(
          modeConstrainedOutput,
          _selectedLanguage,
          enableFuzzy: true,
          fuzzyThreshold: 0.75,
        );
        
        final correctedOutput = diacriticsResult['text'] as String;
        final wasChanged = diacriticsResult['changed'] as bool;
        final metadata = diacriticsResult['metadata'] as Map<String, dynamic>;
        
        // Log telemetry event if diacritics were corrected
        if (wasChanged) {
          logger.info('Diacritics corrected', tag: 'ai-chat', context: {'method': metadata['method'], 'language': _selectedLanguage});
          // Track diacritics correction via telemetry service
          try {
            final telemetry = ref.read(telemetryServiceProvider);
            await telemetry.trackPoliePerformance(
              mode: _mode.name,
              language: _selectedLanguage,
              responseTimeMs: 0, // Would need to track start time
              tokenCount: output.length,
              diacriticsCorrected: true,
              modelUsed: GroqChatProviderMixin1._modelName,
              confidence: (metadata['score'] as num?)?.toDouble() ?? 1.0,
            );
          } catch (e) {
            logger.error('Error tracking diacritics correction', tag: 'ai-chat', error: e);
          }
        }

        final assistantMsg = ChatMessage(
          role: 'assistant',
          content: correctedOutput,
          timestamp: DateTime.now(),
        );

        _messages.add(assistantMsg);
        state = state.copyWith();
        await _saveChatHistory();

        // Track Polie performance metrics
        try {
          final responseTime = DateTime.now().difference(messageStartTime);
          final telemetry = ref.read(telemetryServiceProvider);
          await telemetry.trackPoliePerformance(
            mode: _mode.name,
            language: _selectedLanguage,
            responseTimeMs: responseTime.inMilliseconds,
            tokenCount: correctedOutput.length, // Approximate token count
            diacriticsCorrected: wasChanged,
            modelUsed: GroqChatProviderMixin1._modelName,
            confidence: (metadata['score'] as num?)?.toDouble(),
          );
        } catch (e) {
          logger.error('Error tracking Polie performance', tag: 'ai-chat', error: e);
        }

        return;
      } catch (e) {
        if (e is DioException && CancelToken.isCancel(e)) {
          state = state.copyWith(isLoading: false);
          return;
        }

        // Try next model name if we get a 404 (model not found)
        if (e is DioException && e.response?.statusCode == 404) {
          if (modelIndex < GroqChatFieldsMixin._legacyModelLabels.length - 1) {
            modelIndex++;
            GroqChatProviderMixin1._modelName = GroqChatFieldsMixin._legacyModelLabels[modelIndex];
            if (kDebugMode) {
              logger.warn('Model not found, trying alternative', tag: 'ai-chat', context: {'previousModel': GroqChatFieldsMixin._legacyModelLabels[modelIndex - 1], 'tryingModel': GroqChatProviderMixin1._modelName});
            }
            continue; // Try with next model
          }
        }

        if (retryCount < 1) {
          retryCount++;
          continue;
        }

        state = state.copyWith(isLoading: false);

        String errorMessage;
        if (e is DioException) {
          if (e.response != null) {
            final errorData = e.response!.data;
            if (e.response!.statusCode == 400) {
              logger.error('Gateway API 400 error', tag: 'ai-chat', context: {'errorData': errorData});
            }
          }
          errorMessage = TransportErrorPolicy.toUserMessage(e);
        } else if (e is TimeoutException) {
          errorMessage = 'Request timed out. Please try again.';
        } else {
          final errorStr = e.toString();
          if (errorStr.contains('Invalid request format')) {
            errorMessage = errorStr;
          } else {
            errorMessage = 'Failed to send message: ${errorStr.replaceAll('Exception: ', '')}';
          }
        }
        setProviderError(errorMessage);
        throw Exception(errorMessage);
      }
    }
  }
}
