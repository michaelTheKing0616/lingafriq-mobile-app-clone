import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lingafriq/design/components/ling_button.dart';
import 'package:lingafriq/design/components/ling_state.dart';
import 'package:lingafriq/design/components/ling_text_field.dart';
import 'package:lingafriq/design/states/empty_state.dart';
import 'package:lingafriq/design/tokens.g.dart';
import 'package:lingafriq/l10n/generated/app_localizations.dart';
import 'package:lingafriq/l10n/l10n_of.dart';
import 'package:lingafriq/navigation/feature_directory.dart';

/// Button Me uses to open the directory.
class AllFeaturesButton extends StatelessWidget {
  const AllFeaturesButton({super.key});

  static const Key buttonKey = ValueKey<String>('directory-open');

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = l10nOf(context);
    return Semantics(
      key: buttonKey,
      container: true,
      button: true,
      label: l10n.directoryOpenSemantics,
      onTap: () => AllFeaturesScreen.open(context),
      child: LingButton(
        label: l10n.directoryTitle,
        unavailableLabel: l10n.commonStateUnavailable,
        onPressed: () => AllFeaturesScreen.open(context),
      ),
    );
  }
}

/// Me → All features. An A to Z list of the route map, grouped by hub.
class AllFeaturesScreen extends StatefulWidget {
  const AllFeaturesScreen({super.key, this.directory, this.hiddenKeys});

  /// Route name used when [open] pushes this page.
  static const String routeName = '/me/all-features';

  static const Key searchKey = ValueKey<String>('directory-search');
  static const Key emptyKey = ValueKey<String>('directory-empty');

  static Key hubKey(String hub) => ValueKey<String>('directory-hub-$hub');

  static Key entryKey(String key) => ValueKey<String>('directory-entry-$key');

  static Key previewKey(String key) =>
      ValueKey<String>('directory-preview-$key');

  /// Pushes this page. Me calls this from [AllFeaturesButton].
  static Future<void> open(BuildContext context) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: routeName),
        builder: (BuildContext context) => const AllFeaturesScreen(),
      ),
    );
  }

  /// Null uses the shipped route map.
  final FeatureDirectory? directory;

  /// Keys left off this list. The catalog still contains them.
  final Set<String>? hiddenKeys;

  @override
  State<AllFeaturesScreen> createState() => AllFeaturesScreenState();
}

class AllFeaturesScreenState extends State<AllFeaturesScreen> {
  final TextEditingController _controller = TextEditingController();
  late FeatureDirectory _directory;

  @override
  void initState() {
    super.initState();
    _directory = widget.directory ?? FeatureDirectory.shipped();
    _controller.addListener(_onQuery);
  }

  @override
  void didUpdateWidget(AllFeaturesScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final FeatureDirectory? next = widget.directory;
    if (next != null && !identical(next, _directory)) {
      _directory = next;
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

  void _clear() {
    _controller.clear();
  }

  void _openPreview(FeatureEntry entry) {
    unawaited(
      Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          settings: const RouteSettings(name: FeaturePreviewPage.routeName),
          builder: (BuildContext context) => FeaturePreviewPage(entry: entry),
        ),
      ),
    );
  }

  void _openEntry(FeatureEntry entry) {
    final String? routeKey = entry.routeKey;
    if (entry.locked || routeKey == null) {
      _openPreview(entry);
      return;
    }
    unawaited(Navigator.of(context).pushNamed('/$routeKey'));
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = l10nOf(context);
    final LingPalette palette = LingPalette.of(Theme.of(context).brightness);
    final String query = _controller.text;
    final List<FeatureHubGroup> groups = _directory.groupsFor(
      query,
      hiddenKeys: widget.hiddenKeys ?? const <String>{},
    );
    final bool queried = query.trim().isNotEmpty;
    return Scaffold(
      backgroundColor: palette.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(LingAfriqTokens.spacing16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
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
                      l10n.directoryBack,
                      softWrap: true,
                      overflow: TextOverflow.visible,
                    ),
                  ),
                ),
              ),
              Text(
                l10n.directoryTitle,
                style: lingBody(palette.onSurface),
                softWrap: true,
                overflow: TextOverflow.visible,
              ),
              const SizedBox(height: LingAfriqTokens.spacing16),
              LingTextField(
                key: AllFeaturesScreen.searchKey,
                label: l10n.directorySearchLabel,
                unavailableLabel: l10n.commonStateUnavailable,
                controller: _controller,
              ),
              const SizedBox(height: LingAfriqTokens.spacing16),
              if (queried && groups.isEmpty)
                LingEmptyState(
                  key: AllFeaturesScreen.emptyKey,
                  title: l10n.directoryEmptyTitle,
                  whatHappened: l10n.directoryEmptyWhat(query.trim()),
                  why: l10n.directoryEmptyWhy,
                  whatToDo: l10n.directoryEmptyNext,
                  actionLabel: l10n.directoryEmptyAction,
                  unavailableLabel: l10n.commonStateUnavailable,
                  onAction: _clear,
                )
              else
                for (final FeatureHubGroup group in groups) ...<Widget>[
                  Semantics(
                    header: true,
                    child: Padding(
                      padding: const EdgeInsets.only(
                        bottom: LingAfriqTokens.spacing8,
                      ),
                      child: Text(
                        group.hub,
                        key: AllFeaturesScreen.hubKey(group.hub),
                        style: lingBody(palette.onSurface),
                        softWrap: true,
                        overflow: TextOverflow.visible,
                      ),
                    ),
                  ),
                  for (final FeatureEntry entry in group.entries) ...<Widget>[
                    if (entry.locked)
                      _LockedFeature(
                        entry: entry,
                        palette: palette,
                        l10n: l10n,
                        onPreview: () => _openPreview(entry),
                      )
                    else
                      _OpenFeature(
                        entry: entry,
                        palette: palette,
                        l10n: l10n,
                        onOpen: () => _openEntry(entry),
                      ),
                    const SizedBox(height: LingAfriqTokens.spacing8),
                  ],
                  const SizedBox(height: LingAfriqTokens.spacing16),
                ],
            ],
          ),
        ),
      ),
    );
  }
}

