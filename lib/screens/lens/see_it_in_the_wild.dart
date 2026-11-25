import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lingafriq/screens/lens/lens_screen.dart';
import 'package:lingafriq/services/lens/object_set_mapper.dart';
import 'package:lingafriq/services/lens/on_device_detector.dart';
import 'package:lingafriq/services/lens/on_device_object_classifier.dart';

/// copy_keys: lens.entry.label (P7-915).
const String kLensEntryLabel = 'Lens';

const String kLensUnavailableMessage =
    'Lens needs a camera and the on-device object model on this device.';

const String kSeeItInTheWildLabel = 'See it in the wild';

/// Active entry context for the topmost [LensScreen] pushed via [openLensEntry].
class LensEntryIntent {
  const LensEntryIntent({
    required this.language,
    this.scopedObjectSetIds = const [],
    this.targetLexemeId,
    this.targetObjectSetId,
  });

  final String language;
  final List<String> scopedObjectSetIds;
  final String? targetLexemeId;
  final String? targetObjectSetId;

  bool get hasScope =>
      scopedObjectSetIds.isNotEmpty ||
      (targetObjectSetId != null && targetObjectSetId!.trim().isNotEmpty) ||
      (targetLexemeId != null && targetLexemeId!.trim().isNotEmpty);
}

class LensEntryScope {
  static LensEntryIntent? active;
}

enum LensAvailabilityReason {
  ready,
  noCamera,
  modelAssetMissing,
}

class LensAvailability {
  const LensAvailability({
    required this.available,
    required this.reason,
  });

  final bool available;
  final LensAvailabilityReason reason;
}

/// Shared curated-object pipeline for Lens and Flashcard Safari (P7-915 AC3).
Future<LensOnDeviceDetector> createLensRecognitionPipeline() async {
  final set = await AfricanObjectSet.loadFromBundle();
  return LensOnDeviceDetector(mapper: ObjectSetMapper(set));
}

/// Filters detections to lesson / word-card scope when ids are provided.
List<String> filterMlKitLabelsForScope({
  required List<String> labels,
  required List<String> scopedObjectSetIds,
  required AfricanObjectSet objectSet,
}) {
  if (scopedObjectSetIds.isEmpty) return labels;
  final allowedMl = <String>{};
  for (final id in scopedObjectSetIds) {
    for (final entry in objectSet.entries) {
      if (entry.objectSetId == id) {
        allowedMl.addAll(entry.mlKitLabels.map((e) => e.toLowerCase()));
      }
    }
  }
  if (allowedMl.isEmpty) return const [];
  return labels
      .where((l) => allowedMl.contains(l.trim().toLowerCase()))
      .toList();
}

typedef LensCameraEnumerator = Future<List<CameraDescription>> Function();

Future<LensAvailability> probeLensAvailability({
  LensCameraEnumerator? cameras,
  Future<ByteData> Function(String key)? loadAsset,
}) async {
  try {
    final list = await (cameras ?? availableCameras)();
    if (list.isEmpty) {
      return const LensAvailability(
        available: false,
        reason: LensAvailabilityReason.noCamera,
      );
    }
    final loader = loadAsset ?? rootBundle.load;
    await loader(PointSayModelLicence.bundledAsset);
    return const LensAvailability(
      available: true,
      reason: LensAvailabilityReason.ready,
    );
  } on FlutterError {
    return const LensAvailability(
      available: false,
      reason: LensAvailabilityReason.modelAssetMissing,
    );
  } catch (_) {
    return const LensAvailability(
      available: false,
      reason: LensAvailabilityReason.noCamera,
    );
  }
}

Future<void> showLensUnavailableExplanation(BuildContext context) async {
  await showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text(kLensEntryLabel),
      content: const Text(kLensUnavailableMessage),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}

Future<void> openLensEntry(
  BuildContext context, {
  required LensEntryIntent intent,
  LensAvailability? preflight,
}) async {
  final availability =
      preflight ?? await probeLensAvailability();
  if (!availability.available) {
    await showLensUnavailableExplanation(context);
    return;
  }
  LensEntryScope.active = intent;
  await Navigator.of(context).push<void>(
    MaterialPageRoute<void>(
      builder: (ctx) => _LensEntryHost(intent: intent),
    ),
  );
  LensEntryScope.active = null;
}

class _LensEntryHost extends StatelessWidget {
  const _LensEntryHost({required this.intent});

  final LensEntryIntent intent;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (intent.hasScope)
          Material(
            color: Colors.black87,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  _scopeBanner(intent),
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        Expanded(
          child: LensScreen(fallbackLanguage: intent.language),
        ),
      ],
    );
  }

  String _scopeBanner(LensEntryIntent intent) {
    if (intent.targetLexemeId != null && intent.targetLexemeId!.isNotEmpty) {
      return 'Looking for: ${intent.targetLexemeId}';
    }
    if (intent.targetObjectSetId != null &&
        intent.targetObjectSetId!.isNotEmpty) {
      return 'Find: ${intent.targetObjectSetId}';
    }
    if (intent.scopedObjectSetIds.isNotEmpty) {
      return 'Find these at home: ${intent.scopedObjectSetIds.join(', ')}';
    }
    return '';
  }
}

/// Word Card → Lens (P7-915 AC4).
class SeeItInTheWildButton extends StatelessWidget {
  const SeeItInTheWildButton({
    super.key,
    required this.language,
    this.targetLexemeId,
    this.targetObjectSetId,
    this.preflight,
  });

  final String language;
  final String? targetLexemeId;
  final String? targetObjectSetId;
  final LensAvailability? preflight;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => openLensEntry(
          context,
          intent: LensEntryIntent(
            language: language,
            targetLexemeId: targetLexemeId,
            targetObjectSetId: targetObjectSetId,
          ),
          preflight: preflight,
        ),
        icon: const Icon(Icons.travel_explore_outlined),
        label: const Text(kSeeItInTheWildLabel),
      ),
    );
  }
}
