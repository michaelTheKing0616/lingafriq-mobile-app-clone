import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../models/game/game_session_model.dart';
import '../../providers/ai_chat_provider_groq.dart';
import 'base_game_screen.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Story Builder - Collaborative story construction
class StoryBuilderGame extends BaseGameScreen {
  const StoryBuilderGame({
    super.key,
    required super.language,
    super.level,
    super.onBack,
  });

  @override
  GameType getGameType() => GameType.storyBuilder;

  @override
  ConsumerState<StoryBuilderGame> createState() => _StoryBuilderGameState();
}

class _StoryBuilderGameState extends BaseGameScreenState<StoryBuilderGame> {
  final List<String> _story = [];
  final TextEditingController _sentenceController = TextEditingController();
  int _currentTurn = 0;
  final int _maxTurns = 5;
  String? _prompt;

  @override
  int getCardCount() => 1;

  @override
  Future<void> onGameInitialized() async {
    setState(() {
      _prompt = 'Once upon a time, in a village...';
      _story.add(_prompt!);
    });
  }

  Future<void> _addSentence() async {
    final sentence = _sentenceController.text.trim();
    if (sentence.isEmpty) return;

    setState(() {
      _story.add(sentence);
      _sentenceController.clear();
      _currentTurn++;
    });

    // Evaluate grammar using AI chat provider
    GameResult result = GameResult.correct;
    Map<String, dynamic> feedback = {'sentence': sentence, 'turn': _currentTurn};
    
    try {
      final aiChatProvider = ref.read(groqChatProvider.notifier);
      final grammarCheck = await aiChatProvider.grammarCheck(widget.language, sentence);
      
      if (grammarCheck.score < 0.8 || grammarCheck.errors.isNotEmpty) {
        result = grammarCheck.errors.isEmpty 
            ? GameResult.partial 
            : GameResult.incorrect;
        feedback['grammar_errors'] = grammarCheck.errors;
        feedback['grammar_score'] = grammarCheck.score;
        feedback['corrected'] = grammarCheck.corrected;
        feedback['suggestions'] = grammarCheck.errors.map((e) => e['suggestion'] ?? e['message'] ?? '').where((s) => s.isNotEmpty).toList();
      } else {
        feedback['grammar_score'] = grammarCheck.score;
      }
    } catch (e) {
      debugPrint('Grammar check error: $e');
      // If grammar check fails, accept the sentence but note the error
      result = GameResult.partial;
      feedback['grammar_check_error'] = 'Unable to verify grammar';
    }

    final duration = startTime != null
        ? DateTime.now().difference(startTime!).inMilliseconds
        : 0;

    completeTurn(
      cardId: 'story_turn_$_currentTurn',
      result: result,
      durationMs: duration,
      feedback: feedback,
    );

    if (_currentTurn >= _maxTurns) {
      finishGame();
    }
  }

  @override
  void dispose() {
    _sentenceController.dispose();
    super.dispose();
  }

  @override
  Widget buildGameContent(BuildContext context) {
    try {
      return Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          children: [
            Semantics(
              label: 'Continue the story, ${_maxTurns - _currentTurn} sentences remaining',
              child: Text(
                'Continue the story (${_maxTurns - _currentTurn} sentences left)',
                style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(height: 2.h),
            Expanded(
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(4.w),
                  child: ListView.builder(
                    itemCount: _story.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: EdgeInsets.only(bottom: 1.h),
                        child: Text(
                          _story[index],
                          style: TextStyle(fontSize: 16.sp),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            SizedBox(height: 2.h),
            Semantics(
              label: 'Type your sentence to add to the story',
              textField: true,
              child: TextField(
                controller: _sentenceController,
                decoration: const InputDecoration(
                  hintText: 'Type your sentence...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
                onSubmitted: (_) => _addSentence(),
              ),
            ),
            SizedBox(height: 2.h),
            Semantics(
              label: _currentTurn >= _maxTurns ? 'Story complete' : 'Add sentence to story',
              button: true,
              enabled: _currentTurn < _maxTurns,
              child: FilledButton(
                onPressed: _currentTurn >= _maxTurns ? null : _addSentence,
                child: Text(_currentTurn >= _maxTurns ? 'Story Complete!' : 'Add Sentence'),
              ),
            ),
          ],
        ),
      );
    } catch (e, st) {
      debugPrint('StoryBuilderGame buildGameContent: $e $st');
      rethrow;
    }
  }
}

