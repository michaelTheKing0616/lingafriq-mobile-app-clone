import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../models/game/game_session_model.dart';
import '../../providers/game_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/gamification_provider.dart';
import '../../providers/hearts_provider.dart';
import '../../services/lazy_game_loader.dart';
import '../../services/telemetry_service.dart';
import '../../utils/gamification_integration.dart';
import '../../widgets/gamification/gamification_widgets.dart';
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
  /// Returns false if user is out of hearts and cannot continue
  Future<bool> completeTurn({
    required String cardId,
    required GameResult result,
    required int durationMs,
    double? confidence,
    Map<String, dynamic>? feedback,
    String? userAction,
  }) async {
    if (_session == null) return true;

    final gameProv = ref.read(gameProvider.notifier);
    await gameProv.completeTurn(
      cardId: cardId,
      result: result,
      durationMs: durationMs,
      confidence: confidence,
      feedback: feedback,
      userAction: userAction,
    );

    // If incorrect, check hearts system
    if (result == GameResult.incorrect) {
      final canContinue = await ref.gamify.onMistake();
      if (!canContinue && mounted) {
        _showOutOfHeartsDialog();
        return false;
      }
    }
    
    return true;
  }

  /// Show dialog when user runs out of hearts
  void _showOutOfHeartsDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.favorite_border, color: Colors.red[400], size: 28),
            const SizedBox(width: 8),
            const Text('Out of Hearts!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'You\'ve run out of hearts. Would you like to refill to continue?',
              style: TextStyle(color: Colors.grey[700]),
            ),
            const SizedBox(height: 16),
            const HeartsWidget(),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context); // Exit game
            },
            child: const Text('Exit Game'),
          ),
          FilledButton.icon(
            onPressed: () async {
              final success = await ref.gamify.refillHearts();
              if (success && mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Hearts refilled! Continue playing.')),
                );
              }
            },
            icon: const Icon(Icons.favorite),
            label: const Text('Refill Hearts'),
          ),
        ],
      ),
    );
  }

  /// Finish the game
  Future<void> finishGame() async {
    try {
      final gameProv = ref.read(gameProvider.notifier);
      final endedSession = await gameProv.endGame();

      // Calculate XP based on performance
      final xpEarned = _calculateXP(endedSession);
      final wordsLearned = endedSession.correctCount;

      // Award gamification
      await ref.gamify.onGameComplete(
        xpEarned: xpEarned,
        wordsLearned: wordsLearned,
      );

      if (mounted) {
        _showCompletionDialog(endedSession, xpEarned);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error finishing game: $e')),
        );
      }
    }
  }

  /// Calculate XP based on game performance
  int _calculateXP(GameSession session) {
    const baseXP = 10;
    final accuracyBonus = (session.accuracy * 20).round();
    final speedBonus = session.durationMs < 30000 ? 10 : (session.durationMs < 60000 ? 5 : 0);
    final perfectBonus = session.accuracy >= 1.0 ? 25 : 0;
    
    return baseXP + accuracyBonus + speedBonus + perfectBonus;
  }

  void _showCompletionDialog(GameSession session, int xpEarned) {
    final isPerfect = session.accuracy >= 1.0;
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              isPerfect ? Icons.star_rounded : Icons.check_circle_rounded,
              color: isPerfect ? Colors.amber : Colors.green,
              size: 28,
            ),
            const SizedBox(width: 8),
            Text(isPerfect ? 'Perfect Score! 🎉' : 'Game Complete!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatRow(Icons.track_changes, 'Accuracy', '${(session.accuracy * 100).toStringAsFixed(0)}%'),
            _buildStatRow(Icons.done_all, 'Correct', '${session.correctCount}/${session.totalTurns}'),
            _buildStatRow(Icons.timer, 'Time', '${(session.durationMs / 1000).toStringAsFixed(0)}s'),
            const Divider(),
            _buildStatRow(Icons.star, 'XP Earned', '+$xpEarned', isHighlight: true),
          ],
        ),
        actions: [
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            icon: const Icon(Icons.check),
            label: const Text('Done'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(IconData icon, String label, String value, {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: isHighlight ? Colors.green : Colors.grey),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[700])),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: isHighlight ? FontWeight.bold : FontWeight.w500,
              color: isHighlight ? Colors.green : Colors.black87,
            ),
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

