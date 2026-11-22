import 'dart:convert';

/// Bundled rule table. The caller loads this file and passes the text to
/// [SurfacingRules.parse]. Evaluation does not read the asset itself.
const String kSurfacingRulesAsset = 'assets/config/surfacing_rules.json';

/// Event kind the tone rule counts. The caller sets this. The table does not
/// create events.
const String kSurfacingToneError = 'tone_error';

/// One feature the table offers. [label] is the learner-facing name.
class SurfacingOffer {
  const SurfacingOffer({
    required this.id,
    required this.label,
    required this.place,
    this.role,
    this.maxPerDay,
  });

  /// Stable id. Callers record this on [SurfacingShown].
  final String id;

  /// Learner-facing name from the rule table.
  final String label;

  /// Where the offer belongs: lesson_recap, play, word_card, lens, lesson,
  /// or today.
  final String place;

  /// Set to matching_game for the single game offered after a lesson.
  final String? role;

  /// When set, the offer is skipped once it has been shown this many times
  /// on the calendar day of [SurfacingQuery.now].
  final int? maxPerDay;

  bool get isMatchingGame => role == 'matching_game';

  @override
  String toString() => 'SurfacingOffer($id, $label, $place)';
}

/// One row of the table, in file order.
class SurfacingRule {
  const SurfacingRule({required this.id, required this.offers});

  final String id;
  final List<SurfacingOffer> offers;
}

/// A learner event the caller already recorded. This type stores that event.
/// It does not invent one.
class SurfacingEvent {
  const SurfacingEvent({required this.kind, required this.at});

  /// [kSurfacingToneError] counts toward the tone rule. Any other kind does not.
  final String kind;

  /// When the caller says the event happened. The tone count uses every
  /// supplied event of the matching kind. It does not drop events by age.
  final DateTime at;
}

/// The last time an offer was shown. The caller stores this. The table only
/// reads it.
class SurfacingShown {
  const SurfacingShown({required this.offerId, required this.at});

  final String offerId;
  final DateTime at;
}

/// Explicit inputs for one evaluation. [now] is the clock.
///
/// A day is the calendar date carried on [now] and on each [SurfacingShown.at]
/// (year, month, and day). Pass those values from the same clock.
class SurfacingQuery {
  const SurfacingQuery({
    required this.now,
    this.lessonFinished = false,
    this.lessonRecapOpen = false,
    this.wordLongPressed = false,
    this.wordCardOpen = false,
    this.objectLesson = false,
    this.cameraButtonUsed = false,
    this.events = const <SurfacingEvent>[],
    this.lastShown = const <SurfacingShown>[],
  });

  final DateTime now;
  final bool lessonFinished;
  final bool lessonRecapOpen;
  final bool wordLongPressed;
  final bool wordCardOpen;
  final bool objectLesson;
  final bool cameraButtonUsed;

  /// Learner events the caller supplies. An empty list is no events.
  final List<SurfacingEvent> events;

  /// Offers already shown, with the time the caller recorded.
  final List<SurfacingShown> lastShown;
}

/// Contextual surfacing rules from ELEVATION section 17.3.
///
/// [evaluate] reads the table and the query. It does not read storage, and it
/// does not add learner events.
class SurfacingRules {
  SurfacingRules._({required this.version, required List<_ParsedRule> rules})
    : _rules = List<_ParsedRule>.unmodifiable(rules);

  /// Table version from the JSON object.
  final int version;

  final List<_ParsedRule> _rules;

  List<SurfacingRule> get rules {
    return List<SurfacingRule>.unmodifiable(
      _rules.map(
        (_ParsedRule rule) => SurfacingRule(id: rule.id, offers: rule.offers),
      ),
    );
  }

