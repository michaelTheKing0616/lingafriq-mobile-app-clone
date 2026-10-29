import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/l10n/generated/app_localizations.dart';
import 'package:lingafriq/l10n/l10n_of.dart';
import 'package:lingafriq/providers/game_catalog_provider.dart';
import 'package:lingafriq/screens/games/game_router.dart';
import 'package:lingafriq/services/lazy_game_loader.dart';
import 'package:lingafriq/utils/error_handler.dart' hide ErrorBoundary;
import 'package:lingafriq/utils/games_prefetch_language.dart';
import 'package:lingafriq/widgets/animations/smooth_transitions.dart';
import 'package:lingafriq/widgets/error_boundary.dart';
import 'package:lingafriq/widgets/loading/loading_overlay.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'game_catalog.dart';
import 'game_catalog_l10n.dart';
import 'game_onboarding_overlay.dart';

/// Server catalog merged over the bundled one; throws when offline.
final gamesRemoteCatalogProvider =
    FutureProvider.autoDispose<List<GameCatalogEntry>>(
      (ref) async => GameCatalog.mergeRemoteRows(
        await ref.read(gameCatalogServiceProvider).fetchCatalogRows(),
      ),
      retry: (_, _) => null,
    );

/// The learner's saved practice language for games.
final gamesHubLanguageProvider = FutureProvider.autoDispose<String>(
  (ref) async =>
      resolveGamesHubLanguageSync(await SharedPreferences.getInstance()),
);

const _ink = Color(0xFF1F2340);
const _muted = Color(0xFF5B607A);
const _navy = Color(0xFF2E3A87);
const _line = Color(0xFFE3E5EF);

/// Tile colours (NYT Games hub pattern, recoloured to the LingAfriq
/// palette). All carry dark ink at >= 4.5:1.
const _tiles = [
  Color(0xFF8FB4F2), // sky
  Color(0xFFFFD34D), // gold
  Color(0xFFF2A07B), // terracotta
  Color(0xFF8ED1A5), // savanna green
  Color(0xFFC7A6E8), // dusk purple
];

const _cats = [
  'Vocabulary',
  'Grammar',
  'Pronunciation',
  'Cultural',
  'Traditional',
];

String _catLabel(AppLocalizations l, String c) => switch (c) {
  'Vocabulary' => l.gmCatVocabulary,
  'Grammar' => l.gmCatGrammar,
  'Pronunciation' => l.gmCatPronunciation,
  'Cultural' => l.gmCatCultural,
  'Traditional' => l.gmCatTraditional,
  _ => c,
};

String _langName(String slug) =>
    slug.isEmpty ? slug : slug[0].toUpperCase() + slug.substring(1);

/// Game names/descriptions come from l10n keys by game id (see
/// game_catalog_l10n.dart), so they are already in the UI language.
String _gName(BuildContext c, GameCatalogEntry g) =>
    localizedGameName(l10nOf(c), g.type);
String _gDesc(BuildContext c, GameCatalogEntry g) =>
    localizedGameDescription(l10nOf(c), g.type);

/// Catalog text is English content (bundled + server rows); keep it LTR
/// and isolated inside Arabic UI.
String _iso(BuildContext c, String s) =>
    Directionality.of(c) == TextDirection.rtl ? '\u2066$s\u2069' : s;

/// Games hub (games-duels/05 NYT Games hub): greeting, practice-language
/// chips, a featured "today's pick" card, Core/Cultural segments,
/// category filters and a grid of colour tiles.
class GamesScreenMaterial3 extends ConsumerStatefulWidget {
  const GamesScreenMaterial3({super.key});

  @override
  ConsumerState<GamesScreenMaterial3> createState() =>
      _GamesScreenMaterial3State();
}

class _GamesScreenMaterial3State extends ConsumerState<GamesScreenMaterial3> {
  String? _language;
  GameCatalogSection _section = GameCatalogSection.core;
  String? _category;
  bool _opening = false;

