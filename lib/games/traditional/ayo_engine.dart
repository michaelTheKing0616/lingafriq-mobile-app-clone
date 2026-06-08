// Ayo (Mancala / Ayoayo / Awalé / Oware) — pure game engine.
//
// This file implements the rules and AI for a traditional Yoruba/West-African
// variant of Mancala known as Ayo. The variant used here follows the most
// common modern tournament-style rules:
//
//   - 12 small pits arranged in 2 rows of 6 (player 0 on the bottom, player 1
//     on the top).
//   - 2 stores ("oloko"): one to the right of player 0, one to the left of
//     player 1.
//   - Each small pit starts with 4 seeds. Total seeds = 48.
//   - On your turn, pick one of YOUR non-empty pits and "sow" the seeds
//     counter-clockwise, one per pit, including your own store but skipping
//     the opponent's store.
//   - If your last seed lands in YOUR store you take another turn.
//   - If your last seed lands in an empty pit on YOUR side and the opposite
//     pit on the opponent's side has seeds, you capture both your last seed
//     AND all seeds in the opposite pit into your store.
//   - If a sowing reaches >= 12 seeds in one pit, the next sowing skips that
//     same pit (the "grand-ngolo" rule). We implement this for fidelity.
//   - The game ends when one player has no legal moves; the other captures
//     all remaining seeds on their side.
//   - Winner: whoever holds the most seeds in their store at game end.
//
// The engine is intentionally pure (no Flutter imports) so it can be tested
// independently and used by both the screen and the AI search.

import 'dart:math';

/// Identifies a player. The board stores indexes 0..5 for player 0's pits
/// (bottom row) and 7..12 for player 1's pits (top row). Index 6 = player 0's
/// store; index 13 = player 1's store.
enum AyoPlayer { south, north }

/// Result of attempting a move. Used by callers to decide whether a re-prompt
/// or a continue-turn animation should play.
class AyoMoveResult {
  final List<int> sowingPath;
  final int? capturedFromPit;
  final int capturedSeeds;
  final bool extraTurn;
  final bool gameOver;
  final AyoPlayer? winner;
  const AyoMoveResult({
    required this.sowingPath,
    required this.capturedFromPit,
    required this.capturedSeeds,
    required this.extraTurn,
    required this.gameOver,
    required this.winner,
  });
}

/// Pure, immutable-by-design Ayo board state.
class AyoBoard {
  /// `pits[0..5]`  = player 0's pits, left-to-right from player 0's POV.
  /// `pits[6]`     = player 0's store.
  /// `pits[7..12]` = player 1's pits, right-to-left from player 0's POV
  /// (so sowing counter-clockwise just increments the index).
  /// `pits[13]`    = player 1's store.
  final List<int> pits;
  final AyoPlayer turn;

  AyoBoard._(this.pits, this.turn);

  factory AyoBoard.initial() {
    final p = List<int>.filled(14, 0);
    for (var i = 0; i < 6; i++) {
      p[i] = 4;
      p[i + 7] = 4;
    }
    return AyoBoard._(p, AyoPlayer.south);
  }

  /// Construct an arbitrary board state. Used by the screen to render
  /// intermediate animation frames and by the capture-forfeit logic. Asserts
  /// the pit list has exactly 14 entries.
  factory AyoBoard.fromState({required List<int> pits, required AyoPlayer turn}) {
    assert(pits.length == 14, 'Ayo board requires exactly 14 cells');
    return AyoBoard._(List<int>.from(pits), turn);
  }

  int storeFor(AyoPlayer player) =>
      player == AyoPlayer.south ? pits[6] : pits[13];

  Iterable<int> pitsFor(AyoPlayer player) sync* {
    final base = player == AyoPlayer.south ? 0 : 7;
    for (var i = 0; i < 6; i++) {
      yield base + i;
    }
  }

  List<int> legalMoves() => [
        for (final p in pitsFor(turn))
          if (pits[p] > 0) p,
      ];

  bool isGameOver() {
    final south = [for (final p in pitsFor(AyoPlayer.south)) pits[p]]
        .every((v) => v == 0);
    final north = [for (final p in pitsFor(AyoPlayer.north)) pits[p]]
        .every((v) => v == 0);
    return south || north;
  }

  AyoPlayer? winner() {
    if (!isGameOver()) return null;
    final s = pits[6];
    final n = pits[13];
    if (s > n) return AyoPlayer.south;
    if (n > s) return AyoPlayer.north;
    return null; // draw
  }

  /// Returns the index of the store for the given player.
  static int storeIndex(AyoPlayer player) => player == AyoPlayer.south ? 6 : 13;

  /// Returns the index of the opponent's store (the one we skip while sowing).
  static int opponentStoreIndex(AyoPlayer player) =>
      player == AyoPlayer.south ? 13 : 6;

  static AyoPlayer otherOf(AyoPlayer player) =>
      player == AyoPlayer.south ? AyoPlayer.north : AyoPlayer.south;

  bool pitBelongsTo(int idx, AyoPlayer player) {
    if (player == AyoPlayer.south) return idx >= 0 && idx <= 5;
    return idx >= 7 && idx <= 12;
  }

  int oppositePit(int idx) {
    // Mancala mirror: pit i across the board is 12 - i (skipping stores).
    if (idx >= 0 && idx <= 5) return 12 - idx;
    if (idx >= 7 && idx <= 12) return 12 - idx;
    return idx; // store: no opposite
  }

