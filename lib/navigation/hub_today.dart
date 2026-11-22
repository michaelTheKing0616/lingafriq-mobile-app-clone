import 'package:flutter/widgets.dart';
import 'package:lingafriq/l10n/generated/app_localizations.dart';

/// Shortest daily plan this hub will show, in minutes.
const int kTodayPlanMinMinutes = 10;

/// Longest daily plan this hub will show, in minutes.
const int kTodayPlanMaxMinutes = 15;

/// `type.display` size from the design tokens.
const double kTodayDisplaySize = 22;

/// `type.display` line height from the design tokens.
const double kTodayDisplayHeight = 1.25;

/// Why a Today destination has no content to show.
enum TodayUnavailableKind {
  notBuilt,
  providerAbsent,
  planOutOfRange,
  failed,
  offline,
}

/// Raised by a plan provider that cannot return a plan.
class TodayUnavailable implements Exception {
  const TodayUnavailable(this.kind);

  final TodayUnavailableKind kind;
}

/// Sitemap row on the Today hub.
enum TodayRouteKind {
  hub,
  dailyPlan,
  dailyChallenges,
  quests,
  eventsAndFestivals,
  streaks,
}

/// One registered Today route and how many taps it takes from the hub root.
class TodayRoute {
  const TodayRoute({
    required this.kind,
    required this.id,
    required this.path,
    required this.taps,
    required this.built,
  });

  final TodayRouteKind kind;

  /// Name the sitemap uses. `/today` is the hub path.
  final String id;

  final String path;

  /// Taps from the Today root. The root itself is zero.
  final int taps;

  /// False when the screen is not built yet.
  final bool built;
}

/// Registered Today routes. Every sitemap item is at most two taps.
abstract final class TodayHubRoutes {
  static const TodayRoute hub = TodayRoute(
    kind: TodayRouteKind.hub,
    id: '/today',
    path: '/today',
    taps: 0,
    built: true,
  );

  static const TodayRoute dailyPlan = TodayRoute(
    kind: TodayRouteKind.dailyPlan,
    id: 'daily plan',
    path: '/today/daily-plan',
    taps: 0,
    built: true,
  );

  static const TodayRoute dailyChallenges = TodayRoute(
    kind: TodayRouteKind.dailyChallenges,
    id: 'daily challenges',
    path: '/today/daily-challenges',
    taps: 1,
    built: false,
  );

  static const TodayRoute quests = TodayRoute(
    kind: TodayRouteKind.quests,
    id: 'quests',
    path: '/today/quests',
    taps: 1,
    built: false,
  );

  static const TodayRoute eventsAndFestivals = TodayRoute(
    kind: TodayRouteKind.eventsAndFestivals,
    id: 'events and festivals',
    path: '/today/events-and-festivals',
    taps: 1,
    built: false,
  );

  /// Lesson player is not a sitemap row. With no opener, Start shows not-available.
  static const String lessonPlayer = '/today/lesson';

  static const TodayRoute streaks = TodayRoute(
    kind: TodayRouteKind.streaks,
    id: 'streaks',
    path: '/today/streaks',
    taps: 1,
    built: false,
  );

  static const List<TodayRoute> all = <TodayRoute>[
    hub,
    dailyPlan,
    dailyChallenges,
    quests,
    eventsAndFestivals,
    streaks,
  ];

  /// Rows on the hub root. Each one is one tap.
  static const List<TodayRoute> links = <TodayRoute>[
    dailyChallenges,
    quests,
    eventsAndFestivals,
    streaks,
  ];

  static bool get withinTwoTaps =>
      all.every((TodayRoute route) => route.taps <= 2);

  static TodayRoute? resolve(String? raw) {
    if (raw == null) return null;
    final String name = raw.trim().toLowerCase();
    if (name.isEmpty) return null;
    for (final TodayRoute route in all) {
      if (route.id == name || route.path == name) return route;
    }
    return null;
  }
}

