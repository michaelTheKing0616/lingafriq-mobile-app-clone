// This file contains template implementations for all games
// Each game follows the BaseGameScreen pattern

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../../models/game/game_session_model.dart';
import '../../models/game/phrase_card_model.dart';
import '../../providers/game_provider.dart';
import '../../services/polie_content_generator.dart';
import '../../services/voice/pronunciation_analysis_service.dart';
import '../../providers/dio_provider.dart';
import '../../utils/pan_african_design_system.dart';
import 'base_game_screen.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/skeleton_loader.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/services.dart';

/// Template for creating game screens - copy and customize
mixin GameTemplateMixin<T extends BaseGameScreen> on BaseGameScreenState<T> {
  // Common game logic can go here
}

// ========== GAME IMPLEMENTATIONS ==========

/// Listen & Sketch Game
class ListenSketchGame extends BaseGameScreen {
  const ListenSketchGame({
    Key? key,
    required super.language,
    super.level,
    super.onBack,
  }) : super(key: key);

  @override
  GameType getGameType() => GameType.listenAndSketch;

  @override
  ConsumerState<ListenSketchGame> createState() => _ListenSketchGameState();
}

class _ListenSketchGameState extends BaseGameScreenState<ListenSketchGame> {
  String? _audioText;
  int _currentIndex = 0;
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  bool _showDrawingInterface = false;
  PhraseCard? _currentCard;
  final List<PhraseCard> _cards = [];

  @override
  int getCardCount() => 5;

  @override
  Future<void> onGameInitialized() async {
    final gameProv = ref.read(gameProvider.notifier);
    _cards.addAll(gameProv.availableCards);
    if (_cards.isNotEmpty) {
      _currentCard = _cards[0];
      _audioText = _currentCard!.gloss;
    }
  }

  Future<void> _playAudio() async {
    if (_currentCard?.audioNativeUrl == null) return;
    
    setState(() => _isPlaying = true);
    try {
      await _audioPlayer.setUrl(_currentCard!.audioNativeUrl!);
      await _audioPlayer.play();
      await _audioPlayer.playerStateStream.firstWhere(
        (state) => state.processingState == ProcessingState.completed,
      );
      setState(() {
        _isPlaying = false;
        _showDrawingInterface = true;
      });
    } catch (e) {
      debugPrint('Error playing audio: $e');
      setState(() => _isPlaying = false);
    }
  }

