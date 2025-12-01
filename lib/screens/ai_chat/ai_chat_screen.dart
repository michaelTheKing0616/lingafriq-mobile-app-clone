import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/providers/ai_chat_provider_groq.dart';
import 'package:lingafriq/providers/dialog_provider.dart';
import 'package:lingafriq/providers/tts_provider.dart';
import 'package:lingafriq/utils/app_colors.dart';
import 'package:lingafriq/utils/utils.dart';
import 'package:lingafriq/widgets/top_gradient_box_builder.dart';
import 'package:lingafriq/widgets/primary_button.dart';
import 'package:lingafriq/screens/tabs_view/app_drawer/app_drawer.dart';
import 'package:lingafriq/utils/progress_integration.dart';
import 'package:lingafriq/widgets/error_boundary.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AiChatScreen extends ConsumerStatefulWidget {
  const AiChatScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends ConsumerState<AiChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  final AudioRecorder _audioRecorder = AudioRecorder();
  String? _currentRecordingPath;
  String _streamingText = '';
  bool _isStreaming = false;
  bool _isRecording = false;
  bool _voiceInputEnabled = true;
  bool _voiceOutputEnabled = true;
  String? _lastAssistantMessage;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _audioRecorder.dispose();
    if (_isStreaming) {
      ref.read(groqChatProvider.notifier).interruptAI();
    }
    super.dispose();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _voiceInputEnabled = prefs.getBool('ai_chat_voice_input') ?? true;
      _voiceOutputEnabled = prefs.getBool('ai_chat_voice_output') ?? true;
    });
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('ai_chat_voice_input', _voiceInputEnabled);
    await prefs.setBool('ai_chat_voice_output', _voiceOutputEnabled);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage({String? voiceMessage}) async {
    final message = voiceMessage ?? _messageController.text.trim();
    if (message.isEmpty) return;

    if (_isStreaming) {
      ref.read(groqChatProvider.notifier).interruptAI();
    }

    _messageController.clear();
    _focusNode.unfocus();

    setState(() {
      _streamingText = '';
      _isStreaming = true;
      _lastAssistantMessage = null;
    });

    try {
      final provider = ref.read(groqChatProvider.notifier);
      String fullResponse = '';
      await for (final chunk in provider.sendMessageStream(message)) {
        if (mounted) {
          setState(() {
            _streamingText += chunk;
            fullResponse += chunk;
            _lastAssistantMessage = fullResponse;
          });
          _scrollToBottom();
        }
      }

      if (mounted && fullResponse.isNotEmpty) {
        await ProgressIntegration.onChatActivity(
          ref,
          minutes: _estimateChatMinutes(fullResponse),
          wordsLearned: _estimateWordsLearned(fullResponse),
        );
      }

      if (mounted && _voiceOutputEnabled && fullResponse.isNotEmpty) {
        final tts = ref.read(ttsProvider.notifier);
        await tts.speak(fullResponse, languageName: provider.targetLanguage);
      }
    } catch (e) {
      if (mounted) {
        ref.read(dialogProvider('')).showPlatformDialogue(
              title: 'Error',
              content: Text(e.toString().replaceAll('Exception: ', '')),
              action1Text: 'OK',
            );
      }
    } finally {
      if (mounted) {
        setState(() {
          _streamingText = '';
          _isStreaming = false;
        });
      }
    }
  }

  Future<void> _startVoiceRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final tempDir = await getTemporaryDirectory();
        final filePath =
            '${tempDir.path}/polie_voice_${DateTime.now().millisecondsSinceEpoch}.wav';

        await _audioRecorder.start(
          const RecordConfig(
            encoder: AudioEncoder.wav,
            sampleRate: 16000,
            numChannels: 1,
          ),
          path: filePath,
        );
        setState(() {
          _isRecording = true;
          _currentRecordingPath = filePath;
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Microphone permission denied')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error starting recording: $e')),
        );
      }
    }
  }

  Future<void> _stopVoiceRecording() async {
    try {
      final path = await _audioRecorder.stop();
      setState(() {
        _isRecording = false;
      });

      final recordingPath = path ?? _currentRecordingPath;
      _currentRecordingPath = null;

      if (recordingPath != null) {
        final file = await File(recordingPath).readAsBytes();
        final audioData = Uint8List.fromList(file);
        
        final provider = ref.read(groqChatProvider.notifier);
        final transcribedText = await provider.transcribeAudio(audioData);
        
        if (transcribedText.isNotEmpty) {
          await _sendMessage(voiceMessage: transcribedText);
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Could not transcribe audio. Please try again.')),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error stopping recording: $e')),
        );
      }
      setState(() {
        _isRecording = false;
      });
      _currentRecordingPath = null;
    }
  }

  Future<void> _clearChat() async {
    final result = await ref.read(dialogProvider('')).showPlatformDialogue(
          title: 'Clear Chat',
          content: const Text('Are you sure you want to clear all messages?'),
          action1Text: 'Clear',
          action2Text: 'Cancel',
          action1OnTap: true,
          action2OnTap: false,
        );

    if (result == true) {
      await ref.read(groqChatProvider.notifier).clearChat();
      setState(() {
        _streamingText = '';
        _isStreaming = false;
      });
    }
  }

  void _showLanguageDirectionDialog(BuildContext context, bool isDark) {
    final chatNotifier = ref.read(groqChatProvider.notifier);
    final sourceLanguage = chatNotifier.sourceLanguage;
    final targetLanguage = chatNotifier.targetLanguage;
    
    final languages = [
      'English', 'Yoruba', 'Hausa', 'Igbo', 'Swahili', 'Zulu', 
      'Xhosa', 'Amharic', 'Pidgin', 'Twi', 'Afrikaans', 'French', 'Arabic'
    ];

    String? selectedSource = sourceLanguage;
    String? selectedTarget = targetLanguage;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1F3527) : Colors.white,
        title: Text(
          'Language Direction',
          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'I speak:',
              style: TextStyle(
                color: isDark ? Colors.grey[300] : Colors.grey[700],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: selectedSource,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: isDark ? const Color(0xFF2A4A35) : Colors.grey[100],
              ),
              dropdownColor: isDark ? const Color(0xFF1F3527) : Colors.white,
              style: TextStyle(color: isDark ? Colors.white : Colors.black87),
              items: languages.map((lang) => DropdownMenuItem(
                value: lang,
                child: Text(lang),
              )).toList(),
              onChanged: (value) {
                selectedSource = value;
              },
            ),
            const SizedBox(height: 24),
            Text(
              'I want to learn:',
              style: TextStyle(
                color: isDark ? Colors.grey[300] : Colors.grey[700],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: selectedTarget,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: isDark ? const Color(0xFF2A4A35) : Colors.grey[100],
              ),
              dropdownColor: isDark ? const Color(0xFF1F3527) : Colors.white,
              style: TextStyle(color: isDark ? Colors.white : Colors.black87),
              items: languages.map((lang) => DropdownMenuItem(
                value: lang,
                child: Text(lang),
              )).toList(),
              onChanged: (value) {
                selectedTarget = value;
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () {
              if (selectedSource != null && selectedTarget != null) {
                chatNotifier.setLanguageDirection(selectedSource!, selectedTarget!);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Language direction set: $selectedSource → $selectedTarget'),
                    backgroundColor: AppColors.primaryGreen,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              foregroundColor: Colors.white,
            ),
            child: const Text('Set'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ErrorBoundary(
      errorMessage: 'AI Chat is temporarily unavailable',
      onRetry: () {
        // Retry by rebuilding
        setState(() {});
      },
      child: _buildChatContent(context),
    );
  }

  Widget _buildChatContent(BuildContext context) {
    final chatNotifier = ref.read(groqChatProvider.notifier);
    final chatState = ref.watch(groqChatProvider);
    final isDark = context.isDarkMode;
    final theme = Theme.of(context);

    return Theme(
      data: theme.copyWith(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primaryGreen,
          brightness: isDark ? Brightness.dark : Brightness.light,
        ),
      ),
      child: Scaffold(
        drawer: const AppDrawer(),
        backgroundColor: isDark ? const Color(0xFF102216) : const Color(0xFFF6F8F6),
        body: SafeArea(
          child: Column(
            children: [
              // Material 3 App Bar
              _buildMaterial3AppBar(context, chatNotifier, isDark),
              
              // Chat Messages
              Expanded(
                child: chatNotifier.messages.isEmpty
                    ? _buildEmptyState(context, isDark)
                    : _buildChatMessages(context, chatNotifier, isDark),
              ),
              
              // Material 3 Input Area
              _buildMaterial3Input(context, chatNotifier, isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMaterial3AppBar(BuildContext context, GroqChatProvider chatNotifier, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F3527) : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? const Color(0xFF2A4A35) : const Color(0xFFE5E5E5),
            width: 1,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Builder(
                  builder: (context) => IconButton(
                    icon: Icon(Icons.menu_rounded, color: isDark ? Colors.white : Colors.black87),
                    onPressed: () => Scaffold.of(context).openDrawer(),
                    style: IconButton.styleFrom(
                      backgroundColor: isDark ? Colors.transparent : Colors.grey[100],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'LingAfriq Polyglot (Polie)',
                        style: TextStyle(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      if (chatNotifier.hasMessages)
                        Text(
                          '${chatNotifier.messages.length} messages',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.language, color: isDark ? Colors.white70 : Colors.grey[700]),
                  onPressed: () => _showLanguageDirectionDialog(context, isDark),
                  tooltip: 'Language direction',
                ),
                if (chatNotifier.hasMessages)
                  IconButton(
                    icon: Icon(Icons.delete_outline, color: isDark ? Colors.white70 : Colors.grey[700]),
                    onPressed: _clearChat,
                    tooltip: 'Clear chat',
                  ),
                IconButton(
                  icon: Icon(Icons.arrow_back_ios_new, color: isDark ? Colors.white70 : Colors.grey[700]),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SegmentedButton<PolieMode>(
              segments: const [
                ButtonSegment(
                  value: PolieMode.translation,
                  label: Text('Translation'),
                  icon: Icon(Icons.translate_rounded, size: 16),
                ),
                ButtonSegment(
                  value: PolieMode.tutor,
                  label: Text('Tutor'),
                  icon: Icon(Icons.school_rounded, size: 16),
                ),
              ],
              selected: {chatNotifier.mode},
              onSelectionChanged: (selection) {
                if (selection.isEmpty) return;
                chatNotifier.setMode(selection.first);
              },
              style: ButtonStyle(
                visualDensity: VisualDensity.compact,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                padding: MaterialStateProperty.all(const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          // Material 3 Card with gradient
          Card(
            elevation: 0,
            color: isDark ? const Color(0xFF1F3527) : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: BorderSide(
                color: isDark ? const Color(0xFF2A4A35) : const Color(0xFFE5E5E5),
              ),
            ),
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primaryGreen.withOpacity(0.1),
                    AppColors.accentGold.withOpacity(0.1),
                  ],
                ),
              ),
              child: Icon(
                Icons.psychology_rounded,
                size: 80.sp,
                color: AppColors.primaryGreen,
              ),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Start Learning with Polie',
            style: TextStyle(
              fontSize: 28.sp,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Chat with LingAfriq Polyglot, your AI language tutor.\nPractice African languages, ask questions, have conversations, or get help with translations.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16.sp,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
              height: 1.5,
            ),
          ),
          const SizedBox(height: 40),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: [
              _buildSuggestionChip('How do I say hello in Swahili?', isDark),
              _buildSuggestionChip('Translate "thank you" to Yoruba', isDark),
              _buildSuggestionChip('Practice Pidgin English conversation', isDark),
              _buildSuggestionChip('Explain Igbo grammar', isDark),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionChip(String text, bool isDark) {
    return FilledButton.tonal(
      onPressed: () {
        _messageController.text = text;
        _sendMessage();
      },
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primaryGreen.withOpacity(0.1),
        foregroundColor: AppColors.primaryGreen,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 14.sp),
      ),
    );
  }

  Widget _buildChatMessages(BuildContext context, GroqChatProvider chatProvider, bool isDark) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: chatProvider.messages.length + (_isStreaming ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == chatProvider.messages.length && _isStreaming) {
          return _buildStreamingBubble(context, isDark);
        }
        final message = chatProvider.messages[index];
        return _buildMessageBubble(context, message, isDark);
      },
    );
  }

  Widget _buildStreamingBubble(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.primaryGreen,
            child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Card(
              elevation: 0,
              color: isDark ? const Color(0xFF1F3527) : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isDark ? const Color(0xFF2A4A35) : const Color(0xFFE5E5E5),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _streamingText.isEmpty ? '...' : _streamingText,
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                        fontSize: 15.sp,
                        height: 1.5,
                      ),
                    ),
                    if (_streamingText.isNotEmpty) const SizedBox(height: 8),
                    if (_streamingText.isNotEmpty)
                      Row(
                        children: [
                          SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryGreen),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Polie is typing...',
                            style: TextStyle(
                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                              fontSize: 11.sp,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(BuildContext context, ChatMessage message, bool isDark) {
    final isUser = message.role == 'user';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.primaryGreen,
              child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
          ],
          Flexible(
            child: Card(
              elevation: 0,
              color: isUser
                  ? AppColors.primaryGreen
                  : (isDark ? const Color(0xFF1F3527) : Colors.white),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: isUser
                    ? BorderSide.none
                    : BorderSide(
                        color: isDark ? const Color(0xFF2A4A35) : const Color(0xFFE5E5E5),
                      ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message.content,
                      style: TextStyle(
                        color: isUser ? Colors.white : (isDark ? Colors.white : Colors.black87),
                        fontSize: 15.sp,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _formatTime(message.timestamp),
                      style: TextStyle(
                        color: isUser
                            ? Colors.white70
                            : (isDark ? Colors.grey[400] : Colors.grey[600]),
                        fontSize: 11.sp,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 12),
            CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.accentGold.withOpacity(0.2),
              child: Icon(
                Icons.person_rounded,
                color: AppColors.accentGold,
                size: 20,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMaterial3Input(BuildContext context, GroqChatProvider chatProvider, bool isDark) {
    final isLoading = chatProvider.isBusy || _isStreaming;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F3527) : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF2A4A35) : const Color(0xFFE5E5E5),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 12,
            bottom: 12 + MediaQuery.of(context).viewPadding.bottom,
          ),
          child: Row(
            children: [
              // Voice input button
              if (_voiceInputEnabled && !_isRecording)
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.accentGold.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(Icons.mic_rounded, color: AppColors.accentGold),
                    onPressed: isLoading ? null : _startVoiceRecording,
                    tooltip: 'Voice input',
                  ),
                ),
              if (_isRecording)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.stop_rounded, color: Colors.red),
                    onPressed: _stopVoiceRecording,
                    tooltip: 'Stop recording',
                  ),
                ),
              if (_voiceInputEnabled) const SizedBox(width: 8),
              
              // Text input
              Expanded(
                child: TextField(
                  controller: _messageController,
                  focusNode: _focusNode,
                  enabled: !isLoading,
                  maxLines: null,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendMessage(),
                  onChanged: (_) {
                    if (_isStreaming) {
                      ref.read(groqChatProvider.notifier).interruptAI();
                      setState(() {
                        _isStreaming = false;
                        _streamingText = '';
                      });
                    }
                  },
                  decoration: InputDecoration(
                    hintText: chatProvider.isTranslationMode
                        ? 'Enter text for Polie to translate...'
                        : 'Type your message...',
                    hintStyle: TextStyle(
                      color: isDark ? Colors.grey[500] : Colors.grey[500],
                      fontSize: 15.sp,
                    ),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF102216) : Colors.grey[50],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                  ),
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontSize: 15.sp,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              
              // Send button
              FilledButton(
                onPressed: isLoading ? null : _sendMessage,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(16),
                  shape: const CircleBorder(),
                  minimumSize: const Size(48, 48),
                ),
                child: isLoading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.send_rounded, size: 20),
              ),
              const SizedBox(width: 8),
              
              // Voice output toggle
              PopupMenuButton<String>(
                icon: Icon(
                  _voiceOutputEnabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                  color: _voiceOutputEnabled ? AppColors.primaryGreen : (isDark ? Colors.grey[500] : Colors.grey[500]),
                ),
                tooltip: 'Voice settings',
                onSelected: (value) {
                  if (value == 'toggle_voice_output') {
                    setState(() {
                      _voiceOutputEnabled = !_voiceOutputEnabled;
                    });
                    _savePreferences();
                  } else if (value == 'toggle_voice_input') {
                    setState(() {
                      _voiceInputEnabled = !_voiceInputEnabled;
                    });
                    _savePreferences();
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'toggle_voice_output',
                    child: Row(
                      children: [
                        Icon(
                          _voiceOutputEnabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(_voiceOutputEnabled ? 'Disable Voice Output' : 'Enable Voice Output'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'toggle_voice_input',
                    child: Row(
                      children: [
                        Icon(
                          _voiceInputEnabled ? Icons.mic_rounded : Icons.mic_off_rounded,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(_voiceInputEnabled ? 'Disable Voice Input' : 'Enable Voice Input'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  double _estimateChatMinutes(String text) {
    final words = _countWords(text);
    if (words == 0) return 0;
    final minutes = words / 110;
    return minutes.clamp(0.25, 8.0);
  }

  int _estimateWordsLearned(String text) {
    final words = _countWords(text);
    if (words == 0) return 0;
    return max(1, (words / 14).floor());
  }

  int _countWords(String text) {
    if (text.trim().isEmpty) return 0;
    return text.trim().split(RegExp(r'\s+')).length;
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
    }
  }
}