  /// Parses [source]. A table that is not the expected shape throws
  /// [FormatException]. A label that contains an em dash is refused.
  factory SurfacingRules.parse(String source) {
    final Object? decoded;
    try {
      decoded = jsonDecode(source);
    } on FormatException catch (error) {
      throw FormatException('Surfacing rules are not JSON: ${error.message}');
    }
    final Map<String, Object?> root = _asMap(decoded, 'root');
    final int version = _asInt(root['version'], 'version');
    if (version < 1) {
      throw const FormatException('version must be at least 1');
    }
    final List<Object?> rows = _asList(root['rules'], 'rules');
    final List<_ParsedRule> rules = <_ParsedRule>[];
    for (var index = 0; index < rows.length; index += 1) {
      rules.add(_parseRule(rows[index], 'rules[$index]'));
    }
    return SurfacingRules._(version: version, rules: rules);
  }

  /// Offers whose conditions match [query], in table order.
  ///
  /// An offer with [SurfacingOffer.maxPerDay] is left out once the last-shown
  /// record already reaches that count on the calendar day of [query.now].
  /// The same offer id is returned once.
  List<SurfacingOffer> evaluate(SurfacingQuery query) {
    final List<SurfacingOffer> offers = <SurfacingOffer>[];
    final Set<String> seen = <String>{};
    for (final _ParsedRule rule in _rules) {
      if (!_matches(rule.when, query)) continue;
      for (final SurfacingOffer offer in rule.offers) {
        if (_capped(offer, query)) continue;
        if (!seen.add(offer.id)) continue;
        offers.add(offer);
      }
    }
    return List<SurfacingOffer>.unmodifiable(offers);
  }
}

class _When {
  const _When({
    required this.all,
    required this.any,
    required this.eventKind,
    required this.minCount,
  });

  final List<String> all;
  final List<String> any;
  final String? eventKind;
  final int minCount;
}

class _ParsedRule {
  const _ParsedRule({
    required this.id,
    required this.when,
    required this.offers,
  });

  final String id;
  final _When when;
  final List<SurfacingOffer> offers;
}

const Set<String> _flagNames = <String>{
  'lesson_finished',
  'lesson_recap_open',
  'word_long_pressed',
  'word_card_open',
  'object_lesson',
  'camera_button',
};

_ParsedRule _parseRule(Object? value, String path) {
  final Map<String, Object?> row = _asMap(value, path);
  final String id = _asId(row['id'], '$path.id');
  final _When when = _parseWhen(row['when'], '$path.when');
  final List<Object?> rawOffers = _asList(row['offers'], '$path.offers');
  if (rawOffers.isEmpty) {
    throw FormatException('Expected at least one offer at $path.offers');
  }
  final List<SurfacingOffer> offers = <SurfacingOffer>[];
  for (var index = 0; index < rawOffers.length; index += 1) {
    offers.add(_parseOffer(rawOffers[index], '$path.offers[$index]'));
  }
  return _ParsedRule(
    id: id,
    when: when,
    offers: List<SurfacingOffer>.unmodifiable(offers),
  );
}

_When _parseWhen(Object? value, String path) {
  final Map<String, Object?> row = _asMap(value, path);
  final List<String> all = _flags(row['all'], '$path.all');
  final List<String> any = _flags(row['any'], '$path.any');
  final Object? eventValue = row['event'];
  String? eventKind;
  var minCount = 0;
  if (eventValue != null) {
    eventKind = _asId(eventValue, '$path.event');
    minCount = _asInt(row['min_count'], '$path.min_count');
    if (minCount < 1) {
      throw FormatException('min_count must be at least 1 at $path.min_count');
    }
  } else if (row.containsKey('min_count')) {
    throw FormatException('min_count needs event at $path');
  }
  if (all.isEmpty && any.isEmpty && eventKind == null) {
    throw FormatException('Expected a condition at $path');
  }
  return _When(
    all: List<String>.unmodifiable(all),
    any: List<String>.unmodifiable(any),
    eventKind: eventKind,
    minCount: minCount,
  );
}

