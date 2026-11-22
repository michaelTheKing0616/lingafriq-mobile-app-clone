/// Skill shelves on the Play arcade.
///
/// The seven ids are the sitemap shelves. A route-map game sits on one of
/// them. Tone Forge is a Play route, and it is not a shelf game.
enum PlayShelfId {
  toneAndSound('tone-and-sound'),
  words('words'),
  grammar('grammar'),
  speaking('speaking'),
  culture('culture'),
  traditional('traditional'),
  multiplayer('multiplayer');

  const PlayShelfId(this.segment);

  /// Path segment under `/play`. No spaces, so it is not learner copy.
  final String segment;

  String get path => '/play/$segment';
}

/// One Play feature from the route map, on exactly one shelf.
class PlayShelfGame {
  const PlayShelfGame({required this.key, required this.shelf});

  /// Route-map key. The route row wins when a drawer row shares its label.
  final String key;

  final PlayShelfId shelf;

  String get path => '${shelf.path}/$key';
}

/// Sitemap order. Traditional stays in the list when it has no game.
const List<PlayShelfId> kPlayShelfOrder = <PlayShelfId>[
  PlayShelfId.toneAndSound,
  PlayShelfId.words,
  PlayShelfId.grammar,
  PlayShelfId.speaking,
  PlayShelfId.culture,
  PlayShelfId.traditional,
  PlayShelfId.multiplayer,
];

/// Play features in route-map order.
///
/// Drawer `Games` and route `games` open the same screen, so the route key
/// is the one row. Flashcards and matching pairs are word practice. A
/// challenge with a friend is multiplayer. The three Games lists are the
/// old catalogues. They stay on Words, the retrieval shelf, and they are
/// not opened, so games that are not in the route map are not painted.
const List<PlayShelfGame> kPlayShelfGames = <PlayShelfGame>[
  PlayShelfGame(key: 'games', shelf: PlayShelfId.words),
  PlayShelfGame(key: 'challenge-friend', shelf: PlayShelfId.multiplayer),
  PlayShelfGame(key: 'flashcard-focus', shelf: PlayShelfId.words),
  PlayShelfGame(key: 'games_api_languages', shelf: PlayShelfId.words),
  PlayShelfGame(key: 'games_enhanced_catalog', shelf: PlayShelfId.words),
  PlayShelfGame(key: 'matching-pairs', shelf: PlayShelfId.words),
];

/// How many route-map games are on shelves.
int get playShelfGameCount => kPlayShelfGames.length;

PlayShelfId shelfForPlayKey(String key) {
  final String id = key.toLowerCase();
  if (id.contains('challenge') || id.contains('friend')) {
    return PlayShelfId.multiplayer;
  }
  if (id.contains('tone') || id.contains('sound')) {
    return PlayShelfId.toneAndSound;
  }
  if (id.contains('grammar')) return PlayShelfId.grammar;
  if (id.contains('speak')) return PlayShelfId.speaking;
  if (id.contains('cultur')) return PlayShelfId.culture;
  if (id.contains('traditional')) return PlayShelfId.traditional;
  if (id.contains('flash') || id.contains('match') || id.contains('pair')) {
    return PlayShelfId.words;
  }
  return PlayShelfId.words;
}

List<PlayShelfGame> playGamesOnShelf(PlayShelfId shelf) {
  return <PlayShelfGame>[
    for (final PlayShelfGame game in kPlayShelfGames)
      if (game.shelf == shelf) game,
  ];
}

PlayShelfGame? playGameByKey(String key) {
  for (final PlayShelfGame game in kPlayShelfGames) {
    if (game.key == key) return game;
  }
  return null;
}

/// Empty when [routeMapKeys] are the Play features and each is on one shelf.
List<String> validatePlayShelfCoverage(Set<String> routeMapKeys) {
  final List<String> problems = <String>[];
  final Set<String> seen = <String>{};
  for (final PlayShelfGame game in kPlayShelfGames) {
    if (!seen.add(game.key)) {
      problems.add('duplicate:${game.key}');
    }
    if (game.shelf != shelfForPlayKey(game.key)) {
      problems.add('shelf:${game.key}');
    }
    if (!routeMapKeys.contains(game.key)) {
      problems.add('extra:${game.key}');
    }
  }
  for (final String key in routeMapKeys) {
    if (!seen.contains(key)) problems.add('missing:$key');
  }
  if (playShelfGameCount != routeMapKeys.length) {
    problems.add('count:$playShelfGameCount:${routeMapKeys.length}');
  }
  return problems;
}
