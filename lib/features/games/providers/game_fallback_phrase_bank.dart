part of 'package:lingafriq/providers/game_provider.dart';

Map<String, List<Map<String, dynamic>>> _curatedGameFallbackPhraseBank() {
  return <String, List<Map<String, dynamic>>>{
    ..._curatedGameFallbackPhraseBankWest(),
    ..._curatedGameFallbackPhraseBankEast(),
  };
}
