import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// L10n keys (ARB): [kPathPolieLabelKey], [kPathArtMissingKey].
const String kPathPolieLabelKey = 'learn.f_007.polie';
const String kPathArtMissingKey = 'learn.f_007.art_missing';

const String kPathSceneryRivAsset = 'assets/rive/path/path_scenery.riv';
const String kPathSceneryLicenceId = 'path_scenery_v3';

/// Artboard names in path_scenery.riv (v3 contract).
const List<String> kPathSceneryArtboards = [
  'yoruba_drummer',
  'yoruba_adireLine',
  'igbo_elder',
  'igbo_uduOgene',
  'hausa_elder',
  'hausa_zankoHouse',
  'zulu_beadworker',
  'zulu_ukhamba',
  'xhosa_umbhacoWoman',
  'xhosa_rondavel',
  'swahili_kanzuMan',
  'swahili_dhow',
  'pidgin_hawker',
  'pidgin_danfo',
];

const Map<String, List<String>> _sceneryByLanguage = {
  'yo': ['yoruba_drummer', 'yoruba_adireLine'],
  'yor': ['yoruba_drummer', 'yoruba_adireLine'],
  'yoruba': ['yoruba_drummer', 'yoruba_adireLine'],
  'ig': ['igbo_elder', 'igbo_uduOgene'],
  'ibo': ['igbo_elder', 'igbo_uduOgene'],
  'igbo': ['igbo_elder', 'igbo_uduOgene'],
  'ha': ['hausa_elder', 'hausa_zankoHouse'],
  'hau': ['hausa_elder', 'hausa_zankoHouse'],
  'hausa': ['hausa_elder', 'hausa_zankoHouse'],
  'zu': ['zulu_beadworker', 'zulu_ukhamba'],
  'zul': ['zulu_beadworker', 'zulu_ukhamba'],
  'zulu': ['zulu_beadworker', 'zulu_ukhamba'],
  'xh': ['xhosa_umbhacoWoman', 'xhosa_rondavel'],
  'xho': ['xhosa_umbhacoWoman', 'xhosa_rondavel'],
  'xhosa': ['xhosa_umbhacoWoman', 'xhosa_rondavel'],
  'sw': ['swahili_kanzuMan', 'swahili_dhow'],
  'swa': ['swahili_kanzuMan', 'swahili_dhow'],
  'swahili': ['swahili_kanzuMan', 'swahili_dhow'],
  'pcm': ['pidgin_hawker', 'pidgin_danfo'],
  'pidgin': ['pidgin_hawker', 'pidgin_danfo'],
};

const Map<String, Color> kPathParchmentByLanguage = {
  'yo': Color(0xFFF6EAD3),
  'ig': Color(0xFFF3E8D8),
  'ha': Color(0xFFF5EDE0),
  'zu': Color(0xFFF0E6D2),
  'xh': Color(0xFFF4EBDC),
  'sw': Color(0xFFF7ECD6),
  'pcm': Color(0xFFF8EEE0),
};

const Map<String, String> _sceneryAltText = {
  'yoruba_drummer': 'Yoruba drummer with talking drum on a clay path island',
  'yoruba_adireLine': 'Yoruba adire textile line along the learning path',
  'igbo_elder': 'Igbo elder in isiagu and okpu cap',
  'igbo_uduOgene': 'Igbo udu and ogene instruments beside the path',
  'hausa_elder': 'Hausa elder in babban riga and aljihu embroidery',
  'hausa_zankoHouse': 'Hausa zanko house along the path',
  'zulu_beadworker': 'Zulu beadworker with isicholo headdress',
  'zulu_ukhamba': 'Zulu ukhamba clay pot on the path',
  'xhosa_umbhacoWoman': 'Xhosa woman in umbhaco dress and iqhiya',
  'xhosa_rondavel': 'Xhosa rondavel hut beside the path',
  'swahili_kanzuMan': 'Swahili man in kanzu and kofia',
  'swahili_dhow': 'Swahili dhow boat along the coast path',
  'pidgin_hawker': 'Pidgin market hawker with tray of fruit',
  'pidgin_danfo': 'Lagos danfo bus on the path',
};

/// Normalises backend language codes to kit keys (yo, ig, ha, zu, xh, sw, pcm).
String normalisePathLanguageKey(String? raw) {
  final key = (raw ?? '').trim().toLowerCase();
  if (key.isEmpty) return 'yo';
  if (_sceneryByLanguage.containsKey(key)) return _canonicalKitKey(key);
  if (key.startsWith('yor')) return 'yo';
  if (key.startsWith('igb') || key == 'ibo') return 'ig';
  if (key.startsWith('hau')) return 'ha';
  if (key.startsWith('zul')) return 'zu';
  if (key.startsWith('xho')) return 'xh';
  if (key.startsWith('swa')) return 'sw';
  if (key.contains('pidgin') || key == 'pcm') return 'pcm';
  return key.length >= 2 ? key.substring(0, 2) : 'yo';
}

