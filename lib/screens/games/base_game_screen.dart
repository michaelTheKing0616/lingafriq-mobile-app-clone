import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../models/game/game_session_model.dart';
import '../../providers/game_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/gamification_provider.dart';
import '../../services/lazy_game_loader.dart';
import '../../services/telemetry_service.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Base class for all game screens - handles common functionality
abstract class BaseGameScreen extends ConsumerStatefulWidget {
  final String language;
  final String? level;
  final VoidCallback? onBack;

  const BaseGameScreen({
    Key? key,
    required this.language,
    this.level,
    this.onBack,
  }) : super(key: key);

  GameType getGameType();
}

abstract class BaseGameScreenState<T extends BaseGameScreen> extends ConsumerState<T> {
  GameSession? _session;
  DateTime? _startTime;
  bool _isLoading = true;
  String? _error;

  GameSession? get session => _session;
  DateTime? get startTime => _startTime;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  // Protected setter for error - allows subclasses to set error
  void setError(String? error) {
    setState(() {
      _error = error;
    });
  }
  
  // Protected setter for loading state
  void setLoading(bool loading) {
    setState(() {
      _isLoading = loading;
    });
  }
  
  // Protected setter for start time
  void setStartTime(DateTime? time) {
    setState(() {
      _startTime = time;
    });
  }

  @override
  void initState() {
    super.initState();
    _initializeGame();
  }

  Future<void> _initializeGame() async {
    setState(() => _isLoading = true);
    try {
      final user = ref.read(userProvider);
      if (user == null) {
        setState(() {
          _error = 'User not logged in';
          _isLoading = false;
        });
        return;
      }

      // Optimize: Preload game if not already loaded
      final lazyLoader = ref.read(lazyGameLoaderProvider);
      await lazyLoader.loadGameOnDemand(widget.getGameType());

      final gameProv = ref.read(gameProvider.notifier);
      _session = await gameProv.startGame(
        userId: user.id.toString(),
        gameType: widget.getGameType(),
        language: widget.language,
        level: widget.level,
        cardCount: getCardCount(),
      );

      _startTime = DateTime.now();
      await onGameInitialized();
      
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }


  /// Override to specify card count
  int getCardCount() => 10;

  /// Override for game-specific initialization
  Future<void> onGameInitialized() async {}

  /// Complete a turn - call this from game implementations
  Future<void> completeTurn({
    required String cardId,
    required GameResult result,
    required int durationMs,
    double? confidence,
    Map<String, dynamic>? feedback,
    String? userAction,
  }) async {
    if (_session == null) return;

    final gameProv = ref.read(gameProvider.notifier);
    await gameProv.completeTurn(
      cardId: cardId,
      result: result,
      durationMs: durationMs,
      confidence: confidence,
      feedback: feedback,
      userAction: userAction,
    );
  }

  /// Finish the game
  Future<void> finishGame() async {
    try {
      final gameProv = ref.read(gameProvider.notifier);
      final endedSession = await gameProv.endGame();

      if (mounted) {
        Navigator.pop(context);
        _showCompletionDialog(endedSession);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error finishing game: $e')),
        );
      }
    }
  }

  void _showCompletionDialog(GameSession session) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Game Complete!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Accuracy: ${(session.accuracy * 100).toStringAsFixed(0)}%'),
            Text('Correct: ${session.correctCount}/${session.totalTurns}'),
            Text('Duration: ${(session.durationMs / 1000).toStringAsFixed(0)}s'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
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

    if (_error != null) {
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
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $_error'),
              const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _initializeGame,
                    child: const Text('Retry'),
                  ),
            ],
          ),
        ),
      );
    }

    return buildGameContent(context);
  }

  /// Override to build the actual game UI
  Widget buildGameContent(BuildContext context);
}

