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
            Color.alphaBlend(Colors.brown.withOpacity(0.06), base),
          ],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (child != null) child!,
          if (dimmed)
            ColoredBox(
              color: Colors.black.withOpacity(0.28),
              child: const SizedBox.expand(),
            ),
        ],
      ),
    );
  }
}

/// Scene prop slot: loads licensed artboard name; shows labelled placeholder when gated.
class PathSceneArtSlot extends StatelessWidget {
  const PathSceneArtSlot({
    super.key,
    required this.languageKey,
    required this.unitIndex,
    required this.dimmed,
    required this.bundleLicensed,
    this.reducedMotion = false,
    this.artMissingLabel = 'Scene art unavailable',
  });

  final String? languageKey;
  final int unitIndex;
  final bool dimmed;
  final bool bundleLicensed;
  final bool reducedMotion;
  final String artMissingLabel;

  @override
  Widget build(BuildContext context) {
    final artboard = pathSceneryArtboardFor(
      languageKey: languageKey ?? 'yo',
      unitIndex: unitIndex,
    );
    if (artboard == null || !bundleLicensed) {
      return Semantics(
        label: artMissingLabel,
        child: _ArtMissingTile(label: artMissingLabel),
      );
    }

    return Semantics(
      label: pathSceneryAltText(artboard),
      image: true,
      child: PathParchmentBackdrop(
        languageKey: languageKey,
        dimmed: dimmed,
        child: _SceneryPlaceholder(
          artboard: artboard,
          reducedMotion: reducedMotion,
        ),
      ),
    );
  }
}

class _SceneryPlaceholder extends StatelessWidget {
  const _SceneryPlaceholder({
    required this.artboard,
    required this.reducedMotion,
  });

  final String artboard;
  final bool reducedMotion;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Opacity(
        opacity: reducedMotion ? 0.92 : 1.0,
        child: Text(
          artboard.replaceAll('_', ' '),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Colors.brown.withOpacity(0.45),
                fontStyle: FontStyle.italic,
              ),
        ),
      ),
    );
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
