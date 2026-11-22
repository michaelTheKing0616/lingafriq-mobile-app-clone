import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/design/components/ling_button.dart';
import 'package:lingafriq/design/components/ling_state.dart';
import 'package:lingafriq/design/states/empty_state.dart';
import 'package:lingafriq/design/states/error_state.dart';
import 'package:lingafriq/design/states/offline_state.dart';
import 'package:lingafriq/design/tokens.g.dart';
import 'package:lingafriq/l10n/generated/app_localizations.dart';
import 'package:lingafriq/l10n/l10n_of.dart';
import 'package:lingafriq/models/lesson_item_model.dart';
import 'package:lingafriq/services/lesson_item_verification_service.dart';

/// What a verification load returned. [ready] is the only status with items.
enum VerificationListStatus { loading, ready, empty, error, offline, limited }

/// Lesson items waiting for a verified native speaker.
///
/// A row with no text is dropped. No stand-in line is added.
List<LessonItem> verificationItemsFromRows(List<Map<String, dynamic>> rows) {
  final List<LessonItem> items = <LessonItem>[];
  for (final Map<String, dynamic> row in rows) {
    final LessonItem item = LessonItem.fromJson(row);
    if (item.text.trim().isEmpty) continue;
    items.add(item);
  }
  return items;
}

/// Verify queue for lesson items.
///
/// [verifiedNativeSpeaker] is passed by the caller. When it is omitted or
/// false, the queue stays closed and no item is loaded. A failed load clears
/// the previous list.
class LessonItemVerificationScreen extends StatefulWidget {
  const LessonItemVerificationScreen({
    super.key,
    this.languageCode,
    this.verifiedNativeSpeaker = false,
    this.load,
  }) : live = false;

  const LessonItemVerificationScreen.live({
    super.key,
    this.languageCode,
    this.verifiedNativeSpeaker = false,
  }) : load = null,
       live = true;

  /// App route `/village/verify`. The map key drops the leading slash.
  static const String routePath = '/village/verify';

  static const String routeKey = 'village/verify';

  static const Key emptyKey = ValueKey<String>('verify-empty');

  static const Key errorKey = ValueKey<String>('verify-error');

  static const Key offlineKey = ValueKey<String>('verify-offline');

  static const Key limitedKey = ValueKey<String>('verify-limited');

  static const Key listKey = ValueKey<String>('verify-list');

  final String? languageCode;

  /// True only when the caller passes that this person is a verified native speaker.
  final bool verifiedNativeSpeaker;

  final Future<VerificationQueue> Function()? load;

  /// Reads the pending queue from the existing client.
  final bool live;

  @override
  State<LessonItemVerificationScreen> createState() =>
      _LessonItemVerificationScreenState();
}