SurfacingOffer _parseOffer(Object? value, String path) {
  final Map<String, Object?> row = _asMap(value, path);
  final String label = _asText(row['label'], '$path.label');
  if (_hasEmDash(label)) {
    throw FormatException(
      'User-visible text at $path.label uses a disallowed dash',
    );
  }
  int? maxPerDay;
  if (row.containsKey('max_per_day')) {
    maxPerDay = _asInt(row['max_per_day'], '$path.max_per_day');
    if (maxPerDay < 1) {
      throw FormatException(
        'max_per_day must be at least 1 at $path.max_per_day',
      );
    }
  }
  String? role;
  if (row.containsKey('role')) {
    role = _asId(row['role'], '$path.role');
  }
  return SurfacingOffer(
    id: _asId(row['id'], '$path.id'),
    label: label,
    place: _asId(row['place'], '$path.place'),
    role: role,
    maxPerDay: maxPerDay,
  );
}

List<String> _flags(Object? value, String path) {
  if (value == null) return const <String>[];
  final List<Object?> raw = _asList(value, path);
  final List<String> names = <String>[];
  for (var index = 0; index < raw.length; index += 1) {
    final String name = _asId(raw[index], '$path[$index]');
    if (!_flagNames.contains(name)) {
      throw FormatException('Unknown flag $name at $path[$index]');
    }
    names.add(name);
  }
  return names;
}

bool _matches(_When when, SurfacingQuery query) {
  for (final String name in when.all) {
    if (!_flag(query, name)) return false;
  }
  if (when.any.isNotEmpty) {
    var hit = false;
    for (final String name in when.any) {
      if (_flag(query, name)) {
        hit = true;
        break;
      }
    }
    if (!hit) return false;
  }
  final String? kind = when.eventKind;
  if (kind != null && _countEvents(query, kind) < when.minCount) {
    return false;
  }
  return true;
}

bool _flag(SurfacingQuery query, String name) {
  return switch (name) {
    'lesson_finished' => query.lessonFinished,
    'lesson_recap_open' => query.lessonRecapOpen,
    'word_long_pressed' => query.wordLongPressed,
    'word_card_open' => query.wordCardOpen,
    'object_lesson' => query.objectLesson,
    'camera_button' => query.cameraButtonUsed,
    _ => throw StateError('Unknown surfacing flag $name'),
  };
}

int _countEvents(SurfacingQuery query, String kind) {
  var count = 0;
  for (final SurfacingEvent event in query.events) {
    if (event.kind == kind) count += 1;
  }
  return count;
}

bool _capped(SurfacingOffer offer, SurfacingQuery query) {
  final int? maxPerDay = offer.maxPerDay;
  if (maxPerDay == null) return false;
  var count = 0;
  for (final SurfacingShown shown in query.lastShown) {
    if (shown.offerId != offer.id) continue;
    if (!_sameDay(shown.at, query.now)) continue;
    count += 1;
    if (count >= maxPerDay) return true;
  }
  return false;
}

bool _sameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

bool _hasEmDash(String value) => value.runes.contains(0x2014);

Map<String, Object?> _asMap(Object? value, String path) {
  if (value is Map) {
    return value.map(
      (Object? key, Object? item) =>
          MapEntry<String, Object?>(key.toString(), item),
    );
  }
  throw FormatException('Expected an object at $path');
}

List<Object?> _asList(Object? value, String path) {
  if (value is List) return value.cast<Object?>();
  throw FormatException('Expected a list at $path');
}

String _asText(Object? value, String path) {
  if (value is String && value.trim().isNotEmpty) return value.trim();
  throw FormatException('Expected text at $path');
}

String _asId(Object? value, String path) {
  final String text = _asText(value, path);
  if (text.contains(' ')) {
    throw FormatException('Expected an id at $path');
  }
  return text;
}

int _asInt(Object? value, String path) {
  if (value is int) return value;
  throw FormatException('Expected an integer at $path');
}
