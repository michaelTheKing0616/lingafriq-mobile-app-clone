# Board Games Feature Plan
## Lingua Board (Monopoly-Style) + Lingua Scrabble (Scrabble-Style)
### Production-Ready Flutter Implementation — AUTO Mode Blueprint

**Version:** 1.0  
**Date:** 2026-03-06  
**Target App Version:** 1.7.0+170  
**Scope:** Two full board games, real-time multiplayer, LLM challenge engine, Family-tier subscription gate

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [Architecture Decisions](#2-architecture-decisions)
3. [Complete File Map](#3-complete-file-map)
4. [Phase Plan (AUTO Mode Sequence)](#4-phase-plan)
5. [Data Models](#5-data-models)
6. [Game Engines](#6-game-engines)
7. [Flame Board Components](#7-flame-board-components)
8. [Riverpod Providers](#8-riverpod-providers)
9. [Services](#9-services)
10. [UI Screens & Widgets](#10-ui-screens--widgets)
11. [Real-Time Multiplayer Architecture](#11-real-time-multiplayer-architecture)
12. [AI Challenge Engine](#12-ai-challenge-engine)
13. [API Contract Additions](#13-api-contract-additions)
14. [Backend Requirements](#14-backend-requirements)
15. [Subscription Gating](#15-subscription-gating)
16. [Design System Rules](#16-design-system-rules)
17. [Gamification Integration](#17-gamification-integration)
18. [Assets Required](#18-assets-required)
19. [Testing Strategy](#19-testing-strategy)

---

## 1. Executive Summary

Add two premium African-language board games to the existing LingAfriq Flutter app. Both games:

- Are built with **Flame 1.18** (already in `pubspec.yaml`) for board rendering
- Use **Socket.io** (already wired via `GamificationSocketService`) for real-time multiplayer
- Follow the **Riverpod 3 `NotifierProvider`** pattern used across all 59 existing providers
- Consume the **Pan-African Design System** (`PanAfricanColors`, `PanAfricanTypography`, `PanAfricanSpacing`)
- Hook into the existing **XP / hearts / combo / SRS** gamification layer
- Gate multiplayer behind the **Family subscription tier** (RevenueCat, already integrated)
- Use the app's **LLM AI service** for challenge generation, scaled to all 13 supported African languages
- Support **local pass-and-play** (free tier) and **online real-time multiplayer** (Family tier, 2–4 players)

### Game 1 — Lingua Board
> A Monopoly-inspired board game. 40 tiles arranged around a square. Each tile is an African-language word or cultural challenge. Players roll dice, land on tiles, answer language challenges to earn/spend coins, buy tiles, and collect rent from opponents who land on owned tiles. First to bankrupt the others wins.

### Game 2 — Lingua Scrabble
> A Scrabble-inspired word game on a 15×15 grid with bonus squares. Players draw letter tiles from a language-specific bag and form valid African-language words. Letters have language-adjusted point values. First to 300 points or highest score when the bag empties wins.

---

## 2. Architecture Decisions

### ADR-01: Use Flame for Board Rendering
**Decision:** Both boards are rendered as `FlameGame` widgets embedded inside a Flutter `GameWidget`. Tile interactions, animations (dice rolls, token movement, drag-and-drop) live in Flame components. The Flutter widget tree handles the HUD, modals, and challenge overlays.  
**Rationale:** Flame is already in `pubspec.yaml`. It provides smooth 60fps board animations, sprite support for tokens/tiles, and a clean component system — far better than a pure Flutter Stack/Grid for interactive boards. The `GameWidget.controlled` constructor allows full Riverpod integration.  
**Alternative rejected:** Pure Flutter Stack + AnimatedPositioned — insufficient for smooth multi-token animation and drag/drop with physics.

### ADR-02: Separate `BaseBoardGameScreen` (do NOT extend `BaseGameScreen`)
**Decision:** Create a new `BaseBoardGameScreen` abstract class. Do NOT extend the existing `BaseGameScreen`.  
**Rationale:** `BaseGameScreen` is designed around SRS flash-card quiz turns (load `PhraseCard` list → iterate turns → show completion dialog). Board games have fundamentally different state machines (rooms, player turns, board state, multiplayer sync). However, `BaseBoardGameScreen` will call the same `GamificationProvider` XP/hearts methods and `ComboTracker` so the gamification layer is shared.

### ADR-03: Socket.io Rooms (extend existing `GamificationSocketService`)
**Decision:** Create a new `BoardGameSocketService` that reuses the same `io.Socket` instance from `GamificationSocketService` via a shared singleton pattern. Do NOT create a second socket connection.  
**Rationale:** The backend runs a single Socket.io server. Multiple connections from the same client for the same user would cause duplicate events. `BoardGameSocketService` subscribes to `boardgame:room:{roomId}:*` event namespaces.

### ADR-04: Word Dictionary — Hybrid Local + Backend
**Decision:** Ship a compressed SQLite database of 1000+ words per language as a Flutter asset. For word validation in Scrabble, the device queries this local DB first. Unknown words are validated against a backend endpoint that checks the LLM dictionary. New validated words are cached locally.  
**Rationale:** Offline play is a first-class requirement. The existing app has 7 offline services — both games must work offline in local pass-and-play mode. `sqflite` is used for the local dictionary.

### ADR-05: Language Content is LLM-Generated, then Cached
**Decision:** Tile content (words, translations, pronunciation, cultural trivia, chance cards) is generated by the existing LLM service at game creation time and cached to Hive. The board layout is fixed (40 tiles), but the content on each tile is dynamically generated for the selected language.  
**Rationale:** Scales to any of the 13 supported languages (and future languages) without maintaining a hand-curated dataset per language. The LLM already powers AI challenges across the app.

### ADR-06: `sqflite` for Local Word Dictionary
**Decision:** Add `sqflite: ^2.3.3+1` and `sqflite_ffi: ^2.3.3` to `pubspec.yaml`.  
**Rationale:** The 1000+ word dictionary with language/difficulty/pronunciation metadata is too large and too relational for Hive. SQLite gives fast indexed lookups for word validation, which Scrabble needs on every word placement.

### ADR-07: Family Tier Gates Real-Time Multiplayer Only
**Decision:** Local pass-and-play (2 players, same device) is available to all tiers. Online real-time multiplayer (2–4 players, separate devices) requires Family tier or above. This is checked via RevenueCat's `PurchasesProvider` (already implemented in the app).  
**Rationale:** Aligns with the product's subscription model. Gives free users a taste of both games without a paywall, while adding real value to the Family tier.

---

## 3. Complete File Map

### 3a. New Files to Create

```
lib/
├── games/
│   └── board_games/
│       ├── base_board_game_screen.dart          ← Abstract base for both games
│       │
│       ├── lingua_board/
│       │   ├── models/
│       │   │   ├── lingua_board_tile.dart
│       │   │   ├── lingua_board_player.dart
│       │   │   ├── lingua_board_state.dart
│       │   │   ├── lingua_board_challenge.dart
│       │   │   └── lingua_board_room.dart
│       │   ├── engine/
│       │   │   ├── lingua_board_engine.dart
│       │   │   ├── lingua_board_dice.dart
│       │   │   └── lingua_board_event_resolver.dart
│       │   ├── flame/
│       │   │   ├── lingua_board_flame_game.dart
│       │   │   ├── board_tile_component.dart
│       │   │   ├── player_token_component.dart
│       │   │   ├── dice_component.dart
│       │   │   └── board_center_component.dart
│       │   ├── providers/
│       │   │   └── lingua_board_provider.dart
│       │   ├── screens/
│       │   │   ├── lingua_board_lobby_screen.dart
│       │   │   ├── lingua_board_screen.dart
│       │   │   └── lingua_board_challenge_screen.dart
│       │   └── widgets/
│       │       ├── lingua_board_hud.dart
│       │       ├── dice_roller_widget.dart
│       │       ├── player_panel_widget.dart
│       │       ├── property_card_widget.dart
│       │       └── challenge_modal.dart
│       │
│       └── lingua_scrabble/
│           ├── models/
│           │   ├── scrabble_board_state.dart
│           │   ├── scrabble_letter_tile.dart
│           │   ├── scrabble_player.dart
│           │   ├── scrabble_word_placement.dart
│           │   └── scrabble_room.dart
│           ├── engine/
│           │   ├── scrabble_engine.dart
│           │   ├── scrabble_letter_bag.dart
│           │   ├── scrabble_word_validator.dart
│           │   ├── scrabble_score_calculator.dart
│           │   └── scrabble_board_analyzer.dart
│           ├── flame/
│           │   ├── scrabble_flame_game.dart
│           │   ├── scrabble_cell_component.dart
│           │   ├── letter_tile_component.dart
│           │   └── rack_component.dart
│           ├── providers/
│           │   └── scrabble_provider.dart
│           ├── screens/
│           │   ├── scrabble_lobby_screen.dart
│           │   └── scrabble_screen.dart
│           └── widgets/
│               ├── scrabble_hud.dart
│               ├── letter_rack_widget.dart
│               ├── score_panel_widget.dart
│               └── word_hint_widget.dart
│
├── services/
│   └── board_games/
│       ├── board_game_socket_service.dart
│       ├── board_game_ai_service.dart
│       └── african_dictionary_service.dart
│
└── models/
    └── board_games/
        ├── game_room_model.dart
        └── board_player_model.dart

assets/
└── board_games/
    ├── lingua_board/
    │   ├── board_bg.png            ← Kente-patterned board background
    │   ├── tile_word.png           ← Word property tile frame
    │   ├── tile_chance.png         ← Chance tile frame
    │   ├── tile_chest.png          ← Community chest (cultural trivia) frame
    │   ├── tile_jail.png           ← Jail tile
    │   ├── tile_go.png             ← GO tile
    │   ├── tile_free.png           ← Free parking tile
    │   ├── dice_1.png → dice_6.png ← Dice face sprites
    │   └── tokens/
    │       ├── token_kente.png
    │       ├── token_adinkra.png
    │       ├── token_mask.png
    │       └── token_drum.png
    └── lingua_scrabble/
        ├── board_bg.png            ← Ankara-patterned board background
        ├── tile_normal.png
        ├── tile_dw.png             ← Double word
        ├── tile_tw.png             ← Triple word
        ├── tile_dl.png             ← Double letter
        ├── tile_tl.png             ← Triple letter
        └── tile_center.png         ← Star center tile
```

### 3b. Files to Modify

| File | What to Add |
|---|---|
| `lib/models/game/game_session_model.dart` | Add `linguoBoard` and `linguoScrabble` to `GameType` enum |
| `lib/games/gamekit/all_games_registry.dart` | Register both games in `AllGamesRegistry.games` map |
| `lib/config/api_contract.dart` | Add `static const boardGames = _BoardGames();` group + `_BoardGames` class |
| `lib/screens/games/games_screen.dart` | Add "Board Games" section with cards for both new games |
| `lib/services/gamification/socket_service.dart` | Add `subscribeToRoomEvents(roomId)` and `unsubscribeFromRoom(roomId)` |
| `lib/my_app.dart` | Add named routes: `/lingua-board-lobby`, `/lingua-board`, `/lingua-board-challenge`, `/scrabble-lobby`, `/scrabble` |
| `pubspec.yaml` | Add `sqflite: ^2.3.3+1`, `sqflite_ffi: ^2.3.3`, declare `assets/board_games/` |

---

## 4. Phase Plan

Execute phases in order. Each phase is independently runnable in AUTO mode.

---

### Phase 1 — Foundation (No UI, no game logic)

**Goal:** All scaffolding in place. App compiles. No broken imports.

**Steps:**
1. Add `sqflite: ^2.3.3+1` and `sqflite_ffi: ^2.3.3` to `pubspec.yaml`
2. Declare `assets/board_games/` in `pubspec.yaml` under `flutter.assets`
3. Add `linguoBoard` and `linguoScrabble` to `GameType` enum in `lib/models/game/game_session_model.dart`
4. Register both games in `AllGamesRegistry.games` with appropriate `learningGoals`
5. Add `boardGames` group to `ApiContract` (see Section 13)
6. Add `subscribeToRoomEvents` / `unsubscribeFromRoom` to `GamificationSocketService`
7. Create all model files (empty classes with fields, `copyWith`, `toJson`, `fromJson`)
8. Create stub screen files (each returns a `Scaffold` with `body: const Center(child: Text('Coming soon'))`)
9. Add named routes in `my_app.dart`
10. Add placeholder cards in `games_screen.dart`

**Compile check:** `flutter build apk --debug` must pass with zero errors.

---

### Phase 2 — Data Models (complete)

**Goal:** All models fully implemented with serialization.

Implement (in order, no UI dependencies):
1. `game_room_model.dart` — `GameRoom`, `RoomStatus`, `RoomPlayer`
2. `board_player_model.dart` — `BoardPlayer` (extends/wraps `RoomPlayer`)
3. `lingua_board_tile.dart` — `LinguaBoardTile`, `TileType` enum
4. `lingua_board_player.dart` — `LinguaBoardPlayer`
5. `lingua_board_state.dart` — `LinguaBoardState` (full game state snapshot)
6. `lingua_board_challenge.dart` — `LanguageChallenge`, `ChallengeType` enum
7. `lingua_board_room.dart` — `LinguaBoardRoom`
8. `scrabble_letter_tile.dart` — `ScrabbleLetterTile`, `TilePlacement`
9. `scrabble_player.dart` — `ScrabblePlayer`
10. `scrabble_board_state.dart` — `ScrabbleBoardState` (15×15 grid)
11. `scrabble_word_placement.dart` — `WordPlacement`, `PlacementDirection`
12. `scrabble_room.dart` — `ScrabbleRoom`

---

### Phase 3 — Services (no UI)

**Goal:** All backend and socket services implemented, testable in isolation.

1. `african_dictionary_service.dart` — SQLite dictionary, `isValidWord(word, language)`, `getWordData(word, language)`, `searchWords(prefix, language)`
2. `board_game_ai_service.dart` — LLM challenge generation, `generateTileContent(language, count)`, `generateChallenge(word, language, type)`, `generateHint(letters, language)`
3. `board_game_socket_service.dart` — Room lifecycle: `createRoom`, `joinRoom`, `leaveRoom`, emit/listen for all game events

---

### Phase 4 — Game Engines (no UI)

**Goal:** Pure Dart business logic, fully unit-testable.

1. `lingua_board_dice.dart`
2. `lingua_board_event_resolver.dart`
3. `lingua_board_engine.dart`
4. `scrabble_letter_bag.dart`
5. `scrabble_score_calculator.dart`
6. `scrabble_word_validator.dart`
7. `scrabble_board_analyzer.dart`
8. `scrabble_engine.dart`

---

### Phase 5 — Riverpod Providers

**Goal:** State management layer, wired to engines and services.

1. `lingua_board_provider.dart` — `LinguaBoardProvider extends Notifier<LinguaBoardProviderState>`
2. `scrabble_provider.dart` — `ScrabbleProvider extends Notifier<ScrabbleProviderState>`

---

### Phase 6 — Flame Components

**Goal:** Board rendering components. Must run in isolation via `flutter test` with `FlameGame.game`.

1. Lingua Board: `lingua_board_flame_game.dart`, `board_tile_component.dart`, `player_token_component.dart`, `dice_component.dart`, `board_center_component.dart`
2. Lingua Scrabble: `scrabble_flame_game.dart`, `scrabble_cell_component.dart`, `letter_tile_component.dart`, `rack_component.dart`

---

### Phase 7 — UI Screens & Widgets

**Goal:** Full production UI for both games.

1. `base_board_game_screen.dart`
2. Lingua Board: lobby → game screen → challenge screen → all widgets
3. Lingua Scrabble: lobby → game screen → all widgets
4. Add entry cards to `games_screen.dart`

---

### Phase 8 — Multiplayer Integration

**Goal:** Real-time multiplayer working end-to-end.

1. Wire `BoardGameSocketService` into both providers
2. Room creation / join flow in lobby screens
3. Sync game state on every player action
4. Subscription gate (Family tier check before room creation)

---

### Phase 9 — AI + Polish

**Goal:** LLM-generated content, animations, sound, offline fallbacks.

1. Wire `BoardGameAiService` into both providers
2. Add `flutter_animate` transitions on tile reveals, dice rolls, token movement
3. Wire `just_audio` for cultural sound effects (drums on dice roll, etc.)
4. Offline fallback: serve pre-cached tile content from Hive when no network
5. `speech_to_text` integration for pronunciation challenges in Lingua Board

---

## 5. Data Models

### 5a. `game_room_model.dart`

**Path:** `lib/models/board_games/game_room_model.dart`

```dart
enum RoomStatus { waiting, starting, inProgress, paused, finished }
enum RoomType { localPassAndPlay, onlineRealtime }

class GameRoom {
  final String roomId;
  final String gameType;          // 'lingua_board' | 'lingua_scrabble'
  final String hostUserId;
  final List<RoomPlayer> players; // max 4
  final RoomStatus status;
  final RoomType type;
  final String language;
  final DateTime createdAt;
  final Map<String, dynamic> settings;
  // copyWith / toJson / fromJson
}

class RoomPlayer {
  final String userId;
  final String displayName;
  final String avatarUrl;
  final bool isHost;
  final bool isReady;
  final bool isConnected;
  // copyWith / toJson / fromJson
}
```

### 5b. `lingua_board_tile.dart`

**Path:** `lib/games/board_games/lingua_board/models/lingua_board_tile.dart`

```dart
enum TileType {
  go,          // Start — collect 200 coins when passing
  word,        // African language word — buyable property
  railroad,    // Language family — buyable, special rent
  chance,      // AI-generated language challenge
  culturalChest, // Cultural trivia card
  tax,         // Pay language master tax
  jail,        // Go to jail / visiting
  freeParking, // Rest space, no action
  goToJail,    // Send player to jail
}

class LinguaBoardTile {
  final int position;           // 0–39 around the board
  final TileType type;
  final String? language;       // which African language (for word tiles)
  final String? word;           // the word displayed
  final String? translation;
  final String? pronunciation;  // IPA or phonetic
  final String? audioUrl;
  final String? exampleSentence;
  final int cost;               // coins to buy (0 for non-buyable)
  final int baseRent;           // coins charged to visitors
  final int housedRent;         // rent when owner has answered correctly 3×
  final String? ownerId;        // userId who owns this tile, null = unowned
  final int ownerCorrectCount;  // how many times owner answered correctly
  final Color color;            // tile group color (language family color)
  final String? culturalNote;   // shown on hover / long-press
  // copyWith / toJson / fromJson
}
```

**Board layout — 40 tiles, positions 0–39:**

| Position | Type | Content |
|---|---|---|
| 0 | `go` | GO — collect 200 coins |
| 1–3 | `word` | Swahili group (color: kenteBlue) |
| 4 | `tax` | Language Master Tax |
| 5 | `railroad` | Niger-Congo family |
| 6–8 | `word` | Yoruba group (color: kenteRed) |
| 9 | `chance` | AI Challenge card |
| 10 | `jail` | Visiting / In Jail |
| 11–13 | `word` | Hausa group (color: ankaraPurple) |
| 14 | `railroad` | Afro-Asiatic family |
| 15–17 | `word` | Zulu group (color: kitengeTeal) |
| 18 | `culturalChest` | Cultural Wisdom card |
| 19 | `word` | Zulu group |
| 20 | `freeParking` | Free Parking |
| 21–23 | `word` | Amharic group (color: secondary/gold) |
| 24 | `railroad` | Bantu family |
| 25–27 | `word` | Igbo group (color: maasaiRed) |
| 28 | `chance` | AI Challenge card |
| 29 | `word` | Igbo group |
| 30 | `goToJail` | Go to Jail |
| 31–33 | `word` | Twi group (color: primary/green) |
| 34 | `railroad` | Nilo-Saharan family |
| 35–37 | `word` | Wolof group (color: tertiary/orange) |
| 38 | `tax` | Elder's Tribute |
| 39 | `word` | Wolof group (premium) |

### 5c. `lingua_board_state.dart`

**Path:** `lib/games/board_games/lingua_board/models/lingua_board_state.dart`

```dart
enum TurnPhase {
  waiting,        // Waiting for this player's action
  rollingDice,    // Dice animation in progress
  movingToken,    // Token moving animation
  challengeActive,// Language challenge modal open
  buyDecision,    // Buy/decline a tile
  payingRent,     // Paying rent animation
  turnComplete,   // Waiting to pass to next player
  gameOver,
}

class LinguaBoardState {
  final List<LinguaBoardTile> board;       // 40 tiles, immutable layout
  final List<LinguaBoardPlayer> players;
  final int currentPlayerIndex;
  final TurnPhase phase;
  final int? lastDiceRoll;
  final LanguageChallenge? activeChallenge;
  final List<String> eventLog;            // last 10 events for the log panel
  final bool isMultiplayer;
  final String? roomId;
  final bool isMyTurn;                    // computed: players[currentPlayerIndex].userId == localUserId
  // copyWith / toJson / fromJson
}
```

### 5d. `lingua_board_player.dart`

```dart
class LinguaBoardPlayer {
  final String userId;
  final String displayName;
  final String avatarUrl;
  final int position;           // 0–39
  final int coins;              // starts at 1500
  final List<int> ownedTiles;   // tile positions owned
  final bool isInJail;
  final int jailTurns;
  final int correctAnswers;     // total across session
  final int wrongAnswers;
  final String tokenId;         // 'kente' | 'adinkra' | 'mask' | 'drum'
  final Color tokenColor;
  // copyWith / toJson / fromJson
}
```

### 5e. `lingua_board_challenge.dart`

```dart
enum ChallengeType {
  translate,        // What does X mean?
  multipleChoice,   // Multiple choice translation
  fillBlank,        // Fill in the blank sentence
  pronunciation,    // Say this word (speech_to_text)
  proverb,          // Cultural wisdom trivia
  listening,        // Hear audio, identify word
}

class LanguageChallenge {
  final String id;
  final ChallengeType type;
  final String language;
  final String word;
  final String prompt;           // Question text
  final String correctAnswer;
  final List<String> options;    // For multipleChoice (4 options)
  final String? audioUrl;        // For listening challenges
  final String? hint;
  final int coinsReward;
  final int coinsPenalty;
  final int timeLimitSeconds;    // default 30
  // toJson / fromJson
}
```

### 5f. Scrabble Models

#### `scrabble_letter_tile.dart`
```dart
class ScrabbleLetterTile {
  final String id;            // uuid
  final String letter;
  final int points;
  final bool isBlank;         // blank tiles = 0 points, player chooses letter
  String? assignedLetter;     // if isBlank == true, set when played
  // copyWith
}

class TilePlacement {
  final ScrabbleLetterTile tile;
  final int row;              // 0–14
  final int col;              // 0–14
}
```

#### `scrabble_board_state.dart`
```dart
enum BonusType { none, doubleLetter, tripleLetter, doubleWord, tripleWord, center }

class ScrabbleBoardCell {
  final int row;
  final int col;
  final BonusType bonus;
  final ScrabbleLetterTile? tile;  // null = empty
  final bool isLocked;             // true = placed in a previous turn
}

class ScrabbleBoardState {
  final List<List<ScrabbleBoardCell>> grid;    // 15×15
  final List<ScrabblePlayer> players;
  final int currentPlayerIndex;
  final List<ScrabbleLetterTile> bag;
  final List<TilePlacement> pendingPlacements; // current turn, not yet committed
  final List<String> validatedWords;           // this turn's words, shown before confirm
  final bool isMyTurn;
  final String? roomId;
  final bool gameOver;
  // copyWith / toJson / fromJson
}
```

**Bonus Square Layout (standard Scrabble):**
```
TW positions: (0,0),(0,7),(0,14),(7,0),(7,14),(14,0),(14,7),(14,14)
DW positions: (1,1),(2,2),(3,3),(4,4),(7,7/center),(10,10),(11,11),(12,12),(13,13)
              (1,13),(2,12),(3,11),(4,10),(10,4),(11,3),(12,2),(13,1)
TL positions: (1,5),(1,9),(5,1),(5,5),(5,9),(5,13),(9,1),(9,5),(9,9),(9,13),(13,5),(13,9)
DL positions: (0,3),(0,11),(2,6),(2,8),(3,0),(3,7),(3,14),(6,2),(6,6),(6,8),(6,12),
              (7,3),(7,11),(8,2),(8,6),(8,8),(8,12),(11,0),(11,7),(11,14),(12,6),(12,8),
              (14,3),(14,11)
```

#### `scrabble_player.dart`
```dart
class ScrabblePlayer {
  final String userId;
  final String displayName;
  final String avatarUrl;
  final List<ScrabbleLetterTile> rack;  // 7 tiles max
  final int score;
  final int passCount;         // 3 consecutive passes → game ends
  final List<String> wordsPlayed;
  // copyWith / toJson / fromJson
}
```

---

## 6. Game Engines

### 6a. `lingua_board_engine.dart`

**Path:** `lib/games/board_games/lingua_board/engine/lingua_board_engine.dart`

Pure Dart class — no Flutter dependencies, no providers. Receives state, returns new state.

```dart
class LinguaBoardEngine {
  /// Roll two dice. Returns [die1, die2].
  static (int, int) rollDice();

  /// Move player by diceTotal steps. Handles passing GO (+200 coins).
  static LinguaBoardState movePlayer(
    LinguaBoardState state,
    int playerIndex,
    int steps,
  );

  /// Resolve landing on a tile. Returns updated state + what event occurred.
  static (LinguaBoardState, TileLandEvent) resolveTileLand(
    LinguaBoardState state,
    int playerIndex,
  );

  /// Apply challenge result (correct / incorrect).
  static LinguaBoardState applyChallenge(
    LinguaBoardState state,
    int playerIndex,
    bool wasCorrect,
  );

  /// Buy a tile for the current player.
  static LinguaBoardState buyTile(
    LinguaBoardState state,
    int playerIndex,
    int tilePosition,
  );

  /// Compute rent owed for landing on owned tile.
  static int computeRent(LinguaBoardTile tile);

  /// Send player to jail.
  static LinguaBoardState sendToJail(LinguaBoardState state, int playerIndex);

  /// Check if a player is bankrupt (coins < 0 and no assets).
  static bool isBankrupt(LinguaBoardPlayer player);

  /// Check for game over (only 1 player solvent).
  static String? getWinnerId(LinguaBoardState state);

  /// Advance to next non-bankrupt player.
  static LinguaBoardState nextTurn(LinguaBoardState state);
}

enum TileLandEvent {
  ownTile,
  unownedTile,
  opponentTile,
  challenge,
  culturalChest,
  tax,
  jail,
  goToJail,
  freeParking,
  go,
}
```

### 6b. `lingua_board_dice.dart`

```dart
import 'dart:math';

class LinguaBoardDice {
  static final Random _rng = Random.secure();

  /// Returns a value 1–6
  static int roll() => _rng.nextInt(6) + 1;

  /// Roll two dice. Returns (die1, die2, total).
  static (int, int, int) rollDouble() {
    final d1 = roll();
    final d2 = roll();
    return (d1, d2, d1 + d2);
  }

  /// True if both dice match (doubles → player rolls again, 3 doubles → jail)
  static bool isDouble(int d1, int d2) => d1 == d2;
}
```

### 6c. `scrabble_engine.dart`

**Path:** `lib/games/board_games/lingua_scrabble/engine/scrabble_engine.dart`

```dart
class ScrabbleEngine {
  /// Draw n tiles from the bag. Mutates bag, returns drawn tiles.
  static (List<ScrabbleLetterTile>, List<ScrabbleLetterTile>) drawTiles(
    List<ScrabbleLetterTile> bag,
    int count,
  );

  /// Refill player rack to 7 tiles from bag.
  static ScrabblePlayer refillRack(ScrabblePlayer player, List<ScrabbleLetterTile> bag);

  /// Validate pending placements form a legal move (connected, direction, etc.)
  /// Returns list of words formed (for scoring) or null if invalid.
  static List<String>? validatePlacement(
    ScrabbleBoardState state,
    List<TilePlacement> placements,
  );

  /// Commit placements: lock tiles, refill rack, advance turn.
  static ScrabbleBoardState commitPlacement(
    ScrabbleBoardState state,
    List<TilePlacement> placements,
    List<String> formedWords,
    int scoreGained,
    AfricanDictionaryService dictionary,
  );

  /// Exchange tiles: return to bag (shuffled back), draw same count.
  static ScrabbleBoardState exchangeTiles(
    ScrabbleBoardState state,
    int playerIndex,
    List<String> tileIds,
  );

  /// Pass turn.
  static ScrabbleBoardState passTurn(ScrabbleBoardState state, int playerIndex);

  /// Check game-over conditions:
  ///   - Bag empty + any player rack empty
  ///   - All players passed consecutively (state.players.every(p => p.passCount >= 2))
  static bool isGameOver(ScrabbleBoardState state);

  /// Final score adjustment: subtract remaining rack tiles, add to opponents if bag empty.
  static ScrabbleBoardState applyFinalScores(ScrabbleBoardState state);
}
```

### 6d. `scrabble_letter_bag.dart`

Generate a language-specific letter bag. African languages have very different phoneme distributions:

```dart
class ScrabbleLetterBag {
  /// Returns 100 language-appropriate letter tiles for the given language.
  /// Letter distribution and point values are tuned per language.
  static List<ScrabbleLetterTile> createBag(String language);

  // Language distributions (examples):
  // Swahili: high A, E, I, O (vowel-heavy), high M, N, K
  // Yoruba: high O, A, high tonal markers (use base latin)
  // Hausa: high A, I, U, high consonant clusters
  // Amharic: uses Ethiopic script — represent syllables, not individual letters
  // Zulu: high click consonants represented as c, x, q
}
```

**Point values design principle:** Common letters in a language = 1 point. Rare letters = higher points. Tonal markers / special characters = 3–5 points.

### 6e. `scrabble_word_validator.dart`

```dart
class ScrabbleWordValidator {
  final AfricanDictionaryService _dictionary;

  ScrabbleWordValidator(this._dictionary);

  /// Returns true if word is valid in the given language.
  Future<bool> isValid(String word, String language);

  /// Returns all valid words that can be formed from given rack letters.
  Future<List<String>> suggestWords(List<String> rack, String language);

  /// Validate all words formed by a placement simultaneously.
  Future<bool> validateAllFormedWords(List<String> words, String language);
}
```

### 6f. `scrabble_score_calculator.dart`

```dart
class ScrabbleScoreCalculator {
  /// Score a single word placement, applying bonus squares.
  /// bonusSquares: positions of any bonus cells covered by THIS placement.
  static int scoreWord(
    String word,
    List<ScrabbleLetterTile> tiles,
    List<BonusType> bonusesApplied,
  );

  /// Bingo bonus: +50 points if all 7 rack tiles are used in one move.
  static int applyBingo(int baseScore, bool usedAllTiles);

  /// Score all words formed in one turn.
  static int scoreTurn(
    List<({String word, List<ScrabbleLetterTile> tiles, List<BonusType> bonuses})> formedWords,
    bool usedAllRackTiles,
  );
}
```

---

## 7. Flame Board Components

### 7a. Lingua Board — Flame Game

**Path:** `lib/games/board_games/lingua_board/flame/lingua_board_flame_game.dart`

```dart
class LinguaBoardFlameGame extends FlameGame with TapCallbacks {
  // Callbacks to Flutter layer
  final void Function(int tilePosition) onTileTapped;
  final void Function() onDiceRollRequested;

  // State (updated by Flutter via updateState())
  LinguaBoardState _state;

  // Components
  late final List<BoardTileComponent> _tileComponents;
  late final List<PlayerTokenComponent> _tokenComponents;
  late final DiceComponent _diceComponent;
  late final BoardCenterComponent _centerComponent;

  @override
  Future<void> onLoad() async {
    // Load board background (kentePattern sprite)
    // Create 40 BoardTileComponent instances positioned around the board
    // Create token components for each player
    // Create DiceComponent at board center
    // Create BoardCenterComponent (decorative logo + instructions)
  }

  /// Called from Flutter provider when game state changes
  void updateState(LinguaBoardState newState) {
    // Animate token movements
    // Update tile ownership colors
    // Trigger dice roll animation if phase == rollingDice
  }

  /// Animate a specific token moving from position A to B (step by step)
  Future<void> animateTokenMove(int playerIndex, int fromPos, int toPos);

  /// Play dice roll animation, then call onDiceRollRequested
  Future<void> animateDiceRoll(int d1, int d2);
}
```

**Board geometry (428×428 logical pixels, matching screenutil base):**
- Each tile: ~48×48px corners, ~36×48px non-corners
- 11 tiles per side (including corners)
- Positions 0–10: bottom row (left→right)
- Positions 10–20: right column (bottom→top)
- Positions 20–30: top row (right→left)
- Positions 30–40: left column (top→bottom)

```dart
class BoardTileComponent extends PositionComponent with TapCallbacks {
  final LinguaBoardTile tile;
  final void Function(int) onTap;

  // Visual state:
  // - unowned: light neutral background + language color strip
  // - owned: owner's token color tint
  // - current player here: pulsing glow ring (flutter_animate equivalent in Flame effect)
}
```

```dart
class PlayerTokenComponent extends PositionComponent {
  final LinguaBoardPlayer player;
  // Sprite: colored African cultural token (kente/adinkra/mask/drum)
  // Stacks offset when multiple tokens on same tile
  // move(int targetPosition) → MoveEffect animation
}
```

```dart
class DiceComponent extends PositionComponent with TapCallbacks {
  // Shows two dice faces
  // Tap triggers roll animation: rapid sprite cycling → settle on result
  // RotateEffect + ScaleEffect during roll
  final void Function() onRollRequested;
}
```

### 7b. Lingua Scrabble — Flame Game

**Path:** `lib/games/board_games/lingua_scrabble/flame/scrabble_flame_game.dart`

```dart
class ScrabbleFlameGame extends FlameGame with DragCallbacks, TapCallbacks {
  final void Function(TilePlacement) onTilePlaced;
  final void Function(String tileId) onTileReturned;
  final void Function() onWordSubmitted;

  ScrabbleBoardState _state;

  late final List<List<ScrabbleCellComponent>> _cells;   // 15×15
  late final RackComponent _rack;
  late final LetterTileComponent? _draggingTile;

  @override
  Future<void> onLoad() async {
    // Render board background (ankara pattern)
    // Create 225 ScrabbleCellComponent instances (15×15 grid)
    // Apply bonus coloring to bonus squares
    // Create RackComponent at bottom
  }

  /// Drag a tile from rack onto a board cell
  @override
  void onDragUpdate(DragUpdateEvent event);

  /// On drag end: snap to nearest valid board cell, or return to rack
  @override
  void onDragEnd(DragEndEvent event);

  void updateState(ScrabbleBoardState newState);
}
```

```dart
class ScrabbleCellComponent extends PositionComponent with TapCallbacks {
  final int row;
  final int col;
  final BonusType bonus;
  ScrabbleLetterTile? placedTile;
  bool isLocked = false;

  // Color mapping:
  //   TW → PanAfricanColors.kenteRed
  //   DW → PanAfricanColors.secondary (gold)
  //   TL → PanAfricanColors.kenteBlue
  //   DL → PanAfricanColors.primaryLight
  //   Normal → PanAfricanColors.neutralLight (light mode) / neutralDark (dark)
  //   Center → PanAfricanColors.primary with star icon
}
```

```dart
class LetterTileComponent extends PositionComponent with DragCallbacks {
  final ScrabbleLetterTile tile;
  bool isDragging = false;
  Vector2? _dragOffset;

  // Visual: rounded rectangle
  //   Background: PanAfricanColors.secondaryLight
  //   Letter: bold, PanAfricanTypography, black
  //   Point value: small, bottom-right corner
  //   Dragging: lifted shadow effect (ScaleEffect to 1.1×)
}
```

---

## 8. Riverpod Providers

### 8a. `lingua_board_provider.dart`

**Path:** `lib/games/board_games/lingua_board/providers/lingua_board_provider.dart`

Follow the **exact pattern** of `lib/providers/game_provider.dart`:

```dart
final linguaBoardProvider =
    NotifierProvider<LinguaBoardProvider, LinguaBoardProviderState>(() {
  return LinguaBoardProvider();
});

class LinguaBoardProviderState {
  final LinguaBoardState? gameState;
  final GameRoom? room;
  final bool isLoading;
  final String? error;
  final bool challengeAnswered;
  final bool? lastAnswerCorrect;
  // copyWith
}

class LinguaBoardProvider extends Notifier<LinguaBoardProviderState>
    with BaseProviderMixin {

  LinguaBoardEngine? _engine;
  BoardGameSocketService? _socketService;
  BoardGameAiService? _aiService;

  @override
  LinguaBoardProviderState build() => LinguaBoardProviderState();

  // --- Room management ---
  Future<void> createLocalGame(String language, int playerCount);
  Future<GameRoom> createOnlineRoom(String language);
  Future<void> joinRoom(String roomCode);
  Future<void> setReady();
  Future<void> startGame();

  // --- Turn actions ---
  Future<void> rollDice();
  Future<void> buyTile();
  Future<void> declineBuy();
  Future<void> submitChallengeAnswer(String answer);
  Future<void> submitPronunciationAnswer(String transcript);
  Future<void> endTurn();

  // --- Socket event handlers (called from BoardGameSocketService callbacks) ---
  void _onRemoteStateUpdate(Map<String, dynamic> data);
  void _onPlayerDisconnected(String userId);

  // --- Gamification integration ---
  void _awardXp(int coins, bool wasCorrect);
  void _updateCombo(bool wasCorrect);
}
```

### 8b. `scrabble_provider.dart`

**Path:** `lib/games/board_games/lingua_scrabble/providers/scrabble_provider.dart`

```dart
final scrabbleProvider =
    NotifierProvider<ScrabbleProvider, ScrabbleProviderState>(() {
  return ScrabbleProvider();
});

class ScrabbleProviderState {
  final ScrabbleBoardState? boardState;
  final GameRoom? room;
  final bool isLoading;
  final String? error;
  final List<String>? pendingWordValidations;  // words formed by current placement
  final bool placementIsValid;
  final String? hint;
  // copyWith
}

class ScrabbleProvider extends Notifier<ScrabbleProviderState>
    with BaseProviderMixin {

  ScrabbleEngine? _engine;
  ScrabbleWordValidator? _validator;
  BoardGameSocketService? _socketService;
  BoardGameAiService? _aiService;

  @override
  ScrabbleProviderState build() => ScrabbleProviderState();

  Future<void> createLocalGame(String language);
  Future<GameRoom> createOnlineRoom(String language);
  Future<void> joinRoom(String roomCode);
  Future<void> startGame();

  // --- Turn actions ---
  void stageTilePlacement(TilePlacement placement);
  void unstageLastTile();
  void clearStagedTiles();
  Future<void> submitWord();       // validates then commits
  Future<void> exchangeTiles(List<String> tileIds);
  Future<void> passTurn();
  Future<void> requestHint();

  // Validates staged placements in real-time (called after every stageTilePlacement)
  Future<void> _validateStagedPlacements();

  void _onRemoteStateUpdate(Map<String, dynamic> data);
  void _awardXp(int score);
}
```

---

## 9. Services

### 9a. `board_game_socket_service.dart`

**Path:** `lib/services/board_games/board_game_socket_service.dart`

**Critical:** Reuses the same `io.Socket` instance from `GamificationSocketService`. Do NOT create a second socket. Obtain the socket via a shared `socketInstanceProvider` (which must be extracted from `GamificationSocketService` if not already a provider).

```dart
class BoardGameSocketService {
  final io.Socket _socket;

  BoardGameSocketService(this._socket);

  // --- Room lifecycle ---
  void createRoom({
    required String gameType,
    required String language,
    required String hostUserId,
    required Function(GameRoom) onCreated,
    required Function(String) onError,
  });

  void joinRoom({
    required String roomCode,
    required String userId,
    required Function(GameRoom) onJoined,
    required Function(String) onError,
  });

  void setReady(String roomId, String userId);
  void leaveRoom(String roomId, String userId);

  // --- Game events: Lingua Board ---
  void emitDiceRolled(String roomId, int d1, int d2, int newPosition);
  void emitChallengeResult(String roomId, String userId, bool correct, int coinsDelta);
  void emitTilePurchased(String roomId, int tilePosition, String buyerId);
  void emitTurnEnd(String roomId, String nextPlayerId);
  void emitStateSync(String roomId, LinguaBoardState state);  // host only, after each action

  // --- Game events: Lingua Scrabble ---
  void emitWordPlaced(String roomId, List<TilePlacement> placements, int score);
  void emitTilesExchanged(String roomId, String userId);
  void emitTurnPassed(String roomId, String userId);
  void emitScrabbleStateSync(String roomId, ScrabbleBoardState state);

  // --- Subscriptions ---
  void subscribeToRoom(String roomId, {
    required Function(GameRoom) onRoomUpdate,
    required Function(Map<String, dynamic>) onGameStateUpdate,
    required Function(String) onPlayerDisconnected,
    required Function(String) onGameOver,
  });

  void unsubscribeFromRoom(String roomId);

  // Socket event namespaces:
  // boardgame:room:{roomId}:update       → room player list changes
  // boardgame:room:{roomId}:state        → full game state sync
  // boardgame:room:{roomId}:player_left  → player disconnected
  // boardgame:room:{roomId}:game_over    → winner announced
}
```

### 9b. `board_game_ai_service.dart`

**Path:** `lib/services/board_games/board_game_ai_service.dart`

Uses the existing Dio instance (`ref.read(dioProvider)`) and existing AI API endpoint pattern from `ApiContract.ai`.

```dart
class BoardGameAiService {
  final Dio _dio;

  BoardGameAiService(this._dio);

  /// Generate 40 tiles for a Lingua Board session.
  /// Calls POST /api/board-games/lingua-board/generate-tiles
  /// Body: { language, difficulty }
  /// Response: List<LinguaBoardTile> with word, translation, pronunciation, audio_url
  Future<List<LinguaBoardTile>> generateBoardTiles(String language);

  /// Generate a single language challenge for a tile.
  /// Calls POST /api/board-games/challenges/generate
  /// Body: { word, language, challenge_type, difficulty }
  Future<LanguageChallenge> generateChallenge({
    required String word,
    required String language,
    required ChallengeType type,
  });

  /// Generate AI word hints for Scrabble.
  /// Calls POST /api/board-games/scrabble/hint
  /// Body: { letters, language, board_state_context }
  Future<String> generateScrabbleHint({
    required List<String> letters,
    required String language,
    required String boardContext,  // brief description of what's on the board
  });

  /// Validate a word against the LLM-powered extended dictionary.
  /// Calls GET /api/board-games/scrabble/validate?word=X&language=Y
  Future<bool> validateWordWithLlm(String word, String language);

  // Caches all results to Hive box 'board_game_ai_cache' with 24hr TTL
}
```

**Offline fallback:** If the network call fails, `BoardGameAiService` falls back to pre-generated content stored in Hive. On first successful load per language, content is cached. The board can always be played offline with cached content.

### 9c. `african_dictionary_service.dart`

**Path:** `lib/services/board_games/african_dictionary_service.dart`

```dart
class AfricanDictionaryService {
  static const String _dbName = 'african_dictionary.db';
  Database? _db;

  Future<void> initialize();

  /// Returns true if the word is valid in the given language.
  Future<bool> isValidWord(String word, String language);

  /// Returns word metadata: translation, pronunciation, difficulty, example.
  Future<Map<String, dynamic>?> getWordData(String word, String language);

  /// Returns all words starting with prefix (for autocomplete/hints).
  Future<List<String>> searchByPrefix(String prefix, String language, {int limit = 20});

  /// Returns words that can be formed from a given set of letters.
  Future<List<String>> wordsFromLetters(List<String> letters, String language);
}
```

**SQLite Schema:**
```sql
CREATE TABLE words (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  language TEXT NOT NULL,
  word TEXT NOT NULL,
  normalized_word TEXT NOT NULL,  -- lowercase, diacritics stripped, for matching
  translation TEXT NOT NULL,
  pronunciation TEXT,
  difficulty INTEGER DEFAULT 1,   -- 1=beginner, 2=intermediate, 3=advanced
  example_sentence TEXT,
  audio_url TEXT,
  UNIQUE(language, normalized_word)
);
CREATE INDEX idx_words_lang_word ON words(language, normalized_word);
CREATE INDEX idx_words_prefix ON words(language, normalized_word COLLATE NOCASE);
```

**Initial data:** Ship a pre-populated SQLite file as an asset at `assets/board_games/african_dictionary.db`. The file is copied to the documents directory on first launch. Contains 200 words × 13 languages = 2600+ entries minimum (expandable).

---

## 10. UI Screens & Widgets

### 10a. `base_board_game_screen.dart`

**Path:** `lib/games/board_games/base_board_game_screen.dart`

```dart
abstract class BaseBoardGameScreen extends ConsumerStatefulWidget {
  final String language;
  final GameRoom? existingRoom;
  const BaseBoardGameScreen({super.key, required this.language, this.existingRoom});
}

abstract class BaseBoardGameScreenState<T extends BaseBoardGameScreen>
    extends ConsumerState<T> {

  // Shared: award XP, update combo, play SFX, show toast notifications
  void awardXp(int amount, String reason);
  void onCorrectAnswer();
  void onWrongAnswer();
  void showCoinAnimation(int amount, bool gained);   // floating +200 / -50 coins
  void showEventToast(String message);               // "You bought Maji!"
  Future<bool> checkSubscriptionGate();              // check Family tier for multiplayer
}
```

### 10b. `lingua_board_lobby_screen.dart`

**Design:** Pan-African dark card with Kente texture background. Two modes:
- **"Play Locally"** — immediately launches with N players (1–4, same device)
- **"Play Online"** — subscription gate check → create/join room flow

**Widget tree:**
```
Scaffold
  body: Stack
    ├── KentePatternBackground()         ← custom painter with kente pattern
    └── Column
        ├── TopGradientBox (matches existing pattern)
        ├── LanguageSelector (dropdown, 13 languages)
        ├── GamePreviewCard                ← animated board preview (Flutter animate)
        │     Shows miniature 40-tile board, tokens animated around it
        ├── ModeSelectionRow
        │     ├── LocalGameButton
        │     └── OnlineGameButton (subscription badge if not Family tier)
        ├── PlayerCountSelector (for local: 2/3/4 players)
        └── RulesButton → opens bottom sheet with rules
```

**Online room creation flow (sheet or separate screen):**
```
CreateOrJoinSheet
  ├── "Create Room" tab
  │     └── Generates 6-char room code, shows QR-style code, waits for players
  │         Players list shows avatars + "Ready" toggle
  │         "Start Game" button active when ≥2 players ready
  └── "Join Room" tab
        └── 6-char code input + "Join" button
```

### 10c. `lingua_board_screen.dart`

**Layout (portrait 428×926):**

```
Scaffold
  body: Column
    ├── LinguaBoardHud (top strip: current player indicator, coins, turn phase)
    ├── Expanded
    │     Stack
    │       ├── GameWidget<LinguaBoardFlameGame>    ← the Flame board (fills square area)
    │       ├── EventLogOverlay (last 5 events, semi-transparent, right side)
    │       └── ChallengeOverlay (animates in when challenge active)
    └── PlayerPanelWidget (bottom: scrollable list of all players' status)
```

**LinguaBoardHud:**
```
Row
  ├── AvatarIndicator(currentPlayer)
  ├── Text("${currentPlayer.displayName}'s turn")
  ├── Spacer
  ├── CoinBadge(coins)
  └── TurnPhaseIndicator (dice icon / challenge icon / etc.)
```

### 10d. `lingua_board_challenge_screen.dart`

Presented as a **bottom sheet** (DraggableScrollableSheet, initial 70% height) — NOT a full screen push, so the board remains visible behind it.

```
Container (rounded top corners)
  Column
    ├── ChallengeTypeChip  (e.g., "TRANSLATE", "PRONOUNCE")
    ├── LanguageBadge      (e.g., "Swahili")
    ├── SizedBox(h: 24)
    ├── WordCard           ← large, bold Dosis font
    │     word: "Maji"
    │     pronunciation: "mah-jee"
    │     AudioPlayButton
    ├── SizedBox(h: 16)
    ├── ChallengeBody      ← depends on ChallengeType:
    │     translate: Text field input + Submit button
    │     multipleChoice: 4 OptionTile widgets
    │     pronunciation: MicButton + transcript display (speech_to_text)
    │     fillBlank: Sentence with blank + text field
    │     proverb: Question text + 4 options
    ├── CountdownTimer     ← 30s arc progress indicator
    └── CoinsStakeRow      ← "+${challenge.coinsReward} | -${challenge.coinsPenalty}"
```

**Feedback animation after answer:**
- Correct → green flash overlay + "+200 coins" float animation + drum beat SFX
- Incorrect → red shake animation + "-50 coins" float animation

### 10e. `scrabble_lobby_screen.dart`

Similar to board lobby. Key differences:
- Ankara pattern background
- Shows tile letter distribution sample for selected language
- Language selector drives letter bag preview

### 10f. `scrabble_screen.dart`

**Layout:**

```
Scaffold
  body: Column
    ├── ScrabbleHud (scores for all players, current player indicator)
    ├── Expanded (flex: 7)
    │     GameWidget<ScrabbleFlameGame>   ← 15×15 board (square, fills width)
    ├── WordHintWidget (compact: shows pending words + validity indicator)
    └── ActionRow
          ├── SubmitButton (green, active only when placement valid)
          ├── ClearButton
          ├── ExchangeButton
          ├── PassButton
          └── HintButton (AI hint)

  // Bottom Sheet: letter rack (slides up, always visible when it's your turn)
```

**ScrabbleHud:** Horizontal scroll of player score chips. Active player's chip has a pulsing border (flutter_animate).

**WordHintWidget:** Shows the word(s) being formed in real-time as tiles are placed:
```
Row
  ├── Text("MAJI")           ← word formed
  ├── ScorePreview("+13 pts")
  └── ValidityIcon           ← green check / red X
```

### 10g. Pan-African Visual Design Rules (apply to ALL board game screens)

1. **Background:** Use `PanAfricanGradients.darkSurface` in dark mode. In light mode, use a subtle Kente/Ankara custom painter as texture.
2. **Cards / surfaces:** `PanAfricanColors.surface` with `PanAfricanRadius.lg` (16px), `PanAfricanShadows.medium`
3. **Primary actions:** `PanAfricanColors.primary` (forest green) fill with white text
4. **Coins / gold rewards:** `PanAfricanColors.secondary` (#F7CB46) with `PanAfricanColors.onSecondaryContainer` text
5. **Danger / penalties:** `PanAfricanColors.kenteRed`
6. **Correct answers:** `PanAfricanColors.primary` pulse flash
7. **Wrong answers:** `PanAfricanColors.maasaiRed` shake + fade
8. **Typography:** All text uses `PanAfricanTypography` — Dosis font throughout
9. **Spacing:** All padding/margin from `PanAfricanSpacing` tokens (no hardcoded numbers except via screenutil `.w`/`.h`)
10. **Language badges:** Each language has its cultural color — Swahili=kenteBlue, Yoruba=kenteRed, Hausa=ankaraPurple, Zulu=kitengeTeal, Amharic=secondary, etc.

---

## 11. Real-Time Multiplayer Architecture

### Flow Overview

```
Player A (host)                    Backend Socket.io              Player B
     |                                     |                          |
     |── createRoom(lang, gameType) ──────►|                          |
     |◄─ roomCreated({ roomId, code }) ─── |                          |
     |                                     |                          |
     |                                     |◄── joinRoom(code) ───────|
     |◄─ roomUpdate({ players }) ──────────|──── roomUpdate ─────────►|
     |                                     |                          |
     |── setReady() ──────────────────────►|                          |
     |                                     |◄── setReady() ───────────|
     |◄─ roomUpdate(all ready) ────────────|──── roomUpdate ─────────►|
     |                                     |                          |
     |── startGame() ─────────────────────►|                          |
     |                                     |──── gameStarted ────────►|
     |◄─ initialState(LinguaBoardState) ───|──── initialState ────────►|
     |                                     |                          |
  [Player A rolls dice]                    |                          |
     |── diceRolled(d1, d2, pos) ─────────►|                          |
     |                                     |──── diceRolled ─────────►|
     |── stateSync(fullState) ─────────────►|                          |
     |                                     |──── stateSync ──────────►|
     |                                     |                          |
  [Player A answers challenge]             |                          |
     |── challengeResult(correct, delta) ──►|                          |
     |                                     |──── challengeResult ────►|
     |── stateSync(fullState) ─────────────►|                          |
     |                                     |──── stateSync ──────────►|
```

### State Sync Strategy

- **Authoritative host:** The host client is authoritative. After every action, the host emits `stateSync` with the full serialized `LinguaBoardState` or `ScrabbleBoardState`.
- **Other clients** apply the synced state directly — they do NOT run their own game engine to compute the result.
- **Latency tolerance:** Actions that are purely visual (dice roll animation, token movement) are played optimistically on all clients simultaneously. State sync confirms the outcome.
- **Disconnection handling:** If host disconnects, promote the next player (by join order) as the new host. Backend handles promotion via `boardgame:room:{id}:host_change` event.
- **Reconnection:** On reconnect, client emits `requestStateSync(roomId)` → host responds with full current state.

### Room Codes

- 6-character alphanumeric room code (uppercase, no ambiguous characters: no 0/O, 1/I/L)
- Generated on backend. Valid for 30 minutes while in `waiting` status, indefinitely while `inProgress`.
- Share via `share_plus` (existing in pubspec) from the lobby screen.

### Subscription Gate Logic

```dart
Future<bool> checkMultiplayerAccess(WidgetRef ref) async {
  final purchases = ref.read(purchasesProvider);
  final entitlements = await purchases.getEntitlements();
  final hasFamily = entitlements['family']?.isActive ?? false;
  final hasPremium = entitlements['premium']?.isActive ?? false;
  if (!hasFamily && !hasPremium) {
    // Show upgrade sheet
    ref.read(navigationProvider).showSubscriptionUpgradeSheet(
      context: context,
      feature: 'Online Multiplayer',
      requiredTier: 'Family',
    );
    return false;
  }
  return true;
}
```

---

## 12. AI Challenge Engine

### How It Works

1. **At game creation (Lingua Board):** `BoardGameAiService.generateBoardTiles(language)` calls the backend which calls the LLM with:
   ```
   System: You are a language content generator for African languages.
   Generate 30 African-language word tiles for a board game in {language}.
   For each word provide: word, translation, pronunciation (phonetic), 
   difficulty (1-3), example_sentence, cultural_note.
   Mix difficulties: 60% easy, 30% medium, 10% hard.
   Return JSON array.
   ```
2. **At tile landing (Lingua Board):** `BoardGameAiService.generateChallenge(word, language, type)` generates the specific challenge question, wrong answers, and hint.
3. **At hint request (Scrabble):** `BoardGameAiService.generateScrabbleHint(letters, language)` suggests a word from the rack.
4. **Word validation (Scrabble):** `AfricanDictionaryService.isValidWord()` checks local SQLite first. Cache miss → `BoardGameAiService.validateWordWithLlm()` → cache result.

### Language Scaling

The system scales to any of the 13 existing languages (and new ones) automatically because:
- All prompts are parameterized with `{language}`
- The letter bag in Scrabble uses a language-specific frequency map (one `Map<String, ({int count, int points})>` per language)
- The SQLite dictionary is populated per language — new languages can be added by inserting rows

### LLM Prompt Templates (stored in backend, not hardcoded in Flutter)

The backend exposes these as template keys so prompts can be updated without app updates:
- `board_games.generate_tiles` — tile content generation
- `board_games.generate_challenge.translate`
- `board_games.generate_challenge.multiple_choice`
- `board_games.generate_challenge.fill_blank`
- `board_games.generate_challenge.proverb`
- `board_games.scrabble.hint`
- `board_games.scrabble.validate`

---

## 13. API Contract Additions

**Add to `lib/config/api_contract.dart`:**

```dart
static const boardGames = _BoardGames();

class _BoardGames {
  const _BoardGames();

  // Lingua Board
  String get linguaBoardGenerateTiles => '/api/board-games/lingua-board/tiles/generate';
  String get linguaBoardChallengeGenerate => '/api/board-games/lingua-board/challenge/generate';

  // Rooms (both games)
  String get createRoom => '/api/board-games/rooms/create';
  String get joinRoom => '/api/board-games/rooms/join';
  String get leaveRoom => '/api/board-games/rooms/leave';
  String roomState(String roomId) => '/api/board-games/rooms/$roomId/state';

  // Lingua Scrabble
  String get scrabbleValidateWord => '/api/board-games/scrabble/validate';
  String get scrabbleHint => '/api/board-games/scrabble/hint';
  String get scrabbleDictionary => '/api/board-games/scrabble/dictionary';

  // Sessions (for XP/gamification sync — same pattern as existing games)
  String get boardGameSessionStart => '/api/board-games/sessions/start';
  String get boardGameSessionEnd => '/api/board-games/sessions/end';
}
```

---

## 14. Backend Requirements

The backend team needs to implement these endpoints and socket events.

### REST Endpoints

| Method | Path | Description |
|---|---|---|
| POST | `/api/board-games/rooms/create` | Create a room, return `{ roomId, code }` |
| POST | `/api/board-games/rooms/join` | Join by code, return `GameRoom` |
| POST | `/api/board-games/rooms/leave` | Leave room |
| GET | `/api/board-games/rooms/:id/state` | Get current game state (for reconnection) |
| POST | `/api/board-games/lingua-board/tiles/generate` | LLM tile content generation |
| POST | `/api/board-games/lingua-board/challenge/generate` | LLM challenge generation |
| GET | `/api/board-games/scrabble/validate` | Word validation (`?word=X&lang=Y`) |
| POST | `/api/board-games/scrabble/hint` | LLM Scrabble hint |
| GET | `/api/board-games/scrabble/dictionary` | Bulk download word list for a language (for offline) |
| POST | `/api/board-games/sessions/start` | Log session start (feeds into existing XP/gamification) |
| POST | `/api/board-games/sessions/end` | Log session end with score/xp |

### Socket.io Events (new namespaces)

```
Client → Server:
  boardgame:room:create       { gameType, language, hostUserId }
  boardgame:room:join         { roomCode, userId }
  boardgame:room:ready        { roomId, userId }
  boardgame:room:leave        { roomId, userId }
  boardgame:room:start        { roomId }
  boardgame:action:dice_roll  { roomId, d1, d2, newPosition }
  boardgame:action:challenge  { roomId, userId, correct, delta }
  boardgame:action:buy_tile   { roomId, tilePosition, userId }
  boardgame:action:turn_end   { roomId, nextPlayerId }
  boardgame:action:state_sync { roomId, state }         ← host only
  boardgame:action:word_place { roomId, placements, score }
  boardgame:action:exchange   { roomId, userId }
  boardgame:action:pass       { roomId, userId }
  boardgame:reconnect_sync    { roomId }                ← client requests state

Server → Client:
  boardgame:room:{roomId}:update         { GameRoom }   ← player list changes
  boardgame:room:{roomId}:started        { initialState }
  boardgame:room:{roomId}:state          { fullGameState }
  boardgame:room:{roomId}:player_left    { userId }
  boardgame:room:{roomId}:host_changed   { newHostId }
  boardgame:room:{roomId}:game_over      { winnerId, finalScores }
```

---

## 15. Subscription Gating

### What is Gated

| Feature | Free | Premium | Family |
|---|---|---|---|
| Local pass-and-play (same device) | ✅ | ✅ | ✅ |
| Single-player vs AI (basic) | ✅ | ✅ | ✅ |
| Online multiplayer (2–4 players) | ❌ | ❌ | ✅ |
| Spectator mode | ❌ | ✅ | ✅ |
| All 13 languages | ❌ (3 free) | ✅ | ✅ |
| AI hints in Scrabble | ❌ | ✅ | ✅ |

### Implementation

The gate is checked in `BaseBoardGameScreen.checkSubscriptionGate()` which calls `ref.read(purchasesProvider)`. The `purchasesProvider` already exists in the app.

Display: When a gated feature is tapped by a non-qualifying user, show the existing subscription upgrade bottom sheet (`SubscriptionUpgradeSheet` — already in the app) with a tailored message:
> "Play with family and friends across the world! Upgrade to Family to unlock online multiplayer."

---

## 16. Design System Rules

### Color Assignments per Game

**Lingua Board:**
- Board background: subtle Kente weave pattern (custom `CustomPainter` with geometric shapes in `PanAfricanColors.neutralDark` / `neutralDarkest`)
- Word tiles: background color from language group map
- GO tile: `PanAfricanColors.primary` with white text
- Jail: `PanAfricanColors.neutralDark` with iron bar pattern
- Free Parking: `PanAfricanColors.secondary` (gold)
- Chance tiles: `PanAfricanColors.ankaraPurple`
- Cultural Chest: `PanAfricanColors.kitengeTeal`
- Tax: `PanAfricanColors.kenteRed`
- Coins UI: always `PanAfricanColors.secondary` (#F7CB46) text on dark bg

**Lingua Scrabble:**
- Board background: Ankara fabric pattern (custom `CustomPainter`)
- Normal cells: `PanAfricanColors.neutralLight` (light) / `PanAfricanColors.neutralDark` (dark)
- TW cells: `PanAfricanColors.kenteRed` opacity 0.85
- DW cells: `PanAfricanColors.secondary` opacity 0.85
- TL cells: `PanAfricanColors.kenteBlue` opacity 0.85
- DL cells: `PanAfricanColors.primaryLight` opacity 0.85
- Center star: `PanAfricanColors.primary`
- Letter tiles: `PanAfricanColors.secondaryLight` background, black letter

### Animation Budget

All animations use `flutter_animate` (already in pubspec) with these rules:
- Dice roll: max 800ms
- Token movement: 300ms per tile step (staggered)
- Challenge modal slide-up: 350ms cubic ease
- Correct answer flash: 200ms green overlay fade
- Wrong answer shake: 400ms horizontal shake (use `ShakeEffect`)
- Coin float: 600ms vertical float + fade out
- Tile purchase: 400ms scale bounce

### Typography

- Board tile words: `PanAfricanTypography.titleSmall` (bold, 14sp)
- Player names in HUD: `PanAfricanTypography.bodyMedium`
- Coin counts: `PanAfricanTypography.titleMedium` (bold, gold color)
- Challenge word: `PanAfricanTypography.headlineMedium` (bold, center)
- Scrabble letters: `PanAfricanTypography.titleLarge` (ExtraBold, Dosis)
- Point values: `PanAfricanTypography.labelSmall`

---

## 17. Gamification Integration

Both games integrate with the **existing** gamification layer. No new providers needed for XP/hearts/combo — call the existing methods:

```dart
// Award XP (existing method in GamificationProvider)
ref.read(gamificationProvider.notifier).awardXp(
  amount: xpAmount,
  source: 'lingua_board_challenge',
);

// Update streak (existing)
ref.read(gamificationProvider.notifier).recordActivity();

// Update combo (existing ComboTracker)
_comboTracker.recordAnswer(wasCorrect: true);

// Update hearts (existing HeartsProvider) — only in challenge mode
// Board games do NOT use hearts by default (use coins instead)
// Hearts are only used if the user enables "Hard Mode" in settings

// Achievement check — existing AchievementService
// Will automatically fire achievements such as:
//   - "First Board Game Win"
//   - "Scrabble Master" (play 10 Scrabble games)
//   - "Language Monopolist" (own all tiles of one language group)
```

**XP rewards:**
- Correct challenge answer in Lingua Board: 15 XP
- Buying a tile: 5 XP
- Winning a game: 100 XP
- Valid Scrabble word (<5 letters): 10 XP
- Valid Scrabble word (5–7 letters): 20 XP
- Bingo (all 7 tiles): 50 XP bonus
- Winning a Scrabble game: 100 XP

**Session sync:** At game end, call:
```dart
ref.read(gameProvider.notifier).completeSession(
  gameType: GameType.linguoBoard,
  language: language,
  score: finalScore,
  correctAnswers: correctCount,
  totalTurns: turnCount,
);
```
This uses the existing `GameProvider.completeSession()` which handles backend sync, SRS update, and streak update.

---

## 18. Assets Required

All paths relative to `assets/board_games/`.

### Lingua Board

| Asset | Description | Format | Size target |
|---|---|---|---|
| `lingua_board/tokens/token_kente.png` | Kente cloth token | PNG, transparent | 64×64px |
| `lingua_board/tokens/token_adinkra.png` | Adinkra symbol token | PNG, transparent | 64×64px |
| `lingua_board/tokens/token_mask.png` | African mask token | PNG, transparent | 64×64px |
| `lingua_board/tokens/token_drum.png` | African drum token | PNG, transparent | 64×64px |
| `lingua_board/dice_1.png` → `dice_6.png` | Dice faces | PNG, transparent | 48×48px |
| `lingua_board/tile_chance.png` | Chance card back | PNG | 48×48px |
| `lingua_board/tile_chest.png` | Cultural chest card back | PNG | 48×48px |

### Lingua Scrabble

| Asset | Description | Format | Size target |
|---|---|---|---|
| `lingua_scrabble/tile_letter.9.png` | Letter tile nine-patch | PNG | 40×40px |

### Sound Effects (`assets/sounds/board_games/`)

| Asset | Description |
|---|---|
| `dice_roll.mp3` | 0.5s rolling dice sound |
| `token_move.mp3` | 0.1s light step sound (played per tile) |
| `correct_answer.mp3` | 0.8s African drum celebration |
| `wrong_answer.mp3` | 0.3s low tone |
| `coin_earn.mp3` | 0.4s coin jingle |
| `tile_purchase.mp3` | 0.5s stamp sound |
| `word_placed.mp3` | 0.3s tile snap |
| `bingo.mp3` | 1s celebration (7-tile play) |

---

## 19. Testing Strategy

### Unit Tests (Phase 4 deliverable)

**`test/games/board_games/lingua_board/`**
- `lingua_board_engine_test.dart` — test every engine method: move, rent, bankrupt, win, jail
- `lingua_board_dice_test.dart` — distribution test over 10,000 rolls
- `lingua_board_event_resolver_test.dart` — all TileLandEvent types

**`test/games/board_games/lingua_scrabble/`**
- `scrabble_engine_test.dart` — draw, refill, exchange, commit placement
- `scrabble_letter_bag_test.dart` — distribution, 100 tiles per language
- `scrabble_score_calculator_test.dart` — bonus squares, bingo, multi-word turns
- `scrabble_word_validator_test.dart` — valid/invalid words, prefix search
- `scrabble_board_analyzer_test.dart` — placement validation, adjacency rules

### Widget Tests (Phase 7 deliverable)

- `challenge_modal_test.dart` — renders all 5 challenge types, timer countdown, answer submission
- `player_panel_test.dart` — correct player info, highlights current player
- `letter_rack_test.dart` — renders 7 tiles, drag-to-board interaction
- `scrabble_hud_test.dart` — score updates, current player highlight

### Integration Tests (Phase 8 deliverable)

- `lingua_board_local_multiplayer_test.dart` — full 2-player local game, verify win condition
- `scrabble_local_game_test.dart` — full game to completion (using pre-seeded rack + board state)

---

## Appendix: `pubspec.yaml` Changes

Add to `dependencies`:
```yaml
sqflite: ^2.3.3+1
sqflite_ffi: ^2.3.3
```

Add to `flutter.assets`:
```yaml
- assets/board_games/lingua_board/
- assets/board_games/lingua_board/tokens/
- assets/board_games/lingua_scrabble/
- assets/board_games/african_dictionary.db
- assets/sounds/board_games/
```

---

## Appendix: `GameType` Enum Addition

In `lib/models/game/game_session_model.dart`, add to `GameType`:
```dart
enum GameType {
  // ... existing 36 values ...
  linguoBoard,      // Monopoly-style African language board game
  linguoScrabble,   // Scrabble-style African language word game
}
```

---

## Appendix: `AllGamesRegistry` Additions

In `lib/games/gamekit/all_games_registry.dart`:
```dart
'linguo_board': GameDefinition(
  gameId: 'linguo_board',
  displayName: 'Lingua Board',
  learningGoals: ['vocabulary', 'translation', 'cultural_wisdom', 'pronunciation'],
),
'linguo_scrabble': GameDefinition(
  gameId: 'linguo_scrabble',
  displayName: 'Lingua Scrabble',
  learningGoals: ['spelling', 'vocabulary', 'word_construction'],
),
```

---

## Appendix: Named Routes

In `lib/my_app.dart`, add to `_onGenerateRoute`:
```dart
case '/lingua-board-lobby':
  return SmoothPageRoute(page: LinguaBoardLobbyScreen(
    language: settings.arguments as String? ?? 'swahili',
  ));
case '/lingua-board':
  return SmoothPageRoute(page: LinguaBoardScreen(
    language: (settings.arguments as Map)['language'],
    room: (settings.arguments as Map)['room'],
  ));
case '/lingua-board-challenge':
  return SmoothPageRoute(page: LinguaBoardChallengeScreen(
    challenge: settings.arguments as LanguageChallenge,
  ));
case '/scrabble-lobby':
  return SmoothPageRoute(page: ScrabbleLobbyScreen(
    language: settings.arguments as String? ?? 'swahili',
  ));
case '/scrabble':
  return SmoothPageRoute(page: ScrabbleScreen(
    language: (settings.arguments as Map)['language'],
    room: (settings.arguments as Map)['room'],
  ));
```

---

*End of plan. Total estimated new Dart files: ~55. Modified files: 7. New assets: ~20 files. Backend endpoints: 11 REST + 12 Socket.io events.*
