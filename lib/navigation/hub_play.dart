import 'package:flutter/material.dart';
import 'package:lingafriq/design/components/ling_button.dart';
import 'package:lingafriq/design/components/ling_state.dart';
import 'package:lingafriq/design/states/empty_state.dart';
import 'package:lingafriq/design/states/error_state.dart';
import 'package:lingafriq/design/states/offline_state.dart';
import 'package:lingafriq/design/tokens.g.dart';
import 'package:lingafriq/games/gamekit/play_shelves.dart';
import 'package:lingafriq/games/tone_forge/tone_forge_screen.dart';
import 'package:lingafriq/l10n/generated/app_localizations.dart';
import 'package:lingafriq/l10n/l10n_of.dart';
import 'package:lingafriq/screens/games/game_mastery_results_screen.dart';

/// Play root, or a load that has no list, failed, or has no network.
enum PlayHubStatus { ready, empty, error, offline }

/// A place that is not built. The only field is which place was opened.
class PlayNotAvailable {
  const PlayNotAvailable(this.placeId);

  final String placeId;
}

/// What opening a registered path does. A gap carries no sample content.
sealed class PlayOpening {
  const PlayOpening();
}

final class PlayHubOpening extends PlayOpening {
  const PlayHubOpening();
}

final class PlayShelfOpening extends PlayOpening {
  const PlayShelfOpening(this.shelf);

  final PlayShelfId shelf;
}

final class PlayToneForgeOpening extends PlayOpening {
  const PlayToneForgeOpening();
}

final class PlayMasteryResultsOpening extends PlayOpening {
  const PlayMasteryResultsOpening();
}

final class PlayGapOpening extends PlayOpening {
  const PlayGapOpening(this.gap);

  final PlayNotAvailable gap;
}

final class PlayUnknownOpening extends PlayOpening {
  const PlayUnknownOpening(this.path);

  final String path;
}

/// Routes for the Play sitemap. A game is two taps: shelf, then the game.
abstract final class PlayRoutes {
  static const String root = '/play';
  static const String toneForge = '/play/tone-forge';
  static const String masteryResults = '/play/mastery-results';

  static const String toneForgeId = 'tone-forge';
  static const String masteryResultsId = 'mastery-results';

  static List<String> get shelfPaths => <String>[
    for (final PlayShelfId shelf in kPlayShelfOrder) shelf.path,
  ];

  static List<String> get gamePaths => <String>[
    for (final PlayShelfGame game in kPlayShelfGames) game.path,
  ];

  static List<String> get paths => <String>[
    root,
    ...shelfPaths,
    toneForge,
    masteryResults,
    ...gamePaths,
  ];

  static bool isRegistered(String path) => paths.contains(path);

  static PlayShelfId? shelfForPath(String path) {
    for (final PlayShelfId shelf in kPlayShelfOrder) {
      if (shelf.path == path) return shelf;
    }
    return null;
  }

  static PlayShelfGame? gameForPath(String path) {
    for (final PlayShelfGame game in kPlayShelfGames) {
      if (game.path == path) return game;
    }
    return null;
  }

  /// Taps from the Play root. The root is 0. A missed path is -1.
  static int tapsFromRoot(String path) {
    if (path == root) return 0;
    if (!isRegistered(path)) return -1;
    final int parts = path
        .split('/')
        .where((String part) => part.isNotEmpty)
        .length;
    return parts - 1;
  }

  static PlayOpening openingFor(String path) {
    if (path == root) return const PlayHubOpening();
    final PlayShelfId? shelf = shelfForPath(path);
    if (shelf != null) return PlayShelfOpening(shelf);
    if (path == toneForge) return const PlayToneForgeOpening();
    if (path == masteryResults) return const PlayMasteryResultsOpening();
    final PlayShelfGame? game = gameForPath(path);
    if (game != null) return PlayGapOpening(PlayNotAvailable(game.key));
    return PlayUnknownOpening(path);
  }

  static Route<void> onGenerate(RouteSettings settings) {
    final String path = settings.name ?? root;
    return MaterialPageRoute<void>(
      settings: RouteSettings(name: path, arguments: settings.arguments),
      builder: (BuildContext context) => _pageFor(context, path),
    );
  }
}

String playShelfLabel(AppLocalizations l10n, PlayShelfId shelf) {
  return switch (shelf) {
    PlayShelfId.toneAndSound => l10n.hubHPlayShelfTone,
    PlayShelfId.words => l10n.hubHPlayShelfWords,
    PlayShelfId.grammar => l10n.hubHPlayShelfGrammar,
    PlayShelfId.speaking => l10n.hubHPlayShelfSpeaking,
    PlayShelfId.culture => l10n.hubHPlayShelfCulture,
    PlayShelfId.traditional => l10n.hubHPlayShelfTraditional,
    PlayShelfId.multiplayer => l10n.hubHPlayShelfMultiplayer,
  };
}

