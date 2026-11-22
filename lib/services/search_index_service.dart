import 'package:lingafriq/models/verified_lexeme.dart';
import 'package:lingafriq/services/quiz/item_graders.dart';

/// How many hits one group keeps. Closer matches stay.
const int kSearchGroupLimit = 25;

/// Groups a query can return. Order on the page is this order.
enum SearchBucket { words, features, content }

/// A local word. [surface] is what the learner sees.
class SearchWord {
  const SearchWord({
    required this.id,
    required this.surface,
    this.gloss,
    this.language = '',
    this.lexeme,
  });

  final String id;
  final String surface;
  final String? gloss;
  final String language;
  final VerifiedLexeme? lexeme;

  /// Lexeme the Word Card can open. Uses [lexeme] when the caller has one.
  VerifiedLexeme toLexeme() {
    final VerifiedLexeme? existing = lexeme;
    if (existing != null) return existing;
    final String? glossText = gloss;
    return VerifiedLexeme(
      lexemeId: id,
      language: language,
      verificationStatus: 'verified',
      lemma: surface,
      standardOrthography: surface,
      exampleSentence: glossText,
      audioUris: const <String>[],
      raw: <String, dynamic>{
        'lemma': surface,
        'orthography': <String, dynamic>{'standard': surface},
        'senses': <Map<String, dynamic>>[
          <String, dynamic>{'gloss_en': glossText, 'gloss': glossText},
        ],
      },
    );
  }
}

/// One feature from [kRouteMapCsv]. The label is the route-map label.
class SearchFeature {
  const SearchFeature({
    required this.key,
    required this.label,
    required this.hub,
    required this.job,
    required this.unlockStage,
    required this.learningLoop,
    required this.routeBuilt,
  });

  final String key;
  final String label;
  final String hub;
  final String job;
  final String unlockStage;
  final String learningLoop;

  /// True when [key] is a registered route the app can open.
  final bool routeBuilt;
}

/// A local lesson, note, or other saved item. Not a feature name.
class SearchContent {
  const SearchContent({
    required this.id,
    required this.title,
    this.detail = '',
    this.routeKey,
    this.routeBuilt = false,
  });

  final String id;
  final String title;
  final String detail;
  final String? routeKey;
  final bool routeBuilt;

  /// Route to open when this item has a built route.
  String? get openRoute {
    final String? key = routeKey;
    if (!routeBuilt || key == null || key.isEmpty) return null;
    return key;
  }
}

class SearchWordHit {
  const SearchWordHit({required this.word, required this.rank});

  final SearchWord word;
  final int rank;
}

class SearchFeatureHit {
  const SearchFeatureHit({required this.feature, required this.rank});

  final SearchFeature feature;
  final int rank;
}

class SearchContentHit {
  const SearchContentHit({required this.content, required this.rank});

  final SearchContent content;
  final int rank;
}

/// Grouped hits for one query. Empty lists are groups with no match.
class SearchResults {
  const SearchResults({
    required this.query,
    required this.words,
    required this.features,
    required this.content,
  });

  final String query;
  final List<SearchWordHit> words;
  final List<SearchFeatureHit> features;
  final List<SearchContentHit> content;

  bool get isEmpty => words.isEmpty && features.isEmpty && content.isEmpty;
}

/// Lower is closer. 99 means [field] does not match [query].
///
/// A match is the whole field, a whole word, or the start of a word.
/// A query buried inside another word does not match.
int searchMatchRank(String query, String field) {
  final String needle = foldAnswer(query.trim(), diacriticInsensitive: true);
  final String hay = foldAnswer(field.trim(), diacriticInsensitive: true);
  if (needle.isEmpty || hay.isEmpty) return 99;
  if (hay == needle) return 0;
  final List<String> words = hay.split(RegExp(r'\s+'));
  if (words.contains(needle)) return 1;
  if (hay.startsWith(needle)) return 2;
  if (words.any((String word) => word.startsWith(needle))) return 3;
  return 99;
}

int _bestRank(String query, List<String> fields) {
  var best = 99;
  for (final String field in fields) {
    final int rank = searchMatchRank(query, field);
    if (rank < best) best = rank;
  }
  return best;
}

int _byRank(
  int rankA,
  String titleA,
  String idA,
  int rankB,
  String titleB,
  String idB,
) {
  final int byRank = rankA.compareTo(rankB);
  if (byRank != 0) return byRank;
  final int byTitle = foldAnswer(
    titleA,
    diacriticInsensitive: true,
  ).compareTo(foldAnswer(titleB, diacriticInsensitive: true));
  if (byTitle != 0) return byTitle;
  return idA.compareTo(idB);
}

class _FeatureRow {
  const _FeatureRow({
    required this.kind,
    required this.key,
    required this.label,
    required this.hub,
    required this.job,
    required this.unlockStage,
    required this.learningLoop,
  });

