import 'package:flutter/material.dart';
import 'package:lingafriq/design/components/ling_button.dart';
import 'package:lingafriq/design/components/ling_state.dart';
import 'package:lingafriq/design/states/empty_state.dart';
import 'package:lingafriq/design/states/error_state.dart';
import 'package:lingafriq/design/states/offline_state.dart';
import 'package:lingafriq/design/tokens.g.dart';
import 'package:lingafriq/l10n/generated/app_localizations.dart';
import 'package:lingafriq/l10n/l10n_of.dart';
import 'package:lingafriq/models/profile_model.dart';
import 'package:lingafriq/screens/tabs_view/profile/profile_tab.dart';

/// How far a Me place is built.
///
/// [notAvailable] opens [MeNotAvailable]. It does not invent rows.
enum MePlaceKind { ready, notAvailable }

/// One registered Me place. [id] is a route key, not learner copy.
class MePlace {
  const MePlace({required this.id, required this.path, required this.kind});

  final String id;
  final String path;
  final MePlaceKind kind;
}

/// A place that is not built. The only field is which place was opened.
class MeNotAvailable {
  const MeNotAvailable(this.placeId);

  final String placeId;
}

/// What opening a registered path does. The gap carries no sample content.
sealed class MeOpening {
  const MeOpening();
}

final class MeHubOpening extends MeOpening {
  const MeHubOpening();
}

final class MeProfileOpening extends MeOpening {
  const MeProfileOpening();
}

final class MeGapOpening extends MeOpening {
  const MeGapOpening(this.gap);

  final MeNotAvailable gap;
}

final class MeUnknownOpening extends MeOpening {
  const MeUnknownOpening(this.path);

  final String path;
}

/// Me root, or a load that has no list, failed, or has no network.
enum MeHubStatus { ready, empty, error, offline }

/// Routes for the Me sitemap. Profile and avatar is the built place.
abstract final class MeRoutes {
  static const String root = '/me';
  static const String profile = '/me/profile';
  static const String progress = '/me/progress';
  static const String achievements = '/me/achievements';
  static const String leagues = '/me/leagues';
  static const String family = '/me/family';
  static const String plus = '/me/plus';
  static const String settings = '/me/settings';
  static const String about = '/me/about';

  static const List<String> paths = <String>[
    root,
    profile,
    progress,
    achievements,
    leagues,
    family,
    plus,
    settings,
    about,
  ];

  /// Sitemap order. Profile is ready. The other places are not built yet.
  static const List<MePlace> places = <MePlace>[
    MePlace(id: 'profile', path: profile, kind: MePlaceKind.ready),
    MePlace(id: 'progress', path: progress, kind: MePlaceKind.notAvailable),
    MePlace(
      id: 'achievements',
      path: achievements,
      kind: MePlaceKind.notAvailable,
    ),
    MePlace(id: 'leagues', path: leagues, kind: MePlaceKind.notAvailable),
    MePlace(id: 'family', path: family, kind: MePlaceKind.notAvailable),
    MePlace(id: 'plus', path: plus, kind: MePlaceKind.notAvailable),
    MePlace(id: 'settings', path: settings, kind: MePlaceKind.notAvailable),
    MePlace(id: 'about', path: about, kind: MePlaceKind.notAvailable),
  ];

  static bool isRegistered(String path) => paths.contains(path);

  static MePlace? find(String path) {
    for (final MePlace place in places) {
      if (place.path == path) return place;
    }
    return null;
  }

  static String pathFor(String placeId) {
    for (final MePlace place in places) {
      if (place.id == placeId) return place.path;
    }
    return root;
  }

  /// Taps from the Me root. The root is 0. A missed path is -1.
  static int tapsFromRoot(String path) {
    if (path == root) return 0;
    if (!isRegistered(path)) return -1;
    final int parts = path
        .split('/')
        .where((String part) => part.isNotEmpty)
        .length;
    return parts - 1;
  }

  static MeOpening openingFor(String path) {
    if (path == root) return const MeHubOpening();
    final MePlace? place = find(path);
    if (place == null) return MeUnknownOpening(path);
    if (place.kind == MePlaceKind.notAvailable) {
      return MeGapOpening(MeNotAvailable(place.id));
    }
    return const MeProfileOpening();
  }
}

String mePlaceLabel(AppLocalizations l10n, String placeId) {
  return switch (placeId) {
    'profile' => l10n.hubHMeProfile,
    'progress' => l10n.hubHMeProgress,
    'achievements' => l10n.hubHMeAchievements,
    'leagues' => l10n.hubHMeLeagues,
    'family' => l10n.hubHMeFamily,
    'plus' => l10n.hubHMePlus,
    'settings' => l10n.hubHMeSettings,
    'about' => l10n.hubHMeAbout,
    _ => l10n.hubHMeNotAvailableTitle,
  };
}