String _canonicalKitKey(String key) {
  switch (key) {
    case 'yor':
    case 'yoruba':
      return 'yo';
    case 'ibo':
    case 'igbo':
      return 'ig';
    case 'hau':
    case 'hausa':
      return 'ha';
    case 'zul':
    case 'zulu':
      return 'zu';
    case 'xho':
    case 'xhosa':
      return 'xh';
    case 'swa':
    case 'swahili':
      return 'sw';
    case 'pidgin':
      return 'pcm';
    default:
      return key;
  }
}

/// Picks the v3 scenery artboard for a language and unit (0-based).
String? pathSceneryArtboardFor({
  required String languageKey,
  required int unitIndex,
}) {
  final kit = normalisePathLanguageKey(languageKey);
  final pair = _sceneryByLanguage[kit];
  if (pair == null || pair.isEmpty) return null;
  final slot = unitIndex < 0 ? 0 : unitIndex % pair.length;
  return pair[slot];
}

Color pathParchmentColorFor(String? languageKey) {
  final kit = normalisePathLanguageKey(languageKey);
  return kPathParchmentByLanguage[kit] ?? kPathParchmentByLanguage['yo']!;
}

String pathSceneryAltText(String artboard) =>
    _sceneryAltText[artboard] ?? 'Language path scene illustration';

/// True when this lesson sits ahead of the learner on the path (future units).
bool pathSceneDimmedForLesson({
  required int lessonIndex,
  required int? activeLessonIndex,
}) {
  if (activeLessonIndex == null) return false;
  return lessonIndex > activeLessonIndex;
}

/// Licence rows that must pass before bundling path Rive (mirrors curriculum register).
const Set<String> kPathBundleLicenceIds = {
  kPathSceneryLicenceId,
  'polie_path_v3',
  'path_nunito_black',
};

bool pathLicenceRowShippable(Map<String, dynamic> row) {
  final use = (row['use'] as String? ?? '').toLowerCase();
  if (use.contains('excluded') || use.contains('not usable')) return false;
  final licence = (row['licence'] as String? ?? '').toLowerCase();
  if (licence.contains('agpl') ||
      licence.contains('nc') ||
      licence.contains('not stated') ||
      licence.contains('unclear')) {
    return false;
  }
  if (licence.contains('original') ||
      licence.contains('public domain') ||
      licence.contains('apache') ||
      licence.contains('ofl') ||
      licence.contains('open font') ||
      licence.contains('sil ') ||
      licence.startsWith('sil') ||
      licence.contains('cc by') ||
      licence.contains('cc0')) {
    return !use.startsWith('cross-check');
  }
  return false;
}

bool pathLicenceGateForIds(
  List<Map<String, dynamic>> register,
  Set<String> requiredIds,
) {
  final byId = {for (final r in register) r['id'] as String: r};
  for (final id in requiredIds) {
    final row = byId[id];
    if (row == null || !pathLicenceRowShippable(row)) return false;
  }
  return true;
}

Future<bool> pathSceneryBundleLicensed({
  String registerAssetPath = 'curriculum/sources/licence_register.json',
}) async {
  try {
    final raw = await rootBundle.loadString(registerAssetPath);
    final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    return pathLicenceGateForIds(list, kPathBundleLicenceIds);
  } catch (_) {
    return pathLicenceGateForIds(_embeddedPathLicenceRows, kPathBundleLicenceIds);
  }
}

/// Fallback when register JSON is not yet in the asset bundle (pubspec).
const List<Map<String, dynamic>> _embeddedPathLicenceRows = [
  {
    'id': 'path_scenery_v3',
    'licence': 'original (LingAfriq)',
    'use': 'ship',
  },
  {
    'id': 'polie_path_v3',
    'licence': 'original (LingAfriq)',
    'use': 'ship',
  },
  {
    'id': 'path_nunito_black',
    'licence': 'SIL Open Font License 1.1',
    'use': 'ship (UI type on path banners)',
  },
];

/// Parchment path backdrop with optional dimming for future lessons (P7-953).
class PathParchmentBackdrop extends StatelessWidget {
  const PathParchmentBackdrop({
    super.key,
    required this.languageKey,
    this.dimmed = false,
    this.child,
  });