class _LessonItemVerificationScreenState
    extends State<LessonItemVerificationScreen> {
  VerificationListStatus _status = VerificationListStatus.loading;
  List<LessonItem> _items = const <LessonItem>[];
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    if (!widget.verifiedNativeSpeaker) {
      _status = VerificationListStatus.limited;
      return;
    }
    if (widget.load == null && !widget.live) {
      _status = VerificationListStatus.empty;
      return;
    }
    _schedule(_generation);
  }

  @override
  void didUpdateWidget(LessonItemVerificationScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (identical(oldWidget.load, widget.load) &&
        oldWidget.live == widget.live &&
        oldWidget.verifiedNativeSpeaker == widget.verifiedNativeSpeaker &&
        oldWidget.languageCode == widget.languageCode) {
      return;
    }
    _items = const <LessonItem>[];
    _generation += 1;
    if (!widget.verifiedNativeSpeaker) {
      _status = VerificationListStatus.limited;
      return;
    }
    if (widget.load == null && !widget.live) {
      _status = VerificationListStatus.empty;
      return;
    }
    _status = VerificationListStatus.loading;
    _schedule(_generation);
  }

  void _schedule(int generation) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || generation != _generation) return;
      _run(generation);
    });
  }

  Future<void> _run(int generation) async {
    if (!widget.verifiedNativeSpeaker) return;
    final Future<VerificationQueue> Function() load = widget.load ?? _loadLive;
    try {
      final VerificationQueue view = await load();
      if (!mounted || generation != _generation) return;
      setState(() => _apply(view));
    } catch (_) {
      if (!mounted || generation != _generation) return;
      setState(() {
        _status = VerificationListStatus.error;
        _items = const <LessonItem>[];
      });
    }
  }

  Future<VerificationQueue> _loadLive() async {
    final ProviderContainer? container = _container();
    if (container == null) return const VerificationQueue.empty();
    final LessonItemVerificationService service = container.read(
      lessonItemVerificationServiceProvider,
    );
    return service.loadPending(languageCode: widget.languageCode);
  }

  ProviderContainer? _container() {
    try {
      return ProviderScope.containerOf(context, listen: false);
    } catch (_) {
      return null;
    }
  }

  void _apply(VerificationQueue view) {
    final List<LessonItem> items = verificationItemsFromRows(view.items);
    if (view.status == VerificationQueueStatus.ready && items.isNotEmpty) {
      _status = VerificationListStatus.ready;
      _items = List<LessonItem>.unmodifiable(items);
      return;
    }
    _items = const <LessonItem>[];
    if (view.status == VerificationQueueStatus.offline) {
      _status = VerificationListStatus.offline;
    } else if (view.status == VerificationQueueStatus.error) {
      _status = VerificationListStatus.error;
    } else {
      _status = VerificationListStatus.empty;
    }
  }

  void _retry() {
    if (!widget.verifiedNativeSpeaker) return;
    setState(() {
      _items = const <LessonItem>[];
      _status = VerificationListStatus.loading;
      _generation += 1;
    });
    _schedule(_generation);
  }

  void _back() {
    final NavigatorState nav = Navigator.of(context);
    nav.popUntil((Route<dynamic> route) {
      final String? name = route.settings.name;
      return name == '/village' || name == '/village/map' || route.isFirst;
    });
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = l10nOf(context);
    final Widget body = switch (_status) {
      VerificationListStatus.loading => _loading(context, l10n),
      VerificationListStatus.limited => _limited(context, l10n),
      VerificationListStatus.empty => LingEmptyState(
        key: LessonItemVerificationScreen.emptyKey,
        title: l10n.revRvContribVerifyTitle,
        whatHappened: l10n.revRvContribVerifyEmptyWhat,
        why: l10n.revRvContribVerifyEmptyWhy,
        whatToDo: l10n.revRvContribVerifyEmptyNext,
        actionLabel: l10n.hubHVillageBack,
        unavailableLabel: l10n.commonStateUnavailable,
        onAction: _back,
      ),
      VerificationListStatus.error => LingErrorState(
        key: LessonItemVerificationScreen.errorKey,
        whatHappened: l10n.revRvContribVerifyFailWhat,
        why: l10n.revRvContribVerifyFailWhy,
        whatToDo: l10n.revRvContribVerifyFailNext,
        actionLabel: l10n.commonActionTryAgain,
        unavailableLabel: l10n.commonStateUnavailable,
        onAction: _retry,
      ),
      VerificationListStatus.offline => LingOfflineState(
        key: LessonItemVerificationScreen.offlineKey,
        whatHappened: l10n.shellOfflineWhat,
        why: l10n.revRvContribVerifyOfflineWhy,
        whatToDo: l10n.shellOfflineNext,
        queuedActions: 0,
        actionLabel: l10n.commonActionTryAgain,
        unavailableLabel: l10n.commonStateUnavailable,
        onAction: _retry,
      ),
      VerificationListStatus.ready => _list(context, l10n),
    };
    return _frame(context, l10n, body);
  }

  Widget _loading(BuildContext context, AppLocalizations l10n) {
    return Text(
      l10n.loading,
      style: lingBody(LingPalette.of(Theme.of(context).brightness).onSurface),
      softWrap: true,
      overflow: TextOverflow.visible,
    );
  }

  Widget _limited(BuildContext context, AppLocalizations l10n) {
    final LingPalette palette = LingPalette.of(Theme.of(context).brightness);
    return Column(
      key: LessonItemVerificationScreen.limitedKey,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          l10n.revRvContribVerifyLimitedWhat,
          style: lingBody(palette.onSurface),
          softWrap: true,
          overflow: TextOverflow.visible,
        ),
        const SizedBox(height: LingAfriqTokens.spacing16),
        Text(
          l10n.revRvContribVerifyLimitedWhy,
          style: lingBody(palette.onSurfaceVariant),
          softWrap: true,
          overflow: TextOverflow.visible,
        ),
        const SizedBox(height: LingAfriqTokens.spacing16),
        Text(
          l10n.revRvContribVerifyLimitedNext,
          style: lingBody(palette.onSurfaceVariant),
          softWrap: true,
          overflow: TextOverflow.visible,
        ),
        const SizedBox(height: LingAfriqTokens.spacing16),
        LingButton(
          label: l10n.hubHVillageBack,
          unavailableLabel: l10n.commonStateUnavailable,
          onPressed: _back,
        ),
      ],
    );
  }

  Widget _frame(BuildContext context, AppLocalizations l10n, Widget body) {
    final LingPalette palette = LingPalette.of(Theme.of(context).brightness);
    final bool canLeave =
        _status == VerificationListStatus.loading ||
        _status == VerificationListStatus.ready;
    return Scaffold(
      backgroundColor: palette.surface,
      body: SafeArea(
        child: Semantics(
          container: true,
          label: l10n.revRvContribVerifyTitle,
          child: ListView(
            padding: const EdgeInsets.all(LingAfriqTokens.spacing16),
            children: <Widget>[
              Text(
                l10n.revRvContribVerifyTitle,
                style: lingBody(palette.onSurface),
                softWrap: true,
                overflow: TextOverflow.visible,
              ),
              const SizedBox(height: LingAfriqTokens.spacing16),
              body,
              if (canLeave) ...<Widget>[
                const SizedBox(height: LingAfriqTokens.spacing16),
                LingButton(
                  label: l10n.hubHVillageBack,
                  unavailableLabel: l10n.commonStateUnavailable,
                  onPressed: _back,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _list(BuildContext context, AppLocalizations l10n) {
    final LingPalette palette = LingPalette.of(Theme.of(context).brightness);
    return Column(
      key: LessonItemVerificationScreen.listKey,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (final LessonItem item in _items) ...<Widget>[
          Text(
            item.text,
            style: lingBody(palette.onSurface),
            softWrap: true,
            overflow: TextOverflow.visible,
          ),
          if (item.translation.trim().isNotEmpty) ...<Widget>[
            const SizedBox(height: LingAfriqTokens.spacing8),
            Text(
              item.translation,
              style: lingBody(palette.onSurfaceVariant),
              softWrap: true,
              overflow: TextOverflow.visible,
            ),
          ],
          const SizedBox(height: LingAfriqTokens.spacing16),
        ],
      ],
    );
  }
}
