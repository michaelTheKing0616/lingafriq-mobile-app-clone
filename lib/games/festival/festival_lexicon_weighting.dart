import 'package:lingafriq/games/festival/festival_theme_service.dart';
import 'package:lingafriq/models/game/game_content_models.dart';
import 'package:lingafriq/models/verified_lexeme.dart';

bool lexemeMatchesFestivalTheme(
  VerifiedLexeme lexeme,
  VillageFestivalThemeId themeId,
) {
  final tags = _collectTags(lexeme.raw);
  final needle = 'village_festival:${themeId.name}';
  if (tags.contains(needle)) return true;
  if (tags.contains(themeId.name)) return true;
  if (tags.contains('festival_${themeId.name}')) return true;
  return false;
}

int countThemedLexemes(
  List<VerifiedLexeme> lexemes,
  VillageFestivalThemeId themeId,
) {
  var count = 0;
  for (final lexeme in lexemes) {
    if (lexemeMatchesFestivalTheme(lexeme, themeId)) {
      count++;
    }
  }
  return count;
}

/// Stable boost: themed items move earlier; every row stays in the pool (AC2).
List<GameLexiconPoolItem> reorderPoolForFestival({
  required List<GameLexiconPoolItem> items,
  required List<VerifiedLexeme> lexemes,
  required VillageFestivalThemeId themeId,
}) {
  final byId = <String, VerifiedLexeme>{
    for (final row in lexemes) row.lexemeId: row,
  };
  final themed = <GameLexiconPoolItem>[];
  final rest = <GameLexiconPoolItem>[];
  for (final item in items) {
    final lex = byId[item.id];
    if (lex != null && lexemeMatchesFestivalTheme(lex, themeId)) {
      themed.add(item);
    } else {
      rest.add(item);
    }
  }
  return [...themed, ...rest];
}

Set<String> _collectTags(Map<String, dynamic> raw) {
  final tags = <String>{};
  void addFrom(dynamic value) {
    if (value is String && value.trim().isNotEmpty) {
      tags.add(value.trim().toLowerCase());
    }
    if (value is List) {
      for (final entry in value) {
        addFrom(entry);
      }
    }
  }

  addFrom(raw['game_tags']);
  addFrom(raw['topics']);
  addFrom(raw['festival_topics']);
  final senses = raw['senses'];
  if (senses is List) {
    for (final sense in senses) {
      if (sense is Map) {
        addFrom(sense['topics']);
        addFrom(sense['semantic_domains']);
      }
    }
  }
  return tags;
}
