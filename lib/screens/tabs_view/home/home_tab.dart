import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/design/components/ling_button.dart';
import 'package:lingafriq/design/components/ling_list_row.dart';
import 'package:lingafriq/design/components/ling_state.dart';
import 'package:lingafriq/design/states/empty_state.dart';
import 'package:lingafriq/design/states/error_state.dart';
import 'package:lingafriq/design/states/offline_state.dart';
import 'package:lingafriq/design/tokens.g.dart';
import 'package:lingafriq/design/typography.dart';
import 'package:lingafriq/l10n/generated/app_localizations.dart';
import 'package:lingafriq/l10n/l10n_of.dart';
import 'package:lingafriq/models/language_response.dart';
import 'package:lingafriq/navigation/hub_today.dart';
import 'package:lingafriq/providers/api_provider.dart';
import 'package:lingafriq/providers/navigation_provider.dart';
import 'package:lingafriq/providers/shared_preferences_provider.dart';
import 'package:lingafriq/utils/constants.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:lingafriq/widgets/pan_african_components.dart';

import '../../../detail_types/introduction_screen.dart';
import 'language_detail_screen.dart';

final languagesProvider = FutureProvider.autoDispose((ref) {
  return ref.read(apiProvider.notifier).getLanguages();
});

/// Today hub. The daily plan is the root. Other sitemap rows are one tap away.
class HomeTab extends StatelessWidget {
  const HomeTab({
    super.key,
    this.planSource,
    this.onOpenPath,
    this.onStartLesson,
    this.initialRoute,
  });

  /// Real plan provider. Null means the provider is absent.
  final TodayPlanSource? planSource;

  /// Next step from an empty plan.
  final VoidCallback? onOpenPath;

  /// Opens the lesson the provider named. Absent means that screen is not built.
  final ValueChanged<TodayNextLesson>? onStartLesson;

  final String? initialRoute;

  @override
  Widget build(BuildContext context) {
    final String start = initialRoute ?? TodayHubRoutes.hub.path;
    return Navigator(
      initialRoute: start,
      onGenerateRoute: (RouteSettings settings) {
        final String name = settings.name ?? start;
        final TodayRoute? route = TodayHubRoutes.resolve(name);
        final Widget? opened = route == null ? null : todayOpenedScreen(route);
        if (route != null && opened != null) {
          final TodayRoute destination = route;
          return MaterialPageRoute<void>(
            settings: RouteSettings(name: destination.path),
            builder: (BuildContext context) => opened,
          );
        }
        return MaterialPageRoute<void>(
          settings: RouteSettings(name: route?.path ?? name),
          builder: (BuildContext context) {
            return _TodayHubPage(
              route: route,
              planSource: planSource,
              onOpenPath: onOpenPath,
              onStartLesson: onStartLesson,
            );
          },
        );
      },
    );
  }
}

class _TodayHubPage extends StatefulWidget {
  const _TodayHubPage({
    required this.route,
    required this.planSource,
    required this.onOpenPath,
    required this.onStartLesson,
  });

  final TodayRoute? route;
  final TodayPlanSource? planSource;
  final VoidCallback? onOpenPath;
  final ValueChanged<TodayNextLesson>? onStartLesson;

  @override
  State<_TodayHubPage> createState() => _TodayHubPageState();
}

class _TodayHubPageState extends State<_TodayHubPage> {
  TodaySurface? _surface;
  bool _loaded = false;

  TodaySurface _read() {
    if (_loaded && _surface != null) return _surface!;
    _loaded = true;
    _surface = resolveTodaySurface(widget.planSource);
    return _surface!;
  }

  void _reload() {
    setState(() {
      _loaded = false;
    });
  }