  void _selectPicture(int index) {
    final duration = startTime != null
        ? DateTime.now().difference(startTime!).inMilliseconds
        : 0;
    
    completeTurn(
      cardId: _currentCard!.cardId,
      result: GameResult.correct, // Assume correct for now - can add validation
      durationMs: duration,
      feedback: {'selected_picture': index, 'audio_text': _audioText},
    );

    if (_currentIndex < _cards.length - 1) {
      setState(() {
        _currentIndex++;
        _currentCard = _cards[_currentIndex];
        _audioText = _currentCard!.gloss;
        _showDrawingInterface = false;
      });
    } else {
      finishGame();
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget buildGameContent(BuildContext context) {
    if (_currentCard == null) {
      return const Scaffold(
        body: Center(child: Text('No cards available')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.getGameType().displayName} (${_currentIndex + 1}/${_cards.length})'),
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
              value: (_currentIndex + 1) / _cards.length,
            ),
            SizedBox(height: 4.h),
            if (!_showDrawingInterface)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.headphones, size: 64),
                      SizedBox(height: 2.h),
                      Text(
                        'Listen to the description',
                        style: TextStyle(fontSize: 18.sp),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 4.h),
                      FilledButton.icon(
                        onPressed: _isPlaying ? null : _playAudio,
                        icon: Icon(_isPlaying ? Icons.volume_up : Icons.play_arrow),
                        label: Text(_isPlaying ? 'Playing...' : 'Play Audio'),
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: Column(
                  children: [
                    Text(
                      'Select the correct picture:',
                      style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 4.h),
                    Expanded(
                      child: GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        itemCount: 4, // Show 4 picture options
                        itemBuilder: (context, index) {
                          return Card(
                            child: InkWell(
                              onTap: () => _selectPicture(index),
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.image, size: 48),
                                    SizedBox(height: 8),
                                    Text('Option ${index + 1}'),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Picture-Word Association Game
class PictureWordGame extends BaseGameScreen {
  const PictureWordGame({
    Key? key,
    required super.language,
    super.level,
    super.onBack,
  }) : super(key: key);

  @override
  GameType getGameType() => GameType.pictureWordAssociation;

  @override
  ConsumerState<PictureWordGame> createState() => _PictureWordGameState();
}

class _PictureWordGameState extends BaseGameScreenState<PictureWordGame> {
  final List<PhraseCard> _cards = [];
  int _currentIndex = 0;
  PhraseCard? _currentCard;
  String? _selectedWord;
  List<String> _wordOptions = [];
  int _score = 0;
  bool _showResult = false;
  bool _isCorrect = false;

  @override
  int getCardCount() => 8;

  @override
  Future<void> onGameInitialized() async {
    final gameProv = ref.read(gameProvider.notifier);
    _cards.addAll(gameProv.availableCards);
    if (_cards.isNotEmpty) {
      _loadCurrentCard();
    }
  }

  void _loadCurrentCard() {
    if (_currentIndex >= _cards.length) {
      finishGame();
      return;
    }
    
    setState(() {
      _currentCard = _cards[_currentIndex];
      _selectedWord = null;
      _showResult = false;
      _wordOptions = _generateWordOptions(_currentCard!);
    });
  }

  List<String> _generateWordOptions(PhraseCard card) {
    final options = [card.gloss ?? card.text];
    // Add 3 random wrong options from other cards
    final otherCards = _cards.where((c) => c.cardId != card.cardId).toList();
    otherCards.shuffle(Random());
    for (int i = 0; i < 3 && i < otherCards.length; i++) {
      options.add(otherCards[i].gloss ?? otherCards[i].text);
    }
    options.shuffle(Random());
    return options;
  }

  void _selectWord(String word) {
    if (_showResult) return;
    
    setState(() {
      _selectedWord = word;
      _isCorrect = word == (_currentCard!.gloss ?? _currentCard!.text);
      _showResult = true;
      if (_isCorrect) _score++;
    });

    HapticFeedback.mediumImpact();
    
    final duration = startTime != null
        ? DateTime.now().difference(startTime!).inMilliseconds
        : 0;

    completeTurn(
      cardId: _currentCard!.cardId,
      result: _isCorrect ? GameResult.correct : GameResult.incorrect,
      durationMs: duration,
      confidence: _isCorrect ? 1.0 : 0.0,
      feedback: {
        'selected_word': word,
        'correct_word': _currentCard!.gloss ?? _currentCard!.text,
        'image_url': _currentCard!.imageUrl,
      },
    );

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _currentIndex++;
          _loadCurrentCard();
        });
      }
    });
  }

  @override
  Widget buildGameContent(BuildContext context) {
    if (isLoading || _currentCard == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.getGameType().displayName),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: widget.onBack ?? () => Navigator.pop(context),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final progress = (_currentIndex + 1) / _cards.length;

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.getGameType().displayName} (${_currentIndex + 1}/${_cards.length})'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onBack ?? () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          LinearProgressIndicator(value: progress),
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(4.w),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Image display
                  Container(
                    width: double.infinity,
                    height: 300.h,
                    decoration: BoxDecoration(
                      color: isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight,
                      borderRadius: BorderRadius.circular(PanAfricanRadius.lg),
                      boxShadow: PanAfricanShadows.md,
                    ),
                    child: _currentCard!.imageUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(PanAfricanRadius.lg),
                            child: Image.network(
                              _currentCard!.imageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Center(
                                child: Icon(Icons.image, size: 64.sp, color: PanAfricanColors.neutralMedium),
                              ),
                            ),
                          )
                        : Center(
                            child: Icon(Icons.image, size: 64.sp, color: PanAfricanColors.neutralMedium),
                          ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    'Select the correct word:',
                    style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 2.h),
                  // Word options
                  ..._wordOptions.map((word) => Padding(
                        padding: EdgeInsets.symmetric(vertical: 1.h),
                        child: SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: _showResult ? null : () => _selectWord(word),
                            style: FilledButton.styleFrom(
                              backgroundColor: _showResult
                                  ? (_isCorrect && word == _selectedWord
                                      ? Colors.green
                                      : (!_isCorrect && word == _selectedWord
                                          ? Colors.red
                                          : (word == (_currentCard!.gloss ?? _currentCard!.text) && _showResult
                                              ? Colors.green.shade100
                                              : null)))
                                  : PanAfricanColors.primary,
                              padding: EdgeInsets.symmetric(vertical: 2.h),
                            ),
                            child: Text(
                              word,
                              style: TextStyle(fontSize: 16.sp),
                            ),
                          ),
                        ),
                      )),
                  if (_showResult)
                    Padding(
                      padding: EdgeInsets.only(top: 2.h),
                      child: Text(
                        _isCorrect ? 'Correct! 🎉' : 'Incorrect. Try again!',
                        style: TextStyle(
                          fontSize: 16.sp,
                          color: _isCorrect ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Memory Map Game
class MemoryMapGame extends BaseGameScreen {
  const MemoryMapGame({
    Key? key,
    required super.language,
    super.level,
    super.onBack,
  }) : super(key: key);

  @override
  GameType getGameType() => GameType.memoryMap;

  @override
  ConsumerState<MemoryMapGame> createState() => _MemoryMapGameState();
}

class _MemoryMapGameState extends BaseGameScreenState<MemoryMapGame> {
  final List<PhraseCard> _cards = [];
  final Map<String, Offset> _wordPositions = {};
  String? _selectedWord;
  String? _targetLocation;
  int _currentRound = 0;
  final int _maxRounds = 5;
  int _score = 0;
  bool _showResult = false;

  @override
  int getCardCount() => 10;

  @override
  Future<void> onGameInitialized() async {
    final gameProv = ref.read(gameProvider.notifier);
    _cards.addAll(gameProv.availableCards);
    if (_cards.isNotEmpty) {
      _setupRound();
    }
  }

  void _setupRound() {
    if (_currentRound >= _maxRounds) {
      finishGame();
      return;
    }

    setState(() {
      _currentRound++;
      _wordPositions.clear();
      _selectedWord = null;
      _showResult = false;
      
      // Assign words to random map positions
      final random = Random();
      for (int i = 0; i < _cards.length && i < 8; i++) {
        final card = _cards[i];
        _wordPositions[card.gloss ?? card.text] = Offset(
          random.nextDouble() * 0.8 + 0.1, // 0.1 to 0.9
          random.nextDouble() * 0.8 + 0.1,
        );
      }
      
      // Select a random target word
      final words = _wordPositions.keys.toList();
      _targetLocation = words[random.nextInt(words.length)];
    });
  }

  void _selectWord(String word) {
    if (_showResult) return;
    
    setState(() {
      _selectedWord = word;
      _showResult = true;
      
      final isCorrect = word == _targetLocation;
      if (isCorrect) _score++;
      
      final duration = startTime != null
          ? DateTime.now().difference(startTime!).inMilliseconds
          : 0;

      completeTurn(
        cardId: _cards.firstWhere((c) => (c.gloss ?? c.text) == word).cardId,
        result: isCorrect ? GameResult.correct : GameResult.incorrect,
        durationMs: duration,
        confidence: isCorrect ? 1.0 : 0.0,
        feedback: {
          'selected_word': word,
          'target_location': _targetLocation,
          'round': _currentRound,
        },
      );
    });

    HapticFeedback.mediumImpact();

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        _setupRound();
      }
    });
  }

  @override
  Widget buildGameContent(BuildContext context) {
    if (isLoading || _wordPositions.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.getGameType().displayName),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: widget.onBack ?? () => Navigator.pop(context),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.getGameType().displayName} (Round $_currentRound/$_maxRounds)'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onBack ?? () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(4.w),
            child: Column(
              children: [
                Text(
                  'Find the word at this location:',
                  style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 1.h),
                Container(
                  padding: EdgeInsets.all(2.w),
                  decoration: BoxDecoration(
                    color: PanAfricanColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(PanAfricanRadius.md),
                  ),
                  child: Text(
                    _targetLocation ?? '',
                    style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                // Map background
                Container(
                  margin: EdgeInsets.all(4.w),
                  decoration: BoxDecoration(
                    color: isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight,
                    borderRadius: BorderRadius.circular(PanAfricanRadius.lg),
                    border: Border.all(color: PanAfricanColors.primary, width: 2),
                  ),
                  child: CustomPaint(
                    painter: _MapPainter(
                      wordPositions: _wordPositions,
                      selectedWord: _selectedWord,
                      targetLocation: _targetLocation,
                      showResult: _showResult,
                      labelColor: colorScheme.onPrimary,
                    ),
                  ),
                ),
                // Word buttons at bottom
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: EdgeInsets.all(4.w),
                    decoration: BoxDecoration(
                      color: isDark ? PanAfricanColors.surfaceContainerDark : PanAfricanColors.surfaceContainerLight,
                      boxShadow: PanAfricanShadows.md,
                    ),
                    child: Wrap(
                      spacing: 2.w,
                      runSpacing: 2.h,
                      children: _wordPositions.keys.map((word) {
                        final isSelected = word == _selectedWord;
                        final isCorrect = word == _targetLocation && _showResult;
                        final isWrong = isSelected && word != _targetLocation && _showResult;
                        
                        return FilledButton(
                          onPressed: _showResult ? null : () => _selectWord(word),
                          style: FilledButton.styleFrom(
                            backgroundColor: isWrong
                                ? Colors.red
                                : (isCorrect && _showResult
                                    ? Colors.green
                                    : PanAfricanColors.primary),
                          ),
                          child: Text(word),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MapPainter extends CustomPainter {
  final Map<String, Offset> wordPositions;
  final String? selectedWord;
  final String? targetLocation;
  final bool showResult;
  final Color labelColor;

  _MapPainter({
    required this.wordPositions,
    required this.selectedWord,
    required this.targetLocation,
    required this.showResult,
    required this.labelColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..strokeWidth = 2;

    // Draw map features (simplified)
    paint.color = Colors.brown.shade300;
    canvas.drawCircle(Offset(size.width * 0.3, size.height * 0.3), 20, paint);
    canvas.drawCircle(Offset(size.width * 0.7, size.height * 0.6), 20, paint);
    
    // Draw word markers
    wordPositions.forEach((word, position) {
      final x = position.dx * size.width;
      final y = position.dy * size.height;
      
      if (showResult && word == targetLocation) {
        paint.color = Colors.green;
      } else if (showResult && word == selectedWord && word != targetLocation) {
        paint.color = Colors.red;
      } else {
        paint.color = Colors.blue;
      }
      
      canvas.drawCircle(Offset(x, y), 15, paint);
      
      // Draw word label
      final textPainter = TextPainter(
        text: TextSpan(
          text: word.length > 8 ? '${word.substring(0, 8)}...' : word,
          style: TextStyle(color: labelColor, fontSize: 10),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(x - textPainter.width / 2, y + 20));
    });
  }

  @override
  bool shouldRepaint(_MapPainter oldDelegate) {
    return oldDelegate.wordPositions != wordPositions ||
        oldDelegate.selectedWord != selectedWord ||
        oldDelegate.showResult != showResult;
  }
}

/// Conversation Relay Game
class ConversationRelayGame extends BaseGameScreen {
  const ConversationRelayGame({
    Key? key,
    required super.language,
    super.level,
    super.onBack,
  }) : super(key: key);

  @override
  GameType getGameType() => GameType.conversationRelay;

  @override
  ConsumerState<ConversationRelayGame> createState() => _ConversationRelayGameState();
}

class _ConversationRelayGameState extends BaseGameScreenState<ConversationRelayGame> {
  final List<Map<String, dynamic>> _conversationHistory = [];
  final TextEditingController _messageController = TextEditingController();
  String? _currentPrompt;
  int _turnCount = 0;
  final int _maxTurns = 10;
  bool _isWaitingResponse = false;

  @override
  int getCardCount() => 5;

  @override
  Future<void> onGameInitialized() async {
    await _startConversation();
  }

  Future<void> _startConversation() async {
    try {
      final polieGenerator = ref.read(polieContentGeneratorProvider);
      final scenario = await polieGenerator.generateMarketScenario(widget.language);
      setState(() {
        _currentPrompt = scenario['scenario']?.toString() ?? 'Start a conversation';
        _conversationHistory.add({
          'type': 'system',
          'text': _currentPrompt!,
          'timestamp': DateTime.now(),
        });
      });
    } catch (e) {
      debugPrint('Error starting conversation: $e');
      // Use fallback content so game is still playable
      final fallbackPrompt = 'Start a conversation in ${widget.language}';
      setState(() {
        _currentPrompt = fallbackPrompt;
        _conversationHistory.add({
          'type': 'system',
          'text': fallbackPrompt,
          'timestamp': DateTime.now(),
        });
      });
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _isWaitingResponse) return;
    if (_turnCount >= _maxTurns) {
      finishGame();
      return;
    }

    final userMessage = _messageController.text.trim();
    setState(() {
      _conversationHistory.add({
        'type': 'user',
        'text': userMessage,
        'timestamp': DateTime.now(),
      });
      _messageController.clear();
      _isWaitingResponse = true;
      _turnCount++;
    });

    HapticFeedback.lightImpact();

    // Simulate AI response (in production, this would call Polie or backend)
    await Future.delayed(const Duration(seconds: 1));
    
    final duration = startTime != null
        ? DateTime.now().difference(startTime!).inMilliseconds
        : 0;

    completeTurn(
      cardId: 'conv_${_turnCount}',
      result: GameResult.correct, // Conversation practice is always correct
      durationMs: duration,
      confidence: 1.0,
      feedback: {
        'message': userMessage,
        'turn': _turnCount,
      },
    );

    setState(() {
      _conversationHistory.add({
        'type': 'ai',
        'text': _generateAIResponse(userMessage),
        'timestamp': DateTime.now(),
      });
      _isWaitingResponse = false;
    });
  }

  String _generateAIResponse(String userMessage) {
    // Generate contextual response based on user message
    final responses = [
      'That\'s great! Can you tell me more?',
      'Interesting! How do you say that in ${widget.language}?',
      'I understand. What else would you like to discuss?',
      'Good point! Let\'s continue the conversation.',
    ];
    return responses[Random().nextInt(responses.length)];
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget buildGameContent(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.getGameType().displayName),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: widget.onBack ?? () => Navigator.pop(context),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.getGameType().displayName} (Turn $_turnCount/$_maxTurns)'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onBack ?? () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          if (_currentPrompt != null)
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(4.w),
              color: PanAfricanColors.primary.withOpacity(0.1),
              child: Text(
                _currentPrompt!,
                style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(4.w),
              itemCount: _conversationHistory.length,
              itemBuilder: (context, index) {
                final message = _conversationHistory[index];
                final isUser = message['type'] == 'user';
                final colorScheme = Theme.of(context).colorScheme;
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: EdgeInsets.symmetric(vertical: 1.h),
                    padding: EdgeInsets.all(3.w),
                    decoration: BoxDecoration(
                      color: isUser
                          ? PanAfricanColors.primary
                          : (isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight),
                      borderRadius: BorderRadius.circular(PanAfricanRadius.md),
                    ),
                    child: Text(
                      message['text'] as String,
                      style: TextStyle(
                        color: isUser ? colorScheme.onPrimary : null,
                        fontSize: 14.sp,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_isWaitingResponse)
            Padding(
              padding: EdgeInsets.all(4.w),
              child: Row(
                children: [
                  SizedBox(
                    width: 20.w,
                    height: 20.h,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 2.w),
                  Text('AI is typing...', style: TextStyle(fontSize: 12.sp)),
                ],
              ),
            ),
          Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: isDark ? PanAfricanColors.surfaceContainerDark : PanAfricanColors.surfaceContainerLight,
              boxShadow: PanAfricanShadows.md,
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type your message in ${widget.language}...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(PanAfricanRadius.md),
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                SizedBox(width: 2.w),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                  color: PanAfricanColors.primary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Grammar Jam Game
class GrammarJamGame extends BaseGameScreen {
  const GrammarJamGame({
    Key? key,
    required super.language,
    super.level,
    super.onBack,
  }) : super(key: key);

  @override
  GameType getGameType() => GameType.grammarJam;

  @override
  ConsumerState<GrammarJamGame> createState() => _GrammarJamGameState();
}

class _GrammarJamGameState extends BaseGameScreenState<GrammarJamGame> {
  final List<Map<String, dynamic>> _sentences = [];
  int _currentIndex = 0;
  String? _currentSentence;
  List<String> _wordOptions = [];
  List<String> _selectedWords = [];
  int _score = 0;
  int _timeRemaining = 60; // seconds
  bool _gameActive = false;
  Timer? _timer;

  @override
  int getCardCount() => 10;

  @override
  Future<void> onGameInitialized() async {
    await _loadSentences();
  }

  Future<void> _loadSentences() async {
    try {
      final polieGenerator = ref.read(polieContentGeneratorProvider);
      final content = await polieGenerator.generateGameContent(
        gameType: 'grammar_jam',
        language: widget.language,
        difficulty: widget.level,
      );
      
      // Parse sentences from content
      final sentences = _parseSentences(content['content']?.toString() ?? '');
      setState(() {
        _sentences.addAll(sentences);
        if (_sentences.isNotEmpty) {
          _loadCurrentSentence();
        }
      });
    } catch (e) {
      debugPrint('Error loading sentences: $e');
      // Fallback sentences
      setState(() {
        _sentences.addAll([
          {'sentence': 'Hello, how are you?', 'words': ['Hello', 'how', 'are', 'you']},
          {'sentence': 'I am learning ${widget.language}', 'words': ['I', 'am', 'learning', widget.language]},
        ]);
        _loadCurrentSentence();
      });
    }
  }

  List<Map<String, dynamic>> _parseSentences(String content) {
    // Parse sentences from Polie content
    final lines = content.split('\n').where((l) => l.trim().isNotEmpty).toList();
    return lines.take(10).map((line) {
      final words = line.split(RegExp(r'[ ,.!?]+')).where((w) => w.isNotEmpty).toList();
      return {
        'sentence': line.trim(),
        'words': words,
      };
    }).toList();
  }

  void _loadCurrentSentence() {
    if (_currentIndex >= _sentences.length) {
      finishGame();
      return;
    }
    
    final sentence = _sentences[_currentIndex];
    final words = List<String>.from(sentence['words'] as List);
    words.shuffle(Random());
    
    setState(() {
      _currentSentence = sentence['sentence'] as String;
      _wordOptions = words;
      _selectedWords = [];
    });
  }

  void _selectWord(String word) {
    if (!_gameActive || _selectedWords.contains(word)) return;
    
    setState(() {
      _selectedWords.add(word);
    });
    
    HapticFeedback.lightImpact();
    
    // Check if sentence is complete
    final originalWords = List<String>.from(_sentences[_currentIndex]['words'] as List);
    if (_selectedWords.length == originalWords.length) {
      _checkSentence();
    }
  }

  void _removeWord(String word) {
    setState(() {
      _selectedWords.remove(word);
    });
    HapticFeedback.lightImpact();
  }

  void _checkSentence() {
    final originalWords = List<String>.from(_sentences[_currentIndex]['words'] as List);
    final isCorrect = _selectedWords.join(' ') == originalWords.join(' ');
    
    if (isCorrect) _score++;
    
    final duration = startTime != null
        ? DateTime.now().difference(startTime!).inMilliseconds
        : 0;

    completeTurn(
      cardId: 'grammar_${_currentIndex}',
      result: isCorrect ? GameResult.correct : GameResult.incorrect,
      durationMs: duration,
      confidence: isCorrect ? 1.0 : 0.0,
      feedback: {
        'sentence': _currentSentence,
        'selected': _selectedWords.join(' '),
        'correct': originalWords.join(' '),
      },
    );

    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _currentIndex++;
          _loadCurrentSentence();
        });
      }
    });
  }

  void _startGame() {
    setState(() {
      _gameActive = true;
      _timeRemaining = 60;
    });
    
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeRemaining > 0) {
        setState(() {
          _timeRemaining--;
        });
      } else {
        timer.cancel();
        finishGame();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget buildGameContent(BuildContext context) {
    if (isLoading || _sentences.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.getGameType().displayName),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: widget.onBack ?? () => Navigator.pop(context),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (!_gameActive) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.getGameType().displayName),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: widget.onBack ?? () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.music_note, size: 64.sp),
              SizedBox(height: 2.h),
              Text(
                'Arrange words to form correct sentences',
                style: TextStyle(fontSize: 18.sp),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 4.h),
              Semantics(
                label: 'Start game',
                button: true,
                child: FilledButton(
                  onPressed: _startGame,
                  child: const Text('Start Jam'),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.getGameType().displayName} - Score: $_score'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onBack ?? () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Timer
          Semantics(
            label: 'Time remaining: $_timeRemaining seconds',
            child: Container(
              padding: EdgeInsets.all(2.w),
              color: _timeRemaining < 10 ? Colors.red.shade100 : PanAfricanColors.primary.withOpacity(0.1),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.timer, size: 20.sp),
                  SizedBox(width: 2.w),
                  Text(
                    '$_timeRemaining',
                  style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(4.w),
              child: Column(
                children: [
                  // Selected words
                  Container(
                    padding: EdgeInsets.all(4.w),
                    decoration: BoxDecoration(
                      color: isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight,
                      borderRadius: BorderRadius.circular(PanAfricanRadius.md),
                    ),
                    child: Wrap(
                      spacing: 2.w,
                      runSpacing: 2.h,
                      children: _selectedWords.map((word) => Chip(
                        label: Text(word),
                        onDeleted: () => _removeWord(word),
                        deleteIcon: const Icon(Icons.close, size: 18),
                      )).toList(),
                    ),
                  ),
                  SizedBox(height: 4.h),
                  // Word options
                  Expanded(
                    child: GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 2.w,
                        mainAxisSpacing: 2.h,
                      ),
                      itemCount: _wordOptions.length,
                      itemBuilder: (context, index) {
                        final word = _wordOptions[index];
                        final isSelected = _selectedWords.contains(word);
                        return FilledButton(
                          onPressed: isSelected ? null : () => _selectWord(word),
                          style: FilledButton.styleFrom(
                            backgroundColor: isSelected
                                ? Colors.grey
                                : PanAfricanColors.primary,
                          ),
                          child: Text(word, style: TextStyle(fontSize: 14.sp)),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Pronunciation Karaoke Game
class PronunciationKaraokeGame extends BaseGameScreen {
  const PronunciationKaraokeGame({
    Key? key,
    required super.language,
    super.level,
    super.onBack,
  }) : super(key: key);

  @override
  GameType getGameType() => GameType.pronunciationKaraoke;

  @override
  ConsumerState<PronunciationKaraokeGame> createState() => _PronunciationKaraokeGameState();
}

class _PronunciationKaraokeGameState extends BaseGameScreenState<PronunciationKaraokeGame> {
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final List<Map<String, dynamic>> _songs = [];
  int _currentSongIndex = 0;
  Map<String, dynamic>? _currentSong;
  bool _isRecording = false;
  bool _isPlaying = false;
  int? _pronunciationScore;
  String? _recordingPath;
  int _currentLineIndex = 0;
  List<String> _lyrics = [];

  @override
  int getCardCount() => 3;

  @override
  Future<void> onGameInitialized() async {
    await _loadSongs();
  }

  Future<void> _loadSongs() async {
    try {
      final polieGenerator = ref.read(polieContentGeneratorProvider);
      final content = await polieGenerator.generateGameContent(
        gameType: 'pronunciation_karaoke',
        language: widget.language,
      );
      
      // Parse songs from content
      final songs = _parseSongs(content['content']?.toString() ?? '');
      setState(() {
        _songs.addAll(songs);
        if (_songs.isNotEmpty) {
          _currentSong = _songs[0];
          _lyrics = List<String>.from(_currentSong!['lyrics'] as List? ?? []);
        }
      });
    } catch (e) {
      debugPrint('Error loading songs: $e');
      // Fallback songs
      setState(() {
        _songs.addAll([
          {
            'title': 'Traditional ${widget.language} Song',
            'lyrics': ['Line 1', 'Line 2', 'Line 3', 'Line 4'],
          },
        ]);
        _currentSong = _songs[0];
        _lyrics = List<String>.from(_currentSong!['lyrics'] as List);
      });
    }
  }

  List<Map<String, dynamic>> _parseSongs(String content) {
    // Parse songs from Polie content
    final lines = content.split('\n').where((l) => l.trim().isNotEmpty).toList();
    return [
      {
        'title': 'Song 1',
        'lyrics': lines.take(4).toList(),
      },
    ];
  }

  Future<void> _playSong() async {
    setState(() => _isPlaying = true);
    // In production, this would play actual audio
    await Future.delayed(const Duration(seconds: 2));
    setState(() => _isPlaying = false);
  }

  Future<void> _startRecording() async {
    if (await _recorder.hasPermission()) {
      setState(() => _isRecording = true);
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      _recordingPath = '${tempDir.path}/karaoke_$timestamp.m4a';
      await _recorder.start(const RecordConfig(), path: _recordingPath!);
    }
  }

  Future<void> _stopRecording() async {
    final path = await _recorder.stop();
    setState(() => _isRecording = false);
    
    if (path != null && _currentSong != null) {
      await _scorePronunciation(path);
    }
  }

  Future<void> _scorePronunciation(String audioPath) async {
    try {
      final dio = ref.read(client);
      final audioFile = File(audioPath);
      if (!await audioFile.exists()) return;

      final audioData = await audioFile.readAsBytes();
      final pronunciationService = PronunciationAnalysisService(dio);
      
      // Create a lesson item from current lyrics line
      final currentLine = _lyrics[_currentLineIndex];
      // This would use actual lesson item - simplified for now
      
      final score = Random().nextInt(30) + 70; // Simulated score 70-100
      
      setState(() {
        _pronunciationScore = score;
      });

      final duration = startTime != null
          ? DateTime.now().difference(startTime!).inMilliseconds
          : 0;

      completeTurn(
        cardId: 'karaoke_${_currentSongIndex}_${_currentLineIndex}',
        result: score >= 85 ? GameResult.correct : GameResult.partial,
        durationMs: duration,
        confidence: score / 100.0,
        feedback: {
          'score': score,
          'line': currentLine,
          'song': _currentSong!['title'],
        },
      );

      if (_currentLineIndex < _lyrics.length - 1) {
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() {
              _currentLineIndex++;
              _pronunciationScore = null;
            });
          }
        });
      } else {
        // Song complete
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            if (_currentSongIndex < _songs.length - 1) {
              setState(() {
                _currentSongIndex++;
                _currentSong = _songs[_currentSongIndex];
                _lyrics = List<String>.from(_currentSong!['lyrics'] as List);
                _currentLineIndex = 0;
                _pronunciationScore = null;
              });
            } else {
              finishGame();
            }
          }
        });
      }
    } catch (e) {
      debugPrint('Error scoring pronunciation: $e');
    }
  }

  @override
  void dispose() {
    _recorder.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget buildGameContent(BuildContext context) {
    if (isLoading || _currentSong == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.getGameType().displayName),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: widget.onBack ?? () => Navigator.pop(context),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.getGameType().displayName} - ${_currentSong!['title']}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onBack ?? () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Lyrics display
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_pronunciationScore != null)
                    Container(
                      padding: EdgeInsets.all(4.w),
                      margin: EdgeInsets.only(bottom: 4.h),
                      decoration: BoxDecoration(
                        color: _pronunciationScore! >= 85
                            ? Colors.green.shade100
                            : Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(PanAfricanRadius.md),
                      ),
                      child: Text(
                        'Score: $_pronunciationScore%',
                        style: TextStyle(
                          fontSize: 24.sp,
                          fontWeight: FontWeight.bold,
                          color: _pronunciationScore! >= 85 ? Colors.green : Colors.orange,
                        ),
                      ),
                    ),
                  Text(
                    _lyrics[_currentLineIndex],
                    style: TextStyle(
                      fontSize: 24.sp,
                      fontWeight: FontWeight.bold,
                      color: PanAfricanColors.primary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    'Line ${_currentLineIndex + 1} of ${_lyrics.length}',
                    style: TextStyle(fontSize: 14.sp, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
          // Controls
          Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: isDark ? PanAfricanColors.surfaceContainerDark : PanAfricanColors.surfaceContainerLight,
              boxShadow: PanAfricanShadows.md,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                  iconSize: 48.sp,
                  onPressed: _isPlaying ? null : _playSong,
                  color: PanAfricanColors.primary,
                ),
                GestureDetector(
                  onTapDown: (_) => _startRecording(),
                  onTapUp: (_) => _stopRecording(),
                  onTapCancel: () => _stopRecording(),
                  child: Container(
                    width: 80.w,
                    height: 80.h,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isRecording ? Colors.red : PanAfricanColors.primary,
                    ),
                    child: Icon(
                      _isRecording ? Icons.mic : Icons.mic_none,
                      color: colorScheme.onPrimary,
                      size: 40.sp,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.skip_next),
                  iconSize: 48.sp,
                  onPressed: _pronunciationScore == null ? null : () {
                    if (_currentLineIndex < _lyrics.length - 1) {
                      setState(() {
                        _currentLineIndex++;
                        _pronunciationScore = null;
                      });
                    }
                  },
                  color: PanAfricanColors.primary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Quiz Chef Game
class QuizChefGame extends BaseGameScreen {
  const QuizChefGame({
    Key? key,
    required super.language,
    super.level,
    super.onBack,
  }) : super(key: key);

  @override
  GameType getGameType() => GameType.quizChef;

  @override
  ConsumerState<QuizChefGame> createState() => _QuizChefGameState();
}

class _QuizChefGameState extends BaseGameScreenState<QuizChefGame> {
  Map<String, dynamic>? _currentRecipe;
  List<Map<String, dynamic>> _recipeSteps = [];
  int _currentStepIndex = 0;
  List<String> _stepOptions = [];
  String? _selectedStep;
  int _score = 0;
  bool _showResult = false;
  bool _isCorrect = false;

  @override
  int getCardCount() => 5;

  @override
  Future<void> onGameInitialized() async {
    await _loadRecipe();
  }

  Future<void> _loadRecipe() async {
    try {
      final polieGenerator = ref.read(polieContentGeneratorProvider);
      final content = await polieGenerator.generateGameContent(
        gameType: 'recipe_cooking',
        language: widget.language,
        additionalContext: 'Create a traditional recipe with cooking steps',
      );
      
      // Parse recipe from content
      final recipe = _parseRecipe(content['content']?.toString() ?? '');
      setState(() {
        _currentRecipe = recipe;
        _recipeSteps = List<Map<String, dynamic>>.from(recipe['steps'] as List? ?? []);
        if (_recipeSteps.isNotEmpty) {
          _loadCurrentStep();
        }
      });
    } catch (e) {
      debugPrint('Error loading recipe: $e');
      // Fallback recipe
      setState(() {
        _currentRecipe = {
          'title': 'Traditional ${widget.language} Dish',
          'steps': [
            {'step': 'Prepare ingredients', 'order': 1},
            {'step': 'Heat the pan', 'order': 2},
            {'step': 'Add spices', 'order': 3},
            {'step': 'Cook until done', 'order': 4},
          ],
        };
        _recipeSteps = List<Map<String, dynamic>>.from(_currentRecipe!['steps'] as List);
        _loadCurrentStep();
      });
    }
  }

  Map<String, dynamic> _parseRecipe(String content) {
    // Parse recipe from Polie content
    final lines = content.split('\n').where((l) => l.trim().isNotEmpty).take(5).toList();
    return {
      'title': 'Traditional Recipe',
      'steps': lines.asMap().entries.map((e) => {
        'step': e.value.trim(),
        'order': e.key + 1,
      }).toList(),
    };
  }

  void _loadCurrentStep() {
    if (_currentStepIndex >= _recipeSteps.length) {
      finishGame();
      return;
    }

    final currentStep = _recipeSteps[_currentStepIndex];
    final correctStep = currentStep['step'] as String;
    
    // Generate wrong options
    final wrongSteps = _recipeSteps
        .where((s) => s['step'] != correctStep)
        .map((s) => s['step'] as String)
        .take(3)
        .toList();
    
    final options = [correctStep, ...wrongSteps];
    options.shuffle(Random());
    
    setState(() {
      _stepOptions = options;
      _selectedStep = null;
      _showResult = false;
    });
  }

  void _selectStep(String step) {
    if (_showResult) return;
    
    final correctStep = _recipeSteps[_currentStepIndex]['step'] as String;
    final isCorrect = step == correctStep;
    
    setState(() {
      _selectedStep = step;
      _isCorrect = isCorrect;
      _showResult = true;
      if (isCorrect) _score++;
    });

    HapticFeedback.mediumImpact();
    
    final duration = startTime != null
        ? DateTime.now().difference(startTime!).inMilliseconds
        : 0;

    completeTurn(
      cardId: 'recipe_step_${_currentStepIndex}',
      result: isCorrect ? GameResult.correct : GameResult.incorrect,
      durationMs: duration,
      confidence: isCorrect ? 1.0 : 0.0,
      feedback: {
        'selected_step': step,
        'correct_step': correctStep,
        'step_number': _currentStepIndex + 1,
      },
    );

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _currentStepIndex++;
          _loadCurrentStep();
        });
      }
    });
  }

  @override
  Widget buildGameContent(BuildContext context) {
    if (isLoading || _currentRecipe == null || _recipeSteps.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.getGameType().displayName),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: widget.onBack ?? () => Navigator.pop(context),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final progress = (_currentStepIndex + 1) / _recipeSteps.length;

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.getGameType().displayName} - Step ${_currentStepIndex + 1}/${_recipeSteps.length}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onBack ?? () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          LinearProgressIndicator(value: progress),
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(4.w),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Recipe title
                  Container(
                    padding: EdgeInsets.all(4.w),
                    decoration: BoxDecoration(
                      color: PanAfricanColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(PanAfricanRadius.md),
                    ),
                    child: Text(
                      _currentRecipe!['title'] as String,
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  // Cooking icon
                  Icon(
                    Icons.restaurant_menu,
                    size: 64.sp,
                    color: PanAfricanColors.primary,
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    'What is the next step?',
                    style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4.h),
                  // Step options
                  ..._stepOptions.map((step) => Padding(
                        padding: EdgeInsets.symmetric(vertical: 1.h),
                        child: SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: _showResult ? null : () => _selectStep(step),
                            style: FilledButton.styleFrom(
                              backgroundColor: _showResult
                                  ? (_isCorrect && step == _selectedStep
                                      ? Colors.green
                                      : (!_isCorrect && step == _selectedStep
                                          ? Colors.red
                                          : (step == _recipeSteps[_currentStepIndex]['step'] && _showResult
                                              ? Colors.green.shade100
                                              : null)))
                                  : PanAfricanColors.primary,
                              padding: EdgeInsets.symmetric(vertical: 2.h),
                            ),
                            child: Text(
                              step,
                              style: TextStyle(fontSize: 16.sp),
                            ),
                          ),
                        ),
                      )),
                  if (_showResult)
                    Padding(
                      padding: EdgeInsets.only(top: 2.h),
                      child: Text(
                        _isCorrect ? 'Correct! 🎉' : 'Incorrect. Try again!',
                        style: TextStyle(
                          fontSize: 16.sp,
                          color: _isCorrect ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

