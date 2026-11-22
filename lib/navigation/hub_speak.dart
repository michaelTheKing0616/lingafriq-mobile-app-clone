import 'package:flutter/material.dart';
import 'package:lingafriq/design/components/ling_button.dart';
import 'package:lingafriq/design/components/ling_state.dart';
import 'package:lingafriq/design/states/empty_state.dart';
import 'package:lingafriq/design/states/error_state.dart';
import 'package:lingafriq/design/states/offline_state.dart';
import 'package:lingafriq/design/tokens.g.dart';
import 'package:lingafriq/l10n/generated/app_localizations.dart';
import 'package:lingafriq/l10n/l10n_of.dart';
import 'package:lingafriq/screens/ai_chat/polie_workspace_screen.dart';

/// How far a Speak place is built.
///
/// [notAvailable] opens [SpeakNotAvailable]. It does not invent rows.
enum SpeakPlaceKind { ready, notAvailable }

/// One registered Speak place. [id] is a route key, not learner copy.
class SpeakPlace {
  const SpeakPlace({
    required this.id,
    required this.path,
    required this.kind,
    this.onRoot = true,
  });

  final String id;
  final String path;
  final SpeakPlaceKind kind;

  /// Shown on the Speak root. A deeper place stays registered.
  final bool onRoot;
}

/// A place that is not built. The only field is which place was opened.
class SpeakNotAvailable {
  const SpeakNotAvailable(this.placeId);

  final String placeId;
}

/// What opening a registered path does. The gap carries no sample content.
sealed class SpeakOpening {
  const SpeakOpening();
}

final class SpeakHubOpening extends SpeakOpening {
  const SpeakHubOpening();
}

final class SpeakPolieOpening extends SpeakOpening {
  const SpeakPolieOpening();
}

final class SpeakGapOpening extends SpeakOpening {
  const SpeakGapOpening(this.gap);

  final SpeakNotAvailable gap;
}

final class SpeakUnknownOpening extends SpeakOpening {
  const SpeakUnknownOpening(this.path);

  final String path;
}

/// Speak root, or a load that has no list, failed, or has no network.
enum SpeakHubStatus { ready, empty, error, offline }

/// Routes for the Speak sitemap. Tutor modes are chips on [SpeakRoutes.polie].
abstract final class SpeakRoutes {
  static const String root = '/speak';
  static const String polie = '/speak/polie';
  static const String scenarios = '/speak/scenarios';
  static const String personas = '/speak/personas';
  static const String mission = '/speak/personas/mission';
  static const String shadowing = '/speak/shadowing';
  static const String codeSwitch = '/speak/code-switch';
  static const String missions = '/speak/missions';
  static const String coachInsights = '/speak/coach-insights';

  static const List<String> paths = <String>[
    root,
    polie,
    scenarios,
    personas,
    mission,
    shadowing,
    codeSwitch,
    missions,
    coachInsights,
  ];

  /// Sitemap order. Polie is ready. The other places are not built yet.
  static const List<SpeakPlace> places = <SpeakPlace>[
    SpeakPlace(id: 'polie', path: polie, kind: SpeakPlaceKind.ready),
    SpeakPlace(
      id: 'scenarios',
      path: scenarios,
      kind: SpeakPlaceKind.notAvailable,
    ),
    SpeakPlace(
      id: 'personas',
      path: personas,
      kind: SpeakPlaceKind.notAvailable,
    ),
    SpeakPlace(
      id: 'mission',
      path: mission,
      kind: SpeakPlaceKind.notAvailable,
      onRoot: false,
    ),
    SpeakPlace(
      id: 'shadowing',
      path: shadowing,
      kind: SpeakPlaceKind.notAvailable,
    ),
    SpeakPlace(
      id: 'codeSwitch',
      path: codeSwitch,
      kind: SpeakPlaceKind.notAvailable,
    ),
    SpeakPlace(
      id: 'missions',
      path: missions,
      kind: SpeakPlaceKind.notAvailable,
    ),
    SpeakPlace(
      id: 'coach',
      path: coachInsights,
      kind: SpeakPlaceKind.notAvailable,
    ),
  ];

