import 'package:flutter/material.dart';
import 'package:lingafriq/screens/learning/learn_hub_pages.dart';

/// One Learn sitemap place. [hub] is the root.
enum LearnPlace {
  hub,
  path,
  lesson,
  recap,
  words,
  reviewDashboard,
  vocabDashboard,
  reviewRush,
  grammar,
  phraseDna,
  listening,
  writing,
  toneGym,
  culture,
  magazine,
  heritage,
  history,
  mannerisms,
  culturalHub,
  passport,
  downloads,
}

/// How the hub root should render. Ready shows the sitemap.
enum LearnHubStatus { ready, error, offline }

/// A lesson that already exists on a unit. The hub does not create one.
class LearnLesson {
  const LearnLesson({required this.id, required this.title});

  final String id;
  final String title;
}

/// A path unit supplied by the caller. [cefr] is the band on that unit.
class LearnUnit {
  const LearnUnit({
    required this.id,
    required this.title,
    required this.cefr,
    this.lessons = const <LearnLesson>[],
  });

  final String id;
  final String title;
  final String cefr;
  final List<LearnLesson> lessons;
}

/// Units that share one CEFR band, in the order they were given.
class LearnCefrGroup {
  const LearnCefrGroup({required this.level, required this.units});

  final String level;
  final List<LearnUnit> units;
}

/// Registered Learn routes. Names match the sitemap in §17.2.
abstract final class LearnRoutes {
  static const String hub = '/learn';
  static const String path = '/learn/path';
  static const String lesson = '/learn/lesson';
  static const String recap = '/learn/recap';
  static const String words = '/learn/words';
  static const String reviewDashboard = '/learn/review-dashboard';
  static const String vocabDashboard = '/learn/vocab-dashboard';
  static const String reviewRush = '/learn/review-rush';
  static const String grammar = '/learn/grammar';
  static const String phraseDna = '/learn/phrase-dna';
  static const String listening = '/learn/listening';
  static const String writing = '/learn/writing';
  static const String toneGym = '/learn/tone-gym';
  static const String culture = '/learn/culture';
  static const String magazine = '/learn/culture/magazine';
  static const String heritage = '/learn/culture/heritage';
  static const String history = '/learn/culture/history';
  static const String mannerisms = '/learn/culture/mannerisms';
  static const String culturalHub = '/learn/culture/hub';
  static const String passport = '/learn/passport';
  static const String downloads = '/learn/downloads';
}

/// One row in the Learn route table.
class LearnDestination {
  const LearnDestination({
    required this.place,
    required this.route,
    required this.parent,
    required this.onRoot,
    required this.staticChild,
  });

  final LearnPlace place;
  final String route;
  final LearnPlace? parent;

  /// Shown on the Learn root.
  final bool onRoot;

  /// Shown on the parent screen. Lessons come from units, not this flag.
  final bool staticChild;
}

/// CEFR bands in syllabus order. A band with no units is not added.
const List<String> learnCefrBands = <String>[
  'A1',
  'A2',
  'B1',
  'B2',
  'C1',
  'C2',
];

