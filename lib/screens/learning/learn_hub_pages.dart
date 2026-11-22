import 'package:flutter/material.dart';
import 'package:lingafriq/design/components/ling_state.dart';
import 'package:lingafriq/design/states/empty_state.dart';
import 'package:lingafriq/design/states/error_state.dart';
import 'package:lingafriq/design/states/offline_state.dart';
import 'package:lingafriq/design/tokens.g.dart';
import 'package:lingafriq/l10n/generated/app_localizations.dart';
import 'package:lingafriq/l10n/l10n_of.dart';
import 'package:lingafriq/navigation/hub_learn.dart';

/// Builds the page for a registered or unknown Learn route.
Widget buildLearnPage({
  required String route,
  required List<LearnUnit> units,
  required LearnHubStatus status,
  required VoidCallback? onRetry,
}) {
  if (status == LearnHubStatus.error) {
    return LearnStatusPage(route: route, status: status, onRetry: onRetry);
  }
  if (status == LearnHubStatus.offline) {
    return LearnStatusPage(route: route, status: status, onRetry: onRetry);
  }
  final LearnPlace? place = learnPlaceFor(route);
  if (place == null) {
    return LearnNotAvailablePage(route: route);
  }
  return switch (learnScreenKind(place)) {
    LearnScreenKind.hub => LearnRootPage(units: units),
    LearnScreenKind.path => LearnPathPage(units: units, onRetry: onRetry),
    LearnScreenKind.grammar => const LearnGrammarPage(),
    LearnScreenKind.culture => const LearnCulturePage(),
    LearnScreenKind.notAvailable => LearnNotAvailablePage(
      route: route,
      place: place,
    ),
  };
}

String learnPlaceLabel(AppLocalizations l10n, LearnPlace place) {
  return switch (place) {
    LearnPlace.hub => l10n.shellTabLearn,
    LearnPlace.path => l10n.hubLearnPathAndLessons,
    LearnPlace.lesson => l10n.hubLearnPathAndLessons,
    LearnPlace.recap => l10n.hubLearnLessonRecap,
    LearnPlace.words => l10n.hubLearnWordsAndReview,
    LearnPlace.reviewDashboard => l10n.revRvLearnReviewDashboard,
    LearnPlace.vocabDashboard => l10n.revRvLearnVocabDashboard,
    LearnPlace.reviewRush => l10n.hubLearnReviewRush,
    LearnPlace.grammar => l10n.hubLearnGrammar,
    LearnPlace.phraseDna => l10n.hubLearnPhraseDna,
    LearnPlace.listening => l10n.hubLearnListening,
    LearnPlace.writing => l10n.hubLearnWriting,
    LearnPlace.toneGym => l10n.hubLearnToneGym,
    LearnPlace.culture => l10n.hubLearnCultureShelf,
    LearnPlace.magazine => l10n.hubLearnMagazine,
    LearnPlace.heritage => l10n.hubLearnHeritage,
    LearnPlace.history => l10n.hubLearnHistory,
    LearnPlace.mannerisms => l10n.hubLearnMannerisms,
    LearnPlace.culturalHub => l10n.hubLearnCulturalHub,
    LearnPlace.passport => l10n.hubLearnPassport,
    LearnPlace.downloads => l10n.hubLearnDownloads,
  };
}

List<Widget> _withGaps(List<Widget> children) {
  final List<Widget> spaced = <Widget>[];
  for (var index = 0; index < children.length; index += 1) {
    if (index > 0) {
      spaced.add(const SizedBox(height: LingAfriqTokens.spacing16));
    }
    spaced.add(children[index]);
  }
  return spaced;
}

class LearnPageBody extends StatelessWidget {
  const LearnPageBody({required this.route, required this.children, super.key});

  final String route;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final LingPalette palette = LingPalette.of(Theme.of(context).brightness);
    return Material(
      key: LearnHubKeys.route(route),
      color: palette.surface,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(LingAfriqTokens.spacing16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: _withGaps(children),
          ),
        ),
      ),
    );
  }
}

