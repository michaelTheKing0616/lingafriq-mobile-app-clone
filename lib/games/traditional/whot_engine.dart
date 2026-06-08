// Nigerian Whot — pure engine.
//
// Whot is the most popular indigenous card game across Nigeria. We use the
// classic 54-card deck with five suits: Circle, Cross, Square, Star, Triangle
// (Whot). Suit-cards run 1, 2, 3, 4, 5, 7, 8, 10, 11, 12, 13, 14. There are
// 4 wild "Whot" cards numbered 20.
//
// Action cards we implement:
//   - 1  : Hold On   — opponent skips one turn
//   - 2  : Pick 2    — next player picks 2 cards (stackable)
//   - 5  : General Market — every other player picks 1
//   - 8  : Suspension — skip the next player
//   - 14 : General Market — every other player picks 1
//   - 20 : Whot (wild) — play any time; demands a suit
//
// First to empty their hand wins. If you cannot play, you draw from market.
//
// The engine is pure and deterministic given a seeded [Random].

import 'dart:math';

enum WhotSuit { circle, cross, square, star, whot }

class WhotCard {
  final WhotSuit suit;
  final int rank; // 1..14 for suit cards; 20 for Whot
  const WhotCard({required this.suit, required this.rank});

  bool get isWhot => suit == WhotSuit.whot;

  @override
  String toString() => isWhot ? 'Whot(20)' : '${suit.name}-$rank';
}

class WhotState {
  final List<WhotCard> deck;
  final List<WhotCard> pile;
  final List<List<WhotCard>> hands; // one list per player
  final int turn;                   // index of player whose turn it is
  final int pickStack;              // total pending picks (Pick-2 chain)
  final int skipNext;               // number of additional turns to skip
  final WhotSuit? demandedSuit;     // set when a Whot was played

  const WhotState({
    required this.deck,
    required this.pile,
    required this.hands,
    required this.turn,
    this.pickStack = 0,
    this.skipNext = 0,
    this.demandedSuit,
  });

  WhotCard get topCard => pile.last;
  int get numPlayers => hands.length;

  WhotState copyWith({
    List<WhotCard>? deck,
    List<WhotCard>? pile,
    List<List<WhotCard>>? hands,
    int? turn,
    int? pickStack,
    int? skipNext,
    WhotSuit? demandedSuit,
    bool clearDemandedSuit = false,
  }) {
    return WhotState(
      deck: deck ?? this.deck,
      pile: pile ?? this.pile,
      hands: hands ?? this.hands,
      turn: turn ?? this.turn,
      pickStack: pickStack ?? this.pickStack,
      skipNext: skipNext ?? this.skipNext,
      demandedSuit: clearDemandedSuit ? null : (demandedSuit ?? this.demandedSuit),
    );
  }
}

class WhotEngine {
  final Random _rng;
  WhotEngine({int? seed}) : _rng = Random(seed);

  /// Build the standard 54-card Whot deck.
  List<WhotCard> _buildDeck() {
    final cards = <WhotCard>[];
    const ranks = [1, 2, 3, 4, 5, 7, 8, 10, 11, 12, 13, 14];
    for (final s in [WhotSuit.circle, WhotSuit.cross, WhotSuit.square, WhotSuit.star]) {
      for (final r in ranks) {
        cards.add(WhotCard(suit: s, rank: r));
      }
    }
    for (var i = 0; i < 4; i++) {
      cards.add(const WhotCard(suit: WhotSuit.whot, rank: 20));
    }
    return cards;
  }

  WhotState deal({required int players, int handSize = 5}) {
    assert(players >= 2 && players <= 4);
    final deck = _buildDeck()..shuffle(_rng);
    final hands = List<List<WhotCard>>.generate(players, (_) => <WhotCard>[]);
    for (var i = 0; i < handSize; i++) {
      for (var p = 0; p < players; p++) {
        hands[p].add(deck.removeLast());
      }
    }
    // Initial pile card cannot be an action card.
    var top = deck.removeLast();
    while (_isAction(top.rank) || top.isWhot) {
      deck.insert(0, top);
      top = deck.removeLast();
    }
    return WhotState(
      deck: deck,
      pile: [top],
      hands: hands,
      turn: 0,
    );
  }

  bool _isAction(int rank) =>
      rank == 1 || rank == 2 || rank == 5 || rank == 8 || rank == 14;

  /// Lists indices of cards in [hands[player]] that can be legally played
  /// given the current state.
  List<int> legalIndexes(WhotState s, int player) {
    final hand = s.hands[player];
    final top = s.topCard;
    final demanded = s.demandedSuit;
    final indices = <int>[];
    for (var i = 0; i < hand.length; i++) {
      final c = hand[i];
      if (s.pickStack > 0) {
        // Must play a 2 to continue chain (or another Whot? Different rulesets
        // vary; we keep the strict canonical version: only 2 stacks).
        if (c.rank == 2) indices.add(i);
        continue;
      }
      if (c.isWhot) {
        indices.add(i);
        continue;
      }
      if (demanded != null) {
        if (c.suit == demanded) indices.add(i);
        continue;
      }
      if (c.suit == top.suit || c.rank == top.rank) {
        indices.add(i);
      }
    }
    return indices;
  }

