import 'package:flutter/material.dart';
import 'package:lingafriq/design/components/ling_button.dart';
import 'package:lingafriq/design/components/ling_state.dart';
import 'package:lingafriq/design/states/empty_state.dart';
import 'package:lingafriq/design/states/error_state.dart';
import 'package:lingafriq/design/states/offline_state.dart';
import 'package:lingafriq/design/tokens.g.dart';
import 'package:lingafriq/l10n/generated/app_localizations.dart';
import 'package:lingafriq/l10n/l10n_of.dart';
import 'package:lingafriq/screens/contribute/lesson_item_verification_screen.dart';
import 'package:lingafriq/screens/contribute/native_speaker_contribution_screen.dart';
import 'package:lingafriq/screens/gamification/classroom_dashboard_screen.dart';
import 'package:lingafriq/screens/social/revived_social_screens.dart';
import 'package:lingafriq/services/social/revived_social.dart';
import 'package:lingafriq/screens/social_audio/following_screen.dart';
import 'package:lingafriq/screens/social_audio/scheduled_sessions_screen.dart';

/// How far a Village place is built.
///
/// [notAvailable] opens [VillageNotAvailablePage]. It does not invent posts,
/// people, or counts.
enum VillagePlaceKind { ready, notAvailable }

/// Who is opening Village. A minor is under 13.
enum VillageAudience { adult, minor }

/// Why a row stays on the list but does not open.
enum VillageGateKind { none, level, guardian }

/// Level name on a locked row. It is not a score.
enum VillageLevelLock { a2, b1 }

/// How the hub root should render.
enum VillageHubStatus { ready, empty, error, offline }

/// Typed surface. [notAvailable] is the gap for a place that is not built.
enum VillageSurfaceKind { ready, empty, error, offline, notAvailable, locked }

/// One registered Village place. [id] matches the sitemap name.
class VillagePlace {
  const VillagePlace({
    required this.id,
    required this.path,
    required this.taps,
    required this.kind,
    this.onRoot = true,
    this.guardianGated = false,
    this.levelLock,
    this.childId,
  });

  final String id;
  final String path;
  final int taps;
  final VillagePlaceKind kind;

  /// Shown on the Village root. The hub, the map, and Verify are not rows.
  final bool onRoot;

  /// A minor sees this row locked. It stays visible.
  final bool guardianGated;

  /// An adult sees Locked and this unlock line. Open anyway does not
  /// mark an earlier lesson done.
  final VillageLevelLock? levelLock;

  /// Sitemap child reached from this place. Verify sits under Create.
  final String? childId;
}

/// A place that is not built. The only field is which place was opened.
class VillageNotAvailable {
  const VillageNotAvailable(this.placeId);

  final String placeId;
}

/// What opening a registered path does. A gap carries no sample content.
sealed class VillageOpening {
  const VillageOpening();
}

final class VillageHubOpening extends VillageOpening {
  const VillageHubOpening();
}

final class VillageGapOpening extends VillageOpening {
  const VillageGapOpening(this.gap);

  final VillageNotAvailable gap;
}

final class VillageLockedOpening extends VillageOpening {
  const VillageLockedOpening(this.placeId, this.gate);

  final String placeId;
  final VillageGateKind gate;
}

final class VillageUnknownOpening extends VillageOpening {
  const VillageUnknownOpening(this.path);

  final String path;
}

/// Passed when an adult chooses Open anyway. A minor cannot set this.
class VillageOpen {
  const VillageOpen({this.anyway = false});

  final bool anyway;
}

/// Gate for [place] and [audience]. A guardian gate wins over a level lock.
VillageGateKind villageGate(VillagePlace place, VillageAudience audience) {
  if (place.guardianGated && audience == VillageAudience.minor) {
    return VillageGateKind.guardian;
  }
  if (place.levelLock != null) {
    return VillageGateKind.level;
  }
  return VillageGateKind.none;
}

/// Speaking and hosting on Radio use the guardian gate already on that place.
bool radioSpeakHostLocked(VillageAudience audience) {
  final VillagePlace? place = VillageRoutes.find(VillageRoutes.radio);
  if (place == null) return true;
  return villageGate(place, audience) == VillageGateKind.guardian;
}