/// Opens Me on [navigator].
///
/// Pass this to the shell Me control. The hub is pushed on the current tab's
/// navigator, so Back returns to that same tab.
void openMeHub(
  NavigatorState navigator, {
  ProfileModel? account,
  MeHubStatus status = MeHubStatus.ready,
}) {
  navigator.push<void>(
    MaterialPageRoute<void>(
      settings: const RouteSettings(name: MeRoutes.root),
      builder: (BuildContext context) {
        return MeHub(account: account, status: status);
      },
    ),
  );
}

Widget _pageFor(BuildContext context, String routePath) {
  final MeOpening opening = MeRoutes.openingFor(routePath);
  return switch (opening) {
    MeHubOpening() => const MeHubPage(),
    MeProfileOpening() => const _MeProfileHost(),
    MeGapOpening(:final gap) => MeNotAvailablePage(gap: gap),
    MeUnknownOpening(:final path) => MeUnknownPage(path: path),
  };
}

/// Me hub. The shell Me control pushes this on the current tab.
class MeHub extends StatefulWidget {
  const MeHub({
    super.key,
    this.status = MeHubStatus.ready,
    this.initialRoute = MeRoutes.root,
    this.account,
    this.onRetry,
  });

  static Key placeKey(String id) => ValueKey<String>('me-place-$id');

  static const Key emptyKey = ValueKey<String>('me-hub-empty');

  static const Key errorKey = ValueKey<String>('me-hub-error');

  static const Key offlineKey = ValueKey<String>('me-hub-offline');

  static const Key gapKey = ValueKey<String>('me-not-available');

  static const Key leaveKey = ValueKey<String>('me-hub-leave');

  final MeHubStatus status;

  final String initialRoute;

  /// Saved learner, when one exists. Null draws no stand-in profile.
  final ProfileModel? account;

  final VoidCallback? onRetry;

  @override
  State<MeHub> createState() => _MeHubState();
}

class _MeHubState extends State<MeHub> {
  final GlobalKey<NavigatorState> _navigator = GlobalKey<NavigatorState>();

  void _onBack(String routeName) {
    final NavigatorState? inner = _navigator.currentState;
    if (inner != null && inner.canPop()) {
      inner.pop();
      return;
    }
    if (routeName != MeRoutes.root && inner != null) {
      inner.pushReplacementNamed(MeRoutes.root);
      return;
    }
    final NavigatorState? parent = Navigator.maybeOf(context);
    if (parent != null && parent.canPop()) {
      parent.pop();
    }
  }

  Route<void> _onGenerate(RouteSettings settings) {
    final String path = settings.name ?? MeRoutes.root;
    return MaterialPageRoute<void>(
      settings: RouteSettings(name: path, arguments: settings.arguments),
      builder: (BuildContext context) => _pageFor(context, path),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool canLeave = Navigator.maybeOf(context)?.canPop() ?? false;
    return _MeHubData(
      status: widget.status,
      account: widget.account,
      onRetry: widget.onRetry,
      onBack: _onBack,
      canLeave: canLeave,
      child: Navigator(
        key: _navigator,
        initialRoute: widget.initialRoute,
        onGenerateRoute: _onGenerate,
        onGenerateInitialRoutes:
            (NavigatorState navigator, String initialRoute) {
              return <Route<dynamic>>[
                _onGenerate(RouteSettings(name: initialRoute)),
              ];
            },
      ),
    );
  }
}

/// Live hub status. The route is created once, so the page reads this.
class _MeHubData extends InheritedWidget {
  const _MeHubData({
    required this.status,
    required this.account,
    required this.onRetry,
    required this.onBack,
    required this.canLeave,
    required super.child,
  });

  final MeHubStatus status;
  final ProfileModel? account;
  final VoidCallback? onRetry;
  final void Function(String routeName) onBack;
  final bool canLeave;

  static _MeHubData of(BuildContext context) {
    final _MeHubData? data = context
        .dependOnInheritedWidgetOfExactType<_MeHubData>();
    assert(data != null, 'Me pages are built under MeHub.');
    return data!;
  }

  @override
  bool updateShouldNotify(_MeHubData oldWidget) {
    return status != oldWidget.status ||
        !identical(account, oldWidget.account) ||
        onRetry != oldWidget.onRetry ||
        canLeave != oldWidget.canLeave;
  }
}

class _MeProfileHost extends StatelessWidget {
  const _MeProfileHost();

  @override
  Widget build(BuildContext context) {
    final _MeHubData data = _MeHubData.of(context);
    return MeProfileScreen(
      account: data.account,
      onBack: () => data.onBack(MeRoutes.profile),
    );
  }
}

/// Root of [MeRoutes.root].
class MeHubPage extends StatelessWidget {
  const MeHubPage({super.key});