  final String kind;
  final String key;
  final String label;
  final String hub;
  final String job;
  final String unlockStage;
  final String learningLoop;
}

/// Local index of words, route-map features, and content.
class SearchIndexService {
  const SearchIndexService({
    required this.words,
    required this.features,
    required this.content,
  });

  /// Features from [kRouteMapCsv], plus any local [words] and [content].
  ///
  /// [builtRouteKeys] limits which route keys count as built. Null treats
  /// every route-kind row as built. Drawer-only names stay unbuilt.
  factory SearchIndexService.fromRouteMap(
    String csv, {
    List<SearchWord> words = const <SearchWord>[],
    List<SearchContent> content = const <SearchContent>[],
    Set<String>? builtRouteKeys,
  }) {
    return SearchIndexService(
      words: words,
      features: featuresFromRouteMap(csv, builtRouteKeys: builtRouteKeys),
      content: content,
    );
  }

  /// The shipped route map. Labels are copied from that file, not invented.
  factory SearchIndexService.routeMapCatalog({
    List<SearchWord> words = const <SearchWord>[],
    List<SearchContent> content = const <SearchContent>[],
    Set<String>? builtRouteKeys,
  }) {
    return SearchIndexService.fromRouteMap(
      kRouteMapCsv,
      words: words,
      content: content,
      builtRouteKeys: builtRouteKeys,
    );
  }

  final List<SearchWord> words;
  final List<SearchFeature> features;
  final List<SearchContent> content;

  SearchResults search(String raw) {
    final String query = raw.trim();
    if (query.isEmpty) {
      return const SearchResults(
        query: '',
        words: <SearchWordHit>[],
        features: <SearchFeatureHit>[],
        content: <SearchContentHit>[],
      );
    }
    final List<SearchWordHit> wordHits = <SearchWordHit>[];
    for (final SearchWord word in words) {
      final int rank = _bestRank(query, <String>[
        word.surface,
        word.gloss ?? '',
      ]);
      if (rank == 99) continue;
      wordHits.add(SearchWordHit(word: word, rank: rank));
    }
    wordHits.sort(
      (SearchWordHit a, SearchWordHit b) => _byRank(
        a.rank,
        a.word.surface,
        a.word.id,
        b.rank,
        b.word.surface,
        b.word.id,
      ),
    );

    final List<SearchFeatureHit> featureHits = <SearchFeatureHit>[];
    for (final SearchFeature feature in features) {
      final int rank = _bestRank(query, <String>[
        feature.label,
        feature.hub,
        feature.learningLoop,
      ]);
      if (rank == 99) continue;
      featureHits.add(SearchFeatureHit(feature: feature, rank: rank));
    }
    featureHits.sort(
      (SearchFeatureHit a, SearchFeatureHit b) => _byRank(
        a.rank,
        a.feature.label,
        a.feature.key,
        b.rank,
        b.feature.label,
        b.feature.key,
      ),
    );

    final List<SearchContentHit> contentHits = <SearchContentHit>[];
    for (final SearchContent item in content) {
      final int rank = _bestRank(query, <String>[item.title, item.detail]);
      if (rank == 99) continue;
      contentHits.add(SearchContentHit(content: item, rank: rank));
    }
    contentHits.sort(
      (SearchContentHit a, SearchContentHit b) => _byRank(
        a.rank,
        a.content.title,
        a.content.id,
        b.rank,
        b.content.title,
        b.content.id,
      ),
    );

    return SearchResults(
      query: query,
      words: _take(wordHits),
      features: _take(featureHits),
      content: _take(contentHits),
    );
  }
}

List<T> _take<T>(List<T> hits) {
  if (hits.length <= kSearchGroupLimit) return hits;
  return hits.sublist(0, kSearchGroupLimit);
}

/// One feature per label. A route row wins over a drawer row with the same name.
List<SearchFeature> featuresFromRouteMap(
  String csv, {
  Set<String>? builtRouteKeys,
}) {
  final List<List<String>> rows = _csvRows(csv);
  if (rows.isEmpty) return const <SearchFeature>[];
  final List<String> header = rows.first
      .map((String cell) => cell.trim())
      .toList();
  final Map<String, int> index = <String, int>{};
  for (var i = 0; i < header.length; i++) {
    index[header[i]] = i;
  }
  String read(List<String> row, String name) {
    final int? at = index[name];
    if (at == null || at >= row.length) return '';
    return row[at].trim();
  }

  final Map<String, List<_FeatureRow>> grouped = <String, List<_FeatureRow>>{};
  for (final List<String> row in rows.skip(1)) {
    final String label = read(row, 'label');
    if (label.isEmpty) continue;
    final String folded = foldAnswer(label, diacriticInsensitive: true);
    grouped
        .putIfAbsent(folded, () => <_FeatureRow>[])
        .add(
          _FeatureRow(
            kind: read(row, 'kind'),
            key: read(row, 'key'),
            label: label,
            hub: read(row, 'hub'),
            job: read(row, 'job'),
            unlockStage: read(row, 'unlock_stage'),
            learningLoop: read(row, 'learning_loop'),
          ),
        );
  }

  final List<SearchFeature> features = <SearchFeature>[];
  for (final List<_FeatureRow> same in grouped.values) {
    final _FeatureRow chosen = _preferRoute(same);
    final bool built =
        chosen.kind == 'route' &&
        (builtRouteKeys == null || builtRouteKeys.contains(chosen.key));
    features.add(
      SearchFeature(
        key: chosen.key,
        label: chosen.label,
        hub: chosen.hub,
        job: chosen.job,
        unlockStage: chosen.unlockStage,
        learningLoop: chosen.learningLoop,
        routeBuilt: built,
      ),
    );
  }
  return features;
}