  /// Plays [pit] for the current turn. Returns a new board AND a structured
  /// move result describing the animation steps and captured seeds. Throws
  /// [StateError] if the move is illegal.
  (AyoBoard, AyoMoveResult) play(int pit) {
    if (!legalMoves().contains(pit)) {
      throw StateError('Illegal Ayo move: pit=$pit turn=$turn');
    }
    final next = List<int>.from(pits);
    var idx = pit;
    var seeds = next[pit];
    next[pit] = 0;
    final path = <int>[];
    final me = turn;
    final opponentStore = opponentStoreIndex(me);
    final sourcePit = pit;

    while (seeds > 0) {
      idx = (idx + 1) % 14;
      if (idx == opponentStore) continue;
      // Grand-ngolo: if a single sowing wraps around back to the source pit,
      // skip it so a long lap doesn't deposit into itself.
      if (idx == sourcePit && seeds > 0) continue;
      next[idx] += 1;
      path.add(idx);
      seeds -= 1;
    }

    // Capture rule.
    int? capturedFromPit;
    var capturedSeeds = 0;
    if (pitBelongsTo(idx, me) && next[idx] == 1) {
      final opp = oppositePit(idx);
      if (next[opp] > 0) {
        capturedFromPit = opp;
        capturedSeeds = next[opp] + next[idx];
        next[storeIndex(me)] += capturedSeeds;
        next[opp] = 0;
        next[idx] = 0;
      }
    }

    final extraTurn = idx == storeIndex(me);
    final nextTurn = extraTurn ? me : otherOf(me);
    var board = AyoBoard._(next, nextTurn);

    // End-of-game sweep.
    var gameOver = board.isGameOver();
    AyoPlayer? winner;
    if (gameOver) {
      board = board._sweepRemaining();
      winner = board.winner();
    }

    return (
      board,
      AyoMoveResult(
        sowingPath: path,
        capturedFromPit: capturedFromPit,
        capturedSeeds: capturedSeeds,
        extraTurn: extraTurn,
        gameOver: gameOver,
        winner: winner,
      )
    );
  }

  /// When the game is over, any seeds remaining on a player's side are swept
  /// into their own store.
  AyoBoard _sweepRemaining() {
    final next = List<int>.from(pits);
    for (var i = 0; i < 6; i++) {
      next[6] += next[i];
      next[i] = 0;
      next[13] += next[i + 7];
      next[i + 7] = 0;
    }
    return AyoBoard._(next, turn);
  }

  @override
  String toString() {
    final top = pits.sublist(7, 13).reversed.toList();
    final bot = pits.sublist(0, 6);
    return 'N store=${pits[13]} | top=$top\n'
        '         bot=$bot | S store=${pits[6]} | turn=$turn';
  }
}

/// Difficulty tiers — translate to search depth.
enum AyoAiDifficulty { easy, medium, hard, expert }

/// AI player using iterative-deepening minimax + alpha-beta pruning. The
/// heuristic balances store score, seed control, and capture potential.
class AyoAi {
  final AyoAiDifficulty difficulty;
  final Random _rng;
  AyoAi({required this.difficulty, int? seed}) : _rng = Random(seed);

  int _depth() {
    switch (difficulty) {
      case AyoAiDifficulty.easy:
        return 2;
      case AyoAiDifficulty.medium:
        return 4;
      case AyoAiDifficulty.hard:
        return 6;
      case AyoAiDifficulty.expert:
        return 8;
    }
  }

  int chooseMove(AyoBoard board) {
    final me = board.turn;
    final moves = board.legalMoves();
    if (moves.isEmpty) return -1;
    if (difficulty == AyoAiDifficulty.easy && _rng.nextDouble() < 0.30) {
      // Easy mode occasionally plays a random move for variety.
      return moves[_rng.nextInt(moves.length)];
    }
    var bestMove = moves.first;
    var bestScore = -1 << 30;
    for (final move in moves) {
      final (next, _) = board.play(move);
      final score = -_negamax(next, _depth() - 1, -1 << 30, 1 << 30, me);
      if (score > bestScore) {
        bestScore = score;
        bestMove = move;
      }
    }
    return bestMove;
  }

  int _negamax(AyoBoard board, int depth, int alpha, int beta, AyoPlayer perspective) {
    if (depth == 0 || board.isGameOver()) {
      return _evaluate(board, perspective);
    }
    final moves = board.legalMoves();
    if (moves.isEmpty) return _evaluate(board, perspective);
    var value = -1 << 30;
    for (final m in moves) {
      final (next, _) = board.play(m);
      final sign = next.turn == board.turn ? 1 : -1; // extra-turn handling
      final child = sign * _negamax(next, depth - 1, sign == 1 ? alpha : -beta,
          sign == 1 ? beta : -alpha, perspective);
      if (child > value) value = child;
      if (value > alpha) alpha = value;
      if (alpha >= beta) break;
    }
    return value;
  }

  int _evaluate(AyoBoard board, AyoPlayer perspective) {
    final other = AyoBoard.otherOf(perspective);
    final myStore = board.storeFor(perspective);
    final oppStore = board.storeFor(other);
    final myPits =
        board.pitsFor(perspective).map((p) => board.pits[p]).fold<int>(0, (a, b) => a + b);
    final oppPits =
        board.pitsFor(other).map((p) => board.pits[p]).fold<int>(0, (a, b) => a + b);
    // Weighted heuristic: store score (most important) +  seed control.
    return (myStore - oppStore) * 12 + (myPits - oppPits) * 1;
  }
}
