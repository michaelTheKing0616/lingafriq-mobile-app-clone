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
import 'game_templates.dart';
import 'cultural_games.dart';
import '../../games/drum_rhythm/drum_rhythm_screen.dart';

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
  }
}

