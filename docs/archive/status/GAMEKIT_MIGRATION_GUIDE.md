# GameKit Migration Guide

## Overview

All games must now use the **GameKit framework** instead of implementing their own logic. This ensures:
- ✅ No random correctness logic
- ✅ Consistent scoring, difficulty, and feedback
- ✅ Rive animation integration
- ✅ Polie backend evaluation
- ✅ Production-ready code

## Architecture

```
lib/games/
├── gamekit/              # Core framework (used by ALL games)
│   ├── game.dart
│   ├── game_engine.dart
│   ├── game_session.dart
│   ├── game_scoring.dart
│   ├── game_difficulty.dart
│   ├── game_feedback.dart
│   ├── game_animation_bridge.dart
│   └── game_result.dart
├── tone_forge/          # Flagship game (gold standard)
├── proverb_unlocker/    # Refactored example
└── [other games]/       # All games follow same pattern
```

## Migration Steps

### 1. Create Game Models

Create `[game_name]_models.dart`:

```dart
class MyGameContent {
  final String text;
  final String correctAnswer;
  final List<String> options;
  final String contentId;
  // ... game-specific fields
}

class MyGameInput {
  final String selectedAnswer;
  // ... user input fields
}
```

### 2. Create Scoring Engine

Create `[game_name]_scoring.dart`:

```dart
class MyGameScoringEngine implements GameScoringEngine {
  final PolieGameClient polieClient;

  MyGameScoringEngine({required this.polieClient});

  @override
  Future<GameScore> score(GameTurnContext context) async {
    final content = context.content as MyGameContent;
    final input = context.input as MyGameInput;

    // Use Polie backend - NO RANDOM LOGIC
    final evaluation = await polieClient.evaluateTurn(
      gameId: 'my_game',
      contentId: content.contentId,
      language: context.session.language,
      userInput: {'selected_answer': input.selectedAnswer},
      difficulty: context.session.level ?? 'A2',
      sessionMetrics: context.session.performanceProfile,
    );

    return GameScore(
      accuracy: evaluation.accuracy,
      isPerfect: evaluation.accuracy > 0.9,
      isFail: evaluation.accuracy < 0.4,
    );
  }
}
```

### 3. Create Feedback Engine

Create `[game_name]_feedback.dart`:

```dart
class MyGameFeedbackEngine implements GameFeedbackEngine {
  @override
  Future<GameFeedback> generate(GameTurnContext context, GameScore score) async {
    if (score.isPerfect) {
      return GameFeedback.success(
        message: 'Excellent!',
        animationEvent: AnimationEvent.proud,
      );
    }
    // ... other cases
  }
}
```

### 4. Create Game Class

Create `[game_name]_game.dart`:

```dart
class MyGame extends Game<MyGameContent, MyGameInput> {
  final PolieGameClient polieClient;

  MyGame({
    required GameEngine engine,
    required this.polieClient,
  }) : super(engine);

  @override
  GameConfig get config => const GameConfig(
    gameId: 'my_game',
    displayName: 'My Game',
  );

  @override
  Future<MyGameContent> loadContent(GameSession session) async {
    final polieContent = await polieClient.generateContent(
      gameId: config.gameId,
      language: session.language,
      // ... other params
    );
    return MyGameContent.fromPolieContent(polieContent);
  }

  @override
  Future<GameTurnResult> playTurn(
    MyGameContent content,
    MyGameInput input,
    GameSession session,
  ) async {
    final context = GameTurnContext(
      content: content,
      input: input,
      session: session,
    );
    return await engine.resolve(context);
  }
}
```

### 5. Create Game Screen

Create `[game_name]_screen.dart`:

```dart
class MyGameScreen extends BaseGameScreen {
  // ... standard setup
}

class _MyGameScreenState extends BaseGameScreenState<MyGameScreen> {
  late MyGame _game;
  late PolieGameClient _polieClient;
  late GameAnimationBridge _animationBridge;
  late RiveGameGuideController _guideController;

  @override
  void initState() {
    super.initState();
    _guideController = RiveGameGuideController();
    _animationBridge = GameAnimationBridge(guideController: _guideController);
    _polieClient = PolieGameClient();
    _game = MyGameFactory.create(
      polieClient: _polieClient,
      animationBridge: _animationBridge,
    );
  }

  // Use _game.loadContent() and _game.playTurn()
  // Display RiveGameGuide widget
}
```

## Key Changes from Old System

### ❌ OLD (Random Logic)
```dart
_isCorrect = Random().nextBool(); // BAD!
```

### ✅ NEW (Polie Backend)
```dart
final evaluation = await polieClient.evaluateTurn(...);
final isCorrect = evaluation.correct; // Real evaluation
```

### ❌ OLD (No Animation)
```dart
// No animation system
```

### ✅ NEW (Rive Integration)
```dart
_guideController.celebrate(); // Animated feedback
```

### ❌ OLD (Inconsistent Scoring)
```dart
// Each game implements its own scoring
```

### ✅ NEW (Unified Engine)
```dart
final result = await engine.resolve(context); // Consistent
```

## Reference Implementations

1. **ToneForge** (`lib/games/tone_forge/`) - Flagship game with audio analysis
2. **ProverbUnlocker** (`lib/games/proverb_unlocker/`) - Refactored example

## Backend Integration

The backend must implement:
- `POST /v1/game-content` - Generate game content
- `POST /v1/polie/evaluate-game-turn` - Evaluate turns

See `node-backend/src/routes/polie/gameEvaluator.ts` for implementation.

## Checklist

- [ ] Remove all `Random().nextBool()` calls
- [ ] Create game models
- [ ] Create scoring engine using Polie
- [ ] Create feedback engine
- [ ] Create game class extending `Game<TContent, TInput>`
- [ ] Create game screen with Rive integration
- [ ] Test with Polie backend
- [ ] Remove old implementation

## Questions?

See `ToneForge` or `ProverbUnlocker` for complete working examples.

