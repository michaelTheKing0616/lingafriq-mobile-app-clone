import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../models/game/game_session_model.dart';
import 'base_game_screen.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../widgets/game_ui/index.dart';

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
      // Yoruba
      _GrammarQuestion(
        text: 'Mo n ko eko',
        correctError: 'Missing diacritics: "Mo ń kọ́ ẹ̀kọ́"',
        errors: ['Missing diacritics: "Mo ń kọ́ ẹ̀kọ́"', 'Wrong word order', 'Missing verb'],
      ),
      _GrammarQuestion(
        text: 'Bawo ni o?',
        correctError: 'Missing diacritics: "Báwo ní o?"',
        errors: ['Missing diacritics: "Báwo ní o?"', 'Wrong tense', 'Missing subject'],
      ),
      _GrammarQuestion(
        text: 'Ó fẹ́ jẹ oúnjẹ',
        correctError: 'Wrong tone marker: should be "Ó fẹ́ jẹun oúnjẹ"',
        errors: ['Wrong tone marker: should be "Ó fẹ́ jẹun oúnjẹ"', 'Missing subject', 'Wrong word order'],
      ),
      // Hausa
      _GrammarQuestion(
        text: 'Ina zuwa kasuwa jiya',
        correctError: 'Wrong tense: "Na je kasuwa jiya" (past tense required)',
        errors: ['Wrong tense: "Na je kasuwa jiya" (past tense required)', 'Missing diacritics', 'Wrong word order'],
      ),
      _GrammarQuestion(
        text: 'Shi yana da kyau',
        correctError: 'Wrong pronoun gender: "Ita tana da kyau" (feminine subject)',
        errors: ['Wrong pronoun gender: "Ita tana da kyau" (feminine subject)', 'Missing verb', 'Wrong tense'],
      ),
      // Igbo
      _GrammarQuestion(
        text: 'Ọ na-aga ahịa echi',
        correctError: 'Wrong tense: "Ọ ga-aga ahịa echi" (future tense required)',
        errors: ['Wrong tense: "Ọ ga-aga ahịa echi" (future tense required)', 'Missing subject', 'Wrong word order'],
      ),
      _GrammarQuestion(
        text: 'Anyị nọ na ụlọ akwụkwọ',
        correctError: 'Missing auxiliary verb: "Anyị nọ n\'ụlọ akwụkwọ"',
        errors: ['Missing auxiliary verb: "Anyị nọ n\'ụlọ akwụkwọ"', 'Wrong pronoun', 'Wrong tense'],
      ),
      // Swahili
      _GrammarQuestion(
        text: 'Mimi kupenda chakula',
        correctError: 'Missing subject prefix: "Mimi napenda chakula"',
        errors: ['Missing subject prefix: "Mimi napenda chakula"', 'Wrong word order', 'Missing object'],
      ),
      _GrammarQuestion(
        text: 'Watoto wanacheza mpira jana',
        correctError: 'Wrong tense marker: "Watoto walicheza mpira jana" (past tense)',
        errors: ['Wrong tense marker: "Watoto walicheza mpira jana" (past tense)', 'Missing subject', 'Wrong noun class'],
      ),
      // Zulu
      _GrammarQuestion(
        text: 'Ngiya eskoleni kusasa',
        correctError: 'Wrong tense prefix: "Ngizoya eskoleni kusasa" (future tense)',
        errors: ['Wrong tense prefix: "Ngizoya eskoleni kusasa" (future tense)', 'Missing object', 'Wrong word order'],
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
        padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 16.h),
        child: Column(
          children: [
            Semantics(
              label: 'Progress: question ${_currentIndex + 1} of ${_questions.length}',
              value: '${_currentIndex + 1} of ${_questions.length}',
              child: LinearProgressIndicator(
                value: (_currentIndex + 1) / _questions.length,
              ),
            ),
            SizedBox(height: 12.h),
            Semantics(
              label: 'Sentence to check: ${question.text}',
              child: GameCard(
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
                    SizedBox(height: 8.h),
                    Text(
                      question.text,
                      style: TextStyle(fontSize: 24.sp),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 14.h),
            Expanded(
              child: ListView.builder(
                itemCount: question.errors.length,
                itemBuilder: (context, index) {
                  final error = question.errors[index];
                  final isSelected = _selectedError == error;
                  final isCorrect = error == question.correctError;

                  final GameCardState cardState;
                  if (_showResult) {
                    if (isCorrect) {
                      cardState = GameCardState.correct;
                    } else if (isSelected) {
                      cardState = GameCardState.incorrect;
                    } else {
                      cardState = GameCardState.disabled;
                    }
                  } else if (isSelected) {
                    cardState = GameCardState.selected;
                  } else {
                    cardState = GameCardState.normal;
                  }

                  return Padding(
                    padding: EdgeInsets.only(bottom: 10.h),
                    child: Semantics(
                      label: 'Error option: $error',
                      button: true,
                      selected: isSelected,
                      enabled: !_showResult,
                      child: GameCard(
                        state: cardState,
                        onTap: _showResult ? null : () => _selectError(error),
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
                  );
                },
              ),
            ),
            if (!_showResult)
              Semantics(
                label: 'Check answer button',
                button: true,
                enabled: _selectedError != null,
                child: PrimaryActionButton(
                  onPressed: _selectedError == null ? null : _checkAnswer,
                  label: 'Check Answer',
                  icon: Icons.verified_rounded,
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
                  SizedBox(height: 12.h),
                  Semantics(
                    label: _currentIndex < _questions.length - 1 ? 'Next question' : 'Finish game',
                    button: true,
                    child: PrimaryActionButton(
                      onPressed: _nextQuestion,
                      label: _currentIndex < _questions.length - 1 ? 'Next Question' : 'Finish',
                      icon: _currentIndex < _questions.length - 1
                          ? Icons.navigate_next_rounded
                          : Icons.flag_rounded,
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