String playGameLabel(AppLocalizations l10n, String key) {
  return switch (key) {
    'games' => l10n.hubHPlayGameGames,
    'challenge-friend' => l10n.hubHPlayGameChallengeFriend,
    'flashcard-focus' => l10n.hubHPlayGameFlashcardFocus,
    'games_api_languages' => l10n.hubHPlayGameApiLanguages,
    'games_enhanced_catalog' => l10n.hubHPlayGameEnhancedCatalog,
    'matching-pairs' => l10n.hubHPlayGameMatchingPairs,
    _ => l10n.hubHPlayNotAvailableTitle,
  };
}

String playPlaceLabel(AppLocalizations l10n, String placeId) {
  for (final PlayShelfId shelf in kPlayShelfOrder) {
    if (shelf.segment == placeId) return playShelfLabel(l10n, shelf);
  }
  if (placeId == PlayRoutes.toneForgeId) return l10n.hubHPlayToneForge;
  if (placeId == PlayRoutes.masteryResultsId) {
    return l10n.revRvPlayMasteryTitle;
  }
  if (playGameByKey(placeId) != null) return playGameLabel(l10n, placeId);
  return l10n.hubHPlayNotAvailableTitle;
}

void playBackToRoot(BuildContext context) {
  final NavigatorState navigator = Navigator.of(context);
  var found = false;
  navigator.popUntil((Route<dynamic> route) {
    if (route.settings.name == PlayRoutes.root) {
      found = true;
      return true;
    }
    return route.isFirst;
  });
  if (!found) {
    navigator.pushReplacementNamed(PlayRoutes.root);
  }
}

Widget _pageFor(BuildContext context, String routePath) {
  final PlayOpening opening = PlayRoutes.openingFor(routePath);
  return switch (opening) {
    PlayHubOpening() => const PlayHubPage(),
    PlayShelfOpening(:final shelf) => PlayShelfPage(shelf: shelf),
    PlayToneForgeOpening() => ToneForgeScreen.play(
      onBack: () => playBackToRoot(context),
    ),
    PlayMasteryResultsOpening() => GameMasteryResultsScreen.play(
      onDone: () => playBackToRoot(context),
    ),
    PlayGapOpening(:final gap) => PlayNotAvailablePage(gap: gap),
    PlayUnknownOpening(:final path) => PlayUnknownPage(path: path),
  };
}

/// Play hub. Each tab of the shell can host this navigator on its own stack.
class PlayHub extends StatelessWidget {
  const PlayHub({
    super.key,
    this.status = PlayHubStatus.ready,
    this.initialRoute = PlayRoutes.root,
    this.onRetry,
  });

  static Key shelfKey(PlayShelfId shelf) =>
      ValueKey<String>('play-shelf-${shelf.segment}');

  static Key gameKey(String key) => ValueKey<String>('play-game-$key');

  static const Key toneForgeKey = ValueKey<String>('play-tone-forge');

  static const Key masteryResultsKey = ValueKey<String>('play-mastery-results');

  static const Key emptyKey = ValueKey<String>('play-hub-empty');

  static const Key errorKey = ValueKey<String>('play-hub-error');

  static const Key offlineKey = ValueKey<String>('play-hub-offline');

  static const Key gapKey = ValueKey<String>('play-not-available');

  static const Key shelfEmptyKey = ValueKey<String>('play-shelf-empty');

  final PlayHubStatus status;

  final String initialRoute;

  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return _PlayHubData(
      status: status,
      onRetry: onRetry,
      child: Navigator(
        initialRoute: initialRoute,
        onGenerateRoute: PlayRoutes.onGenerate,
      ),
    );
  }
}

/// Live hub status. The route is created once, so the page reads this.
class _PlayHubData extends InheritedWidget {
  const _PlayHubData({
    required this.status,
    required this.onRetry,
    required super.child,
  });

  final PlayHubStatus status;
  final VoidCallback? onRetry;

  static _PlayHubData of(BuildContext context) {
    final _PlayHubData? data = context
        .dependOnInheritedWidgetOfExactType<_PlayHubData>();
    assert(data != null, 'Play pages are built under PlayHub.');
    return data!;
  }

  @override
  bool updateShouldNotify(_PlayHubData oldWidget) {
    return status != oldWidget.status || onRetry != oldWidget.onRetry;
  }
}

/// Root of [PlayRoutes.root]. Shelves and Tone Forge are one tap.
class PlayHubPage extends StatelessWidget {
  const PlayHubPage({super.key});