/// Finder keys for the Today hub.
abstract final class TodayHubMarks {
  static const Key plan = ValueKey<String>('today-plan');
  static const Key empty = ValueKey<String>('today-empty');
  static const Key notAvailable = ValueKey<String>('today-not-available');
  static const Key minutes = ValueKey<String>('today-minutes');
  static const Key dueReviews = ValueKey<String>('today-due-reviews');
  static const Key nextLesson = ValueKey<String>('today-next-lesson');
  static const Key lessonTitle = ValueKey<String>('today-lesson-title');
  static const Key lessonTarget = ValueKey<String>('today-lesson-target');

  static Key destination(TodayRouteKind kind) =>
      ValueKey<String>('today-destination-${kind.name}');

  static Key review(String id) => ValueKey<String>('today-review-$id');
}

/// A review the plan provider says is due. The label is the provider's own.
class TodayDueReview {
  const TodayDueReview({required this.id, required this.label});

  final String id;
  final String label;
}

/// The next lesson the plan provider chose. This hub does not invent one.
class TodayNextLesson {
  const TodayNextLesson({
    required this.id,
    required this.title,
    this.targetLine,
  });

  final String id;
  final String title;
  final String? targetLine;
}

/// What a plan provider returns. Null fields mean that part is absent.
class TodayPlan {
  const TodayPlan({
    required this.minutes,
    this.dueReviews = const <TodayDueReview>[],
    this.nextLesson,
  });

  final int minutes;
  final List<TodayDueReview> dueReviews;
  final TodayNextLesson? nextLesson;
}

/// Real daily-plan source. A missing source is not replaced with sample rows.
abstract interface class TodayPlanSource {
  /// A plan, or null when the hub has nothing queued.
  TodayPlan? load();
}

/// A plan that is allowed on screen: 10 to 15 minutes, with real rows.
class TodayShownPlan {
  const TodayShownPlan({
    required this.minutes,
    required this.dueReviews,
    required this.nextLesson,
  });

  final int minutes;
  final List<TodayDueReview> dueReviews;
  final TodayNextLesson nextLesson;
}

/// What the hub paints for the daily plan.
sealed class TodaySurface {
  const TodaySurface();
}

class TodaySurfaceReady extends TodaySurface {
  const TodaySurfaceReady(this.plan);

  final TodayShownPlan plan;
}

class TodaySurfaceEmpty extends TodaySurface {
  const TodaySurfaceEmpty();
}

class TodaySurfaceBlocked extends TodaySurface {
  const TodaySurfaceBlocked(this.kind);

  final TodayUnavailableKind kind;
}

/// Reads [source] without adding lesson rows it did not return.
TodaySurface resolveTodaySurface(TodayPlanSource? source) {
  if (source == null) {
    return const TodaySurfaceBlocked(TodayUnavailableKind.providerAbsent);
  }
  final TodayPlan? plan;
  try {
    plan = source.load();
  } on TodayUnavailable catch (error) {
    return TodaySurfaceBlocked(error.kind);
  } catch (_) {
    return const TodaySurfaceBlocked(TodayUnavailableKind.failed);
  }
  if (plan == null) return const TodaySurfaceEmpty();

  final List<TodayDueReview> reviews = <TodayDueReview>[
    for (final TodayDueReview review in plan.dueReviews)
      if (review.id.trim().isNotEmpty && review.label.trim().isNotEmpty)
        TodayDueReview(id: review.id.trim(), label: review.label.trim()),
  ];
  final TodayNextLesson? lesson = plan.nextLesson;
  final String title = lesson?.title.trim() ?? '';
  final String lessonId = lesson?.id.trim() ?? '';
  if (reviews.isEmpty && title.isEmpty) {
    return const TodaySurfaceEmpty();
  }

  final bool ranged =
      plan.minutes >= kTodayPlanMinMinutes &&
      plan.minutes <= kTodayPlanMaxMinutes;
  if (!ranged || reviews.isEmpty || title.isEmpty || lessonId.isEmpty) {
    return const TodaySurfaceBlocked(TodayUnavailableKind.planOutOfRange);
  }

  final String? target = lesson?.targetLine?.trim();
  return TodaySurfaceReady(
    TodayShownPlan(
      minutes: plan.minutes,
      dueReviews: List<TodayDueReview>.unmodifiable(reviews),
      nextLesson: TodayNextLesson(
        id: lessonId,
        title: title,
        targetLine: (target == null || target.isEmpty) ? null : target,
      ),
    ),
  );
}

