import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../models/game/game_session_model.dart';
import 'base_game_screen.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Grammar Detective - Find and fix grammar errors
class GrammarDetectiveGame extends BaseGameScreen {
  const GrammarDetectiveGame({
    super.key,
    required super.language,
    super.level,
    super.onBack,
  });

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
      durationMs: startTime != null
          ? DateTime.now().difference(startTime!).inMilliseconds
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
  String? get appBarTitle =>
      _questions.isEmpty ? null : '${widget.getGameType().displayName} (${_currentIndex + 1}/${_questions.length})';

  @override
  Widget buildGameContent(BuildContext context) {
    try {
      if (_questions.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }

      final question = _questions[_currentIndex];

      return Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          children: [
            Semantics(
              label: 'Progress: question ${_currentIndex + 1} of ${_questions.length}',
              value: '${_currentIndex + 1} of ${_questions.length}',
              child: LinearProgressIndicator(
                value: (_currentIndex + 1) / _questions.length,
              ),
            ),
            SizedBox(height: 4.h),
            Semantics(
              label: 'Sentence to check: ${question.text}',
              child: Card(
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
                    child: Semantics(
                      label: 'Error option: $error',
                      button: true,
                      selected: isSelected,
                      enabled: !_showResult,
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
                                  const Icon(Icons.check_circle, color: Colors.green, semanticLabel: 'Correct'),
                                if (_showResult && isSelected && !isCorrect)
                                  const Icon(Icons.cancel, color: Colors.red, semanticLabel: 'Incorrect'),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            if (!_showResult)
              Semantics(
                label: 'Check answer button',
                button: true,
                enabled: _selectedError != null,
                child: FilledButton(
                  onPressed: _selectedError == null ? null : _checkAnswer,
                  child: const Text('Check Answer'),
                ),
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
                  Semantics(
                    label: _currentIndex < _questions.length - 1 ? 'Next question' : 'Finish game',
                    button: true,
                    child: FilledButton(
                      onPressed: _nextQuestion,
                      child: Text(_currentIndex < _questions.length - 1
                          ? 'Next Question'
                          : 'Finish'),
                    ),
                  ),
                ],
              ),
          ],
        ),
      );
    } catch (e, st) {
      debugPrint('GrammarDetectiveGame buildGameContent: $e $st');
      rethrow;
    }
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