_FeatureRow _preferRoute(List<_FeatureRow> rows) {
  for (final _FeatureRow row in rows) {
    if (row.kind == 'route') return row;
  }
  return rows.first;
}

List<List<String>> _csvRows(String csv) {
  final List<List<String>> rows = <List<String>>[];
  final List<String> row = <String>[];
  final StringBuffer cell = StringBuffer();
  var quoted = false;
  for (var i = 0; i < csv.length; i++) {
    final String char = csv[i];
    if (quoted) {
      if (char == '"') {
        if (i + 1 < csv.length && csv[i + 1] == '"') {
          cell.write('"');
          i += 1;
        } else {
          quoted = false;
        }
      } else {
        cell.write(char);
      }
      continue;
    }
    if (char == '"') {
      quoted = true;
    } else if (char == ',') {
      row.add(cell.toString());
      cell.clear();
    } else if (char == '\n') {
      row.add(cell.toString());
      cell.clear();
      if (row.any((String value) => value.trim().isNotEmpty)) {
        rows.add(List<String>.from(row));
      }
      row.clear();
    } else if (char != '\r') {
      cell.write(char);
    }
  }
  if (cell.isNotEmpty || row.isNotEmpty) {
    row.add(cell.toString());
    if (row.any((String value) => value.trim().isNotEmpty)) {
      rows.add(List<String>.from(row));
    }
  }
  return rows;
}

