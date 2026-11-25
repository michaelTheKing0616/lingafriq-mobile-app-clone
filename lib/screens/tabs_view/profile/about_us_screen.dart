import 'package:flutter/material.dart';
import 'package:lingafriq/design/components/ling_button.dart';
import 'package:lingafriq/design/components/ling_state.dart';
import 'package:lingafriq/design/states/empty_state.dart';
import 'package:lingafriq/design/states/error_state.dart';
import 'package:lingafriq/design/states/offline_state.dart';
import 'package:lingafriq/design/tokens.g.dart';
import 'package:lingafriq/l10n/generated/app_localizations.dart';
import 'package:lingafriq/l10n/l10n_of.dart';

/// What an About load returned. [ready] is the only status that carries a story.
enum AboutPageStatus { loading, ready, empty, error, offline }

class AboutView {
  const AboutView._(this.status, this.story);

  const AboutView.ready(String story) : this._(AboutPageStatus.ready, story);

  const AboutView.empty() : this._(AboutPageStatus.empty, null);

  const AboutView.error() : this._(AboutPageStatus.error, null);

  const AboutView.offline() : this._(AboutPageStatus.offline, null);

  final AboutPageStatus status;
  final String? story;
}

/// About LingAfriq.
///
/// With no loader, the page is empty. A failed load clears any story that
/// was on screen.
class AboutUsScreen extends StatefulWidget {
  const AboutUsScreen({super.key, this.load});

  /// App route `/me/about`. The map key drops the leading slash.
  static const String routePath = '/me/about';

  static const String routeKey = 'me/about';

  static const Key emptyKey = ValueKey<String>('me-about-empty');

  static const Key errorKey = ValueKey<String>('me-about-error');

  static const Key offlineKey = ValueKey<String>('me-about-offline');

  static const Key storyKey = ValueKey<String>('me-about-story');

  /// Loads the story. Null means there is no story to show.
  final Future<AboutView> Function()? load;

  @override
  State<AboutUsScreen> createState() => _AboutUsScreenState();
}

class _AboutUsScreenState extends State<AboutUsScreen> {
  AboutPageStatus _status = AboutPageStatus.loading;
  String? _story;

  @override
  void initState() {
    super.initState();
    if (widget.load == null) {
      _status = AboutPageStatus.empty;
      _story = null;
      return;
    }
    _status = AboutPageStatus.loading;
    _story = null;
    _run();
  }

  @override
  void didUpdateWidget(AboutUsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.load, widget.load)) {
      _story = null;
      if (widget.load == null) {
        _status = AboutPageStatus.empty;
        return;
      }
      _status = AboutPageStatus.loading;
      _run();
    }
  }

  Future<void> _run() async {
    final Future<AboutView> Function()? load = widget.load;
    if (load == null) {
      if (!mounted) return;
      setState(() {
        _status = AboutPageStatus.empty;
        _story = null;
      });
      return;
    }
    try {
      final AboutView view = await load();
      if (!mounted) return;
      final String story = (view.story ?? '').trim();
      setState(() {
        if (view.status == AboutPageStatus.ready && story.isNotEmpty) {
          _status = AboutPageStatus.ready;
          _story = story;
          return;
        }
        _story = null;
        if (view.status == AboutPageStatus.offline) {
          _status = AboutPageStatus.offline;
        } else if (view.status == AboutPageStatus.error ||
            view.status == AboutPageStatus.loading) {
          _status = AboutPageStatus.error;
        } else {
          _status = AboutPageStatus.empty;
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _status = AboutPageStatus.error;
        _story = null;
      });
    }
  }

  void _retry() {
    setState(() {
      _status = AboutPageStatus.loading;
      _story = null;
    });
    _run();
  }

  void _back() {
    final NavigatorState? navigator = Navigator.maybeOf(context);
    if (navigator != null && navigator.canPop()) navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = l10nOf(context);
    final LingPalette palette = LingPalette.of(Theme.of(context).brightness);
    return Scaffold(
      backgroundColor: palette.surface,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(LingAfriqTokens.spacing16),
          children: <Widget>[
            Text(
              l10n.hubHMeAbout,
              style: lingBody(palette.onSurface),
              softWrap: true,
              overflow: TextOverflow.visible,
            ),
            const SizedBox(height: LingAfriqTokens.spacing16),
            _body(l10n, palette),
            const SizedBox(height: LingAfriqTokens.spacing16),
            LingButton(
              label: l10n.hubHMeBack,
              unavailableLabel: l10n.commonStateUnavailable,
              onPressed: _back,
            ),
          ],
        ),
      ),
    );
  }

  Widget _body(AppLocalizations l10n, LingPalette palette) {
    switch (_status) {
      case AboutPageStatus.loading:
        return Text(
          l10n.loading,
          style: lingBody(palette.onSurface),
          softWrap: true,
          overflow: TextOverflow.visible,
        );
      case AboutPageStatus.empty:
        return LingEmptyState(
          key: AboutUsScreen.emptyKey,
          title: l10n.hubHMeAbout,
          whatHappened: l10n.revRvMeAboutEmptyWhat,
          why: l10n.revRvMeAboutEmptyWhy,
          whatToDo: l10n.revRvMeAboutEmptyNext,
          actionLabel: l10n.hubHMeBack,
          unavailableLabel: l10n.commonStateUnavailable,
          onAction: _back,
        );
      case AboutPageStatus.error:
        return LingErrorState(
          key: AboutUsScreen.errorKey,
          whatHappened: l10n.revRvMeAboutErrorWhat,
          why: l10n.revRvMeAboutErrorWhy,
          whatToDo: l10n.revRvMeAboutErrorNext,
          actionLabel: l10n.commonActionTryAgain,
          unavailableLabel: l10n.commonStateUnavailable,
          onAction: _retry,
        );
      case AboutPageStatus.offline:
        return LingOfflineState(
          key: AboutUsScreen.offlineKey,
          whatHappened: l10n.shellOfflineWhat,
          why: l10n.revRvMeAboutOfflineWhy,
          whatToDo: l10n.shellOfflineNext,
          queuedActions: 0,
          actionLabel: l10n.commonActionTryAgain,
          unavailableLabel: l10n.commonStateUnavailable,
          onAction: _retry,
        );
      case AboutPageStatus.ready:
        return Text(
          _story ?? '',
          key: AboutUsScreen.storyKey,
          style: lingBody(palette.onSurface),
          softWrap: true,
          overflow: TextOverflow.visible,
        );
    }
  }
}
