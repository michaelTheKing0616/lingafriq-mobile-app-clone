import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:lingafriq/providers/ai_chat_provider_groq.dart';
import 'package:lingafriq/utils/app_colors.dart';
import 'package:lingafriq/utils/utils.dart';
import 'package:lingafriq/providers/tts_provider.dart';

class ListeningQuizScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> passageData;

  const ListeningQuizScreen({Key? key, required this.passageData})
      : super(key: key);

  @override
  ConsumerState<ListeningQuizScreen> createState() =>
      _ListeningQuizScreenState();
}

class _ListeningQuizScreenState extends ConsumerState<ListeningQuizScreen> {
  final FlutterTts _tts = FlutterTts();
  bool _hasListened = false;
  final Map<int, String?> _selectedAnswers = {};
  final Map<int, TextEditingController> _textControllers = {};

  @override
  void initState() {
    super.initState();
    _initTTS();
  }

  Future<void> _initTTS() async {
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.5);
  }

  @override
  void dispose() {
    // Stop any playing TTS
    try {
      final tts = ref.read(ttsProvider.notifier);
      tts.stop();
    } catch (e) {
      // Ignore if provider not available
    }
    for (var controller in _textControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _playPassage() async {
    final passage = widget.passageData['passage'] as String? ?? '';
    if (passage.isEmpty) return;
    
    try {
      final tts = ref.read(ttsProvider.notifier);
      // Use language from widget or default to English
      final language =
          (widget.passageData['language'] as String?)?.toLowerCase() ?? 'english';
      await tts.speak(passage, languageName: language);
      
      setState(() {
        _hasListened = true;
      });
    } catch (e) {
      debugPrint('Error playing passage: $e');
      // Still mark as listened even if TTS fails
      setState(() {
        _hasListened = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final questions = (widget.passageData['questions'] as List?) ?? [];
    final isDark = context.isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Listening Comprehension'),
        backgroundColor: AppColors.primaryGreen,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              color: isDark ? Colors.grey[800] : Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.play_circle_filled,
                          size: 64, color: AppColors.primaryGreen),
                      onPressed: _playPassage,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _hasListened
                          ? 'Tap to replay'
                          : 'Tap to listen to the passage',
                      style: TextStyle(
                        fontSize: 16.sp,
                        color: context.adaptive54,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            ...questions.asMap().entries.map((entry) {
              final index = entry.key;
              final q = entry.value as Map<String, dynamic>;
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildQuestionCard(q, index, isDark),
              );
            }),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _hasListened ? _submitAnswers : null,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Submit Answers'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionCard(Map<String, dynamic> q, int index, bool isDark) {
    final type = q['type'] as String? ?? 'open';
    final question = q['question'] as String? ?? '';

    return Card(
      color: isDark ? Colors.grey[800] : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Q${index + 1}: $question',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: context.adaptive,
              ),
            ),
            const SizedBox(height: 12),
            if (type == 'mcq') ...[
              ...((q['options'] as List?) ?? []).asMap().entries.map((opt) {
                final optIndex = opt.key;
                final optText = opt.value as String;
                return RadioListTile<String>(
                  title: Text(optText),
                  value: optText,
                  groupValue: _selectedAnswers[index],
                  onChanged: (value) {
                    setState(() {
                      _selectedAnswers[index] = value;
                    });
                  },
                );
              }),
            ] else ...[
              Builder(
                builder: (context) {
                  if (!_textControllers.containsKey(index)) {
                    _textControllers[index] = TextEditingController();
                  }
                  return TextField(
                    controller: _textControllers[index],
                    decoration: InputDecoration(
                      labelText: 'Your answer',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onChanged: (value) {
                      _selectedAnswers[index] = value;
                    },
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _submitAnswers() async {
    // Evaluate answers and show results
    // This would call the provider's evaluateOpenAnswer method
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Answers submitted!')),
      );
    }
  }
}