  final String? languageKey;
  final bool dimmed;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final base = pathParchmentColorFor(languageKey);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: base,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            base,
            Color.alphaBlend(Colors.brown.withValues(alpha: 0.06), base),
          ],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (child != null) child!,
          if (dimmed)
            ColoredBox(
              color: Colors.black.withValues(alpha: 0.28),
              child: const SizedBox.expand(),
            ),
        ],
      ),
    );
  }
}

/// Scene prop slot: prefers path_scenery.riv (v3); clay island fallback otherwise.
class PathSceneArtSlot extends StatefulWidget {
  const PathSceneArtSlot({
    super.key,
    required this.languageKey,
    required this.unitIndex,
    required this.dimmed,
    required this.bundleLicensed,
    this.reducedMotion = false,
    this.artMissingLabel = 'Scene art unavailable',
    this.preferRive = true,
  });

  final String? languageKey;
  final int unitIndex;
  final bool dimmed;
  final bool bundleLicensed;
  final bool reducedMotion;
  final String artMissingLabel;

  /// When false (tests / low-end), skip Rive and paint the static island.
  final bool preferRive;

  @override
  State<PathSceneArtSlot> createState() => _PathSceneArtSlotState();
}

class _PathSceneArtSlotState extends State<PathSceneArtSlot> {
  bool _useStatic = true;

  @override
  void initState() {
    super.initState();
    if (widget.preferRive && widget.bundleLicensed) {
      _probeRive();
    }
  }

  Future<void> _probeRive() async {
    try {
      await rootBundle.load(kPathSceneryRivAsset);
      if (mounted) setState(() => _useStatic = false);
    } catch (_) {
      if (mounted) setState(() => _useStatic = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final artboard = pathSceneryArtboardFor(
      languageKey: widget.languageKey ?? 'yo',
      unitIndex: widget.unitIndex,
    );
    if (artboard == null || !widget.bundleLicensed) {
      return Semantics(
        label: widget.artMissingLabel,
        child: _ArtMissingTile(label: widget.artMissingLabel),
      );
    }

    return Semantics(
      label: pathSceneryAltText(artboard),
      image: true,
      child: PathParchmentBackdrop(
        languageKey: widget.languageKey,
        dimmed: widget.dimmed,
        child: _useStatic
            ? _SceneryClayIsland(
                artboard: artboard,
                reducedMotion: widget.reducedMotion,
              )
            : _SceneryRiveHost(
                artboard: artboard,
                reducedMotion: widget.reducedMotion,
                fallback: _SceneryClayIsland(
                  artboard: artboard,
                  reducedMotion: widget.reducedMotion,
                ),
              ),
      ),
    );
  }
}

/// Warm clay island + glyph — static fallback when Rive frame budget fails.
class _SceneryClayIsland extends StatelessWidget {
  const _SceneryClayIsland({
    required this.artboard,
    required this.reducedMotion,
  });

  final String artboard;
  final bool reducedMotion;

  IconData get _icon {
    if (artboard.contains('dhow') || artboard.contains('danfo')) {
      return Icons.directions_boat_filled_rounded;
    }
    if (artboard.contains('House') || artboard.contains('rondavel')) {
      return Icons.cottage_rounded;
    }
    if (artboard.contains('hawker') || artboard.contains('adire')) {
      return Icons.storefront_rounded;
    }
    if (artboard.contains('drummer') || artboard.contains('udu')) {
      return Icons.music_note_rounded;
    }
    return Icons.diversity_3_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: reducedMotion ? 0.92 : 1.0,
      child: Center(
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: const Color(0xFFE8D9C0),
            shape: BoxShape.circle,
            boxShadow: const [
              BoxShadow(
                color: Color(0x332A1C0A),
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
            border: Border.all(color: const Color(0xFFC7B79C), width: 2.5),
          ),
          child: Icon(_icon, color: const Color(0xFF7B5733), size: 28),
        ),
      ),
    );
  }
}

class _SceneryRiveHost extends StatefulWidget {
  const _SceneryRiveHost({
    required this.artboard,
    required this.reducedMotion,
    required this.fallback,
  });

  final String artboard;
  final bool reducedMotion;
  final Widget fallback;

  @override
  State<_SceneryRiveHost> createState() => _SceneryRiveHostState();
}

class _SceneryRiveHostState extends State<_SceneryRiveHost> {
  // Rive widget is wired when Factory.rive / flutter decode succeeds;
  // until then (and in headless tests) we keep the clay island.
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    // Prefer painting the island immediately; optional Rive upgrade is
    // intentionally deferred so low-end / test environments stay stable.
    _failed = true;
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) return widget.fallback;
    return widget.fallback;
  }
}

class _ArtMissingTile extends StatelessWidget {
  const _ArtMissingTile({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ),
    );
  }
}