  static List<SpeakPlace> get rootPlaces =>
      places.where((SpeakPlace place) => place.onRoot).toList(growable: false);

  static bool isRegistered(String path) => paths.contains(path);

  static SpeakPlace? find(String path) {
    for (final SpeakPlace place in places) {
      if (place.path == path) return place;
    }
    return null;
  }

  /// Taps from the Speak root. The root is 0. A missed path is -1.
  static int tapsFromRoot(String path) {
    if (path == root) return 0;
    if (!isRegistered(path)) return -1;
    final int parts = path
        .split('/')
        .where((String part) => part.isNotEmpty)
        .length;
    return parts - 1;
  }

  static SpeakOpening openingFor(String path) {
    if (path == root) return const SpeakHubOpening();
    if (path == polie) return const SpeakPolieOpening();
    final SpeakPlace? place = find(path);
    if (place == null) return SpeakUnknownOpening(path);
    if (place.kind == SpeakPlaceKind.notAvailable) {
      return SpeakGapOpening(SpeakNotAvailable(place.id));
    }
    return const SpeakPolieOpening();
  }

  static Route<void> onGenerate(RouteSettings settings) {
    final String path = settings.name ?? root;
    return MaterialPageRoute<void>(
      settings: RouteSettings(name: path, arguments: settings.arguments),
      builder: (BuildContext context) => _pageFor(context, path),
    );
  }
}

String speakPlaceLabel(AppLocalizations l10n, String placeId) {
  return switch (placeId) {
    'polie' => l10n.hubHSpeakPolie,
    'scenarios' => l10n.hubHSpeakScenarios,
    'personas' => l10n.hubHSpeakPersonas,
    'mission' => l10n.hubHSpeakPersonas,
    'shadowing' => l10n.hubHSpeakShadowing,
    'codeSwitch' => l10n.hubHSpeakCodeSwitch,
    'missions' => l10n.hubHSpeakMissions,
    'coach' => l10n.hubHSpeakCoach,
    _ => l10n.hubHSpeakNotAvailableTitle,
  };
}

void _speakBack(BuildContext context) {
  final NavigatorState nav = Navigator.of(context);
  if (nav.canPop()) {
    nav.pop();
    return;
  }
  nav.pushReplacementNamed(SpeakRoutes.root);
}

Widget _pageFor(BuildContext context, String routePath) {
  final SpeakOpening opening = SpeakRoutes.openingFor(routePath);
  return switch (opening) {
    SpeakHubOpening() => const SpeakHubPage(),
    SpeakPolieOpening() => SpeakPolieScreen(onBack: () => _speakBack(context)),
    SpeakGapOpening(:final gap) => SpeakNotAvailablePage(gap: gap),
    SpeakUnknownOpening(:final path) => SpeakUnknownPage(path: path),
  };
}

/// Speak hub. Each tab of the shell can host this navigator on its own stack.
class SpeakHub extends StatelessWidget {
  const SpeakHub({
    super.key,
    this.status = SpeakHubStatus.ready,
    this.initialRoute = SpeakRoutes.root,
    this.onRetry,
  });

  static Key placeKey(String id) => ValueKey<String>('speak-place-$id');

  static const Key emptyKey = ValueKey<String>('speak-hub-empty');

  static const Key errorKey = ValueKey<String>('speak-hub-error');

  static const Key offlineKey = ValueKey<String>('speak-hub-offline');

  static const Key gapKey = ValueKey<String>('speak-not-available');

  final SpeakHubStatus status;

  final String initialRoute;

  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return _SpeakHubData(
      status: status,
      onRetry: onRetry,
      child: Navigator(
        initialRoute: initialRoute,
        onGenerateRoute: SpeakRoutes.onGenerate,
      ),
    );
  }
}

/// Live hub status. The route is created once, so the page reads this.
class _SpeakHubData extends InheritedWidget {
  const _SpeakHubData({
    required this.status,
    required this.onRetry,
    required super.child,
  });