/// Following screen with the Radio guardian gate applied.
Widget buildRadioFollowing(VillageAudience audience) {
  return FollowingScreen.live(guardianLocked: radioSpeakHostLocked(audience));
}

/// Scheduled sessions screen with the Radio guardian gate applied.
Widget buildRadioScheduled(VillageAudience audience) {
  return ScheduledSessionsScreen.live(
    guardianLocked: radioSpeakHostLocked(audience),
  );
}

/// Routes for the Village sitemap. The root is the place list, the map.
abstract final class VillageRoutes {
  static const String root = '/village';
  static const String map = '/village/map';
  static const String circles = '/village/circles';
  static const String square = '/village/square';
  static const String chats = '/village/chats';
  static const String chatSearch = '/village/chat-search';
  static const String contactInfo = '/village/contact-info';
  static const String moderation = '/village/moderation';
  static const String chatWelcome = '/village/chat-welcome';
  static const String status = '/village/status';
  static const String clips = '/village/clips';
  static const String radio = '/village/radio';
  static const String radioFollowing = '/village/radio/following';
  static const String radioScheduled = '/village/radio/scheduled';
  static const String school = '/village/school';
  static const String elderHut = '/village/elder-hut';
  static const String corrections = '/village/corrections';
  static const String create = '/village/create';
  static const String verify = LessonItemVerificationScreen.routePath;
  static const String contribute = NativeSpeakerContributionScreen.routePath;
  static const String teacher = ClassroomDashboardScreen.routePath;

  static const List<VillagePlace> places = <VillagePlace>[
    VillagePlace(
      id: '/village',
      path: root,
      taps: 0,
      kind: VillagePlaceKind.ready,
      onRoot: false,
    ),
    VillagePlace(
      id: 'map',
      path: map,
      taps: 0,
      kind: VillagePlaceKind.ready,
      onRoot: false,
    ),
    VillagePlace(
      id: 'circles',
      path: circles,
      taps: 1,
      kind: VillagePlaceKind.notAvailable,
    ),
    VillagePlace(
      id: 'square',
      path: square,
      taps: 1,
      kind: VillagePlaceKind.notAvailable,
      guardianGated: true,
    ),
    VillagePlace(
      id: 'chats',
      path: chats,
      taps: 1,
      kind: VillagePlaceKind.ready,
      guardianGated: true,
    ),
    VillagePlace(
      id: 'status',
      path: status,
      taps: 1,
      kind: VillagePlaceKind.notAvailable,
    ),
    VillagePlace(
      id: 'clips',
      path: clips,
      taps: 1,
      kind: VillagePlaceKind.notAvailable,
      guardianGated: true,
      levelLock: VillageLevelLock.a2,
    ),
    VillagePlace(
      id: 'radio',
      path: radio,
      taps: 1,
      kind: VillagePlaceKind.notAvailable,
      guardianGated: true,
    ),
    VillagePlace(
      id: 'school',
      path: school,
      taps: 1,
      kind: VillagePlaceKind.notAvailable,
    ),
    VillagePlace(
      id: 'elder hut',
      path: elderHut,
      taps: 1,
      kind: VillagePlaceKind.notAvailable,
    ),
    VillagePlace(
      id: 'corrections',
      path: corrections,
      taps: 1,
      kind: VillagePlaceKind.notAvailable,
    ),
    VillagePlace(
      id: 'create',
      path: create,
      taps: 1,
      kind: VillagePlaceKind.notAvailable,
      guardianGated: true,
      levelLock: VillageLevelLock.b1,
      childId: 'verify',
    ),
    VillagePlace(
      id: 'verify',
      path: verify,
      taps: 2,
      kind: VillagePlaceKind.ready,
      onRoot: false,
    ),
  ];

  static List<String> get sitemapIds =>
      places.map((VillagePlace place) => place.id).toList(growable: false);

  static List<VillagePlace> get rootPlaces => places
      .where((VillagePlace place) => place.onRoot)
      .toList(growable: false);

