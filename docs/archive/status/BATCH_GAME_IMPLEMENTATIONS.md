# Batch Game Implementation Guide

## Status
- ✅ Proverb Unlocker - FULLY IMPLEMENTED
- ✅ Drum Rhythm Shadowing - FULLY IMPLEMENTED  
- ✅ Market Bargaining Simulator - FULLY IMPLEMENTED (code exists, verify it's applied)

## Remaining Games to Implement (18 games)

All games should follow this pattern:

### Template Structure:
```dart
class _GameNameGameState extends BaseGameScreenState<GameNameGame> {
  // State variables
  Map<String, dynamic>? _currentContent;
  int _score = 0;
  int _round = 0;
  final int _maxRounds = 5;
  bool _isLoading = false;
  
  @override
  Future<void> onGameInitialized() async {
    await _loadNewContent();
  }
  
  Future<void> _loadNewContent() async {
    // Use PolieContentGenerator
    // Update state
    // Create game options
  }
  
  void _handleUserAction(String action) {
    // Process user input
    // Check correctness
    // Update score
    // Record turn
    // Auto-advance
  }
  
  Future<void> _endGame() async {
    await finishGame();
    // Show completion dialog
  }
  
  @override
  Widget buildGameContent(BuildContext context) {
    // Build game UI with:
    // - Loading state
    // - Error handling
    // - Game content display
    // - User interaction
    // - Feedback
  }
}
```

## Games to Implement

1. **Clan Lineage Story Builder** - Use `generateCulturalStory()`
2. **Taxi/Bus Stop Survival** - Use `generateMarketScenario()` with transportation theme
3. **Food Quest** - Use Polie to generate food vocabulary and scenarios
4. **Call and Response** - Use Polie to generate call-response patterns
5. **Greeting Diplomacy Challenge** - Use Polie to generate greeting scenarios
6. **Folktale Reconstruction** - Use `generateCulturalStory()`
7. **Phrase Sniper** - Quick recognition game with Polie phrases
8. **Liar Liar** - Truth detection with Polie-generated statements
9. **Village Quest** - Use `generateCulturalStory()` with village theme
10. **Accent Decoding Puzzle** - Use Polie to explain regional accents
11. **Flashcard Safari** - Safari-themed vocabulary from Polie
12. **Rapid Tongue Twister Race** - Polie-generated tongue twisters
13. **Emoji Translator** - Match emojis to Polie-generated phrases
14. **Rhythm Typing** - Type to Polie-generated rhythm patterns
15. **Elders Blessings Challenge** - Polie-generated traditional blessings
16. **Multilingual Relay Race** - Switch between languages with Polie content
17. **Cultural Etiquette Scenarios** - Polie-generated etiquette situations
18. **Drum to Word Matching** - Match drum patterns to Polie words

## Implementation Priority

### High Priority (Core Games)
1. Food Quest - Very popular game type
2. Greeting Diplomacy Challenge - Important cultural learning
3. Folktale Reconstruction - Story-based learning
4. Village Quest - Immersive experience

### Medium Priority
5. Call and Response - Traditional learning method
6. Phrase Sniper - Quick practice
7. Flashcard Safari - Vocabulary building
8. Cultural Etiquette Scenarios - Practical learning

### Lower Priority (Can be enhanced later)
9. Remaining games

## Next Steps

1. Implement Food Quest game fully
2. Implement Greeting Diplomacy Challenge
3. Implement Folktale Reconstruction
4. Continue with remaining games systematically

