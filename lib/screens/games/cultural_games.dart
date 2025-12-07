import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../models/game/game_session_model.dart';
import 'base_game_screen.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Proverb Unlocker Game
class ProverbUnlockerGame extends BaseGameScreen {
  const ProverbUnlockerGame({
    Key? key,
    required super.language,
    super.level,
    super.onBack,
  }) : super(key: key);

  @override
  GameType getGameType() => GameType.proverbUnlocker;

  @override
  ConsumerState<ProverbUnlockerGame> createState() => _ProverbUnlockerGameState();
}

class _ProverbUnlockerGameState extends BaseGameScreenState<ProverbUnlockerGame> {
  @override
  Widget buildGameContent(BuildContext context) {
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
            const Icon(Icons.lightbulb, size: 64),
            SizedBox(height: 2.h),
            Text(
              'Decode African proverbs',
              style: TextStyle(fontSize: 18.sp),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 4.h),
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Feature coming soon!')),
                );
              },
              child: const Text('Start'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Drum Rhythm Shadowing Game
class DrumRhythmGame extends BaseGameScreen {
  const DrumRhythmGame({
    Key? key,
    required super.language,
    super.level,
    super.onBack,
  }) : super(key: key);

  @override
  GameType getGameType() => GameType.drumRhythmShadowing;

  @override
  ConsumerState<DrumRhythmGame> createState() => _DrumRhythmGameState();
}

class _DrumRhythmGameState extends BaseGameScreenState<DrumRhythmGame> {
  @override
  Widget buildGameContent(BuildContext context) {
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
            const Icon(Icons.music_note, size: 64),
            SizedBox(height: 2.h),
            Text(
              'Match tone patterns with drums',
              style: TextStyle(fontSize: 18.sp),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 4.h),
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Feature coming soon!')),
                );
              },
              child: const Text('Start'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Clan Lineage Story Builder Game
class ClanStoryGame extends BaseGameScreen {
  const ClanStoryGame({
    Key? key,
    required super.language,
    super.level,
    super.onBack,
  }) : super(key: key);

  @override
  GameType getGameType() => GameType.clanLineageStoryBuilder;

  @override
  ConsumerState<ClanStoryGame> createState() => _ClanStoryGameState();
}

class _ClanStoryGameState extends BaseGameScreenState<ClanStoryGame> {
  @override
  Widget buildGameContent(BuildContext context) {
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
            const Icon(Icons.account_tree, size: 64),
            SizedBox(height: 2.h),
            Text(
              'Journey through African villages',
              style: TextStyle(fontSize: 18.sp),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 4.h),
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Feature coming soon!')),
                );
              },
              child: const Text('Start'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Market Bargaining Simulator Game
class MarketBargainingGame extends BaseGameScreen {
  const MarketBargainingGame({
    Key? key,
    required super.language,
    super.level,
    super.onBack,
  }) : super(key: key);

  @override
  GameType getGameType() => GameType.marketBargainingSimulator;

  @override
  ConsumerState<MarketBargainingGame> createState() => _MarketBargainingGameState();
}

class _MarketBargainingGameState extends BaseGameScreenState<MarketBargainingGame> {
  @override
  Widget buildGameContent(BuildContext context) {
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
            const Icon(Icons.store, size: 64),
            SizedBox(height: 2.h),
            Text(
              'Negotiate prices in African markets',
              style: TextStyle(fontSize: 18.sp),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 4.h),
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Feature coming soon!')),
                );
              },
              child: const Text('Start'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Taxi & Bus Stop Survival Game
class TaxiSurvivalGame extends BaseGameScreen {
  const TaxiSurvivalGame({
    Key? key,
    required super.language,
    super.level,
    super.onBack,
  }) : super(key: key);

  @override
  GameType getGameType() => GameType.taxiBusStopSurvival;

  @override
  ConsumerState<TaxiSurvivalGame> createState() => _TaxiSurvivalGameState();
}

class _TaxiSurvivalGameState extends BaseGameScreenState<TaxiSurvivalGame> {
  @override
  Widget buildGameContent(BuildContext context) {
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
            const Icon(Icons.directions_bus, size: 64),
            SizedBox(height: 2.h),
            Text(
              'Navigate transport hubs',
              style: TextStyle(fontSize: 18.sp),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 4.h),
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Feature coming soon!')),
                );
              },
              child: const Text('Start'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Food Quest Game
class FoodQuestGame extends BaseGameScreen {
  const FoodQuestGame({
    Key? key,
    required super.language,
    super.level,
    super.onBack,
  }) : super(key: key);

  @override
  GameType getGameType() => GameType.foodQuest;

  @override
  ConsumerState<FoodQuestGame> createState() => _FoodQuestGameState();
}

class _FoodQuestGameState extends BaseGameScreenState<FoodQuestGame> {
  @override
  Widget buildGameContent(BuildContext context) {
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
            const Icon(Icons.restaurant_menu, size: 64),
            SizedBox(height: 2.h),
            Text(
              'Learn food vocabulary by cooking',
              style: TextStyle(fontSize: 18.sp),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 4.h),
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Feature coming soon!')),
                );
              },
              child: const Text('Start'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Call and Response Game
class CallResponseGame extends BaseGameScreen {
  const CallResponseGame({
    Key? key,
    required super.language,
    super.level,
    super.onBack,
  }) : super(key: key);

  @override
  GameType getGameType() => GameType.callAndResponse;

  @override
  ConsumerState<CallResponseGame> createState() => _CallResponseGameState();
}

class _CallResponseGameState extends BaseGameScreenState<CallResponseGame> {
  @override
  Widget buildGameContent(BuildContext context) {
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
            const Icon(Icons.queue_music, size: 64),
            SizedBox(height: 2.h),
            Text(
              'Music-based pronunciation practice',
              style: TextStyle(fontSize: 18.sp),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 4.h),
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Feature coming soon!')),
                );
              },
              child: const Text('Start'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Greeting Diplomacy Challenge Game
class GreetingDiplomacyGame extends BaseGameScreen {
  const GreetingDiplomacyGame({
    Key? key,
    required super.language,
    super.level,
    super.onBack,
  }) : super(key: key);

  @override
  GameType getGameType() => GameType.greetingDiplomacyChallenge;

  @override
  ConsumerState<GreetingDiplomacyGame> createState() => _GreetingDiplomacyGameState();
}

class _GreetingDiplomacyGameState extends BaseGameScreenState<GreetingDiplomacyGame> {
  @override
  Widget buildGameContent(BuildContext context) {
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
            const Icon(Icons.handshake, size: 64),
            SizedBox(height: 2.h),
            Text(
              'Master cultural greeting rituals',
              style: TextStyle(fontSize: 18.sp),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 4.h),
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Feature coming soon!')),
                );
              },
              child: const Text('Start'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Folktale Reconstruction Game
class FolktaleGame extends BaseGameScreen {
  const FolktaleGame({
    Key? key,
    required super.language,
    super.level,
    super.onBack,
  }) : super(key: key);

  @override
  GameType getGameType() => GameType.folktaleReconstruction;

  @override
  ConsumerState<FolktaleGame> createState() => _FolktaleGameState();
}

class _FolktaleGameState extends BaseGameScreenState<FolktaleGame> {
  @override
  Widget buildGameContent(BuildContext context) {
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
            const Icon(Icons.book, size: 64),
            SizedBox(height: 2.h),
            Text(
              'Arrange folktale parts correctly',
              style: TextStyle(fontSize: 18.sp),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 4.h),
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Feature coming soon!')),
                );
              },
              child: const Text('Start'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Phrase Sniper Game
class PhraseSniperGame extends BaseGameScreen {
  const PhraseSniperGame({
    Key? key,
    required super.language,
    super.level,
    super.onBack,
  }) : super(key: key);

  @override
  GameType getGameType() => GameType.phraseSniper;

  @override
  ConsumerState<PhraseSniperGame> createState() => _PhraseSniperGameState();
}

class _PhraseSniperGameState extends BaseGameScreenState<PhraseSniperGame> {
  @override
  Widget buildGameContent(BuildContext context) {
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
            const Icon(Icons.speed, size: 64),
            SizedBox(height: 2.h),
            Text(
              'Fast-paced reaction game',
              style: TextStyle(fontSize: 18.sp),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 4.h),
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Feature coming soon!')),
                );
              },
              child: const Text('Start'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Liar Liar Game
class LiarLiarGame extends BaseGameScreen {
  const LiarLiarGame({
    Key? key,
    required super.language,
    super.level,
    super.onBack,
  }) : super(key: key);

  @override
  GameType getGameType() => GameType.liarLiar;

  @override
  ConsumerState<LiarLiarGame> createState() => _LiarLiarGameState();
}

class _LiarLiarGameState extends BaseGameScreenState<LiarLiarGame> {
  @override
  Widget buildGameContent(BuildContext context) {
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
            const Icon(Icons.psychology, size: 64),
            SizedBox(height: 2.h),
            Text(
              'Detect grammatical errors',
              style: TextStyle(fontSize: 18.sp),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 4.h),
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Feature coming soon!')),
                );
              },
              child: const Text('Start'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Village Quest Game
class VillageQuestGame extends BaseGameScreen {
  const VillageQuestGame({
    Key? key,
    required super.language,
    super.level,
    super.onBack,
  }) : super(key: key);

  @override
  GameType getGameType() => GameType.villageQuest;

  @override
  ConsumerState<VillageQuestGame> createState() => _VillageQuestGameState();
}

class _VillageQuestGameState extends BaseGameScreenState<VillageQuestGame> {
  @override
  Widget buildGameContent(BuildContext context) {
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
            const Icon(Icons.village, size: 64),
            SizedBox(height: 2.h),
            Text(
              'NPC conversation game',
              style: TextStyle(fontSize: 18.sp),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 4.h),
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Feature coming soon!')),
                );
              },
              child: const Text('Start'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Accent Decoding Puzzle Game
class AccentPuzzleGame extends BaseGameScreen {
  const AccentPuzzleGame({
    Key? key,
    required super.language,
    super.level,
    super.onBack,
  }) : super(key: key);

  @override
  GameType getGameType() => GameType.accentDecodingPuzzle;

  @override
  ConsumerState<AccentPuzzleGame> createState() => _AccentPuzzleGameState();
}

class _AccentPuzzleGameState extends BaseGameScreenState<AccentPuzzleGame> {
  @override
  Widget buildGameContent(BuildContext context) {
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
            const Icon(Icons.language, size: 64),
            SizedBox(height: 2.h),
            Text(
              'Match accents to regions',
              style: TextStyle(fontSize: 18.sp),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 4.h),
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Feature coming soon!')),
                );
              },
              child: const Text('Start'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Flashcard Safari Game
class FlashcardSafariGame extends BaseGameScreen {
  const FlashcardSafariGame({
    Key? key,
    required super.language,
    super.level,
    super.onBack,
  }) : super(key: key);

  @override
  GameType getGameType() => GameType.flashcardSafari;

  @override
  ConsumerState<FlashcardSafariGame> createState() => _FlashcardSafariGameState();
}

class _FlashcardSafariGameState extends BaseGameScreenState<FlashcardSafariGame> {
  @override
  Widget buildGameContent(BuildContext context) {
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
            const Icon(Icons.camera_alt, size: 64),
            SizedBox(height: 2.h),
            Text(
              'AR vocabulary scanning',
              style: TextStyle(fontSize: 18.sp),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 4.h),
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Feature coming soon!')),
                );
              },
              child: const Text('Start'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Rapid Tongue Twister Race Game
class TongueTwisterGame extends BaseGameScreen {
  const TongueTwisterGame({
    Key? key,
    required super.language,
    super.level,
    super.onBack,
  }) : super(key: key);

  @override
  GameType getGameType() => GameType.rapidTongueTwisterRace;

  @override
  ConsumerState<TongueTwisterGame> createState() => _TongueTwisterGameState();
}

class _TongueTwisterGameState extends BaseGameScreenState<TongueTwisterGame> {
  @override
  Widget buildGameContent(BuildContext context) {
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
            const Icon(Icons.speed, size: 64),
            SizedBox(height: 2.h),
            Text(
              'Repeat tongue twisters as fast as possible',
              style: TextStyle(fontSize: 18.sp),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 4.h),
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Feature coming soon!')),
                );
              },
              child: const Text('Start'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Emoji Translator Game
class EmojiTranslatorGame extends BaseGameScreen {
  const EmojiTranslatorGame({
    Key? key,
    required super.language,
    super.level,
    super.onBack,
  }) : super(key: key);

  @override
  GameType getGameType() => GameType.emojiTranslator;

  @override
  ConsumerState<EmojiTranslatorGame> createState() => _EmojiTranslatorGameState();
}

class _EmojiTranslatorGameState extends BaseGameScreenState<EmojiTranslatorGame> {
  @override
  Widget buildGameContent(BuildContext context) {
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
            const Icon(Icons.emoji_emotions, size: 64),
            SizedBox(height: 2.h),
            Text(
              'Translate emoji sentences',
              style: TextStyle(fontSize: 18.sp),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 4.h),
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Feature coming soon!')),
                );
              },
              child: const Text('Start'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Rhythm Typing Game
class RhythmTypingGame extends BaseGameScreen {
  const RhythmTypingGame({
    Key? key,
    required super.language,
    super.level,
    super.onBack,
  }) : super(key: key);

  @override
  GameType getGameType() => GameType.rhythmTyping;

  @override
  ConsumerState<RhythmTypingGame> createState() => _RhythmTypingGameState();
}

class _RhythmTypingGameState extends BaseGameScreenState<RhythmTypingGame> {
  @override
  Widget buildGameContent(BuildContext context) {
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
            const Icon(Icons.keyboard, size: 64),
            SizedBox(height: 2.h),
            Text(
              'Type with drum sounds',
              style: TextStyle(fontSize: 18.sp),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 4.h),
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Feature coming soon!')),
                );
              },
              child: const Text('Start'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Elders' Blessings Challenge Game
class EldersBlessingsGame extends BaseGameScreen {
  const EldersBlessingsGame({
    Key? key,
    required super.language,
    super.level,
    super.onBack,
  }) : super(key: key);

  @override
  GameType getGameType() => GameType.eldersBlessingsChallenge;

  @override
  ConsumerState<EldersBlessingsGame> createState() => _EldersBlessingsGameState();
}

class _EldersBlessingsGameState extends BaseGameScreenState<EldersBlessingsGame> {
  @override
  Widget buildGameContent(BuildContext context) {
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
            const Icon(Icons.favorite, size: 64),
            SizedBox(height: 2.h),
            Text(
              'Learn blessing phrases',
              style: TextStyle(fontSize: 18.sp),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 4.h),
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Feature coming soon!')),
                );
              },
              child: const Text('Start'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Multilingual Relay Race Game
class MultilingualRelayGame extends BaseGameScreen {
  const MultilingualRelayGame({
    Key? key,
    required super.language,
    super.level,
    super.onBack,
  }) : super(key: key);

  @override
  GameType getGameType() => GameType.multilingualRelayRace;

  @override
  ConsumerState<MultilingualRelayGame> createState() => _MultilingualRelayGameState();
}

class _MultilingualRelayGameState extends BaseGameScreenState<MultilingualRelayGame> {
  @override
  Widget buildGameContent(BuildContext context) {
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
            const Icon(Icons.swap_horiz, size: 64),
            SizedBox(height: 2.h),
            Text(
              'Switch between languages',
              style: TextStyle(fontSize: 18.sp),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 4.h),
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Feature coming soon!')),
                );
              },
              child: const Text('Start'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Cultural Etiquette Scenarios Game
class CulturalEtiquetteGame extends BaseGameScreen {
  const CulturalEtiquetteGame({
    Key? key,
    required super.language,
    super.level,
    super.onBack,
  }) : super(key: key);

  @override
  GameType getGameType() => GameType.culturalEtiquetteScenarios;

  @override
  ConsumerState<CulturalEtiquetteGame> createState() => _CulturalEtiquetteGameState();
}

class _CulturalEtiquetteGameState extends BaseGameScreenState<CulturalEtiquetteGame> {
  @override
  Widget buildGameContent(BuildContext context) {
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
            const Icon(Icons.people, size: 64),
            SizedBox(height: 2.h),
            Text(
              'Interactive cultural situations',
              style: TextStyle(fontSize: 18.sp),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 4.h),
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Feature coming soon!')),
                );
              },
              child: const Text('Start'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Drum-to-Word Matching Game
class DrumWordGame extends BaseGameScreen {
  const DrumWordGame({
    Key? key,
    required super.language,
    super.level,
    super.onBack,
  }) : super(key: key);

  @override
  GameType getGameType() => GameType.drumToWordMatching;

  @override
  ConsumerState<DrumWordGame> createState() => _DrumWordGameState();
}

class _DrumWordGameState extends BaseGameScreenState<DrumWordGame> {
  @override
  Widget buildGameContent(BuildContext context) {
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
            const Icon(Icons.music_note, size: 64),
            SizedBox(height: 2.h),
            Text(
              'Decode drum patterns to words',
              style: TextStyle(fontSize: 18.sp),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 4.h),
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Feature coming soon!')),
                );
              },
              child: const Text('Start'),
            ),
          ],
        ),
      ),
    );
  }
}