  /// Rows a minor sees locked. They stay on the place list.
  static List<VillagePlace> get guardianGated => places
      .where((VillagePlace place) => place.guardianGated)
      .toList(growable: false);

  static bool get withinTwoTaps =>
      places.every((VillagePlace place) => place.taps <= 2);

  static bool isRegistered(String path) =>
      places.any((VillagePlace place) => place.path == path);

  static VillagePlace? find(String raw) {
    final String name = raw.trim();
    if (name.isEmpty) return null;
    for (final VillagePlace place in places) {
      if (place.id == name || place.path == name) return place;
    }
    return null;
  }

  /// Taps from the Village root. A missed path is -1.
  static int tapsFor(String raw) {
    final VillagePlace? place = find(raw);
    if (place == null) return -1;
    return place.taps;
  }

  static VillageOpening openingFor(
    String path, {
    VillageAudience audience = VillageAudience.adult,
    bool anyway = false,
  }) {
    if (path == root || path == map) return const VillageHubOpening();
    final VillagePlace? place = find(path);
    if (place == null) return VillageUnknownOpening(path);
    final VillageGateKind gate = villageGate(place, audience);
    if (gate == VillageGateKind.guardian ||
        (gate == VillageGateKind.level && !anyway)) {
      return VillageLockedOpening(place.id, gate);
    }
    if (place.kind == VillagePlaceKind.notAvailable) {
      return VillageGapOpening(VillageNotAvailable(place.id));
    }
    return const VillageHubOpening();
  }

  static Route<void> onGenerate(RouteSettings settings) {
    final String path = settings.name ?? root;
    final bool anyway =
        settings.arguments is VillageOpen &&
        (settings.arguments as VillageOpen).anyway;
    return MaterialPageRoute<void>(
      settings: RouteSettings(name: path, arguments: settings.arguments),
      builder: (BuildContext context) =>
          _pageFor(context, path, anyway: anyway),
    );
  }
}

String villagePlaceLabel(AppLocalizations l10n, String placeId) {
  return switch (placeId) {
    '/village' => l10n.hubHVillageTitle,
    'map' => l10n.hubHVillageMap,
    'circles' => l10n.hubHVillageCircles,
    'square' => l10n.hubHVillageSquare,
    'chats' => l10n.hubHVillageChats,
    'status' => l10n.hubHVillageStatus,
    'clips' => l10n.hubHVillageClips,
    'radio' => l10n.hubHVillageRadio,
    'school' => l10n.hubHVillageSchool,
    'elder hut' => l10n.hubHVillageElderHut,
    'corrections' => l10n.hubHVillageCorrections,
    'create' => l10n.hubHVillageCreate,
    'verify' => l10n.hubHVillageVerify,
    _ => l10n.hubHVillageNotAvailableTitle,
  };
}

String? villageGateLine(
  AppLocalizations l10n,
  VillagePlace place,
  VillageGateKind gate,
) {
  return switch (gate) {
    VillageGateKind.none => null,
    VillageGateKind.guardian => l10n.hubHVillageGuardian,
    VillageGateKind.level => switch (place.levelLock) {
      VillageLevelLock.a2 => l10n.hubHVillageUnlocksA2,
      VillageLevelLock.b1 => l10n.hubHVillageUnlocksB1,
      null => null,
    },
  };
}

void _villageBack(BuildContext context) {
  final NavigatorState nav = Navigator.of(context);
  var atRoot = false;
  nav.popUntil((Route<dynamic> route) {
    final String? name = route.settings.name;
    atRoot = name == VillageRoutes.root || name == VillageRoutes.map;
    return atRoot || route.isFirst;
  });
  if (!atRoot) {
    nav.pushReplacementNamed(VillageRoutes.root);
  }
}