  @override
  Widget build(BuildContext context) {
    final _MeHubData data = _MeHubData.of(context);
    final MeHubStatus status = data.status;
    final VoidCallback? onRetry = data.onRetry;
    final AppLocalizations l10n = l10nOf(context);
    final LingPalette palette = LingPalette.of(Theme.of(context).brightness);
    final Widget body = switch (status) {
      MeHubStatus.ready => _ready(context, l10n, palette),
      MeHubStatus.empty => _empty(context, l10n),
      MeHubStatus.error => _error(l10n, onRetry),
      MeHubStatus.offline => _offline(l10n, onRetry),
    };
    return Scaffold(
      backgroundColor: palette.surface,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(LingAfriqTokens.spacing16),
          children: <Widget>[
            if (data.canLeave) ...<Widget>[
              LingButton(
                key: MeHub.leaveKey,
                label: l10n.hubHMeLeave,
                unavailableLabel: l10n.commonStateUnavailable,
                onPressed: () => data.onBack(MeRoutes.root),
              ),
              const SizedBox(height: LingAfriqTokens.spacing16),
            ],
            if (status != MeHubStatus.empty) ...<Widget>[
              Text(
                l10n.hubHMeTitle,
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
        for (final MePlace place in MeRoutes.places)
          Padding(
            padding: const EdgeInsets.only(bottom: LingAfriqTokens.spacing8),
            child: _PlaceButton(place: place, palette: palette, l10n: l10n),
          ),
      ],
    );
  }

  Widget _empty(BuildContext context, AppLocalizations l10n) {
    return LingEmptyState(
      key: MeHub.emptyKey,
      title: l10n.hubHMeTitle,
      whatHappened: l10n.hubHMeEmptyWhat,
      why: l10n.hubHMeEmptyWhy,
      whatToDo: l10n.hubHMeEmptyNext,
      actionLabel: l10n.hubHMeOpenProfile,
      unavailableLabel: l10n.commonStateUnavailable,
      onAction: () {
        Navigator.of(context).pushNamed(MeRoutes.profile);
      },
    );
  }

  Widget _error(AppLocalizations l10n, VoidCallback? onRetry) {
    return LingErrorState(
      key: MeHub.errorKey,
      whatHappened: l10n.hubHMeErrorWhat,
      why: l10n.hubHMeErrorWhy,
      whatToDo: l10n.hubHMeErrorNext,
      actionLabel: l10n.commonActionTryAgain,
      unavailableLabel: l10n.commonStateUnavailable,
      onAction: onRetry ?? () {},
    );
  }

  Widget _offline(AppLocalizations l10n, VoidCallback? onRetry) {
    return LingOfflineState(
      key: MeHub.offlineKey,
      whatHappened: l10n.shellOfflineWhat,
      why: l10n.hubHMeOfflineWhy,
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

  final MePlace place;
  final LingPalette palette;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final String label = mePlaceLabel(l10n, place.id);
    return Semantics(
      key: MeHub.placeKey(place.id),
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

/// Typed gap for a Me place that is not built. No sample rows are painted.
class MeNotAvailablePage extends StatelessWidget {
  const MeNotAvailablePage({required this.gap, super.key});

  final MeNotAvailable gap;

  @override
  Widget build(BuildContext context) {
    final _MeHubData data = _MeHubData.of(context);
    final AppLocalizations l10n = l10nOf(context);
    final LingPalette palette = LingPalette.of(Theme.of(context).brightness);
    final String name = mePlaceLabel(l10n, gap.placeId);
    final String path = MeRoutes.pathFor(gap.placeId);
    return Scaffold(
      key: MeHub.gapKey,
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
              l10n.hubHMeNotAvailableTitle,
              style: lingBody(palette.onSurface),
              softWrap: true,
              overflow: TextOverflow.visible,
            ),
            const SizedBox(height: LingAfriqTokens.spacing16),
            Text(
              l10n.hubHMeNotAvailableWhat(name),
              style: lingBody(palette.onSurfaceVariant),
              softWrap: true,
              overflow: TextOverflow.visible,
            ),
            const SizedBox(height: LingAfriqTokens.spacing16),
            Text(
              l10n.hubHMeNotAvailableWhy,
              style: lingBody(palette.onSurfaceVariant),
              softWrap: true,
              overflow: TextOverflow.visible,
            ),
            const SizedBox(height: LingAfriqTokens.spacing16),
            Text(
              l10n.hubHMeNotAvailableNext,
              style: lingBody(palette.onSurfaceVariant),
              softWrap: true,
              overflow: TextOverflow.visible,
            ),
            const SizedBox(height: LingAfriqTokens.spacing16),
            LingButton(
              label: l10n.hubHMeBack,
              unavailableLabel: l10n.commonStateUnavailable,
              onPressed: () => data.onBack(path),
            ),
          ],
        ),
      ),
    );
  }
}

/// A path that is not in [MeRoutes.paths].
class MeUnknownPage extends StatelessWidget {
  const MeUnknownPage({required this.path, super.key});

  final String path;

  @override
  Widget build(BuildContext context) {
    final _MeHubData data = _MeHubData.of(context);
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
              whatToDo: l10n.hubHMeNotAvailableNext,
              actionLabel: l10n.hubHMeBack,
              unavailableLabel: l10n.commonStateUnavailable,
              onAction: () => data.onBack(path),
            ),
          ],
        ),
      ),
    );
  }
}