/// Route map shipped with search. Same bytes as docs/build/design/ROUTE_MAP.csv.
const String kRouteMapCsv =
    r'''kind,key,label,hub,job,unlock_stage,learning_loop,surface,source
drawer,Badges,Badges,Me,live it,Account created,Cultural badges,,lib/screens/tabs_view/app_drawer/app_drawer.dart:705
drawer,Badges,Badges,Me,live it,Account created,Cultural badges,,lib/screens/tabs_view/app_drawer/app_drawer_material3.dart:571
drawer,Dashboard,Dashboard,Today,learn it,Day 1,Today session,,lib/screens/tabs_view/app_drawer/app_drawer.dart:183
drawer,Dashboard,Dashboard,Today,learn it,Day 1,Today session,,lib/screens/tabs_view/app_drawer/app_drawer_material3.dart:161
drawer,Games,Games,Play,learn it,Day 1,Arcade retrieval,,lib/screens/tabs_view/app_drawer/app_drawer.dart:428
drawer,Games,Games,Play,learn it,Day 1,Arcade retrieval,,lib/screens/tabs_view/app_drawer/app_drawer_material3.dart:247
drawer,Leaderboards,Leaderboards,Me,live it,Account created,Fair leagues,,lib/screens/tabs_view/app_drawer/app_drawer.dart:719
drawer,Leaderboards,Leaderboards,Me,live it,Account created,Fair leagues,,lib/screens/tabs_view/app_drawer/app_drawer_material3.dart:585
drawer,Lessons,Lessons,Learn,learn it,Day 1,Path lesson,,lib/screens/tabs_view/app_drawer/app_drawer.dart:197
drawer,Lessons,Lessons,Learn,learn it,Day 1,Path lesson,,lib/screens/tabs_view/app_drawer/app_drawer_material3.dart:170
drawer,Micro-Mentors,Micro-Mentors,Village,live it,B1,Mentor session,,lib/screens/tabs_view/app_drawer/app_drawer.dart:558
drawer,Micro-Mentors,Micro-Mentors,Village,live it,B1,Mentor session,,lib/screens/tabs_view/app_drawer/app_drawer_material3.dart:443
drawer,Profile,Profile,Me,live it,Account created,Learner identity,,lib/screens/tabs_view/app_drawer/app_drawer.dart:740
drawer,Profile,Profile,Me,live it,Account created,Learner identity,,lib/screens/tabs_view/app_drawer/app_drawer_material3.dart:606
drawer,Settings,Settings,Me,live it,Day 1,Settings,,lib/screens/tabs_view/app_drawer/app_drawer.dart:754
drawer,Settings,Settings,Me,live it,Day 1,Settings,,lib/screens/tabs_view/app_drawer/app_drawer_material3.dart:620
drawer,drawerFlbHeritageArchive,FLB Heritage Archive,Learn,learn it,Day 1,Culture shelf,,lib/screens/tabs_view/app_drawer/app_drawer.dart:456
drawer,drawerFlbHeritageArchive,FLB Heritage Archive,Learn,learn it,Day 1,Culture shelf,,lib/screens/tabs_view/app_drawer/app_drawer_material3.dart:305
drawer,shellAiChat,AI Chat,Speak,say it,Day 1,Polie conversation,,lib/screens/tabs_view/app_drawer/app_drawer.dart:253
drawer,shellAiChat,AI Chat,Speak,say it,Day 1,Polie conversation,,lib/screens/tabs_view/app_drawer/app_drawer_material3.dart:226
drawer,shellAuthenticPathA1C1,Authentic Path (A1–C1),Learn,learn it,A2,Real-world track,,lib/screens/tabs_view/app_drawer/app_drawer.dart:211
drawer,shellAuthenticPathA1C1,Authentic Path (A1–C1),Learn,learn it,A2,Real-world track,,lib/screens/tabs_view/app_drawer/app_drawer_material3.dart:184
drawer,shellCommunityFeed,Community Feed,Village,live it,Account created,Square,square,lib/screens/tabs_view/app_drawer/app_drawer.dart:544
drawer,shellCommunityFeed,Community Feed,Village,live it,Account created,Square,square,lib/screens/tabs_view/app_drawer/app_drawer_material3.dart:426
drawer,shellConversationScenarios,Conversation Scenarios,Speak,say it,Week 1 / A1 unit 3,Scenario dialogue,,lib/screens/tabs_view/app_drawer/app_drawer.dart:323
drawer,shellCreateContent,Create Content,Village,live it,B1,Create a mini-lesson,,lib/screens/tabs_view/app_drawer/app_drawer.dart:509
drawer,shellCreateContent,Create Content,Village,live it,B1,Create a mini-lesson,,lib/screens/tabs_view/app_drawer/app_drawer_material3.dart:390
drawer,shellCulturalHub,Cultural Hub,Learn,learn it,Day 1,Culture shelf,,lib/screens/tabs_view/app_drawer/app_drawer.dart:407
drawer,shellCulturalMagazine,Cultural Magazine,Learn,learn it,Day 1,Culture shelf,,lib/screens/tabs_view/app_drawer/app_drawer.dart:442
drawer,shellCulturalMagazine,Cultural Magazine,Learn,learn it,Day 1,Culture shelf,,lib/screens/tabs_view/app_drawer/app_drawer_material3.dart:261
drawer,shellDialectPreference,Dialect preference,Learn,learn it,Day 1,Dialect choice,,lib/screens/tabs_view/app_drawer/app_drawer_material3.dart:381
drawer,shellFlashcardReview,Flashcard Review,Learn,learn it,Day 1,Words and review,,lib/screens/tabs_view/app_drawer/app_drawer.dart:365
drawer,shellFriendQuests,Friend Quests,Today,learn it,Account created,Friend quest,,lib/screens/tabs_view/app_drawer/app_drawer.dart:684
drawer,shellGlobalChat,Global Chat,Village,live it,Week 1 / A1 unit 3,Language Squares,chat,lib/screens/tabs_view/app_drawer/app_drawer.dart:530
drawer,shellGlobalChat,Global Chat,Village,live it,Week 1 / A1 unit 3,Language Squares,chat,lib/screens/tabs_view/app_drawer/app_drawer_material3.dart:412
drawer,shellGrammarHub,Grammar Hub,Learn,learn it,Day 1,Grammar drill,,lib/screens/tabs_view/app_drawer/app_drawer.dart:274
drawer,shellHeritageMilestones,Heritage milestones,Learn,learn it,Day 1,Culture shelf,,lib/screens/tabs_view/app_drawer/app_drawer_material3.dart:372
drawer,shellHistoricalPersonas,Historical Personas,Speak,say it,Week 1 / A1 unit 3,Persona mission,,lib/screens/tabs_view/app_drawer/app_drawer.dart:614
drawer,shellHistoricalPersonas,Historical Personas,Speak,say it,Week 1 / A1 unit 3,Persona mission,,lib/screens/tabs_view/app_drawer/app_drawer_material3.dart:529
drawer,shellImportMedia,Import Media,Learn,learn it,Day 1,Import a sign and read it,,lib/screens/tabs_view/app_drawer/app_drawer.dart:470
drawer,shellImportMedia,Import Media,Learn,learn it,Day 1,Import a sign and read it,,lib/screens/tabs_view/app_drawer/app_drawer_material3.dart:319
drawer,shellLanguageVillages,Language Villages,Village,live it,Account created,Village place,,lib/screens/tabs_view/app_drawer/app_drawer.dart:586
drawer,shellLanguageVillages,Language Villages,Village,live it,Account created,Village place,,lib/screens/tabs_view/app_drawer/app_drawer_material3.dart:486
drawer,shellLearningPath,Learning Path,Learn,learn it,Day 1,My plan,,lib/screens/tabs_view/app_drawer/app_drawer.dart:288
drawer,shellListeningPractice,Listening Practice,Learn,learn it,Day 1,Listening input,,lib/screens/tabs_view/app_drawer/app_drawer.dart:337
drawer,shellLiveClassroom,Live Classroom,Village,learn it,Account created,Classroom lesson,,lib/screens/tabs_view/app_drawer/app_drawer_material3.dart:472
drawer,shellLiveTranslate,Live translate,Speak,say it,Day 1,Conversation Bridge,,lib/screens/tabs_view/app_drawer/app_drawer.dart:500
drawer,shellLiveTranslate,Live translate,Speak,say it,Day 1,Conversation Bridge,,lib/screens/tabs_view/app_drawer/app_drawer_material3.dart:349
drawer,shellLivingDictionary,Living Dictionary,Learn,learn it,Day 1,Words and review,,lib/screens/tabs_view/app_drawer/app_drawer_material3.dart:358
drawer,shellMicroMentorReports,Micro-mentor reports,Village,live it,B1,Mentor session,,lib/screens/tabs_view/app_drawer/app_drawer.dart:649
drawer,shellMicroMentorReports,Micro-mentor reports,Village,live it,B1,Mentor session,,lib/screens/tabs_view/app_drawer/app_drawer_material3.dart:550
drawer,shellMyTribes,My Tribes,Village,live it,Account created,Circle practice,,lib/screens/tabs_view/app_drawer/app_drawer.dart:600
drawer,shellMyTribes,My Tribes,Village,live it,Account created,Circle practice,,lib/screens/tabs_view/app_drawer/app_drawer_material3.dart:515
drawer,shellNativeContentReview,Native content review,Village,live it,native speaker (any level),Native verification,,lib/screens/tabs_view/app_drawer/app_drawer.dart:225
drawer,shellNativeContentReview,Native content review,Village,live it,native speaker (any level),Native verification,,lib/screens/tabs_view/app_drawer/app_drawer_material3.dart:198
drawer,shellPersonaMissions,Persona Missions,Speak,say it,Week 1 / A1 unit 3,Persona mission,,lib/screens/tabs_view/app_drawer/app_drawer.dart:628
drawer,shellPhraseDna,Phrase DNA,Learn,learn it,Day 1,Words and review,,lib/screens/tabs_view/app_drawer/app_drawer_material3.dart:275
drawer,shellPointSay,Point & Say,Speak,say it,Day 1,"Point, hear, and say",,lib/screens/tabs_view/app_drawer/app_drawer.dart:484
drawer,shellPointSay,Point & Say,Speak,say it,Day 1,"Point, hear, and say",,lib/screens/tabs_view/app_drawer/app_drawer_material3.dart:333
drawer,shellPolieTutor,Polie Tutor,Speak,say it,Day 1,Polie conversation,,lib/screens/tabs_view/app_drawer/app_drawer_material3.dart:212
drawer,shellPracticeRooms,Practice Rooms,Village,say it,Week 1 / A1 unit 3,Practice room,,lib/screens/tabs_view/app_drawer/app_drawer_material3.dart:501
drawer,shellPrivateChat,Private Chat,Village,live it,Week 1 / A1 unit 3,Language-exchange DMs,chat,lib/screens/tabs_view/app_drawer/app_drawer.dart:572
drawer,shellPrivateChat,Private Chat,Village,live it,Week 1 / A1 unit 3,Language-exchange DMs,chat,lib/screens/tabs_view/app_drawer/app_drawer_material3.dart:458
drawer,shellSocialHub,Social Hub,Village,live it,Account created,Pick one village loop,,lib/screens/tabs_view/app_drawer/app_drawer.dart:670
drawer,shellToneRhythm,Tone & Rhythm,Learn,say it,Day 1,Tone practice,,lib/screens/tabs_view/app_drawer/app_drawer_material3.dart:289
drawer,shellTutorMode,Tutor Mode,Speak,say it,Day 1,Polie conversation,,lib/screens/tabs_view/app_drawer/app_drawer.dart:239
drawer,shellVocabularyBuilder,Vocabulary Builder,Learn,learn it,Day 1,Words and review,,lib/screens/tabs_view/app_drawer/app_drawer.dart:302
drawer,shellWritingPractice,Writing Practice,Learn,learn it,Day 1,Writing retrieval,,lib/screens/tabs_view/app_drawer/app_drawer.dart:351
route,achievements,Achievements,Me,live it,Account created,Cultural badges,,lib/my_app.dart
route,ai_chat_select,AI Chat Select,Speak,say it,Day 1,Polie conversation,,lib/my_app.dart
route,ancestral_tree,Ancestral Tree,Village,live it,Account created,See who you helped,,lib/my_app.dart
route,authentic-path,Authentic Path,Learn,learn it,A2,Real-world track,,lib/my_app.dart
route,badges,Badges,Me,live it,Account created,Cultural badges,,lib/my_app.dart
route,call-history,Call History,Village,live it,Week 1 / A1 unit 3,Save phrases from a call,chat,lib/my_app.dart
route,challenge-friend,Challenge Friend,Play,learn it,Account created,Challenge a friend,,lib/my_app.dart
route,classroom-assignments-v2,Classroom Assignments v2,Village,learn it,Account created,Classroom lesson,,lib/my_app.dart
route,classroom-lobby,Classroom Lobby,Village,learn it,Account created,Classroom lesson,,lib/my_app.dart
route,classroom-notes,Classroom Notes,Village,learn it,Account created,Classroom lesson,,lib/my_app.dart
route,classroom-privacy-v2,Classroom Privacy v2,Village,learn it,Account created,Classroom lesson,,lib/my_app.dart
route,classroom-roster-v2,Classroom Roster v2,Village,learn it,Account created,Classroom lesson,,lib/my_app.dart
route,classroom-student-requests-v2,Classroom Student Requests v2,Village,learn it,Account created,Classroom lesson,,lib/my_app.dart
route,community-profile,Community Profile,Village,live it,Account created,Square,square,lib/my_app.dart
route,connections,Connections,Village,live it,Account created,Find a language partner,,lib/my_app.dart
route,contribute_voice,Contribute Voice,Village,live it,native speaker (any level),Native verification,,lib/my_app.dart
route,conversation-scenarios,Conversation Scenarios,Speak,say it,Week 1 / A1 unit 3,Scenario dialogue,,lib/my_app.dart
route,create-friend-quest,Create Friend Quest,Today,learn it,Account created,Friend quest,,lib/my_app.dart
route,cultural-hub,Cultural Hub,Learn,learn it,Day 1,Culture shelf,,lib/my_app.dart
route,curriculum,Curriculum,Learn,learn it,Day 1,Path lesson,,lib/my_app.dart
route,daily_goals,Daily Goals,Today,learn it,Day 1,Today session,,lib/my_app.dart
route,dialect-preference,Dialect Preference,Learn,learn it,Day 1,Dialect choice,,lib/my_app.dart
route,elder-hut,Elder Hut,Village,live it,B1,Ask an elder and save the proverb,,lib/my_app.dart
route,email-verification,Email Verification,Me,live it,Day 1,Account,,lib/my_app.dart
route,events,Events,Today,live it,Day 1,Village festival,,lib/my_app.dart
route,explore-community,Explore Community,Village,live it,Account created,Square,square,lib/my_app.dart
route,family-hub,Family Hub,Me,live it,Account created,Family,,lib/my_app.dart
route,features_guide,Features Guide,Me,live it,Day 1,All features,,lib/my_app.dart
route,flashcard-focus,Flashcard Focus,Play,learn it,Day 1,Arcade retrieval,,lib/my_app.dart
route,flashcard-review,Flashcard Review,Learn,learn it,Day 1,Words and review,,lib/my_app.dart
route,flb-heritage-archive,FLB Heritage Archive,Learn,learn it,Day 1,Culture shelf,,lib/my_app.dart
route,flb-heritage-detail,FLB Heritage Detail,Learn,learn it,Day 1,Culture shelf,,lib/my_app.dart
route,friend-profile,Friend Profile,Village,live it,Account created,Find a language partner,,lib/my_app.dart
route,friend-quests,Friend Quests,Today,learn it,Account created,Friend quest,,lib/my_app.dart
route,games,Games,Play,learn it,Day 1,Arcade retrieval,,lib/my_app.dart
route,games_api_languages,Games API Languages,Play,learn it,Account created,Arcade retrieval,,lib/my_app.dart
route,games_enhanced_catalog,Games Enhanced Catalog,Play,learn it,Account created,Arcade retrieval,,lib/my_app.dart
route,global_chat,Global Chat,Village,live it,Week 1 / A1 unit 3,Language Squares,chat,lib/my_app.dart
route,grammar-exercise,Grammar Exercise,Learn,learn it,Day 1,Grammar drill,,lib/my_app.dart
route,grammar-hub,Grammar Hub,Learn,learn it,Day 1,Grammar drill,,lib/my_app.dart
route,grammar-lesson,Grammar Lesson,Learn,learn it,Day 1,Grammar drill,,lib/my_app.dart
route,guardian-approvals,Guardian Approvals,Me,live it,Account created,Family,,lib/my_app.dart
route,guardian-child-messages,Guardian Child Messages,Me,live it,Account created,Family,,lib/my_app.dart
route,guardian-messaging-guide,Guardian Messaging Guide,Me,live it,Account created,Family,,lib/my_app.dart
route,heritage-milestones,Heritage Milestones,Learn,learn it,Day 1,Culture shelf,,lib/my_app.dart
route,historical-personas,Historical Personas,Speak,say it,Week 1 / A1 unit 3,Persona mission,,lib/my_app.dart
route,import_media,Import Media,Learn,learn it,Day 1,Import a sign and read it,,lib/my_app.dart
route,inter-tribe-leaderboard,Inter Tribe Leaderboard,Village,live it,Account created,Circle Clash,,lib/my_app.dart
route,language-village,Language Village,Village,live it,Account created,Village place,,lib/my_app.dart
route,language-village-place,Language Village Place,Village,live it,Account created,Village place,,lib/my_app.dart
route,leaderboard,Leaderboard,Me,live it,Account created,Fair leagues,,lib/my_app.dart
route,learning-path,Learning Path,Learn,learn it,Day 1,My plan,,lib/my_app.dart
route,lesson-flow,Lesson Flow,Learn,learn it,Day 1,Path lesson,,lib/my_app.dart
route,lingchat_ai,Lingchat AI,Speak,say it,Day 1,Polie conversation,,lib/my_app.dart
route,listening-practice,Listening Practice,Learn,learn it,Day 1,Listening input,,lib/my_app.dart
route,live-classroom,Live Classroom,Village,learn it,Account created,Classroom lesson,,lib/my_app.dart
route,living-dictionary,Living Dictionary,Learn,learn it,Day 1,Words and review,,lib/my_app.dart
route,magazine,Magazine,Learn,learn it,Day 1,Culture shelf,,lib/my_app.dart
route,magic_items,Magic Items,Me,live it,Account created,Avatar wardrobe,,lib/my_app.dart
route,matching-pairs,Matching Pairs,Play,learn it,Day 1,Arcade retrieval,,lib/my_app.dart
route,micro-mentor-hub,Micro Mentor Hub,Village,live it,B1,Mentor session,,lib/my_app.dart
route,my-tribe,My Tribe,Village,live it,Account created,Circle practice,,lib/my_app.dart
route,my-vocabulary,My Vocabulary,Learn,learn it,Day 1,Words and review,,lib/my_app.dart
route,native-content-review,Native Content Review,Village,live it,native speaker (any level),Native verification,,lib/my_app.dart
route,passkey-manage,Passkey Manage,Me,live it,Day 1,Account,,lib/my_app.dart
route,passkey-sign-in,Passkey Sign In,Me,live it,Day 1,Account,,lib/my_app.dart
route,passport-credential,Passport Credential,Learn,learn it,A2,Passport evidence,,lib/my_app.dart
route,passport-proctored,Passport Proctored,Learn,learn it,A2,Passport evidence,,lib/my_app.dart
route,phrase-dna-templates,Phrase DNA Templates,Learn,learn it,Day 1,Words and review,,lib/my_app.dart
route,point-and-say,Point And Say,Speak,say it,Day 1,"Point, hear, and say",,lib/my_app.dart
route,policy,Policy,Me,live it,Day 1,Settings,,lib/my_app.dart
route,polie_mode_selection,Polie Mode Selection,Speak,say it,Day 1,Polie conversation,,lib/my_app.dart
route,practice-room-collaborative,Practice Room Collaborative,Village,say it,Week 1 / A1 unit 3,Practice room,,lib/my_app.dart
route,practice-room-setup,Practice Room Setup,Village,say it,B1,Host a practice room,,lib/my_app.dart
route,practice-session,Practice Session,Village,say it,Week 1 / A1 unit 3,Practice room,,lib/my_app.dart
route,private-chat-inbox,Private Chat Inbox,Village,live it,Week 1 / A1 unit 3,Language-exchange DMs,chat,lib/my_app.dart
route,progress,Progress,Me,live it,Account created,Can-do progress,,lib/my_app.dart
route,quality-report,Quality Report,Village,live it,native speaker (any level),Native verification,,lib/my_app.dart
route,quest,Quest,Today,learn it,Day 1,Village quest,,lib/my_app.dart
route,script-track,Script Track,Learn,learn it,Day 1,Script practice,,lib/my_app.dart
route,search-community,Search Community,Village,live it,Account created,Square,square,lib/my_app.dart
route,session-summary,Session Summary,Village,say it,Week 1 / A1 unit 3,Practice room,,lib/my_app.dart
route,settings,Settings,Me,live it,Day 1,Settings,,lib/my_app.dart
route,share-progress,Share Progress,Village,live it,Account created,Share a phrase you learned,,lib/my_app.dart
route,sign-in-options,Sign In Options,Me,live it,Day 1,Account,,lib/my_app.dart
route,snap-camera,Snap Camera,Village,live it,A2,Clips,clips,lib/my_app.dart
route,snap-inbox,Snap Inbox,Village,live it,A2,Clips,clips,lib/my_app.dart
route,snap-story-feed,Snap Story Feed,Village,live it,A2,Clips,clips,lib/my_app.dart
route,snap-streaks,Snap Streaks,Village,live it,A2,Clips,clips,lib/my_app.dart
route,snap-viewer,Snap Viewer,Village,live it,A2,Clips,clips,lib/my_app.dart
route,social-hub,Social Hub,Village,live it,Account created,Pick one village loop,,lib/my_app.dart
route,speak-engine-lab,Speak Engine Lab,Speak,say it,A2,Code-switch and respect practice,,lib/my_app.dart
route,speaker-queue,Speaker Queue,Village,say it,Account created,Classroom lesson,,lib/my_app.dart
route,staff-micro-mentor-reports,Staff Micro Mentor Reports,Village,live it,B1,Mentor session,,lib/my_app.dart
route,stitch-hub,Stitch Hub,Me,live it,Day 1,All features,,lib/my_app.dart
route,stroke-order-practice,Stroke Order Practice,Learn,learn it,Day 1,Script practice,,lib/my_app.dart
route,suggest-fix,Suggest Fix,Village,live it,native speaker (any level),Native verification,,lib/my_app.dart
route,swahili-village-map,Swahili Village Map,Village,live it,Account created,Village place,,lib/my_app.dart
route,synthetic-voice-styles,Synthetic Voice Styles,Speak,say it,Day 1,Hear a voice and shadow it,,lib/my_app.dart
route,tonal-lesson,Tonal Lesson,Learn,say it,Day 1,Tone practice,,lib/my_app.dart
route,tone-rhythm-trainer,Tone Rhythm Trainer,Learn,say it,Day 1,Tone practice,,lib/my_app.dart
route,tribal-duel,Tribal Duel,Village,live it,Account created,Circle Clash,,lib/my_app.dart
route,tribe,Tribe,Village,live it,Account created,Circle Clash,,lib/my_app.dart
route,tribe-discovery,Tribe Discovery,Village,live it,Account created,Circle practice,,lib/my_app.dart
route,tribe-hub,Tribe Hub,Village,live it,Account created,Circle practice,,lib/my_app.dart
route,tribe-selection,Tribe Selection,Village,live it,Account created,Circle practice,,lib/my_app.dart
route,tribe_selection,Tribe Selection,Village,live it,Account created,Circle practice,,lib/my_app.dart
route,tribe_vs_tribe,Tribe vs Tribe,Village,live it,Account created,Circle Clash,,lib/my_app.dart
route,ugc,UGC,Village,live it,B1,Create a mini-lesson,,lib/my_app.dart
route,village-cafe,Village Cafe,Village,live it,Account created,Village place,,lib/my_app.dart
route,village-circles,Village Circles,Village,live it,Account created,Circle practice,,lib/my_app.dart
route,village-market,Village Market,Village,live it,Account created,Village place,,lib/my_app.dart
route,villages,Villages,Village,live it,Account created,Village place,,lib/my_app.dart
route,villages-hub,Villages Hub,Village,live it,Account created,Village place,,lib/my_app.dart
route,vocabulary-builder,Vocabulary Builder,Learn,learn it,Day 1,Words and review,,lib/my_app.dart
route,wa-media-gallery,WA Media Gallery,Village,live it,Week 1 / A1 unit 3,Saved phrases,chat,lib/my_app.dart
route,wa-starred,WA Starred,Village,live it,Week 1 / A1 unit 3,Saved phrases,chat,lib/my_app.dart
route,wa-status,WA Status,Village,live it,Week 1 / A1 unit 3,Language Status,status,lib/my_app.dart
route,wa-status-create,WA Status Create,Village,live it,Week 1 / A1 unit 3,Language Status,status,lib/my_app.dart
route,wa-status-view,WA Status View,Village,live it,Week 1 / A1 unit 3,Language Status,status,lib/my_app.dart
route,writing-practice,Writing Practice,Learn,learn it,Day 1,Writing retrieval,,lib/my_app.dart
route,x-compose,X Compose,Village,live it,Account created,Square,square,lib/my_app.dart
route,x-explore,X Explore,Village,live it,Account created,Square,square,lib/my_app.dart
route,x-feed-home,X Feed Home,Village,live it,Account created,Square,square,lib/my_app.dart
route,x-lists,X Lists,Village,live it,Account created,Square,square,lib/my_app.dart
route,x-notifications,X Notifications,Village,live it,Account created,Square,square,lib/my_app.dart
route,x-post-detail,X Post Detail,Village,live it,Account created,Square,square,lib/my_app.dart
route,x-profile,X Profile,Village,live it,Account created,Square,square,lib/my_app.dart
''';