Widget _pageFor(BuildContext context, String path, {required bool anyway}) {
  if (path == VillageRoutes.root || path == VillageRoutes.map) {
    return const VillageHubPage();
  }
  final _VillageHubData data = _VillageHubData.of(context);
  if (path == VillageRoutes.radioFollowing ||
      path == VillageRoutes.radioScheduled) {
    if (path == VillageRoutes.radioFollowing) {
      return buildRadioFollowing(data.audience);
    }
    return buildRadioScheduled(data.audience);
  }
  if (path == VillageRoutes.chats ||
      path == VillageRoutes.chatSearch ||
      path == VillageRoutes.contactInfo ||
      path == VillageRoutes.moderation ||
      path == VillageRoutes.chatWelcome) {
    final VillageAudience audience = _VillageHubData.of(context).audience;
    if (audience == VillageAudience.minor) {
      return VillageLockedPage(
        place: VillageRoutes.find(VillageRoutes.chats)!,
        gate: VillageGateKind.guardian,
      );
    }
    final RevivedSocialClient client = liveRevivedSocialClient();
    return switch (path) {
      VillageRoutes.chatSearch => RevivedChatSearchScreen(client: client),
      VillageRoutes.contactInfo => RevivedContactInfoScreen(
        client: client,
        userId: 'unknown',
      ),
      VillageRoutes.moderation => RevivedModerationScreen(client: client),
      VillageRoutes.chatWelcome => RevivedChatWelcomeScreen(
        store: ChatWelcomeStore(),
        userId: 'local',
      ),
      _ => VillageChatToolsScreen(
        client: client,
        onOpen: (String next) {
          Navigator.of(context).pushNamed(next);
        },
      ),
    };
  }
  if (path == VillageRoutes.verify) {
    return LessonItemVerificationScreen(
      verifiedNativeSpeaker: data.verifiedNativeSpeaker,
    );
  }
  if (path == VillageRoutes.contribute) {
    return const NativeSpeakerContributionScreen();
  }
  if (path == VillageRoutes.teacher) {
    return ClassroomDashboardScreen(isTeacher: data.teacher);
  }
  final VillagePlace? place = VillageRoutes.find(path);
  if (place == null) return VillageUnknownPage(path: path);
  final VillageAudience audience = _VillageHubData.of(context).audience;
  final VillageGateKind gate = villageGate(place, audience);
  if (gate == VillageGateKind.guardian ||
      (gate == VillageGateKind.level && !anyway)) {
    return VillageLockedPage(place: place, gate: gate);
  }
  if (place.kind == VillagePlaceKind.notAvailable) {
    return VillageNotAvailablePage(gap: VillageNotAvailable(place.id));
  }
  return const VillageHubPage();
}

/// Reads the kind of the surface that is open. Tests use this type.
class VillageStateMark extends StatelessWidget {
  const VillageStateMark({
    required this.kind,
    required this.child,
    this.placeId,
    super.key,
  });

  final VillageSurfaceKind kind;
  final String? placeId;
  final Widget child;

  @override
  Widget build(BuildContext context) => child;
}

/// Village hub. Each tab of the shell can host this navigator on its own stack.
class VillageHub extends StatelessWidget {
  const VillageHub({
    super.key,
    this.status = VillageHubStatus.ready,
    this.audience = VillageAudience.adult,
    this.initialRoute = VillageRoutes.root,
    this.onRetry,
    this.onClose,
    this.verifiedNativeSpeaker = false,
    this.teacher = false,
  });

  static Key placeKey(String id) => ValueKey<String>('village-place-$id');

  static Key previewKey(String id) => ValueKey<String>('village-preview-$id');

  static Key openAnywayKey(String id) =>
      ValueKey<String>('village-open-anyway-$id');

  static const Key verifyKey = ValueKey<String>('village-verify');

  static const Key contributeKey = ValueKey<String>('village-contribute');

  static const Key teacherKey = ValueKey<String>('village-teacher');

  static const Key radioFollowingKey = ValueKey<String>(
    'village-radio-following',
  );

  static const Key radioScheduledKey = ValueKey<String>(
    'village-radio-scheduled',
  );

  static const Key emptyKey = ValueKey<String>('village-empty');

  static const Key errorKey = ValueKey<String>('village-error');

  static const Key offlineKey = ValueKey<String>('village-offline');

  static const Key gapKey = ValueKey<String>('village-not-available');