  @override
  void didUpdateWidget(covariant _TodayHubPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.planSource != widget.planSource) {
      _loaded = false;
    }
  }

  void _leave(BuildContext context) {
    final NavigatorState navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
      return;
    }
    navigator.pushReplacementNamed(TodayHubRoutes.hub.path);
  }

  void _start(BuildContext context, TodayNextLesson lesson) {
    final ValueChanged<TodayNextLesson>? open = widget.onStartLesson;
    if (open != null) {
      open(lesson);
      return;
    }
    Navigator.of(context).pushNamed(TodayHubRoutes.lessonPlayer);
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = l10nOf(context);
    final LingPalette palette = LingPalette.of(Theme.of(context).brightness);
    final TodayRoute? route = widget.route;
    final bool hub = route?.kind == TodayRouteKind.hub;
    final bool planRoute =
        route != null &&
        route.built &&
        (route.kind == TodayRouteKind.hub ||
            route.kind == TodayRouteKind.dailyPlan);
    final TodaySurface? surface = planRoute ? _read() : null;
    final List<Widget> children = <Widget>[
      if (route != null && !hub && route.built)
        Padding(
          padding: const EdgeInsets.only(bottom: LingAfriqTokens.spacing16),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: LingButton(
              label: l10n.hubTodayBack,
              unavailableLabel: l10n.commonStateUnavailable,
              onPressed: () => _leave(context),
              role: LingButtonRole.quiet,
            ),
          ),
        ),
      if (route != null)
        Text(
          todayRouteLabel(l10n, route),
          style: _display(palette.onSurface),
          softWrap: true,
          overflow: TextOverflow.visible,
        ),
    ];
    if (surface != null) {
      children.add(const SizedBox(height: LingAfriqTokens.spacing16));
      children.add(_planRegion(context, l10n, palette, surface));
    } else {
      children.add(const SizedBox(height: LingAfriqTokens.spacing16));
      children.add(
        _marked(
          const TodaySurfaceBlocked(TodayUnavailableKind.notBuilt),
          _notice(context, l10n, TodayUnavailableKind.notBuilt),
        ),
      );
    }
    if (hub) {
      children.add(const SizedBox(height: LingAfriqTokens.spacing24));
      for (final TodayRoute link in TodayHubRoutes.links) {
        children.add(_destination(context, l10n, link));
        children.add(const SizedBox(height: LingAfriqTokens.spacing8));
      }
    }
    return ColoredBox(
      color: palette.surface,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(LingAfriqTokens.spacing16),
          children: children,
        ),
      ),
    );
  }

  Widget _planRegion(
    BuildContext context,
    AppLocalizations l10n,
    LingPalette palette,
    TodaySurface surface,
  ) {
    final Widget body = switch (surface) {
      TodaySurfaceReady(:final plan) => _ready(context, l10n, palette, plan),
      TodaySurfaceEmpty() => _empty(l10n),
      TodaySurfaceBlocked(:final kind) => _notice(context, l10n, kind),
    };
    return _marked(surface, body);
  }

  Widget _marked(TodaySurface surface, Widget child) {
    return TodayStateMark(
      kind: todaySurfaceKind(surface),
      reason: todaySurfaceReason(surface),
      child: child,
    );
  }

  Widget _ready(
    BuildContext context,
    AppLocalizations l10n,
    LingPalette palette,
    TodayShownPlan plan,
  ) {
    final String? target = plan.nextLesson.targetLine;
    return Column(
      key: TodayHubMarks.plan,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          l10n.hubTodayLead,
          style: lingBody(palette.onSurfaceVariant),
          softWrap: true,
          overflow: TextOverflow.visible,
        ),
        const SizedBox(height: LingAfriqTokens.spacing16),
        Semantics(
          label: l10n.hubTodayMinutesAbout(plan.minutes),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: palette.surfaceContainer,
                borderRadius: BorderRadius.circular(LingAfriqTokens.radiuspill),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minHeight: LingAfriqTokens.spacing48,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: LingAfriqTokens.spacing16,
                    vertical: LingAfriqTokens.spacing8,
                  ),
                  child: Text(
                    l10n.hubTodayMinutes(plan.minutes),
                    key: TodayHubMarks.minutes,
                    style: lingBody(palette.onSurface),
                    softWrap: true,
                    overflow: TextOverflow.visible,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: LingAfriqTokens.spacing24),
        Text(
          l10n.hubTodayDueReviews,
          key: TodayHubMarks.dueReviews,
          style: lingBody(palette.onSurface),
          softWrap: true,
          overflow: TextOverflow.visible,
        ),
        const SizedBox(height: LingAfriqTokens.spacing8),
        for (final TodayDueReview review in plan.dueReviews) ...<Widget>[
          Text(
            review.label,
            key: TodayHubMarks.review(review.id),
            style: lingBody(palette.onSurfaceVariant),
            softWrap: true,
            overflow: TextOverflow.visible,
          ),
          const SizedBox(height: LingAfriqTokens.spacing8),
        ],
        const SizedBox(height: LingAfriqTokens.spacing12),
        Text(
          l10n.hubTodayNextLesson,
          key: TodayHubMarks.nextLesson,
          style: lingBody(palette.onSurface),
          softWrap: true,
          overflow: TextOverflow.visible,
        ),
        const SizedBox(height: LingAfriqTokens.spacing4),
        Text(
          plan.nextLesson.title,
          key: TodayHubMarks.lessonTitle,
          style: lingBody(palette.onSurface),
          softWrap: true,
          overflow: TextOverflow.visible,
        ),
        if (target != null) ...<Widget>[
          const SizedBox(height: LingAfriqTokens.spacing4),
          Text(
            target,
            key: TodayHubMarks.lessonTarget,
            style: LingAfriqType.target.copyWith(color: palette.onSurface),
            softWrap: true,
            overflow: TextOverflow.visible,
          ),
        ],
        const SizedBox(height: LingAfriqTokens.spacing24),
        Semantics(
          label: l10n.hubTodayStartPlan(plan.minutes),
          button: true,
          onTap: () => _start(context, plan.nextLesson),
          child: ExcludeSemantics(
            child: LingButton(
              label: l10n.hubTodayStart,
              unavailableLabel: l10n.commonStateUnavailable,
              onPressed: () => _start(context, plan.nextLesson),
            ),
          ),
        ),
      ],
    );
  }

  Widget _empty(AppLocalizations l10n) {
    return LingEmptyState(
      key: TodayHubMarks.empty,
      title: l10n.hubTodayEmptyTitle,
      whatHappened: l10n.hubTodayEmptyWhat,
      why: l10n.hubTodayEmptyWhy,
      whatToDo: l10n.hubTodayEmptyNext,
      actionLabel: l10n.hubTodayOpenPath,
      unavailableLabel: l10n.commonStateUnavailable,
      onAction: widget.onOpenPath ?? () {},
    );
  }

  Widget _notice(
    BuildContext context,
    AppLocalizations l10n,
    TodayUnavailableKind kind,
  ) {
    final TodayBlockedCopy copy = todayBlockedCopy(l10n, kind);
    if (kind == TodayUnavailableKind.failed) {
      return LingErrorState(
        whatHappened: copy.what,
        why: copy.why,
        whatToDo: copy.next,
        actionLabel: copy.action ?? l10n.commonActionTryAgain,
        unavailableLabel: l10n.commonStateUnavailable,
        onAction: _reload,
      );
    }
    if (kind == TodayUnavailableKind.offline) {
      return LingOfflineState(
        whatHappened: copy.what,
        why: copy.why,
        whatToDo: copy.next,
        queuedActions: 0,
        actionLabel: copy.action ?? l10n.commonActionTryAgain,
        unavailableLabel: l10n.commonStateUnavailable,
        onAction: _reload,
      );
    }
    final String? action = copy.action;
    return Column(
      key: TodayHubMarks.notAvailable,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: ExcludeSemantics(
            child: LingCueDisc(
              fill: LingOfflineState.infoFill(Theme.of(context).brightness),
              mark: LingOfflineState.infoMark(Theme.of(context).brightness),
              kind: LingCueKind.info,
            ),
          ),
        ),
        const SizedBox(height: LingAfriqTokens.spacing16),
        Text(
          copy.what,
          style: lingBody(LingPalette.of(Theme.of(context).brightness).onSurface),
          softWrap: true,
          overflow: TextOverflow.visible,
        ),
        const SizedBox(height: LingAfriqTokens.spacing16),
        Text(
          copy.why,
          style: lingBody(
            LingPalette.of(Theme.of(context).brightness).onSurfaceVariant,
          ),
          softWrap: true,
          overflow: TextOverflow.visible,
        ),
        const SizedBox(height: LingAfriqTokens.spacing16),
        Text(
          copy.next,
          style: lingBody(
            LingPalette.of(Theme.of(context).brightness).onSurfaceVariant,
          ),
          softWrap: true,
          overflow: TextOverflow.visible,
        ),
        if (action != null) ...<Widget>[
          const SizedBox(height: LingAfriqTokens.spacing16),
          LingButton(
            label: action,
            unavailableLabel: l10n.commonStateUnavailable,
            onPressed: () => _leave(context),
            role: LingButtonRole.quiet,
          ),
        ],
      ],
    );
  }

  Widget _destination(
    BuildContext context,
    AppLocalizations l10n,
    TodayRoute route,
  ) {
    return LingListRow(
      key: TodayHubMarks.destination(route.kind),
      label: todayRouteLabel(l10n, route),
      unavailableLabel: l10n.commonStateUnavailable,
      onPressed: () {
        Navigator.of(context).pushNamed(route.path);
      },
    );
  }
}