class _OpenFeature extends StatelessWidget {
  const _OpenFeature({
    required this.entry,
    required this.palette,
    required this.l10n,
    required this.onOpen,
  });

  final FeatureEntry entry;
  final LingPalette palette;
  final AppLocalizations l10n;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      key: AllFeaturesScreen.entryKey(entry.key),
      container: true,
      button: true,
      label: l10n.directoryOpenFeature(entry.label),
      onTap: onOpen,
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
            onTap: onOpen,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: LingAfriqTokens.spacing16,
                vertical: LingAfriqTokens.spacing12,
              ),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: ExcludeSemantics(
                  child: Text(
                    entry.label,
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

class _LockedFeature extends StatelessWidget {
  const _LockedFeature({
    required this.entry,
    required this.palette,
    required this.l10n,
    required this.onPreview,
  });

  final FeatureEntry entry;
  final LingPalette palette;
  final AppLocalizations l10n;
  final VoidCallback onPreview;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      key: AllFeaturesScreen.entryKey(entry.key),
      container: true,
      explicitChildNodes: true,
      label: l10n.directoryLockedSemantics(
        entry.label,
        entry.unlockStage,
        entry.learningLoop,
      ),
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
                  entry.label,
                  style: lingBody(palette.onSurface),
                  softWrap: true,
                  overflow: TextOverflow.visible,
                ),
              ),
              const SizedBox(height: LingAfriqTokens.spacing8),
              ExcludeSemantics(
                child: Text(
                  l10n.directoryLocked,
                  style: lingBody(palette.onSurface),
                  softWrap: true,
                  overflow: TextOverflow.visible,
                ),
              ),
              const SizedBox(height: LingAfriqTokens.spacing8),
              ExcludeSemantics(
                child: Text(
                  l10n.directoryUnlocksAt(entry.unlockStage),
                  style: lingBody(palette.onSurfaceVariant),
                  softWrap: true,
                  overflow: TextOverflow.visible,
                ),
              ),
              const SizedBox(height: LingAfriqTokens.spacing8),
              ExcludeSemantics(
                child: Text(
                  entry.learningLoop,
                  style: lingBody(palette.onSurface),
                  softWrap: true,
                  overflow: TextOverflow.visible,
                ),
              ),
              const SizedBox(height: LingAfriqTokens.spacing16),
              LingButton(
                key: AllFeaturesScreen.previewKey(entry.key),
                label: l10n.directoryPreview,
                unavailableLabel: l10n.commonStateUnavailable,
                onPressed: onPreview,
                role: LingButtonRole.quiet,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Preview for a locked feature, or a drawer feature that has no route.
class FeaturePreviewPage extends StatelessWidget {
  const FeaturePreviewPage({required this.entry, super.key});

  static const String routeName = 'directory-preview';

  static const Key pageKey = ValueKey<String>('directory-preview-page');

  final FeatureEntry entry;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = l10nOf(context);
    final LingPalette palette = LingPalette.of(Theme.of(context).brightness);
    return Scaffold(
      key: pageKey,
      backgroundColor: palette.surface,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(LingAfriqTokens.spacing16),
          children: <Widget>[
            Text(
              l10n.directoryPreview,
              style: lingBody(palette.onSurface),
              softWrap: true,
              overflow: TextOverflow.visible,
            ),
            const SizedBox(height: LingAfriqTokens.spacing16),
            Text(
              entry.label,
              style: lingBody(palette.onSurface),
              softWrap: true,
              overflow: TextOverflow.visible,
            ),
            if (entry.locked) ...<Widget>[
              const SizedBox(height: LingAfriqTokens.spacing16),
              Text(
                l10n.directoryLocked,
                style: lingBody(palette.onSurface),
                softWrap: true,
                overflow: TextOverflow.visible,
              ),
              const SizedBox(height: LingAfriqTokens.spacing16),
              Text(
                l10n.directoryUnlocksAt(entry.unlockStage),
                style: lingBody(palette.onSurfaceVariant),
                softWrap: true,
                overflow: TextOverflow.visible,
              ),
            ],
            const SizedBox(height: LingAfriqTokens.spacing16),
            Text(
              entry.learningLoop,
              style: lingBody(palette.onSurface),
              softWrap: true,
              overflow: TextOverflow.visible,
            ),
            const SizedBox(height: LingAfriqTokens.spacing16),
            LingButton(
              label: l10n.directoryBack,
              unavailableLabel: l10n.commonStateUnavailable,
              onPressed: () {
                unawaited(Navigator.of(context).maybePop());
              },
            ),
          ],
        ),
      ),
    );
  }
}