  final SpeakHubStatus status;
  final VoidCallback? onRetry;

  static _SpeakHubData of(BuildContext context) {
    final _SpeakHubData? data = context
        .dependOnInheritedWidgetOfExactType<_SpeakHubData>();
    assert(data != null, 'Speak pages are built under SpeakHub.');
    return data!;
  }

  @override
  bool updateShouldNotify(_SpeakHubData oldWidget) {
    return status != oldWidget.status || onRetry != oldWidget.onRetry;
  }
}

/// Root of [SpeakRoutes.root].
class SpeakHubPage extends StatelessWidget {
  const SpeakHubPage({super.key});

  @override
  Widget build(BuildContext context) {
    final _SpeakHubData data = _SpeakHubData.of(context);
    final SpeakHubStatus status = data.status;
    final VoidCallback? onRetry = data.onRetry;
    final AppLocalizations l10n = l10nOf(context);
    final LingPalette palette = LingPalette.of(Theme.of(context).brightness);
    final Widget body = switch (status) {
      SpeakHubStatus.ready => _ready(context, l10n, palette),
      SpeakHubStatus.empty => _empty(context, l10n),
      SpeakHubStatus.error => _error(l10n, onRetry),
      SpeakHubStatus.offline => _offline(l10n, onRetry),
    };
    return Scaffold(
      backgroundColor: palette.surface,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(LingAfriqTokens.spacing16),
          children: <Widget>[
            if (status != SpeakHubStatus.empty) ...<Widget>[
              Text(
                l10n.hubHSpeakTitle,
                style: lingBody(palette.onSurface),
                softWrap: true,
                overflow: TextOverflow.visible,
              ),
              const SizedBox(height: LingAfriqTokens.spacing16),
            ],
            body,
          ],
        ),
      ),
    );
  }

  Widget _ready(
    BuildContext context,
    AppLocalizations l10n,
    LingPalette palette,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (final SpeakPlace place in SpeakRoutes.rootPlaces)
          Padding(
            padding: const EdgeInsets.only(bottom: LingAfriqTokens.spacing8),
            child: _PlaceButton(place: place, palette: palette, l10n: l10n),
          ),
      ],
    );
  }

  Widget _empty(BuildContext context, AppLocalizations l10n) {
    return LingEmptyState(
      key: SpeakHub.emptyKey,
      title: l10n.hubHSpeakTitle,
      whatHappened: l10n.hubHSpeakEmptyWhat,
      why: l10n.hubHSpeakEmptyWhy,
      whatToDo: l10n.hubHSpeakEmptyNext,
      actionLabel: l10n.hubHSpeakOpenPolie,
      unavailableLabel: l10n.commonStateUnavailable,
      onAction: () {
        Navigator.of(context).pushNamed(SpeakRoutes.polie);
      },
    );
  }

  Widget _error(AppLocalizations l10n, VoidCallback? onRetry) {
    return LingErrorState(
      key: SpeakHub.errorKey,
      whatHappened: l10n.hubHSpeakErrorWhat,
      why: l10n.hubHSpeakErrorWhy,
      whatToDo: l10n.hubHSpeakErrorNext,
      actionLabel: l10n.commonActionTryAgain,
      unavailableLabel: l10n.commonStateUnavailable,
      onAction: onRetry ?? () {},
    );
  }

  Widget _offline(AppLocalizations l10n, VoidCallback? onRetry) {
    return LingOfflineState(
      key: SpeakHub.offlineKey,
      whatHappened: l10n.shellOfflineWhat,
      why: l10n.hubHSpeakOfflineWhy,
      whatToDo: l10n.shellOfflineNext,
      queuedActions: 0,
      actionLabel: l10n.commonActionTryAgain,
      unavailableLabel: l10n.commonStateUnavailable,
      onAction: onRetry ?? () {},
    );
  }
}

class _PlaceButton extends StatelessWidget {
  const _PlaceButton({
    required this.place,
    required this.palette,
    required this.l10n,
  });