TextStyle _display(Color color) {
  return TextStyle(
    fontFamily: LingAfriqType.displayFamily,
    fontFamilyFallback: LingAfriqType.scriptFallback,
    fontSize: kTodayDisplaySize,
    height: kTodayDisplayHeight,
    color: color,
  );
}

class LanguageItem extends ConsumerWidget {
  final Language language;
  final Function? onTap;
  const LanguageItem({
    super.key,
    required this.language,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Semantics(
      label: l10nOf(context).shellValueTapToOpen(language.name),
      button: true,
      child: InkWell(
        onTap: () async {
          onTap?.call();
          final result = ref.read(sharedPreferencesProvider).showLanguageIntro(language.id);
          if (result) {
            ref.read(navigationProvider).navigateTo(IntroductionScreen(language: language));
            return;
          }
          ref.read(navigationProvider).navigateTo(LanguageDetailScreen(language: language));
        },
        child: PanAfricanCard(
        padding: EdgeInsets.zero,
        hasHoverEffect: true,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(PanAfricanRadius.lg),
          child: Stack(
            children: [
              CachedNetworkImage(
                imageUrl: language.background ?? '',
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
                errorWidget: kErrorLogoWidget,
                placeholder: kImagePlaceHolder,
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Theme.of(context).colorScheme.scrim.withValues(alpha: 0.15),
                      Theme.of(context).colorScheme.scrim.withValues(alpha: 0.55),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: PanAfricanSpacing.sm,
                right: PanAfricanSpacing.sm,
                bottom: PanAfricanSpacing.sm,
                child: Text(
                  language.name,
                  style: PanAfricanTypography.titleMedium(context).copyWith(
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }
}


// Let me explain how it works.

// When user opens the app here is the flow,
// Check if email and password is stored.

// If email and password is not stored -> Take the user to login screen

// If email and password is stored -> 
// 1) Make a request to server to recieve the token. (We can't cache the token as it will be expired after some time)
// 2) Token Recievd (Token is required to make any further requests)
// 3) Check if the user data is stored in the cache based on the email
// 4) If user data is not stored in the cache -> Make a request to server to get the user data and save it to cache (This request takes a lot of time)
// 5) If the user data in cache -> Use the user data from cache and take user to home screen


// we can show an error message to the user if the request fails.
// The app requirement is to unlock the next lesson only when the preceeding lesson is complete Correct?

// To Mark the lesson complete, api request has to be made and successfully.
// If it fails and takes the user to next lessson, the purpose is gone, now the user will be on the next lesson, but the previous lesson is not marked complete.
// Now the next question request is success and that question is marked as complete.


// Now we have such heirachy
// Lesson 1 -> Completed
// Lesson 2 -> Not Completed
// Lesson 3 -> Completed


// What workaround do you have for this



// Hello,


// Thank you for your resubmission. Upon further review, we identified an additional issue that needs your attention. See below for more information.


// If you have any questions, we are here to help. Reply to this message in App Store Connect and let us know.


// Guideline 2.5.4 - Performance - Software Requirements

// Your app declares support for location in the UIBackgroundModes key in your Info.plist file but does not have any features that require persistent location. Apps that declare support for location in the UIBackgroundModes key in your Info.plist file must have features that require persistent location.


// Next Steps


// To resolve this issue, please revise your app to include features that require the persistent use of real-time location updates while the app is in the background.


// If your app does not require persistent real-time location updates, please remove the "location" setting from the UIBackgroundModes key. You may wish to use the significant-change location service or the region monitoring location service if persistent real-time location updates are not required for your app features.


// Resources


// For more information, please review the Starting the Significant-Change Location Service and Monitoring Geographical Regions.


// Guideline 5.1.2 - Legal - Privacy - Data Use and Sharing

// The app privacy information you provided in App Store Connect indicates you collect data in order to track the user, including Precise Location. However, you do not use App Tracking Transparency to request the user's permission before tracking their activity.


// Starting with iOS 14.5, apps on the App Store need to receive the user’s permission through the AppTrackingTransparency framework before collecting data used to track them. This requirement protects the privacy of App Store users.


// Next Steps


// Here are two ways to resolve this issue:


// - If you do not currently track, or decide to stop tracking, update your app privacy information in App Store Connect. You must have the Account Holder or Admin role to update app privacy information.


// - If you track users, you must implement App Tracking Transparency and request permission before collecting data used to track. When you resubmit, indicate in the Review Notes where the permission request is located.


// Resources