part of 'package:lingafriq/providers/ai_chat_provider_groq.dart';

mixin GroqChatPersistenceMixin on GroqChatFieldsMixin {
  String get _chatHistoryKey {
    final modeName = _mode.toString().split('.').last;
    final language = (_targetLanguage.isNotEmpty ? _targetLanguage : _selectedLanguage)
        .toLowerCase()
        .replaceAll(' ', '_')
        .replaceAll(RegExp(r'[^a-z0-9_]'), '');
    return 'ai_chat_history_groq_${modeName}_$language';
  }

  String get _languageCodeForBackend {
    final language = (_targetLanguage.isNotEmpty ? _targetLanguage : _selectedLanguage)
        .toLowerCase()
        .replaceAll(' ', '_')
        .replaceAll(RegExp(r'[^a-z0-9_]'), '');
    return language;
  }

  String get _modeNameForBackend {
    return _mode == PolieMode.translation
        ? 'translation'
        : _mode == PolieMode.tutor
            ? 'tutor'
            : _mode == PolieMode.roleplay
                ? 'roleplay'
                : _mode == PolieMode.conversation
                    ? 'conversation'
                    : _mode == PolieMode.vocab
                        ? 'vocab'
                        : _mode == PolieMode.pronunciation
                            ? 'pronunciation'
                            : _mode == PolieMode.grammar
                                ? 'grammar'
                                : 'review';
  }

  Future<void> clearChat() async {
    _messages.clear();
    state = state.copyWith();
    await _saveChatHistory(); // Save empty history to clear this mode's history
        final modeName = _mode == PolieMode.translation ? "Translation" 
            : _mode == PolieMode.tutor ? "Tutor"
            : _mode == PolieMode.roleplay ? "Roleplay"
            : _mode == PolieMode.conversation ? "Conversation"
            : _mode == PolieMode.vocab ? "Vocab"
            : _mode == PolieMode.pronunciation ? "Pronunciation"
            : _mode == PolieMode.grammar ? "Grammar"
            : "Review";
        logger.info('Cleared chat history', tag: 'ai-chat', context: {'mode': modeName});
  }

  // ----- Persistence -----
  // Separate chat histories for each mode
  /// Chat history key scoped by mode × language (m × n chat bodies)
  /// This ensures each mode × language combination has its own conversation history
  Future<void> _saveChatHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final messagesJson = _messages.map((msg) => msg.toJson()).toList();
      await prefs.setString(_chatHistoryKey, jsonEncode(messagesJson));
      
      // Sync to backend (debounced to avoid too many calls)
      _syncChatHistoryToBackend();
    } catch (e) {
      logger.error('Error saving chat history', tag: 'ai-chat', error: e);
    }
  }

  /// Sync chat history to backend (debounced to avoid too many calls)
  Future<void> _syncChatHistoryToBackend() async {
    try {
      final user = ref.read(userProvider);
      if (user == null) return;

      // Debounce: only sync if last sync was more than 3 seconds ago
      final now = DateTime.now();
      if (_lastBackendSync != null && now.difference(_lastBackendSync!).inSeconds < 3) {
        return;
      }
      _lastBackendSync = now;

      // Use backend API directly for chat history
      try {
        final apiNotifier = ref.read(apiProvider.notifier);
        final success = await apiNotifier.saveAiChatHistory({
          'mode': _modeNameForBackend,
          'language_code': _languageCodeForBackend,
          'messages': _messages.map((m) => m.toJson()).toList(),
        });
        if (success) {
          logger.info('Chat history synced to backend', tag: 'ai-chat', context: {'mode': _modeNameForBackend, 'language': _languageCodeForBackend});
        }
      } catch (apiError) {
        logger.warn('Error syncing to backend API, falling back to sync queue', tag: 'ai-chat', error: apiError);
        // Fallback to sync queue
        await PersistedOutboxService.instance.enqueue(
          type: 'ai_chat_history_sync',
          data: {
            'user_id': user.id.toString(),
            'mode': _modeNameForBackend,
            'languageCode': _languageCodeForBackend,
            'messages': _messages.map((m) => m.toJson()).toList(),
            'timestamp': DateTime.now().toIso8601String(),
          },
        );
      }
    } catch (e) {
      logger.error('Error syncing chat history', tag: 'ai-chat', error: e);
    }
  }

  Future<void> _loadChatHistory() async {
    try {
      // Try loading from backend first
      try {
        final user = ref.read(userProvider);
        if (user != null) {
          final apiNotifier = ref.read(apiProvider.notifier);
          final backendHistory = await apiNotifier.getAiChatHistory(
            mode: _modeNameForBackend,
            languageCode: _languageCodeForBackend,
          );
          
          if (backendHistory != null && backendHistory.isNotEmpty) {
            _messages.clear();
            _messages.addAll(
              backendHistory.map((json) => ChatMessage.fromJson(json)),
            );
            final modeName = _mode == PolieMode.translation ? "Translation" 
                : _mode == PolieMode.tutor ? "Tutor"
                : _mode == PolieMode.roleplay ? "Roleplay"
                : _mode == PolieMode.conversation ? "Conversation"
                : _mode == PolieMode.vocab ? "Vocab"
                : _mode == PolieMode.pronunciation ? "Pronunciation"
                : _mode == PolieMode.grammar ? "Grammar"
                : "Review";
            logger.info('Loaded messages from backend', tag: 'ai-chat', context: {'count': _messages.length, 'mode': modeName, 'language': _languageCodeForBackend});
            state = state.copyWith();
            
            // Also save to local storage for offline access
            final prefs = await SharedPreferences.getInstance();
            final messagesJson = _messages.map((msg) => msg.toJson()).toList();
            await prefs.setString(_chatHistoryKey, jsonEncode(messagesJson));
            return;
          }
        }
      } catch (backendError) {
        logger.warn('Error loading from backend, trying local storage', tag: 'ai-chat', error: backendError);
      }
      
      // Fallback to local storage
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString(_chatHistoryKey);
      if (historyJson != null && historyJson.isNotEmpty) {
        final List<dynamic> messagesList = jsonDecode(historyJson);
        _messages.clear();
        _messages.addAll(
          messagesList.map((json) => ChatMessage.fromJson(json as Map<String, dynamic>)),
        );
        final modeName = _mode == PolieMode.translation ? "Translation" 
            : _mode == PolieMode.tutor ? "Tutor"
            : _mode == PolieMode.roleplay ? "Roleplay"
            : _mode == PolieMode.conversation ? "Conversation"
            : _mode == PolieMode.vocab ? "Vocab"
            : _mode == PolieMode.pronunciation ? "Pronunciation"
            : _mode == PolieMode.grammar ? "Grammar"
            : "Review";
        logger.info('Loaded messages from local storage', tag: 'ai-chat', context: {'count': _messages.length, 'mode': modeName});
        state = state.copyWith();
      } else {
        // No history for this mode × language combination
        _messages.clear();
        final modeName = _mode == PolieMode.translation ? "Translation" 
            : _mode == PolieMode.tutor ? "Tutor"
            : _mode == PolieMode.roleplay ? "Roleplay"
            : _mode == PolieMode.conversation ? "Conversation"
            : _mode == PolieMode.vocab ? "Vocab"
            : _mode == PolieMode.pronunciation ? "Pronunciation"
            : _mode == PolieMode.grammar ? "Grammar"
            : "Review";
        logger.info('No chat history found', tag: 'ai-chat', context: {'mode': modeName, 'language': _languageCodeForBackend});
        state = state.copyWith();
      }
    } catch (e) {
      logger.error('Error loading chat history', tag: 'ai-chat', error: e);
      // On error, clear messages to prevent showing wrong mode's history
      _messages.clear();
      state = state.copyWith();
    }
  }

  Future<void> _loadSRSMemory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final memoryJson = prefs.getString('srs_memory');
      if (memoryJson != null) {
        final Map<String, dynamic> memoryMap = jsonDecode(memoryJson);
        _memory.clear();
        memoryMap.forEach((key, value) {
          _memory[key] = WordMemory.fromJson(value);
        });
      }
    } catch (e) {
      logger.error('Error loading SRS memory', tag: 'ai-chat', error: e);
    }
  }

  Future<void> _saveCEFRInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('cefr_info', jsonEncode(_cefrInfo.toJson()));
    } catch (e) {
      logger.error('Error saving CEFR info', tag: 'ai-chat', error: e);
    }
  }

  Future<void> _loadCEFRInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cefrJson = prefs.getString('cefr_info');
      if (cefrJson != null) {
        _cefrInfo = CEFRInfo.fromJson(jsonDecode(cefrJson));
      }
    } catch (e) {
      logger.error('Error loading CEFR info', tag: 'ai-chat', error: e);
    }
  }

}