/// Sitemap for Learn. [lesson] is reached from Path. Phrase DNA is under
/// Grammar. Culture rows are under the shelf.
const List<LearnDestination> learnDestinations = <LearnDestination>[
  LearnDestination(
    place: LearnPlace.hub,
    route: LearnRoutes.hub,
    parent: null,
    onRoot: false,
    staticChild: false,
  ),
  LearnDestination(
    place: LearnPlace.path,
    route: LearnRoutes.path,
    parent: LearnPlace.hub,
    onRoot: true,
    staticChild: false,
  ),
  LearnDestination(
    place: LearnPlace.lesson,
    route: LearnRoutes.lesson,
    parent: LearnPlace.path,
    onRoot: false,
    staticChild: false,
  ),
  LearnDestination(
    place: LearnPlace.recap,
    route: LearnRoutes.recap,
    parent: LearnPlace.hub,
    onRoot: true,
    staticChild: false,
  ),
  LearnDestination(
    place: LearnPlace.words,
    route: LearnRoutes.words,
    parent: LearnPlace.hub,
    onRoot: true,
    staticChild: false,
  ),
  LearnDestination(
    place: LearnPlace.reviewDashboard,
    route: LearnRoutes.reviewDashboard,
    parent: LearnPlace.hub,
    onRoot: true,
    staticChild: false,
  ),
  LearnDestination(
    place: LearnPlace.vocabDashboard,
    route: LearnRoutes.vocabDashboard,
    parent: LearnPlace.hub,
    onRoot: true,
    staticChild: false,
  ),
  LearnDestination(
    place: LearnPlace.reviewRush,
    route: LearnRoutes.reviewRush,
    parent: LearnPlace.hub,
    onRoot: true,
    staticChild: false,
  ),
  LearnDestination(
    place: LearnPlace.grammar,
    route: LearnRoutes.grammar,
    parent: LearnPlace.hub,
    onRoot: true,
    staticChild: false,
  ),
  LearnDestination(
    place: LearnPlace.phraseDna,
    route: LearnRoutes.phraseDna,
    parent: LearnPlace.grammar,
    onRoot: false,
    staticChild: true,
  ),
  LearnDestination(
    place: LearnPlace.listening,
    route: LearnRoutes.listening,
    parent: LearnPlace.hub,
    onRoot: true,
    staticChild: false,
  ),
  LearnDestination(
    place: LearnPlace.writing,
    route: LearnRoutes.writing,
    parent: LearnPlace.hub,
    onRoot: true,
    staticChild: false,
  ),
  LearnDestination(
    place: LearnPlace.toneGym,
    route: LearnRoutes.toneGym,
    parent: LearnPlace.hub,
    onRoot: true,
    staticChild: false,
  ),
  LearnDestination(
    place: LearnPlace.culture,
    route: LearnRoutes.culture,
    parent: LearnPlace.hub,
    onRoot: true,
    staticChild: false,
  ),
  LearnDestination(
    place: LearnPlace.magazine,
    route: LearnRoutes.magazine,
    parent: LearnPlace.culture,
    onRoot: false,
    staticChild: true,
  ),
  LearnDestination(
    place: LearnPlace.heritage,
    route: LearnRoutes.heritage,
    parent: LearnPlace.culture,
    onRoot: false,
    staticChild: true,
  ),
  LearnDestination(
    place: LearnPlace.history,
    route: LearnRoutes.history,
    parent: LearnPlace.culture,
    onRoot: false,
    staticChild: true,
  ),
  LearnDestination(
    place: LearnPlace.mannerisms,
    route: LearnRoutes.mannerisms,
    parent: LearnPlace.culture,
    onRoot: false,
    staticChild: true,
  ),
  LearnDestination(
    place: LearnPlace.culturalHub,
    route: LearnRoutes.culturalHub,
    parent: LearnPlace.culture,
    onRoot: false,
    staticChild: true,
  ),
  LearnDestination(
    place: LearnPlace.passport,
    route: LearnRoutes.passport,
    parent: LearnPlace.hub,
    onRoot: true,
    staticChild: false,
  ),
  LearnDestination(
    place: LearnPlace.downloads,
    route: LearnRoutes.downloads,
    parent: LearnPlace.hub,
    onRoot: true,
    staticChild: false,
  ),
];

/// Finders for rows, bands, and the not-available page.
abstract final class LearnHubKeys {
  static Key row(LearnPlace place) =>
      ValueKey<String>('learn-row-${place.name}');

  static Key level(String level) => ValueKey<String>('learn-level-$level');

  static Key unit(String id) => ValueKey<String>('learn-unit-$id');

  static Key lesson(String id) => ValueKey<String>('learn-lesson-$id');

  static Key route(String route) => ValueKey<String>('learn-route-$route');

  static const Key empty = ValueKey<String>('learn-empty');

  static const Key notAvailable = ValueKey<String>('learn-not-available');
}

/// Screens that render real structure. Every other place is not available.
enum LearnScreenKind { hub, path, grammar, culture, notAvailable }

LearnScreenKind learnScreenKind(LearnPlace place) {
  return switch (place) {
    LearnPlace.hub => LearnScreenKind.hub,
    LearnPlace.path => LearnScreenKind.path,
    LearnPlace.grammar => LearnScreenKind.grammar,
    LearnPlace.culture => LearnScreenKind.culture,
    _ => LearnScreenKind.notAvailable,
  };
}

LearnDestination? learnDestinationFor(LearnPlace place) {
  for (final LearnDestination destination in learnDestinations) {
    if (destination.place == place) return destination;
  }
  return null;
}

String? learnRouteFor(LearnPlace place) => learnDestinationFor(place)?.route;

LearnPlace? learnParent(LearnPlace place) => learnDestinationFor(place)?.parent;

