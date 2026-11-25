import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lingafriq/design/components/ling_state.dart';
import 'package:lingafriq/design/components/ling_text_field.dart';
import 'package:lingafriq/design/states/empty_state.dart';
import 'package:lingafriq/design/tokens.g.dart';
import 'package:lingafriq/l10n/generated/app_localizations.dart';
import 'package:lingafriq/l10n/l10n_of.dart';
import 'package:lingafriq/services/search_index_service.dart';
import 'package:lingafriq/widgets/word_card_sheet.dart';

/// Page the shell Search control opens.
///
/// A query lists Words, then Features, then Content. A word opens its Word
/// Card. A feature opens its route, or an unlock preview when that route is
/// not built. Feature names come from the route map.
class GlobalSearchPage extends StatefulWidget {
  const GlobalSearchPage({
    super.key,
    this.service,
    this.offline = false,
    this.onOpenDirectory,
  });

  /// Route name used when [open] pushes this page.
  static const String routeName = 'global-search';

  /// Directory the empty state offers. This is the features guide route.
  static const String directoryRoute = '/features_guide';

  static const Key queryKey = ValueKey<String>('global-search-query');
  static const Key idleKey = ValueKey<String>('global-search-idle');
  static const Key emptyKey = ValueKey<String>('global-search-empty');
  static const Key offlineKey = ValueKey<String>('global-search-offline');
  static const Key directoryKey = ValueKey<String>('global-search-directory');

  static Key groupKey(SearchBucket bucket) =>
      ValueKey<String>('global-search-group-${bucket.name}');

  static Key hitKey(String id) => ValueKey<String>('global-search-hit-$id');

  /// Pushes this page on the root navigator the Search control can reach.
  static void open(
    BuildContext context, {
    bool offline = false,
    SearchIndexService? service,
    VoidCallback? onOpenDirectory,
  }) {
    unawaited(
      Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute<void>(
          settings: const RouteSettings(name: routeName),
          builder: (BuildContext context) {
            return GlobalSearchPage(
              offline: offline,
              service: service,
              onOpenDirectory: onOpenDirectory,
            );
          },
        ),
      ),
    );
  }

  /// Index to search. Null uses the shipped route map.
  final SearchIndexService? service;

  /// When true, results are the local index and the offline label shows.
  final bool offline;

  /// Called by the empty-state directory action. Null pushes [directoryRoute].
  final VoidCallback? onOpenDirectory;

  @override
  State<GlobalSearchPage> createState() => GlobalSearchPageState();
}