/// Painted name for a registered route.
String todayRouteLabel(AppLocalizations l10n, TodayRoute route) {
  return switch (route.kind) {
    TodayRouteKind.hub => l10n.hubTodayTitle,
    TodayRouteKind.dailyPlan => l10n.hubTodayDailyPlan,
    TodayRouteKind.dailyChallenges => l10n.hubTodayDailyChallenges,
    TodayRouteKind.quests => l10n.hubTodayQuests,
    TodayRouteKind.eventsAndFestivals => l10n.hubTodayEvents,
    TodayRouteKind.streaks => l10n.hubTodayStreaks,
  };
}

/// Lines for a blocked plan or a screen that is not built yet.
class TodayBlockedCopy {
  const TodayBlockedCopy({
    required this.what,
    required this.why,
    required this.next,
    this.action,
  });

  final String what;
  final String why;
  final String next;
  final String? action;
}

TodayBlockedCopy todayBlockedCopy(
  AppLocalizations l10n,
  TodayUnavailableKind kind,
) {
  return switch (kind) {
    TodayUnavailableKind.notBuilt => TodayBlockedCopy(
      what: l10n.hubTodayNotBuiltWhat,
      why: l10n.hubTodayNotBuiltWhy,
      next: l10n.hubTodayNotBuiltNext,
      action: l10n.hubTodayBack,
    ),
    TodayUnavailableKind.providerAbsent => TodayBlockedCopy(
      what: l10n.hubTodayProviderWhat,
      why: l10n.hubTodayProviderWhy,
      next: l10n.hubTodayProviderNext,
    ),
    TodayUnavailableKind.planOutOfRange => TodayBlockedCopy(
      what: l10n.hubTodayRangeWhat,
      why: l10n.hubTodayRangeWhy,
      next: l10n.hubTodayRangeNext,
    ),
    TodayUnavailableKind.failed => TodayBlockedCopy(
      what: l10n.hubTodayErrorWhat,
      why: l10n.hubTodayErrorWhy,
      next: l10n.hubTodayErrorNext,
      action: l10n.commonActionTryAgain,
    ),
    TodayUnavailableKind.offline => TodayBlockedCopy(
      what: l10n.hubTodayOfflineWhat,
      why: l10n.hubTodayOfflineWhy,
      next: l10n.hubTodayOfflineNext,
      action: l10n.commonActionTryAgain,
    ),
  };
}

/// Which anatomy the page is showing.
enum TodaySurfaceKind { ready, empty, notAvailable, error, offline }

TodaySurfaceKind todaySurfaceKind(TodaySurface surface) {
  return switch (surface) {
    TodaySurfaceReady() => TodaySurfaceKind.ready,
    TodaySurfaceEmpty() => TodaySurfaceKind.empty,
    TodaySurfaceBlocked(:final kind) => switch (kind) {
      TodayUnavailableKind.failed => TodaySurfaceKind.error,
      TodayUnavailableKind.offline => TodaySurfaceKind.offline,
      TodayUnavailableKind.notBuilt ||
      TodayUnavailableKind.providerAbsent ||
      TodayUnavailableKind.planOutOfRange => TodaySurfaceKind.notAvailable,
    },
  };
}

/// Typed reason when [surface] is not a ready or empty plan.
TodayUnavailableKind? todaySurfaceReason(TodaySurface surface) {
  return switch (surface) {
    TodaySurfaceReady() => null,
    TodaySurfaceEmpty() => null,
    TodaySurfaceBlocked(:final kind) => kind,
  };
}

/// Exposes the typed surface to a test without adding visible copy.
class TodayStateMark extends StatelessWidget {
  const TodayStateMark({
    required this.kind,
    required this.child,
    this.reason,
    super.key,
  });

  final TodaySurfaceKind kind;
  final TodayUnavailableKind? reason;
  final Widget child;

  @override
  Widget build(BuildContext context) => child;
}