/// Taps from the Learn root. The root itself is zero.
int learnTapDepth(LearnPlace place) {
  var depth = 0;
  LearnPlace? cursor = learnParent(place);
  while (cursor != null) {
    depth += 1;
    cursor = learnParent(cursor);
  }
  return depth;
}

List<LearnDestination> learnRootDestinations() {
  return <LearnDestination>[
    for (final LearnDestination destination in learnDestinations)
      if (destination.onRoot) destination,
  ];
}

List<LearnDestination> learnStaticChildren(LearnPlace parent) {
  return <LearnDestination>[
    for (final LearnDestination destination in learnDestinations)
      if (destination.parent == parent && destination.staticChild) destination,
  ];
}

String canonicalLearnRoute(String? route) {
  final String trimmed = (route ?? '').trim();
  if (trimmed.isEmpty) return LearnRoutes.hub;
  final String withSlash = trimmed.startsWith('/') ? trimmed : '/$trimmed';
  if (withSlash.length > 1 && withSlash.endsWith('/')) {
    return withSlash.substring(0, withSlash.length - 1);
  }
  return withSlash;
}

LearnPlace? learnPlaceFor(String? route) {
  final String name = canonicalLearnRoute(route);
  for (final LearnDestination destination in learnDestinations) {
    if (destination.route == name) return destination.place;
  }
  return null;
}

bool learnRouteIsRegistered(String? route) => learnPlaceFor(route) != null;

/// Known CEFR codes fold to the syllabus band. Any other text stays as given.
String normalizeLearnCefr(String raw) {
  final String trimmed = raw.trim();
  final String upper = trimmed.toUpperCase();
  if (learnCefrBands.contains(upper)) return upper;
  return trimmed;
}

/// Groups [units] by CEFR band. Does not add a unit or an empty band.
List<LearnCefrGroup> groupLearnUnitsByCefr(List<LearnUnit> units) {
  final Map<String, List<LearnUnit>> buckets = <String, List<LearnUnit>>{};
  final List<String> seen = <String>[];
  for (final LearnUnit unit in units) {
    final String level = normalizeLearnCefr(unit.cefr);
    final List<LearnUnit>? existing = buckets[level];
    if (existing == null) {
      seen.add(level);
      buckets[level] = <LearnUnit>[unit];
    } else {
      existing.add(unit);
    }
  }
  final List<String> ordered = <String>[
    for (final String band in learnCefrBands)
      if (buckets.containsKey(band)) band,
    for (final String level in seen)
      if (level.isNotEmpty && !learnCefrBands.contains(level)) level,
    if (buckets.containsKey('')) '',
  ];
  return <LearnCefrGroup>[
    for (final String level in ordered)
      LearnCefrGroup(
        level: level,
        units: List<LearnUnit>.unmodifiable(buckets[level]!),
      ),
  ];
}

/// Pops back to the Learn root. A second-level screen does not stop on the shelf.
void learnBackToRoot(BuildContext context) {
  final NavigatorState navigator = Navigator.of(context);
  var found = false;
  navigator.popUntil((Route<dynamic> route) {
    if (route.settings.name == LearnRoutes.hub) {
      found = true;
      return true;
    }
    return route.isFirst;
  });
  if (!found) {
    navigator.pushReplacementNamed(LearnRoutes.hub);
  }
}

void openLearnPlace(BuildContext context, LearnPlace place) {
  final String? route = learnRouteFor(place);
  if (route == null) return;
  Navigator.of(context).pushNamed(route);
}

/// Learn hub. [units] are the only path data. An empty list is an empty hub.
class LearnHub extends StatelessWidget {
  const LearnHub({
    super.key,
    this.units = const <LearnUnit>[],
    this.status = LearnHubStatus.ready,
    this.initialRoute = LearnRoutes.hub,
    this.onRetry,
    this.observers = const <NavigatorObserver>[],
  });

  final List<LearnUnit> units;
  final LearnHubStatus status;
  final String initialRoute;
  final VoidCallback? onRetry;
  final List<NavigatorObserver> observers;

  @override
  Widget build(BuildContext context) {
    return Navigator(
      initialRoute: initialRoute,
      observers: observers,
      onGenerateRoute: (RouteSettings settings) {
        final String name = canonicalLearnRoute(settings.name);
        return MaterialPageRoute<void>(
          settings: RouteSettings(name: name, arguments: settings.arguments),
          builder: (BuildContext context) {
            return buildLearnPage(
              route: name,
              units: units,
              status: status,
              onRetry: onRetry,
            );
          },
        );
      },
    );
  }
}