  static const Key lockedKey = ValueKey<String>('village-locked');

  static const Key closeKey = ValueKey<String>('village-close');

  final VillageHubStatus status;
  final VillageAudience audience;
  final String initialRoute;
  final VoidCallback? onRetry;
  final VoidCallback? onClose;

  /// Passed by the caller. Omitted means this person is not a verified native speaker.
  final bool verifiedNativeSpeaker;

  /// Passed by the caller. Omitted means this person is not a teacher.
  final bool teacher;

  @override
  Widget build(BuildContext context) {
    return _VillageHubData(
      status: status,
      audience: audience,
      onRetry: onRetry,
      onClose: onClose,
      verifiedNativeSpeaker: verifiedNativeSpeaker,
      teacher: teacher,
      child: Navigator(
        initialRoute: initialRoute,
        onGenerateRoute: VillageRoutes.onGenerate,
        onGenerateInitialRoutes: (NavigatorState navigator, String route) {
          return <Route<void>>[
            VillageRoutes.onGenerate(RouteSettings(name: route)),
          ];
        },
      ),
    );
  }
}

class _VillageHubData extends InheritedWidget {
  const _VillageHubData({
    required this.status,
    required this.audience,
    required this.onRetry,
    required this.onClose,
    required this.verifiedNativeSpeaker,
    required this.teacher,
    required super.child,
  });

  final VillageHubStatus status;
  final VillageAudience audience;
  final VoidCallback? onRetry;
  final VoidCallback? onClose;
  final bool verifiedNativeSpeaker;
  final bool teacher;

  static _VillageHubData of(BuildContext context) {
    final _VillageHubData? data = context
        .dependOnInheritedWidgetOfExactType<_VillageHubData>();
    assert(data != null, 'Village pages are built under VillageHub.');
    return data!;
  }

  @override
  bool updateShouldNotify(_VillageHubData oldWidget) {
    return status != oldWidget.status ||
        audience != oldWidget.audience ||
        onRetry != oldWidget.onRetry ||
        onClose != oldWidget.onClose ||
        verifiedNativeSpeaker != oldWidget.verifiedNativeSpeaker ||
        teacher != oldWidget.teacher;
  }
}

/// Root of [VillageRoutes.root]. The same page is the Village map.
class VillageHubPage extends StatelessWidget {
  const VillageHubPage({super.key});