class GlobalSearchPageState extends State<GlobalSearchPage> {
  final TextEditingController _controller = TextEditingController();
  late SearchIndexService _service;

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? SearchIndexService.routeMapCatalog();
    _controller.addListener(_onQuery);
  }

  @override
  void didUpdateWidget(GlobalSearchPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.service != null && !identical(widget.service, _service)) {
      _service = widget.service!;
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onQuery);
    _controller.dispose();
    super.dispose();
  }

  void _onQuery() {
    setState(() {});
  }

  SearchResults get _results => _service.search(_controller.text);

  void _openWord(SearchWord word) {
    unawaited(showWordCardSheet(context, lexeme: word.toLexeme()));
  }

  void _openFeature(SearchFeature feature) {
    if (feature.routeBuilt) {
      unawaited(Navigator.of(context).pushNamed('/${feature.key}'));
      return;
    }
    unawaited(
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          settings: const RouteSettings(name: GlobalSearchUnlockPage.routeName),
          builder: (BuildContext context) {
            return GlobalSearchUnlockPage(feature: feature);
          },
        ),
      ),
    );
  }

  void _openContent(SearchContent item) {
    final String? route = item.openRoute;
    if (route != null) {
      unawaited(Navigator.of(context).pushNamed('/$route'));
      return;
    }
    unawaited(
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          settings: const RouteSettings(
            name: GlobalSearchContentPage.routeName,
          ),
          builder: (BuildContext context) {
            return GlobalSearchContentPage(content: item);
          },
        ),
      ),
    );
  }

  void _offerDirectory() {
    final VoidCallback? custom = widget.onOpenDirectory;
    if (custom != null) {
      custom();
      return;
    }
    unawaited(Navigator.of(context).pushNamed(GlobalSearchPage.directoryRoute));
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = l10nOf(context);
    final LingPalette palette = LingPalette.of(Theme.of(context).brightness);
    final SearchResults results = _results;
    final bool queried = results.query.isNotEmpty;
    return Scaffold(
      backgroundColor: palette.surface,
      body: SafeArea(
        child: CustomScrollView(
          slivers: <Widget>[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(LingAfriqTokens.spacing16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Align(
                      alignment: Alignment.centerLeft,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          minHeight: LingAfriqTokens.spacing48,
                        ),
                        child: TextButton(
                          onPressed: () {
                            unawaited(Navigator.of(context).maybePop());
                          },
                          child: Text(
                            l10n.searchBack,
                            softWrap: true,
                            overflow: TextOverflow.visible,
                          ),
                        ),
                      ),
                    ),
                    Text(
                      l10n.shellSearch,
                      style: lingBody(palette.onSurface),
                      softWrap: true,
                      overflow: TextOverflow.visible,
                    ),
                    const SizedBox(height: LingAfriqTokens.spacing16),
                    LingTextField(
                      key: GlobalSearchPage.queryKey,
                      label: l10n.searchFieldLabel,
                      unavailableLabel: l10n.commonStateUnavailable,
                      controller: _controller,
                    ),
                  ],
                ),
              ),
            ),
            if (widget.offline && queried)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: LingAfriqTokens.spacing16,
                  ),
                  child: Text(
                    l10n.searchOfflineLabel,
                    key: GlobalSearchPage.offlineKey,
                    style: lingBody(palette.onSurface),
                    softWrap: true,
                    overflow: TextOverflow.visible,
                  ),
                ),
              ),
            if (!queried)
              SliverToBoxAdapter(child: _Idle(palette: palette))
            else if (results.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  key: GlobalSearchPage.directoryKey,
                  padding: const EdgeInsets.all(LingAfriqTokens.spacing16),
                  child: LingEmptyState(
                    key: GlobalSearchPage.emptyKey,
                    title: l10n.searchEmptyTitle,
                    whatHappened: l10n.searchEmptyWhat(results.query),
                    why: l10n.searchEmptyWhy,
                    whatToDo: l10n.searchEmptyNext,
                    actionLabel: l10n.searchEmptyAction,
                    unavailableLabel: l10n.commonStateUnavailable,
                    onAction: _offerDirectory,
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  LingAfriqTokens.spacing16,
                  LingAfriqTokens.spacing16,
                  LingAfriqTokens.spacing16,
                  LingAfriqTokens.spacing16,
                ),
                sliver: SliverList(
                  delegate: SliverChildListDelegate(
                    _hits(l10n, palette, results),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<Widget> _hits(
    AppLocalizations l10n,
    LingPalette palette,
    SearchResults results,
  ) {
    final List<Widget> tiles = <Widget>[];
    void addGroup(SearchBucket bucket, String title, List<Widget> children) {
      if (children.isEmpty) return;
      tiles.add(
        Semantics(
          header: true,
          child: Padding(
            padding: const EdgeInsets.only(bottom: LingAfriqTokens.spacing8),
            child: Text(
              title,
              key: GlobalSearchPage.groupKey(bucket),
              style: lingBody(palette.onSurface),
              softWrap: true,
              overflow: TextOverflow.visible,
            ),
          ),
        ),
      );
      tiles.addAll(children);
      tiles.add(const SizedBox(height: LingAfriqTokens.spacing16));
    }

    addGroup(SearchBucket.words, l10n.searchWords, <Widget>[
      for (final SearchWordHit hit in results.words)
        _HitTile(
          id: hit.word.id,
          title: hit.word.surface,
          subtitle: hit.word.gloss,
          semanticsLabel: l10n.searchOpenWord(hit.word.surface),
          palette: palette,
          onTap: () => _openWord(hit.word),
        ),
    ]);
    addGroup(SearchBucket.features, l10n.searchFeatures, <Widget>[
      for (final SearchFeatureHit hit in results.features)
        _HitTile(
          id: hit.feature.key,
          title: hit.feature.label,
          subtitle: hit.feature.hub,
          semanticsLabel: l10n.searchOpenFeature(hit.feature.label),
          palette: palette,
          onTap: () => _openFeature(hit.feature),
        ),
    ]);
    addGroup(SearchBucket.content, l10n.searchContent, <Widget>[
      for (final SearchContentHit hit in results.content)
        _HitTile(
          id: hit.content.id,
          title: hit.content.title,
          subtitle: hit.content.detail,
          semanticsLabel: l10n.searchOpenContent(hit.content.title),
          palette: palette,
          onTap: () => _openContent(hit.content),
        ),
    ]);
    return tiles;
  }
}

class _Idle extends StatelessWidget {
  const _Idle({required this.palette});

  final LingPalette palette;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = l10nOf(context);
    return Padding(
      key: GlobalSearchPage.idleKey,
      padding: const EdgeInsets.all(LingAfriqTokens.spacing16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            l10n.searchIdleWhat,
            style: lingBody(palette.onSurface),
            softWrap: true,
            overflow: TextOverflow.visible,
          ),
          const SizedBox(height: LingAfriqTokens.spacing16),
          Text(
            l10n.searchIdleWhy,
            style: lingBody(palette.onSurfaceVariant),
            softWrap: true,
            overflow: TextOverflow.visible,
          ),
          const SizedBox(height: LingAfriqTokens.spacing16),
          Text(
            l10n.searchIdleNext,
            style: lingBody(palette.onSurfaceVariant),
            softWrap: true,
            overflow: TextOverflow.visible,
          ),
        ],
      ),
    );
  }
}