  Future<void> _open(GameCatalogEntry game, String language) async {
    final l = l10nOf(context);
    HapticFeedback.lightImpact();
    setState(() => _opening = true);
    try {
      try {
        await ref
            .read(lazyGameLoaderProvider)
            .loadGameOnDemand(game.type, language: language);
      } catch (_) {
        // Preload is optional; still open the game.
      }
      if (!mounted) return;
      final nav = Navigator.of(context);
      final widget = buildGameScreen(
        gameType: game.type,
        language: language,
        onBack: () => nav.pop(),
        ref: ref,
      );
      final prefs = await SharedPreferences.getInstance();
      final key = 'game_onboarding_${game.type.name}_dismissed';
      if (!(prefs.getBool(key) ?? false) && mounted) {
        await showDialog(
          context: context,
          builder: (ctx) => GameOnboardingOverlay(
            gameType: game.type.name,
            title: _gName(context, game),
            rules: game.rules.isNotEmpty ? game.rules : [l.gmRule1, l.gmRule2],
            onDismiss: () async {
              await prefs.setBool(key, true);
              if (ctx.mounted) Navigator.pop(ctx);
            },
          ),
        );
      }
      if (!mounted) return;
      await nav.push(
        SmoothPageRoute.platform(
          child: ErrorBoundary(
            errorMessage: l.gmLoadError,
            onRetry: () => nav.pop(),
            child: widget,
          ),
        ),
      );
    } catch (e) {
      if (mounted) ErrorHandler.showError(context, e);
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = l10nOf(context);
    final remote = ref.watch(gamesRemoteCatalogProvider);
    final saved = ref.watch(gamesHubLanguageProvider).value;
    final language = _language ?? saved ?? kGamesHubLanguageSlugs.first;
    final base = (remote.value?.isNotEmpty ?? false)
        ? remote.value!
        : GameCatalog.entries;
    final inSection = base.where((e) => e.section == _section).toList();
    final games = _category == null
        ? inSection
        : inSection.where((g) => g.category == _category).toList();
    final cats = _cats.where((c) => inSection.any((g) => g.category == c));
    final big = MediaQuery.textScalerOf(context).scale(10) > 15;
    final width = MediaQuery.sizeOf(context).width;
    final cols = (width.clamp(0, 900) / (big ? 320 : 180)).floor().clamp(1, 4);

    Widget chip(String key, String label, bool sel, VoidCallback onTap) =>
        Padding(
          padding: const EdgeInsetsDirectional.only(end: 8),
          child: ChoiceChip(
            key: Key(key),
            label: Text(label),
            selected: sel,
            showCheckmark: false,
            selectedColor: _navy,
            backgroundColor: Colors.white,
            side: BorderSide(color: sel ? _navy : _line, width: 1.5),
            labelStyle: TextStyle(
              color: sel ? Colors.white : _ink,
              fontWeight: FontWeight.w700,
            ),
            materialTapTargetSize: MaterialTapTargetSize.padded,
            onSelected: (_) {
              HapticFeedback.selectionClick();
              onTap();
            },
          ),
        );

    final rows = <Widget>[];
    final rest = games.skip(1).toList();
    for (var i = 0; i < rest.length; i += cols) {
      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var j = 0; j < cols; j++) ...[
                  if (j > 0) const SizedBox(width: 12),
                  Expanded(
                    child: i + j < rest.length
                        ? _Tile(
                            game: rest[i + j],
                            color: _tiles[(i + j + 1) % _tiles.length],
                            category: _catLabel(l, rest[i + j].category),
                            onTap: () => _open(rest[i + j], language),
                          )
                        : const SizedBox(),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    return LoadingOverlay(
      isLoading: _opening,
      message: l.gmOpening,
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F7F2),
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: _ink,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
          leading: IconButton(
            key: const Key('gm-back'),
            tooltip: l.gmBack,
            icon: const BackButtonIcon(),
            onPressed: () => Navigator.maybePop(context),
          ),
          title: Text(
            l.gmTitle,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 22),
          ),
          actions: [
            if (remote.isLoading)
              Padding(
                padding: const EdgeInsetsDirectional.only(end: 16),
                child: Semantics(
                  key: const Key('gm-syncing'),
                  label: l.gmSyncing,
                  child: const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
          ],
          bottom: const PreferredSize(
            preferredSize: Size.fromHeight(1),
            child: Divider(height: 1, color: _line),
          ),
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: ListView(
              key: const Key('gm-list'),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                Text(
                  l.gmWelcome,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: _ink,
                  ),
                ),
                Text(
                  l.gmWelcomeSub(_iso(context, _langName(language))),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 15, color: _muted),
                ),
                if (remote.hasError) ...[
                  const SizedBox(height: 12),
                  Container(
                    key: const Key('gm-offline'),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _line),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.cloud_off_rounded, color: _navy),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            l.gmOffline,
                            style: const TextStyle(color: _ink),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                Semantics(
                  container: true,
                  label: l.gmLanguage,
                  child: SingleChildScrollView(
                    key: const Key('gm-langs'),
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final s in kGamesHubLanguageSlugs)
                          chip(
                            'gm-lang-$s',
                            _iso(context, _langName(s)),
                            s == language,
                            () => setState(() => _language = s),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (big)
                  SingleChildScrollView(
                    key: const Key('gm-sections'),
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final (sec, label, key) in [
                          (GameCatalogSection.core, l.gmCore, 'gm-core'),
                          (
                            GameCatalogSection.cultural,
                            l.gmCultural,
                            'gm-cultural',
                          ),
                        ])
                          chip(
                            key,
                            label,
                            _section == sec,
                            () => setState(() {
                              _section = sec;
                              _category = null;
                            }),
                          ),
                      ],
                    ),
                  )
                else
                  SegmentedButton<GameCatalogSection>(
                    key: const Key('gm-sections'),
                    showSelectedIcon: false,
                    style: SegmentedButton.styleFrom(
                      selectedBackgroundColor: _navy,
                      selectedForegroundColor: Colors.white,
                      foregroundColor: _ink,
                      minimumSize: const Size(48, 48),
                    ),
                    segments: [
                      ButtonSegment(
                        value: GameCatalogSection.core,
                        label: Text(
                          '${l.gmCore} · ${base.where((e) => e.section == GameCatalogSection.core).length}',
                          key: const Key('gm-core'),
                        ),
                      ),
                      ButtonSegment(
                        value: GameCatalogSection.cultural,
                        label: Text(
                          '${l.gmCultural} · ${base.where((e) => e.section == GameCatalogSection.cultural).length}',
                          key: const Key('gm-cultural'),
                        ),
                      ),
                    ],
                    selected: {_section},
                    onSelectionChanged: (s) => setState(() {
                      HapticFeedback.selectionClick();
                      _section = s.first;
                      _category = null;
                    }),
                  ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  key: const Key('gm-cats'),
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      chip(
                        'gm-cat-all',
                        l.gmCatAll,
                        _category == null,
                        () => setState(() => _category = null),
                      ),
                      for (final c in cats)
                        chip(
                          'gm-cat-$c',
                          _catLabel(l, c),
                          _category == c,
                          () => setState(() => _category = c),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l.gmCount(games.length),
                  key: const Key('gm-count'),
                  style: const TextStyle(color: _muted, fontSize: 13),
                ),
                const SizedBox(height: 10),
                if (games.isEmpty)
                  _Empty(
                    text: l.gmEmpty,
                    action: l.gmShowAll,
                    onAction: () => setState(() => _category = null),
                  )
                else ...[
                  _Featured(
                    game: games.first,
                    label: l.gmFeatured,
                    play: l.gmPlay,
                    category: _catLabel(l, games.first.category),
                    compact: big,
                    onTap: () => _open(games.first, language),
                  ),
                  const SizedBox(height: 12),
                  ...rows,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Featured extends StatelessWidget {
  const _Featured({
    required this.game,
    required this.label,
    required this.play,
    required this.category,
    required this.compact,
    required this.onTap,
  });
  final GameCatalogEntry game;
  final String label, play, category;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = l10nOf(context);
    final art = ExcludeSemantics(
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: _navy,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(game.icon, color: Colors.white, size: 40),
      ),
    );
    return Semantics(
      button: true,
      label: l.gmPlayA11y(
        _gName(context, game),
        category,
        _gDesc(context, game),
      ),
      excludeSemantics: true,
      child: Material(
        key: const Key('gm-featured'),
        color: _tiles[0],
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            label.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 12,
                              letterSpacing: 1,
                              fontWeight: FontWeight.w800,
                              color: _ink,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _gName(context, game),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: _ink,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _gDesc(context, game),
                            style: const TextStyle(fontSize: 15, color: _ink),
                          ),
                        ],
                      ),
                    ),
                    if (!compact) ...[const SizedBox(width: 12), art],
                  ],
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: _ink,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Text(
                        play,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    _Pill(category),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.game,
    required this.color,
    required this.category,
    required this.onTap,
  });
  final GameCatalogEntry game;
  final Color color;
  final String category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = l10nOf(context);
    return Semantics(
      button: true,
      label: l.gmPlayA11y(
        _gName(context, game),
        category,
        _gDesc(context, game),
      ),
      excludeSemantics: true,
      child: Material(
        key: Key('gm-game-${game.type.name}'),
        color: color,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        _gName(context, game),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: _ink,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(game.icon, color: _ink, size: 26),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _gDesc(context, game),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, color: _ink),
                ),
                const Spacer(),
                const SizedBox(height: 10),
                _Pill(category),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.7),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: _ink,
      ),
    ),
  );
}

class _Empty extends StatelessWidget {
  const _Empty({
    required this.text,
    required this.action,
    required this.onAction,
  });
  final String text, action;
  final VoidCallback onAction;
  @override
  Widget build(BuildContext context) => Padding(
    key: const Key('gm-empty'),
    padding: const EdgeInsets.symmetric(vertical: 40),
    child: Column(
      children: [
        const ExcludeSemantics(
          child: Icon(Icons.sports_esports_outlined, size: 56, color: _muted),
        ),
        const SizedBox(height: 12),
        Text(text, style: const TextStyle(fontSize: 16, color: _ink)),
        const SizedBox(height: 12),
        FilledButton(
          key: const Key('gm-show-all'),
          style: FilledButton.styleFrom(
            backgroundColor: _navy,
            minimumSize: const Size(48, 48),
          ),
          onPressed: onAction,
          child: Text(action),
        ),
      ],
    ),
  );
}
