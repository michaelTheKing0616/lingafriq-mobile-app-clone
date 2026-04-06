import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../models/game/game_session_model.dart';
import '../../providers/user_provider.dart';
import 'word_match_audio_game.dart';
import 'pronunciation_duel_game.dart';
import 'tone_trainer_game.dart';
import 'speed_round_game.dart';
import 'story_builder_game.dart';
import 'roleplay_adventure_game.dart';
import 'grammar_detective_game.dart';
import 'game_templates.dart' hide PictureWordGame, MemoryMapGame, PronunciationKaraokeGame, GrammarJamGame, QuizChefGame;
import 'picture_word_association_screen.dart';
import 'memory_map_screen.dart';
import 'pronunciation_karaoke_screen.dart';
import 'cultural_games.dart' hide ClanStoryGame, FolktaleGame, MarketBargainingGame, TaxiSurvivalGame, GreetingDiplomacyGame, EmojiTranslatorGame, EldersBlessingsGame;
import 'market_bargaining_screen.dart';
import 'taxi_survival_screen.dart';
import 'greeting_diplomacy_screen.dart';
import 'emoji_translator_screen.dart';
import 'elders_blessings_screen.dart';
import 'folktale_reconstruction_screen.dart';
import 'board_word_games.dart';
import '../../games/drum_rhythm/drum_rhythm_screen.dart';
import 'clan_lineage_story_builder_screen.dart';
import 'grammar_jam_screen.dart';
import 'quiz_chef_screen.dart';

/// Game Router - Routes to appropriate game screen based on GameType
Widget buildGameScreen({
  required GameType gameType,
  required String language,
  String? level,
  VoidCallback? onBack,
  required WidgetRef ref,
}) {
  final user = ref.read(userProvider);
  final userLevel = level ?? user?.level?.toString() ?? 'A0';

  switch (gameType) {
    case GameType.wordMatchAudio:
      return WordMatchAudioGame(
        language: language,
        level: userLevel,
        onBack: onBack,
      );
    case GameType.pronunciationDuel:
      return PronunciationDuelGame(
        language: language,
        level: userLevel,
        onBack: onBack,
      );
    case GameType.toneTrainer:
      return ToneTrainerGame(
        language: language,
        level: userLevel,
        onBack: onBack,
      );
    case GameType.speedRoundRemix:
      return SpeedRoundGame(
        language: language,
        level: userLevel,
        onBack: onBack,
      );
    case GameType.storyBuilder:
      return StoryBuilderGame(
        language: language,
        level: userLevel,
        onBack: onBack,
      );
    case GameType.roleplayAdventure:
      return RoleplayAdventureGame(
        language: language,
        level: userLevel,
        onBack: onBack,
      );
    case GameType.grammarDetective:
      return GrammarDetectiveGame(
        language: language,
        level: userLevel,
        onBack: onBack,
      );
    case GameType.listenAndSketch:
      return ListenSketchGame(language: language, level: userLevel, onBack: onBack);
    case GameType.pictureWordAssociation:
      return PictureWordGame(language: language, level: userLevel, onBack: onBack);
    case GameType.memoryMap:
      return MemoryMapGame(language: language, level: userLevel, onBack: onBack);
    case GameType.conversationRelay:
      return ConversationRelayGame(language: language, level: userLevel, onBack: onBack);
    case GameType.grammarJam:
      return GrammarJamGame(language: language, level: userLevel, onBack: onBack);
    case GameType.pronunciationKaraoke:
      return PronunciationKaraokeGame(language: language, level: userLevel, onBack: onBack);
    case GameType.quizChef:
      return QuizChefGame(language: language, level: userLevel, onBack: onBack);
    case GameType.proverbUnlocker:
      return ProverbUnlockerGame(language: language, level: userLevel, onBack: onBack);
    case GameType.drumRhythmShadowing:
      return DrumRhythmScreen(language: language, level: userLevel, onBack: onBack);
    case GameType.clanLineageStoryBuilder:
      return ClanStoryGame(language: language, level: userLevel, onBack: onBack);
    case GameType.marketBargainingSimulator:
      return MarketBargainingGame(language: language, level: userLevel, onBack: onBack);
    case GameType.taxiBusStopSurvival:
      return TaxiSurvivalGame(language: language, level: userLevel, onBack: onBack);
    case GameType.foodQuest:
      return FoodQuestGame(language: language, level: userLevel, onBack: onBack);
    case GameType.callAndResponse:
      return CallResponseGame(language: language, level: userLevel, onBack: onBack);
    case GameType.greetingDiplomacyChallenge:
      return GreetingDiplomacyGame(language: language, level: userLevel, onBack: onBack);
    case GameType.folktaleReconstruction:
      return FolktaleGame(language: language, level: userLevel, onBack: onBack);
    case GameType.phraseSniper:
      return PhraseSniperGame(language: language, level: userLevel, onBack: onBack);
    case GameType.liarLiar:
      return LiarLiarGame(language: language, level: userLevel, onBack: onBack);
    case GameType.villageQuest:
      return VillageQuestGame(language: language, level: userLevel, onBack: onBack);
    case GameType.accentDecodingPuzzle:
      return AccentPuzzleGame(language: language, level: userLevel, onBack: onBack);
    case GameType.flashcardSafari:
      return FlashcardSafariGame(language: language, level: userLevel, onBack: onBack);
    case GameType.rapidTongueTwisterRace:
      return TongueTwisterGame(language: language, level: userLevel, onBack: onBack);
    case GameType.emojiTranslator:
      return EmojiTranslatorGame(language: language, level: userLevel, onBack: onBack);
    case GameType.rhythmTyping:
      return RhythmTypingGame(language: language, level: userLevel, onBack: onBack);
    case GameType.eldersBlessingsChallenge:
      return EldersBlessingsGame(language: language, level: userLevel, onBack: onBack);
    case GameType.multilingualRelayRace:
      return MultilingualRelayGame(language: language, level: userLevel, onBack: onBack);
    case GameType.culturalEtiquetteScenarios:
      return CulturalEtiquetteGame(language: language, level: userLevel, onBack: onBack);
    case GameType.drumToWordMatching:
      return DrumWordGame(language: language, level: userLevel, onBack: onBack);
    case GameType.marketMonopolyChallenge:
      return MarketMonopolyChallengeGame(
        language: language,
        level: userLevel,
        onBack: onBack,
      );
    case GameType.scrabbleSprintArena:
      return ScrabbleSprintArenaGame(
        language: language,
        level: userLevel,
        onBack: onBack,
      );
  }
}