  @override
  Widget build(BuildContext context) {
    final _VillageHubData data = _VillageHubData.of(context);
    final AppLocalizations l10n = l10nOf(context);
    final LingPalette palette = LingPalette.of(Theme.of(context).brightness);
    final VillageSurfaceKind kind = switch (data.status) {
      VillageHubStatus.ready => VillageSurfaceKind.ready,
      VillageHubStatus.empty => VillageSurfaceKind.empty,
      VillageHubStatus.error => VillageSurfaceKind.error,
      VillageHubStatus.offline => VillageSurfaceKind.offline,
    };
    final Widget body = switch (data.status) {
      VillageHubStatus.ready => _ready(context, l10n, palette, data.audience),
      VillageHubStatus.empty => _empty(l10n, data.onRetry),
      VillageHubStatus.error => _error(l10n, data.onRetry),
      VillageHubStatus.offline => _offline(l10n, data.onRetry),
    };
    return Scaffold(
      backgroundColor: palette.surface,
      body: SafeArea(
        child: VillageStateMark(
          kind: kind,
          child: ListView(
            padding: const EdgeInsets.all(LingAfriqTokens.spacing16),
            children: <Widget>[
              if (data.onClose != null) ...<Widget>[
                LingButton(
                  key: VillageHub.closeKey,
                  label: l10n.commonActionClose,
                  unavailableLabel: l10n.commonStateUnavailable,
                  onPressed: data.onClose,
                  role: LingButtonRole.quiet,
                ),
                const SizedBox(height: LingAfriqTokens.spacing16),
              ],
              if (data.status != VillageHubStatus.empty) ...<Widget>[
                Text(
                  l10n.hubHVillageTitle,
                  style: lingBody(palette.onSurface),
                  softWrap: true,
                  overflow: TextOverflow.visible,
                ),
                const SizedBox(height: LingAfriqTokens.spacing16),
              ],
              if (data.status == VillageHubStatus.ready) ...<Widget>[
                Text(
                  l10n.hubHVillageMap,
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
      ),
    );
  }

  Widget _ready(
    BuildContext context,
    AppLocalizations l10n,
    LingPalette palette,
    VillageAudience audience,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (final VillagePlace place in VillageRoutes.rootPlaces)
          Padding(
            padding: const EdgeInsets.only(bottom: LingAfriqTokens.spacing8),
            child: _PlaceEntry(
              place: place,
              audience: audience,
              palette: palette,
              l10n: l10n,
            ),
          ),
      ],
    );
  }

  Widget _empty(AppLocalizations l10n, VoidCallback? onRetry) {
    return LingEmptyState(
      key: VillageHub.emptyKey,
      title: l10n.hubHVillageTitle,
      whatHappened: l10n.hubHVillageEmptyWhat,
      why: l10n.hubHVillageEmptyWhy,
      whatToDo: l10n.hubHVillageEmptyNext,
      actionLabel: l10n.commonActionTryAgain,
      unavailableLabel: l10n.commonStateUnavailable,
      onAction: onRetry ?? () {},
    );
  }

  Widget _error(AppLocalizations l10n, VoidCallback? onRetry) {
    return LingErrorState(
      key: VillageHub.errorKey,
      whatHappened: l10n.hubHVillageErrorWhat,
      why: l10n.hubHVillageErrorWhy,
      whatToDo: l10n.hubHVillageErrorNext,
      actionLabel: l10n.commonActionTryAgain,
      unavailableLabel: l10n.commonStateUnavailable,
      onAction: onRetry ?? () {},
    );
  }

  Widget _offline(AppLocalizations l10n, VoidCallback? onRetry) {
    return LingOfflineState(
      key: VillageHub.offlineKey,
      whatHappened: l10n.shellOfflineWhat,
      why: l10n.hubHVillageOfflineWhy,
      whatToDo: l10n.shellOfflineNext,
      queuedActions: 0,
      actionLabel: l10n.commonActionTryAgain,
      unavailableLabel: l10n.commonStateUnavailable,
      onAction: onRetry ?? () {},
    );
  }
}

class _PlaceEntry extends StatelessWidget {
  const _PlaceEntry({
    required this.place,
    required this.audience,
    required this.palette,
    required this.l10n,
  });

  final VillagePlace place;
  final VillageAudience audience;
  final LingPalette palette;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final VillageGateKind gate = villageGate(place, audience);
    final String label = villagePlaceLabel(l10n, place.id);
    if (gate == VillageGateKind.none) {
      return _OpenRow(place: place, label: label, palette: palette);
    }
    final String? line = villageGateLine(l10n, place, gate);
    final String shown = line ?? l10n.hubHVillageLocked;
    return Semantics(
      key: VillageHub.placeKey(place.id),
      container: true,
      explicitChildNodes: true,
      label: l10n.hubHVillageLockedSemantics(label, shown),
      child: Material(
        color: palette.surfaceContainer,
        borderRadius: const BorderRadius.all(
          Radius.circular(LingAfriqTokens.radiussm),
        ),
        child: Padding(
          padding: const EdgeInsets.all(LingAfriqTokens.spacing16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              ExcludeSemantics(
                child: Text(
                  label,
                  style: lingBody(palette.onSurface),
                  softWrap: true,
                  overflow: TextOverflow.visible,
                ),
              ),
              const SizedBox(height: LingAfriqTokens.spacing8),
              ExcludeSemantics(
                child: Text(
                  l10n.hubHVillageLocked,
                  style: lingBody(palette.onSurface),
                  softWrap: true,
                  overflow: TextOverflow.visible,
                ),
              ),
              const SizedBox(height: LingAfriqTokens.spacing8),
              ExcludeSemantics(
                child: Text(
                  shown,
                  style: lingBody(palette.onSurfaceVariant),
                  softWrap: true,
                  overflow: TextOverflow.visible,
                ),
              ),
              const SizedBox(height: LingAfriqTokens.spacing16),
              LingButton(
                key: VillageHub.previewKey(place.id),
                label: l10n.hubHVillagePreview,
                unavailableLabel: l10n.commonStateUnavailable,
                onPressed: () => Navigator.of(context).pushNamed(place.path),
                role: LingButtonRole.quiet,
              ),
              if (gate == VillageGateKind.level) ...<Widget>[
                const SizedBox(height: LingAfriqTokens.spacing8),
                LingButton(
                  key: VillageHub.openAnywayKey(place.id),
                  label: l10n.hubHVillageOpenAnyway,
                  unavailableLabel: l10n.commonStateUnavailable,
                  onPressed: () => Navigator.of(context).pushNamed(
                    place.path,
                    arguments: const VillageOpen(anyway: true),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _OpenRow extends StatelessWidget {
  const _OpenRow({
    required this.place,
    required this.label,
    required this.palette,
  });

  final VillagePlace place;
  final String label;
  final LingPalette palette;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      key: VillageHub.placeKey(place.id),
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

/// Typed gap for a Village place that is not built. No sample rows are painted.
class VillageNotAvailablePage extends StatelessWidget {
  const VillageNotAvailablePage({required this.gap, super.key});

  final VillageNotAvailable gap;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = l10nOf(context);
    final LingPalette palette = LingPalette.of(Theme.of(context).brightness);
    final String name = villagePlaceLabel(l10n, gap.placeId);
    final bool isRadio = gap.placeId == 'radio';
    final String? childId = VillageRoutes.find(gap.placeId)?.childId;
    final VillagePlace? child = childId == null
        ? null
        : VillageRoutes.find(childId);
    return Scaffold(
      key: VillageHub.gapKey,
      backgroundColor: palette.surface,
      body: SafeArea(
        child: VillageStateMark(
          kind: VillageSurfaceKind.notAvailable,
          placeId: gap.placeId,
          child: ListView(
            padding: const EdgeInsets.all(LingAfriqTokens.spacing16),
            children: <Widget>[
              Text(
                name,
                style: lingBody(palette.onSurface),
                softWrap: true,
                overflow: TextOverflow.visible,
              ),
              if (isRadio) ...<Widget>[
                const SizedBox(height: LingAfriqTokens.spacing16),
                LingButton(
                  key: VillageHub.radioFollowingKey,
                  label: l10n.revRvAudioFollowing,
                  unavailableLabel: l10n.commonStateUnavailable,
                  onPressed: () => Navigator.of(
                    context,
                  ).pushNamed(VillageRoutes.radioFollowing),
                  role: LingButtonRole.quiet,
                ),
                const SizedBox(height: LingAfriqTokens.spacing8),
                LingButton(
                  key: VillageHub.radioScheduledKey,
                  label: l10n.revRvAudioScheduled,
                  unavailableLabel: l10n.commonStateUnavailable,
                  onPressed: () => Navigator.of(
                    context,
                  ).pushNamed(VillageRoutes.radioScheduled),
                  role: LingButtonRole.quiet,
                ),
              ] else ...<Widget>[
                const SizedBox(height: LingAfriqTokens.spacing16),
                Text(
                  l10n.hubHVillageNotAvailableTitle,
                  style: lingBody(palette.onSurface),
                  softWrap: true,
                  overflow: TextOverflow.visible,
                ),
                const SizedBox(height: LingAfriqTokens.spacing16),
                Text(
                  l10n.hubHVillageNotAvailableWhat(name),
                  style: lingBody(palette.onSurfaceVariant),
                  softWrap: true,
                  overflow: TextOverflow.visible,
                ),
                const SizedBox(height: LingAfriqTokens.spacing16),
                Text(
                  l10n.hubHVillageNotAvailableWhy,
                  style: lingBody(palette.onSurfaceVariant),
                  softWrap: true,
                  overflow: TextOverflow.visible,
                ),
                const SizedBox(height: LingAfriqTokens.spacing16),
                Text(
                  l10n.hubHVillageNotAvailableNext,
                  style: lingBody(palette.onSurfaceVariant),
                  softWrap: true,
                  overflow: TextOverflow.visible,
                ),
              ],
              if (!isRadio && child != null) ...<Widget>[
                const SizedBox(height: LingAfriqTokens.spacing16),
                LingButton(
                  key: VillageHub.verifyKey,
                  label: villagePlaceLabel(l10n, child.id),
                  unavailableLabel: l10n.commonStateUnavailable,
                  onPressed: () => Navigator.of(context).pushNamed(child.path),
                  role: LingButtonRole.quiet,
                ),
              ],
              if (gap.placeId == 'create') ...<Widget>[
                const SizedBox(height: LingAfriqTokens.spacing8),
                LingButton(
                  key: VillageHub.contributeKey,
                  label: l10n.revRvContribTitle,
                  unavailableLabel: l10n.commonStateUnavailable,
                  onPressed: () => Navigator.of(
                    context,
                  ).pushNamed(VillageRoutes.contribute),
                  role: LingButtonRole.quiet,
                ),
              ],
              if (gap.placeId == 'school') ...<Widget>[
                const SizedBox(height: LingAfriqTokens.spacing16),
                LingButton(
                  key: VillageHub.teacherKey,
                  label: l10n.revRvContribTeacherTitle,
                  unavailableLabel: l10n.commonStateUnavailable,
                  onPressed: () => Navigator.of(
                    context,
                  ).pushNamed(VillageRoutes.teacher),
                  role: LingButtonRole.quiet,
                ),
              ],
              const SizedBox(height: LingAfriqTokens.spacing16),
              LingButton(
                label: l10n.hubHVillageBack,
                unavailableLabel: l10n.commonStateUnavailable,
                onPressed: () => _villageBack(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Locked preview. The row stays on the hub. This page has no sample content.
class VillageLockedPage extends StatelessWidget {
  const VillageLockedPage({required this.place, required this.gate, super.key});

  final VillagePlace place;
  final VillageGateKind gate;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = l10nOf(context);
    final LingPalette palette = LingPalette.of(Theme.of(context).brightness);
    final String name = villagePlaceLabel(l10n, place.id);
    final String line =
        villageGateLine(l10n, place, gate) ?? l10n.hubHVillageLocked;
    return Scaffold(
      key: VillageHub.lockedKey,
      backgroundColor: palette.surface,
      body: SafeArea(
        child: VillageStateMark(
          kind: VillageSurfaceKind.locked,
          placeId: place.id,
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
                l10n.hubHVillageLocked,
                style: lingBody(palette.onSurface),
                softWrap: true,
                overflow: TextOverflow.visible,
              ),
              const SizedBox(height: LingAfriqTokens.spacing16),
              Text(
                line,
                style: lingBody(palette.onSurfaceVariant),
                softWrap: true,
                overflow: TextOverflow.visible,
              ),
              const SizedBox(height: LingAfriqTokens.spacing16),
              LingButton(
                label: l10n.hubHVillageBack,
                unavailableLabel: l10n.commonStateUnavailable,
                onPressed: () => _villageBack(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A path that is not in [VillageRoutes.places].
class VillageUnknownPage extends StatelessWidget {
  const VillageUnknownPage({required this.path, super.key});

  final String path;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = l10nOf(context);
    final LingPalette palette = LingPalette.of(Theme.of(context).brightness);
    final String shown = path.trim().isEmpty ? l10n.shellLinkWasEmpty : path;
    return Scaffold(
      backgroundColor: palette.surface,
      body: SafeArea(
        child: VillageStateMark(
          kind: VillageSurfaceKind.error,
          child: ListView(
            padding: const EdgeInsets.all(LingAfriqTokens.spacing16),
            children: <Widget>[
              LingErrorState(
                whatHappened: l10n.shellLinkMissedWhat,
                why: l10n.shellLinkMissedWhy(shown),
                whatToDo: l10n.hubHVillageNotAvailableNext,
                actionLabel: l10n.hubHVillageBack,
                unavailableLabel: l10n.commonStateUnavailable,
                onAction: () => _villageBack(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