  /// Plays the card. If the card is a Whot, [demandSuit] must be provided.
  /// Returns the new state.
  WhotState play(WhotState s, int player, int cardIndex, {WhotSuit? demandSuit}) {
    assert(player == s.turn);
    final card = s.hands[player][cardIndex];
    final hands = [for (final h in s.hands) List<WhotCard>.from(h)];
    final played = hands[player].removeAt(cardIndex);
    final pile = List<WhotCard>.from(s.pile)..add(played);

    var pickStack = s.pickStack;
    var skipNext = s.skipNext;
    WhotSuit? demanded;

    if (played.isWhot) {
      demanded = demandSuit ?? WhotSuit.circle;
    } else if (played.rank == 2) {
      pickStack = (pickStack <= 0 ? 0 : pickStack) + 2;
    } else if (played.rank == 5 || played.rank == 14) {
      // General market: every other player picks 1.
      for (var p = 0; p < hands.length; p++) {
        if (p == player) continue;
        if (s.deck.isEmpty) break;
      }
    } else if (played.rank == 8) {
      skipNext += 1;
    } else if (played.rank == 1) {
      skipNext += 1;
    }

    // Apply "general market" pickups.
    final deck = List<WhotCard>.from(s.deck);
    if (played.rank == 5 || played.rank == 14) {
      for (var p = 0; p < hands.length; p++) {
        if (p == player || deck.isEmpty) continue;
        hands[p].add(deck.removeLast());
      }
    }

    // Apply Pick-2 stack penalty if next player can't continue.
    // We resolve that lazily on their next turn via [resolvePicks].

    var nextTurn = (player + 1) % hands.length;
    if (skipNext > 0) {
      nextTurn = (nextTurn + 1) % hands.length;
      skipNext -= 1;
    }

    return s.copyWith(
      deck: deck,
      pile: pile,
      hands: hands,
      turn: nextTurn,
      pickStack: pickStack,
      skipNext: skipNext,
      demandedSuit: demanded,
      clearDemandedSuit: !played.isWhot && played.suit != WhotSuit.whot && demanded == null,
    );
  }

  /// If [player] cannot answer the Pick-2 chain, they pick [pickStack] cards
  /// and the stack resets to 0.
  WhotState resolvePicks(WhotState s, int player) {
    if (s.pickStack <= 0) return s;
    final hands = [for (final h in s.hands) List<WhotCard>.from(h)];
    final deck = List<WhotCard>.from(s.deck);
    for (var i = 0; i < s.pickStack && deck.isNotEmpty; i++) {
      hands[player].add(deck.removeLast());
    }
    return s.copyWith(
      hands: hands,
      deck: deck,
      pickStack: 0,
    );
  }

  /// [player] draws one card from market (used when they have no legal play).
  WhotState marketDraw(WhotState s, int player) {
    final hands = [for (final h in s.hands) List<WhotCard>.from(h)];
    final deck = List<WhotCard>.from(s.deck);
    if (deck.isNotEmpty) {
      hands[player].add(deck.removeLast());
    }
    var nextTurn = (player + 1) % hands.length;
    var skipNext = s.skipNext;
    if (skipNext > 0) {
      nextTurn = (nextTurn + 1) % hands.length;
      skipNext -= 1;
    }
    return s.copyWith(
      hands: hands,
      deck: deck,
      turn: nextTurn,
      skipNext: skipNext,
    );
  }

  int? checkWinner(WhotState s) {
    for (var i = 0; i < s.hands.length; i++) {
      if (s.hands[i].isEmpty) return i;
    }
    return null;
  }
}

/// Lightweight AI: prefer special/action cards, then highest-rank matching
/// card, then Whot. Randomised tie-breaks for variety.
class WhotAi {
  final Random _rng;
  WhotAi({int? seed}) : _rng = Random(seed);

  /// Returns (cardIndex, demandedSuit-if-whot). cardIndex = -1 means "draw
  /// from market".
  (int, WhotSuit?) chooseMove(WhotEngine engine, WhotState s, int player) {
    final legal = engine.legalIndexes(s, player);
    if (legal.isEmpty) return (-1, null);
    final hand = s.hands[player];
    // Prefer Pick-2 if we are responding to a chain.
    if (s.pickStack > 0) {
      for (final i in legal) {
        if (hand[i].rank == 2) return (i, null);
      }
    }
    // Prefer action cards.
    for (final priority in [2, 8, 1, 5, 14]) {
      for (final i in legal) {
        if (hand[i].rank == priority) return (i, null);
      }
    }
    // Then Whot.
    for (final i in legal) {
      if (hand[i].isWhot) {
        // Demand the suit we hold most of.
        final counts = <WhotSuit, int>{};
        for (final c in hand) {
          if (c.isWhot) continue;
          counts[c.suit] = (counts[c.suit] ?? 0) + 1;
        }
        WhotSuit best = WhotSuit.circle;
        var bestCount = -1;
        counts.forEach((s, n) {
          if (n > bestCount) {
            bestCount = n;
            best = s;
          }
        });
        return (i, best);
      }
    }
    // Otherwise highest matching rank.
    legal.sort((a, b) => hand[b].rank.compareTo(hand[a].rank));
    if (_rng.nextDouble() < 0.10 && legal.length > 1) {
      return (legal[_rng.nextInt(legal.length)], null);
    }
    return (legal.first, null);
  }
}