/// Game types with a branch in [buildGameScreen]; keep in sync with the switch above.
const Set<GameType> kRoutedGameTypes = {
  GameType.wordMatchAudio,
  GameType.pronunciationDuel,
  GameType.toneTrainer,
  GameType.speedRoundRemix,
  GameType.storyBuilder,
  GameType.roleplayAdventure,
  GameType.grammarDetective,
  GameType.listenAndSketch,
  GameType.pictureWordAssociation,
  GameType.memoryMap,
  GameType.conversationRelay,
  GameType.grammarJam,
  GameType.pronunciationKaraoke,
  GameType.quizChef,
  GameType.proverbUnlocker,
  GameType.drumRhythmShadowing,
  GameType.clanLineageStoryBuilder,
  GameType.marketBargainingSimulator,
  GameType.taxiBusStopSurvival,
  GameType.foodQuest,
  GameType.callAndResponse,
  GameType.greetingDiplomacyChallenge,
  GameType.folktaleReconstruction,
  GameType.phraseSniper,
  GameType.liarLiar,
  GameType.villageQuest,
  GameType.accentDecodingPuzzle,
  GameType.flashcardSafari,
  GameType.rapidTongueTwisterRace,
  GameType.emojiTranslator,
  GameType.rhythmTyping,
  GameType.eldersBlessingsChallenge,
  GameType.multilingualRelayRace,
  GameType.culturalEtiquetteScenarios,
  GameType.drumToWordMatching,
  GameType.marketMonopolyChallenge,
  GameType.scrabbleSprintArena,
};

