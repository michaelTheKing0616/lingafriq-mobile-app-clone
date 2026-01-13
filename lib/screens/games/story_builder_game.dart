import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../models/game/phrase_card_model.dart';
import '../../models/game/game_session_model.dart';
import 'base_game_screen.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../providers/ai_chat_provider_groq.dart';
import '../../services/env_config.dart';

/// Story Builder - Collaborative story construction
class StoryBuilderGame extends BaseGameScreen {
  const StoryBuilderGame({
    Key? key,
    required super.language,
    super.level,
    super.onBack,
  }) : super(key: key);

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
  bool _isCheckingGrammar = false;

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
      _isCheckingGrammar = true;
    });

    // Evaluate grammar using Polie (Groq) when configured; safe fallback otherwise.
    GameResult result = GameResult.partial;
    Map<String, dynamic> feedback = {'sentence': sentence, 'turn': _currentTurn};
    if (EnvConfig.isGroqConfigured) {
      try {
        final polie = ref.read(groqChatProvider.notifier);
        final g = await polie.grammarCheck(widget.language, sentence);
        // Score mapping:
        // - >= 0.8: correct
        // - >= 0.55: partial
        // - < 0.55: wrong
        final score = g.score;
        result = score >= 0.8
            ? GameResult.correct
            : score >= 0.55
                ? GameResult.partial
                : GameResult.incorrect;
        feedback = {
          ...feedback,
          'grammar_score': score,
          'corrected': g.corrected,
          'errors': g.errors,
          'ai': 'groq',
        };
      } catch (_) {
        // Fall through to fallback below.
      }
    }

    // Offline / not configured fallback: heuristic based on basic sentence quality.
    if (!EnvConfig.isGroqConfigured) {
      final looksOk = sentence.length >= 10 && sentence.contains(RegExp(r'[.!?]$'));
      result = looksOk ? GameResult.partial : GameResult.incorrect;
      feedback = {
        ...feedback,
        'ai': 'fallback',
        'note': 'Grammar check not available (no Groq key).',
      };
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

    if (mounted) {
      setState(() => _isCheckingGrammar = false);
    }

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
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.getGameType().displayName),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onBack ?? () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          children: [
            Text(
              'Continue the story (${_maxTurns - _currentTurn} sentences left)',
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
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
            TextField(
              controller: _sentenceController,
              decoration: const InputDecoration(
                hintText: 'Type your sentence...',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
              onSubmitted: (_) => _addSentence(),
            ),
            SizedBox(height: 2.h),
            FilledButton(
              onPressed: (_currentTurn >= _maxTurns || _isCheckingGrammar) ? null : _addSentence,
              child: Text(
                _currentTurn >= _maxTurns
                    ? 'Story Complete!'
                    : _isCheckingGrammar
                        ? 'Checking…'
                        : 'Add Sentence',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