  @override
  Widget build(BuildContext context) {
    final _PlayHubData data = _PlayHubData.of(context);
    final AppLocalizations l10n = l10nOf(context);
    final LingPalette palette = LingPalette.of(Theme.of(context).brightness);
    final bool showTitle = data.status != PlayHubStatus.empty;
    final Widget body = switch (data.status) {
      PlayHubStatus.ready =>
        kPlayShelfGames.isEmpty
            ? _hubEmpty(l10n, data.onRetry)
            : _ready(context, l10n, palette),
      PlayHubStatus.empty => _hubEmpty(l10n, data.onRetry),
      PlayHubStatus.error => _hubError(l10n, data.onRetry),
      PlayHubStatus.offline => _hubOffline(l10n, data.onRetry),
    };
    return Scaffold(
      backgroundColor: palette.surface,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(LingAfriqTokens.spacing16),
          children: <Widget>[
            if (showTitle && data.status != PlayHubStatus.ready) ...<Widget>[
              Text(
                l10n.hubHPlayTitle,
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
        Text(
          l10n.hubHPlayTitle,
          style: lingBody(palette.onSurface),
          softWrap: true,
          overflow: TextOverflow.visible,
        ),
        const SizedBox(height: LingAfriqTokens.spacing8),
        Text(
          l10n.hubHPlaySubtitle,
          style: lingBody(palette.onSurfaceVariant),
          softWrap: true,
          overflow: TextOverflow.visible,
        ),
        const SizedBox(height: LingAfriqTokens.spacing16),
        for (final PlayShelfId shelf in kPlayShelfOrder)
          Padding(
            padding: const EdgeInsets.only(bottom: LingAfriqTokens.spacing8),
            child: _PlayRow(
              rowKey: PlayHub.shelfKey(shelf),
              label: playShelfLabel(l10n, shelf),
              palette: palette,
              onTap: () => Navigator.of(context).pushNamed(shelf.path),
            ),
          ),
        _PlayRow(
          rowKey: PlayHub.toneForgeKey,
          label: l10n.hubHPlayToneForge,
          palette: palette,
          onTap: () => Navigator.of(context).pushNamed(PlayRoutes.toneForge),
        ),
        _PlayRow(
          rowKey: PlayHub.masteryResultsKey,
          label: l10n.revRvPlayMasteryTitle,
          palette: palette,
          onTap: () =>
              Navigator.of(context).pushNamed(PlayRoutes.masteryResults),
        ),
      ],
    );
  }
}

/// One skill shelf. Its games are the second tap. An empty shelf names a next step.
class PlayShelfPage extends StatelessWidget {
  const PlayShelfPage({required this.shelf, super.key});

  final PlayShelfId shelf;

  @override
  Widget build(BuildContext context) {
    final _PlayHubData data = _PlayHubData.of(context);
    final AppLocalizations l10n = l10nOf(context);
    final LingPalette palette = LingPalette.of(Theme.of(context).brightness);
    final List<PlayShelfGame> games = playGamesOnShelf(shelf);
    final Widget body = switch (data.status) {
      PlayHubStatus.ready =>
        games.isEmpty
            ? _shelfEmpty(context, l10n, shelf)
            : _games(context, l10n, palette, games),
      PlayHubStatus.empty => _hubEmpty(l10n, data.onRetry),
      PlayHubStatus.error => _hubError(l10n, data.onRetry),
      PlayHubStatus.offline => _hubOffline(l10n, data.onRetry),
    };
    final bool titled =
        data.status == PlayHubStatus.error ||
        data.status == PlayHubStatus.offline ||
        (data.status == PlayHubStatus.ready && games.isNotEmpty);
    return Scaffold(
      backgroundColor: palette.surface,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(LingAfriqTokens.spacing16),
          children: <Widget>[
            if (titled) ...<Widget>[
              Text(
                playShelfLabel(l10n, shelf),
                style: lingBody(palette.onSurface),
                softWrap: true,
                overflow: TextOverflow.visible,
              ),
              const SizedBox(height: LingAfriqTokens.spacing16),
            ],
            body,
            if (data.status == PlayHubStatus.ready && games.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: LingAfriqTokens.spacing16),
                child: LingButton(
                  label: l10n.hubHPlayBack,
                  unavailableLabel: l10n.commonStateUnavailable,
                  onPressed: () => playBackToRoot(context),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _games(
    BuildContext context,
    AppLocalizations l10n,
    LingPalette palette,
    List<PlayShelfGame> games,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (final PlayShelfGame game in games)
          Padding(
            padding: const EdgeInsets.only(bottom: LingAfriqTokens.spacing8),
            child: _PlayRow(
              rowKey: PlayHub.gameKey(game.key),
              label: playGameLabel(l10n, game.key),
              palette: palette,
              onTap: () => Navigator.of(context).pushNamed(game.path),
            ),
          ),
      ],
    );
  }
}

Widget _hubEmpty(AppLocalizations l10n, VoidCallback? onRetry) {
  return LingEmptyState(
    key: PlayHub.emptyKey,
    title: l10n.hubHPlayTitle,
    whatHappened: l10n.hubHPlayEmptyWhat,
    why: l10n.hubHPlayEmptyWhy,
    whatToDo: l10n.hubHPlayEmptyNext,
    actionLabel: l10n.commonActionTryAgain,
    unavailableLabel: l10n.commonStateUnavailable,
    onAction: onRetry ?? () {},
  );
}

Widget _shelfEmpty(
  BuildContext context,
  AppLocalizations l10n,
  PlayShelfId shelf,
) {
  return LingEmptyState(
    key: PlayHub.shelfEmptyKey,
    title: playShelfLabel(l10n, shelf),
    whatHappened: l10n.hubHPlayShelfEmptyWhat,
    why: l10n.hubHPlayShelfEmptyWhy,
    whatToDo: l10n.hubHPlayShelfEmptyNext,
    actionLabel: l10n.hubHPlayOpenArcade,
    unavailableLabel: l10n.commonStateUnavailable,
    onAction: () => playBackToRoot(context),
  );
}

Widget _hubError(AppLocalizations l10n, VoidCallback? onRetry) {
  return LingErrorState(
    key: PlayHub.errorKey,
    whatHappened: l10n.hubHPlayErrorWhat,
    why: l10n.hubHPlayErrorWhy,
    whatToDo: l10n.hubHPlayErrorNext,
    actionLabel: l10n.commonActionTryAgain,
    unavailableLabel: l10n.commonStateUnavailable,
    onAction: onRetry ?? () {},
  );
}

Widget _hubOffline(AppLocalizations l10n, VoidCallback? onRetry) {
  return LingOfflineState(
    key: PlayHub.offlineKey,
    whatHappened: l10n.shellOfflineWhat,
    why: l10n.hubHPlayOfflineWhy,
    whatToDo: l10n.shellOfflineNext,
    queuedActions: 0,
    actionLabel: l10n.commonActionTryAgain,
    unavailableLabel: l10n.commonStateUnavailable,
    onAction: onRetry ?? () {},
  );
}

class _PlayRow extends StatelessWidget {
  const _PlayRow({
    required this.rowKey,
    required this.label,
    required this.palette,
    required this.onTap,
  });

  final Key rowKey;
  final String label;
  final LingPalette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      key: rowKey,
      container: true,
      button: true,
      label: label,
      onTap: onTap,
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
            onTap: onTap,
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

/// Typed gap for a Play place that is not built. No sample rows are painted.
class PlayNotAvailablePage extends StatelessWidget {
  const PlayNotAvailablePage({required this.gap, super.key});

  final PlayNotAvailable gap;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = l10nOf(context);
    final LingPalette palette = LingPalette.of(Theme.of(context).brightness);
    final String name = playPlaceLabel(l10n, gap.placeId);
    return Scaffold(
      key: PlayHub.gapKey,
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
              l10n.hubHPlayNotAvailableTitle,
              style: lingBody(palette.onSurface),
              softWrap: true,
              overflow: TextOverflow.visible,
            ),
            const SizedBox(height: LingAfriqTokens.spacing16),
            Text(
              l10n.hubHPlayNotAvailableWhat(name),
              style: lingBody(palette.onSurfaceVariant),
              softWrap: true,
              overflow: TextOverflow.visible,
            ),
            const SizedBox(height: LingAfriqTokens.spacing16),
            Text(
              l10n.hubHPlayNotAvailableWhy,
              style: lingBody(palette.onSurfaceVariant),
              softWrap: true,
              overflow: TextOverflow.visible,
            ),
            const SizedBox(height: LingAfriqTokens.spacing16),
            Text(
              l10n.hubHPlayNotAvailableNext,
              style: lingBody(palette.onSurfaceVariant),
              softWrap: true,
              overflow: TextOverflow.visible,
            ),
            const SizedBox(height: LingAfriqTokens.spacing16),
            LingButton(
              label: l10n.hubHPlayBack,
              unavailableLabel: l10n.commonStateUnavailable,
              onPressed: () => playBackToRoot(context),
            ),
          ],
        ),
      ),
    );
  }
}

/// A path that is not in [PlayRoutes.paths].
class PlayUnknownPage extends StatelessWidget {
  const PlayUnknownPage({required this.path, super.key});

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
              whatToDo: l10n.hubHPlayNotAvailableNext,
              actionLabel: l10n.hubHPlayBack,
              unavailableLabel: l10n.commonStateUnavailable,
              onAction: () => playBackToRoot(context),
            ),
          ],
        ),
      ),
    );
  }
}
