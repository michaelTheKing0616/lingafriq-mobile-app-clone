import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../models/game/phrase_card_model.dart';
import '../../models/game/game_session_model.dart';
import 'base_game_screen.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Grammar Detective - Find and fix grammar errors
class GrammarDetectiveGame extends BaseGameScreen {
  const GrammarDetectiveGame({
    Key? key,
    required super.language,
    super.level,
    super.onBack,
  }) : super(key: key);

  @override
  GameType getGameType() => GameType.grammarDetective;

  @override
  ConsumerState<GrammarDetectiveGame> createState() => _GrammarDetectiveGameState();
}

class _GrammarDetectiveGameState extends BaseGameScreenState<GrammarDetectiveGame> {
  final List<_GrammarQuestion> _questions = [];
  int _currentIndex = 0;
  String? _selectedError;
  bool _showResult = false;

  @override
  int getCardCount() => 5;

  @override
  Future<void> onGameInitialized() async {
    // Generate grammar questions
    _questions.addAll([
      _GrammarQuestion(
        text: 'Mo n ko eko', // Missing diacritics
        correctError: 'Missing diacritics: "Mo ń kọ́ ẹ̀kọ́"',
        errors: ['Missing diacritics: "Mo ń kọ́ ẹ̀kọ́"', 'Wrong word order', 'Missing verb'],
      ),
      _GrammarQuestion(
        text: 'Bawo ni o?', // Missing diacritics
        correctError: 'Missing diacritics: "Báwo ní o?"',
        errors: ['Missing diacritics: "Báwo ní o?"', 'Wrong tense', 'Missing subject'],
      ),
    ]);
  }

  void _selectError(String error) {
    setState(() {
      _selectedError = error;
      _showResult = false;
    });
  }

  void _checkAnswer() {
    final question = _questions[_currentIndex];
    final correct = _selectedError == question.correctError;

    completeTurn(
      cardId: 'grammar_$_currentIndex',
      result: correct ? GameResult.correct : GameResult.incorrect,
      durationMs: _startTime != null
          ? DateTime.now().difference(_startTime!).inMilliseconds
          : 0,
      feedback: {'selected': _selectedError, 'correct': question.correctError},
    );

    setState(() => _showResult = true);
  }

  void _nextQuestion() {
    if (_currentIndex < _questions.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedError = null;
        _showResult = false;
      });
    } else {
      finishGame();
    }
  }

  @override
  Widget buildGameContent(BuildContext context) {
    if (_questions.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final question = _questions[_currentIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.getGameType().displayName} (${_currentIndex + 1}/${_questions.length})'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onBack ?? () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          children: [
            LinearProgressIndicator(
              value: (_currentIndex + 1) / _questions.length,
            ),
            SizedBox(height: 4.h),
            Card(
              child: Padding(
                padding: EdgeInsets.all(4.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Find the grammar error:',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      question.text,
                      style: TextStyle(fontSize: 24.sp),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 4.h),
            Expanded(
              child: ListView.builder(
                itemCount: question.errors.length,
                itemBuilder: (context, index) {
                  final error = question.errors[index];
                  final isSelected = _selectedError == error;
                  final isCorrect = error == question.correctError;

                  return Padding(
                    padding: EdgeInsets.only(bottom: 2.h),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _showResult ? null : () => _selectError(error),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: EdgeInsets.all(3.w),
                          decoration: BoxDecoration(
                            color: _showResult
                                ? (isCorrect
                                    ? Colors.green.withOpacity(0.3)
                                    : isSelected
                                        ? Colors.red.withOpacity(0.3)
                                        : Colors.grey[200])
                                : (isSelected
                                    ? Theme.of(context).colorScheme.primaryContainer
                                    : Colors.grey[200]),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(child: Text(error, style: TextStyle(fontSize: 16.sp))),
                              if (_showResult && isCorrect)
                                const Icon(Icons.check_circle, color: Colors.green),
                              if (_showResult && isSelected && !isCorrect)
                                const Icon(Icons.cancel, color: Colors.red),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            if (!_showResult)
              FilledButton(
                onPressed: _selectedError == null ? null : _checkAnswer,
                child: const Text('Check Answer'),
              )
            else
              Column(
                children: [
                  Text(
                    _selectedError == question.correctError
                        ? 'Correct! 🎉'
                        : 'Try again!',
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                      color: _selectedError == question.correctError
                          ? Colors.green
                          : Colors.red,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  FilledButton(
                    onPressed: _nextQuestion,
                    child: Text(_currentIndex < _questions.length - 1
                        ? 'Next Question'
                        : 'Finish'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _GrammarQuestion {
  final String text;
  final String correctError;
  final List<String> errors;

  _GrammarQuestion({
    required this.text,
    required this.correctError,
    required this.errors,
  });
}

