// Language Ludo — pure engine.
//
// Standard 4-player Ludo with an African board theme. Each player owns four
// tokens that start in a home base and race counter-clockwise around a
// 52-square shared track, then turn into a 5-square home column. The first
// player to land all four tokens in the goal wins.
//
// Rules implemented:
//   - Roll a six to release a token from base onto the start square.
//   - Rolling a six grants another roll (max 3 sixes in a row, then turn
//     forfeits to discourage stalling).
//   - When a token lands on an opponent's token (and the square is not a
//     "safe" square), that opponent token returns to base.
//   - Tokens cannot pass beyond their home column entrance — once they
//     approach the home stretch, they must roll exact numbers to fit.
//   - Safe squares: every 8th square (0, 8, 16, 24, 32, 40, 48) and each
//     player's starting square.
//
// Engine is pure (no Flutter) so it can drive both the UI and the AI search.

import 'dart:math';

enum LudoColor { red, green, yellow, blue }

class LudoToken {
  /// -1 = in base (not yet on track), 0..51 = main track position,
  /// 100..104 = home column positions (5 cells per column),
  /// 200 = finished (in the goal).
  int position;
  final LudoColor color;
  LudoToken({required this.color, this.position = -1});

  bool get inBase => position == -1;
  bool get onTrack => position >= 0 && position <= 51;
  bool get inHomeColumn => position >= 100 && position <= 104;
  bool get finished => position == 200;
}

/// Each player's start square index on the shared 52-square track.
const Map<LudoColor, int> ludoStartSquare = {
  LudoColor.red: 0,
  LudoColor.green: 13,
  LudoColor.yellow: 26,
  LudoColor.blue: 39,
};

/// Set of safe-square track indices. Tokens on safe squares cannot be sent
/// home by an opponent.
const Set<int> ludoSafeSquares = {0, 8, 13, 21, 26, 34, 39, 47};

class LudoBoard {
  final Map<LudoColor, List<LudoToken>> tokens;
  LudoColor turn;
  int? lastRoll;
  int consecutiveSixes;
  LudoBoard({
    required this.tokens,
    required this.turn,
    this.lastRoll,
    this.consecutiveSixes = 0,
  });

  factory LudoBoard.initial() {
    return LudoBoard(
      tokens: {
        for (final c in LudoColor.values)
          c: List.generate(4, (_) => LudoToken(color: c)),
      },
      turn: LudoColor.red,
    );
  }

  LudoColor get nextTurn {
    final i = LudoColor.values.indexOf(turn);
    return LudoColor.values[(i + 1) % LudoColor.values.length];
  }

  /// Returns the indices of [tokens] for [color] that can legally be moved on
  /// [roll]. Indices are 0..3.
  List<int> legalMoves(LudoColor color, int roll) {
    final list = tokens[color]!;
    final legal = <int>[];
    for (var i = 0; i < list.length; i++) {
      final t = list[i];
      if (t.finished) continue;
      if (t.inBase) {
        if (roll == 6) legal.add(i);
        continue;
      }
      if (t.onTrack) {
        // Cannot pass home entry by more than 5 spaces.
        final entry = (ludoStartSquare[color]! - 1 + 52) % 52;
        final distanceToEntry = (entry - t.position + 52) % 52;
        if (distanceToEntry >= roll) {
          legal.add(i);
        } else {
          final overshoot = roll - distanceToEntry - 1;
          if (overshoot <= 4) legal.add(i);
        }
        continue;
      }
      if (t.inHomeColumn) {
        if (t.position + roll <= 104 || t.position + roll == 105) {
          // 105 lands on the goal => finished
          legal.add(i);
        }
      }
    }
    return legal;
  }

  /// Applies the move. Returns a record describing capture (if any) and
  /// whether the player rolls again (rolled a six or sent a token home).
  ({LudoColor? capturedColor, bool rollAgain}) move(int tokenIndex, int roll) {
    final t = tokens[turn]![tokenIndex];
    LudoColor? capturedColor;
    if (t.inBase && roll == 6) {
      t.position = ludoStartSquare[turn]!;
    } else if (t.onTrack) {
      final entry = (ludoStartSquare[turn]! - 1 + 52) % 52;
      final distanceToEntry = (entry - t.position + 52) % 52;
      if (distanceToEntry >= roll) {
        t.position = (t.position + roll) % 52;
        // Check for capture.
        for (final c in LudoColor.values) {
          if (c == turn) continue;
          for (final ot in tokens[c]!) {
            if (ot.onTrack && ot.position == t.position &&
                !ludoSafeSquares.contains(t.position)) {
              ot.position = -1;
              capturedColor = c;
            }
          }
        }
      } else {
        final overshoot = roll - distanceToEntry - 1;
        t.position = 100 + overshoot;
        if (t.position == 105) {
          t.position = 200;
        }
      }
    } else if (t.inHomeColumn) {
      t.position += roll;
      if (t.position == 105) t.position = 200;
    }

    final rollAgain = (roll == 6) || (capturedColor != null) ||
        (t.position == 200);
    if (!rollAgain) {
      turn = nextTurn;
      consecutiveSixes = 0;
    } else if (roll == 6) {
      consecutiveSixes++;
      if (consecutiveSixes >= 3) {
        // Forfeit turn after 3 sixes.
        turn = nextTurn;
        consecutiveSixes = 0;
      }
    }
    return (capturedColor: capturedColor, rollAgain: rollAgain);
  }

  bool isWinner(LudoColor color) =>
      tokens[color]!.every((t) => t.finished);

  LudoColor? winner() {
    for (final c in LudoColor.values) {
      if (isWinner(c)) return c;
    }
    return null;
  }
}

/// Lightweight AI: prioritizes (1) finishing a token, (2) capturing, (3)
/// advancing the most-advanced token, (4) bringing a token out on a six.
class LudoAi {
  final LudoColor color;
  final Random _rng;
  LudoAi({required this.color, int? seed}) : _rng = Random(seed);

  int chooseToken(LudoBoard board, int roll) {
    final legal = board.legalMoves(color, roll);
    if (legal.isEmpty) return -1;
    // 1. If a token can finish (land on 200), prefer it.
    for (final i in legal) {
      final t = board.tokens[color]![i];
      if (t.inHomeColumn && t.position + roll == 105) return i;
    }
    // 2. If a move would capture, prefer it.
    for (final i in legal) {
      final t = board.tokens[color]![i];
      if (!t.onTrack) continue;
      final target = (t.position + roll) % 52;
      if (ludoSafeSquares.contains(target)) continue;
      for (final c in LudoColor.values) {
        if (c == color) continue;
        for (final ot in board.tokens[c]!) {
          if (ot.onTrack && ot.position == target) return i;
        }
      }
    }
    // 3. Release a token on a six.
    if (roll == 6) {
      for (final i in legal) {
        if (board.tokens[color]![i].inBase) return i;
      }
    }
    // 4. Move the most-advanced token.
    legal.sort((a, b) {
      final ta = board.tokens[color]![a];
      final tb = board.tokens[color]![b];
      final pa = ta.finished ? 1000 : (ta.inHomeColumn ? 600 + (ta.position - 100) : ta.position);
      final pb = tb.finished ? 1000 : (tb.inHomeColumn ? 600 + (tb.position - 100) : tb.position);
      return pb.compareTo(pa);
    });
    if (_rng.nextDouble() < 0.10 && legal.length > 1) {
      // Occasional randomness for unpredictability.
      return legal[_rng.nextInt(legal.length)];
    }
    return legal.first;
  }
}