class _HitTile extends StatelessWidget {
  const _HitTile({
    required this.id,
    required this.title,
    required this.semanticsLabel,
    required this.palette,
    required this.onTap,
    this.subtitle,
  });

  final String id;
  final String title;
  final String semanticsLabel;
  final LingPalette palette;
  final VoidCallback onTap;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final String? detail = subtitle;
    return Semantics(
      key: GlobalSearchPage.hitKey(id),
      container: true,
      button: true,
      label: semanticsLabel,
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: LingAfriqTokens.spacing48),
        child: InkWell(
          onTap: onTap,
          excludeFromSemantics: true,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: LingAfriqTokens.spacing8,
            ),
            child: ExcludeSemantics(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: lingBody(palette.onSurface),
                    softWrap: true,
                    overflow: TextOverflow.visible,
                  ),
                  if (detail != null && detail.isNotEmpty)
                    Text(
                      detail,
                      style: lingBody(palette.onSurfaceVariant),
                      softWrap: true,
                      overflow: TextOverflow.visible,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Unlock preview for a feature whose route is not built.
class GlobalSearchUnlockPage extends StatelessWidget {
  const GlobalSearchUnlockPage({required this.feature, super.key});

  static const String routeName = 'global-search-unlock';

  final SearchFeature feature;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = l10nOf(context);
    final LingPalette palette = LingPalette.of(Theme.of(context).brightness);
    return Scaffold(
      backgroundColor: palette.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(LingAfriqTokens.spacing16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                l10n.searchPreviewLabel,
                style: lingBody(palette.onSurface),
                softWrap: true,
                overflow: TextOverflow.visible,
              ),
              const SizedBox(height: LingAfriqTokens.spacing16),
              Text(
                feature.label,
                style: lingBody(palette.onSurface),
                softWrap: true,
                overflow: TextOverflow.visible,
              ),
              const SizedBox(height: LingAfriqTokens.spacing16),
              Text(
                l10n.searchUnlockWhat(feature.label),
                style: lingBody(palette.onSurfaceVariant),
                softWrap: true,
                overflow: TextOverflow.visible,
              ),
              const SizedBox(height: LingAfriqTokens.spacing16),
              Text(
                l10n.searchUnlockWhy(feature.unlockStage),
                style: lingBody(palette.onSurfaceVariant),
                softWrap: true,
                overflow: TextOverflow.visible,
              ),
              const SizedBox(height: LingAfriqTokens.spacing16),
              Text(
                feature.learningLoop,
                style: lingBody(palette.onSurface),
                softWrap: true,
                overflow: TextOverflow.visible,
              ),
              const SizedBox(height: LingAfriqTokens.spacing16),
              Text(
                feature.hub,
                style: lingBody(palette.onSurfaceVariant),
                softWrap: true,
                overflow: TextOverflow.visible,
              ),
              const SizedBox(height: LingAfriqTokens.spacing16),
              Text(
                l10n.searchUnlockNext,
                style: lingBody(palette.onSurfaceVariant),
                softWrap: true,
                overflow: TextOverflow.visible,
              ),
              const SizedBox(height: LingAfriqTokens.spacing16),
              Align(
                alignment: Alignment.centerLeft,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minHeight: LingAfriqTokens.spacing48,
                  ),
                  child: TextButton(
                    onPressed: () {
                      unawaited(Navigator.of(context).maybePop());
                    },
                    child: Text(
                      l10n.searchBack,
                      softWrap: true,
                      overflow: TextOverflow.visible,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A content hit that has no built route.
class GlobalSearchContentPage extends StatelessWidget {
  const GlobalSearchContentPage({required this.content, super.key});

  static const String routeName = 'global-search-content';

  final SearchContent content;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = l10nOf(context);
    final LingPalette palette = LingPalette.of(Theme.of(context).brightness);
    return Scaffold(
      backgroundColor: palette.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(LingAfriqTokens.spacing16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                content.title,
                style: lingBody(palette.onSurface),
                softWrap: true,
                overflow: TextOverflow.visible,
              ),
              if (content.detail.isNotEmpty) ...<Widget>[
                const SizedBox(height: LingAfriqTokens.spacing16),
                Text(
                  content.detail,
                  style: lingBody(palette.onSurfaceVariant),
                  softWrap: true,
                  overflow: TextOverflow.visible,
                ),
              ],
              const SizedBox(height: LingAfriqTokens.spacing16),
              Align(
                alignment: Alignment.centerLeft,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minHeight: LingAfriqTokens.spacing48,
                  ),
                  child: TextButton(
                    onPressed: () {
                      unawaited(Navigator.of(context).maybePop());
                    },
                    child: Text(
                      l10n.searchBack,
                      softWrap: true,
                      overflow: TextOverflow.visible,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