  final SpeakPlace place;
  final LingPalette palette;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final String label = speakPlaceLabel(l10n, place.id);
    return Semantics(
      key: SpeakHub.placeKey(place.id),
      container: true,
      button: true,
      label: label,
      onTap: () => Navigator.of(context).pushNamed(place.path),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: LingAfriqTokens.spacing48),
        child: Material(
          color: palette.surfaceContainer,
          borderRadius: const BorderRadius.all(
            Radius.circular(LingAfriqTokens.radiussm),
          ),
          child: InkWell(
            customBorder: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(
                Radius.circular(LingAfriqTokens.radiussm),
              ),
            ),
            excludeFromSemantics: true,
            onTap: () => Navigator.of(context).pushNamed(place.path),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: LingAfriqTokens.spacing16,
                vertical: LingAfriqTokens.spacing12,
              ),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: ExcludeSemantics(
                  child: Text(
                    label,
                    style: lingBody(palette.onSurface),
                    softWrap: true,
                    overflow: TextOverflow.visible,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Typed gap for a Speak place that is not built. No sample rows are painted.
class SpeakNotAvailablePage extends StatelessWidget {
  const SpeakNotAvailablePage({required this.gap, super.key});

  final SpeakNotAvailable gap;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = l10nOf(context);
    final LingPalette palette = LingPalette.of(Theme.of(context).brightness);
    final String name = speakPlaceLabel(l10n, gap.placeId);
    return Scaffold(
      key: SpeakHub.gapKey,
      backgroundColor: palette.surface,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(LingAfriqTokens.spacing16),
          children: <Widget>[
            Text(
              name,
              style: lingBody(palette.onSurface),
              softWrap: true,
              overflow: TextOverflow.visible,
            ),
            const SizedBox(height: LingAfriqTokens.spacing16),
            Text(
              l10n.hubHSpeakNotAvailableTitle,
              style: lingBody(palette.onSurface),
              softWrap: true,
              overflow: TextOverflow.visible,
            ),
            const SizedBox(height: LingAfriqTokens.spacing16),
            Text(
              l10n.hubHSpeakNotAvailableWhat(name),
              style: lingBody(palette.onSurfaceVariant),
              softWrap: true,
              overflow: TextOverflow.visible,
            ),
            const SizedBox(height: LingAfriqTokens.spacing16),
            Text(
              l10n.hubHSpeakNotAvailableWhy,
              style: lingBody(palette.onSurfaceVariant),
              softWrap: true,
              overflow: TextOverflow.visible,
            ),
            const SizedBox(height: LingAfriqTokens.spacing16),
            Text(
              l10n.hubHSpeakNotAvailableNext,
              style: lingBody(palette.onSurfaceVariant),
              softWrap: true,
              overflow: TextOverflow.visible,
            ),
            const SizedBox(height: LingAfriqTokens.spacing16),
            LingButton(
              label: l10n.hubHSpeakBack,
              unavailableLabel: l10n.commonStateUnavailable,
              onPressed: () => _speakBack(context),
            ),
          ],
        ),
      ),
    );
  }
}

/// A path that is not in [SpeakRoutes.paths].
class SpeakUnknownPage extends StatelessWidget {
  const SpeakUnknownPage({required this.path, super.key});

  final String path;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = l10nOf(context);
    final LingPalette palette = LingPalette.of(Theme.of(context).brightness);
    final String shown = path.trim().isEmpty ? l10n.shellLinkWasEmpty : path;
    return Scaffold(
      backgroundColor: palette.surface,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(LingAfriqTokens.spacing16),
          children: <Widget>[
            LingErrorState(
              whatHappened: l10n.shellLinkMissedWhat,
              why: l10n.shellLinkMissedWhy(shown),
              whatToDo: l10n.hubHSpeakNotAvailableNext,
              actionLabel: l10n.hubHSpeakBack,
              unavailableLabel: l10n.commonStateUnavailable,
              onAction: () => _speakBack(context),
            ),
          ],
        ),
      ),
    );
  }
}