class LearnDestinationButton extends StatelessWidget {
  const LearnDestinationButton({
    required this.label,
    required this.onPressed,
    super.key,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final LingPalette palette = LingPalette.of(Theme.of(context).brightness);
    return Semantics(
      container: true,
      button: true,
      label: label,
      onTap: onPressed,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: LingAfriqTokens.spacing48,
          minHeight: LingAfriqTokens.spacing48,
        ),
        child: InkWell(
          excludeFromSemantics: true,
          onTap: onPressed,
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: ExcludeSemantics(
              child: Text(
                label,
                softWrap: true,
                overflow: TextOverflow.visible,
                style: lingBody(palette.onSurface),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class LearnBackButton extends StatelessWidget {
  const LearnBackButton({super.key});

  @override
  Widget build(BuildContext context) {
    return LearnDestinationButton(
      label: l10nOf(context).hubLearnBack,
      onPressed: () => learnBackToRoot(context),
    );
  }
}

class LearnRootPage extends StatelessWidget {
  const LearnRootPage({required this.units, super.key});

  final List<LearnUnit> units;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = l10nOf(context);
    final List<Widget> children = <Widget>[
      if (units.isEmpty)
        LingEmptyState(
          key: LearnHubKeys.empty,
          title: l10n.hubLearnEmptyTitle,
          whatHappened: l10n.hubLearnEmptyWhat,
          why: l10n.hubLearnEmptyWhy,
          whatToDo: l10n.hubLearnEmptyNext,
          actionLabel: l10n.hubLearnOpenPath,
          unavailableLabel: l10n.commonStateUnavailable,
          onAction: () {
            Navigator.of(context).pushNamed(LearnRoutes.path);
          },
        ),
      for (final LearnDestination destination in learnRootDestinations())
        LearnDestinationButton(
          key: LearnHubKeys.row(destination.place),
          label: learnPlaceLabel(l10n, destination.place),
          onPressed: () => openLearnPlace(context, destination.place),
        ),
    ];
    return LearnPageBody(route: LearnRoutes.hub, children: children);
  }
}

class LearnPathPage extends StatelessWidget {
  const LearnPathPage({required this.units, required this.onRetry, super.key});

  final List<LearnUnit> units;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = l10nOf(context);
    final LingPalette palette = LingPalette.of(Theme.of(context).brightness);
    final List<Widget> children = <Widget>[const LearnBackButton()];
    if (units.isEmpty) {
      children.add(
        LingEmptyState(
          key: LearnHubKeys.empty,
          title: l10n.hubLearnPathEmptyTitle,
          whatHappened: l10n.hubLearnPathEmptyWhat,
          why: l10n.hubLearnPathEmptyWhy,
          whatToDo: l10n.hubLearnPathEmptyNext,
          actionLabel: l10n.commonActionTryAgain,
          unavailableLabel: l10n.commonStateUnavailable,
          onAction: onRetry ?? () {},
        ),
      );
    } else {
      for (final LearnCefrGroup group in groupLearnUnitsByCefr(units)) {
        final String levelLabel = group.level.isEmpty
            ? l10n.hubLearnLevelNotSet
            : l10n.hubLearnLevel(group.level);
        children.add(
          Semantics(
            key: LearnHubKeys.level(group.level),
            header: true,
            label: levelLabel,
            child: ExcludeSemantics(
              child: Text(
                levelLabel,
                softWrap: true,
                overflow: TextOverflow.visible,
                style: lingBody(palette.onSurface),
              ),
            ),
          ),
        );
        for (final LearnUnit unit in group.units) {
          children.add(
            Text(
              _shownName(unit.title, unit.id),
              key: LearnHubKeys.unit(unit.id),
              softWrap: true,
              overflow: TextOverflow.visible,
              style: lingBody(palette.onSurfaceVariant),
            ),
          );
          for (final LearnLesson lesson in unit.lessons) {
            final String name = _shownName(lesson.title, lesson.id);
            if (name.isEmpty) continue;
            children.add(
              LearnDestinationButton(
                key: LearnHubKeys.lesson(lesson.id),
                label: name,
                onPressed: () {
                  Navigator.of(
                    context,
                  ).pushNamed(LearnRoutes.lesson, arguments: lesson.id);
                },
              ),
            );
          }
        }
      }
    }
    return LearnPageBody(route: LearnRoutes.path, children: children);
  }
}

class LearnGrammarPage extends StatelessWidget {
  const LearnGrammarPage({super.key});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = l10nOf(context);
    return LearnPageBody(
      route: LearnRoutes.grammar,
      children: <Widget>[
        const LearnBackButton(),
        LingEmptyState(
          key: LearnHubKeys.empty,
          title: l10n.hubLearnGrammarEmptyTitle,
          whatHappened: l10n.hubLearnGrammarEmptyWhat,
          why: l10n.hubLearnGrammarEmptyWhy,
          whatToDo: l10n.hubLearnGrammarEmptyNext,
          actionLabel: l10n.hubLearnOpenPath,
          unavailableLabel: l10n.commonStateUnavailable,
          onAction: () {
            Navigator.of(context).pushNamed(LearnRoutes.path);
          },
        ),
        for (final LearnDestination destination in learnStaticChildren(
          LearnPlace.grammar,
        ))
          LearnDestinationButton(
            key: LearnHubKeys.row(destination.place),
            label: learnPlaceLabel(l10n, destination.place),
            onPressed: () => openLearnPlace(context, destination.place),
          ),
      ],
    );
  }
}

class LearnCulturePage extends StatelessWidget {
  const LearnCulturePage({super.key});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = l10nOf(context);
    return LearnPageBody(
      route: LearnRoutes.culture,
      children: <Widget>[
        const LearnBackButton(),
        for (final LearnDestination destination in learnStaticChildren(
          LearnPlace.culture,
        ))
          LearnDestinationButton(
            key: LearnHubKeys.row(destination.place),
            label: learnPlaceLabel(l10n, destination.place),
            onPressed: () => openLearnPlace(context, destination.place),
          ),
      ],
    );
  }
}

/// Typed not-available state. The page renders only this copy.
class LearnNotAvailablePage extends StatelessWidget {
  const LearnNotAvailablePage({required this.route, this.place, super.key});

  final String route;
  final LearnPlace? place;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = l10nOf(context);
    final LingPalette palette = LingPalette.of(Theme.of(context).brightness);
    final TextStyle ink = lingBody(palette.onSurface);
    return LearnPageBody(
      key: LearnHubKeys.notAvailable,
      route: route,
      children: <Widget>[
        const LearnBackButton(),
        Text(
          l10n.shellNotAvailableYet,
          softWrap: true,
          overflow: TextOverflow.visible,
          style: ink,
        ),
        Text(
          l10n.hubLearnNotAvailableWhat,
          softWrap: true,
          overflow: TextOverflow.visible,
          style: ink,
        ),
        Text(
          l10n.hubLearnNotAvailableWhy,
          softWrap: true,
          overflow: TextOverflow.visible,
          style: lingBody(palette.onSurfaceVariant),
        ),
        Text(
          l10n.hubLearnNotAvailableNext,
          softWrap: true,
          overflow: TextOverflow.visible,
          style: lingBody(palette.onSurfaceVariant),
        ),
      ],
    );
  }
}

class LearnStatusPage extends StatelessWidget {
  const LearnStatusPage({
    required this.route,
    required this.status,
    required this.onRetry,
    super.key,
  });

  final String route;
  final LearnHubStatus status;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = l10nOf(context);
    final Widget body = status == LearnHubStatus.offline
        ? LingOfflineState(
            whatHappened: l10n.shellOfflineWhat,
            why: l10n.hubLearnOfflineWhy,
            whatToDo: l10n.hubLearnOfflineNext,
            queuedActions: 0,
            actionLabel: l10n.commonActionTryAgain,
            unavailableLabel: l10n.commonStateUnavailable,
            onAction: onRetry ?? () {},
          )
        : LingErrorState(
            whatHappened: l10n.hubLearnErrorWhat,
            why: l10n.hubLearnErrorWhy,
            whatToDo: l10n.hubLearnErrorNext,
            actionLabel: l10n.commonActionTryAgain,
            unavailableLabel: l10n.commonStateUnavailable,
            onAction: onRetry ?? () {},
          );
    return LearnPageBody(route: route, children: <Widget>[body]);
  }
}

String _shownName(String title, String id) {
  final String trimmed = title.trim();
  if (trimmed.isNotEmpty) return trimmed;
  return id.trim();
}
