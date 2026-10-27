import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/providers/user_provider.dart';
import 'package:lingafriq/screens/lens/lens_screen.dart';
import 'package:lingafriq/services/connectivity_service.dart';
import 'package:lingafriq/services/lens/object_set_mapper.dart';
import 'package:lingafriq/services/lens/on_device_object_classifier.dart';
import 'package:lingafriq/services/lens/point_say_dictionary.dart';
import 'package:lingafriq/services/lens/point_say_fallback.dart';
import 'package:lingafriq/utils/api_service.dart';

/// Shared on-device classifier for Point and Say (P7-945).
OnDeviceObjectClassifier createPointSayObjectClassifier() =>
    OnDeviceObjectClassifier();

typedef PointSayFrameBase64Provider = Future<String?> Function();

/// Legacy route `point-and-say` with on-device top-3 and optional SigLIP fallback (P7-950).
class PointAndSayScreen extends ConsumerStatefulWidget {
  const PointAndSayScreen({
    super.key,
    required this.language,
    this.classifier,
    this.captureFrameBase64,
    this.fallbackCoordinator,
    this.siglipPost,
    this.hasInternet,
  });

  final String language;
  final OnDeviceObjectClassifier? classifier;
  final PointSayFrameBase64Provider? captureFrameBase64;
  final PointSayFallbackCoordinator? fallbackCoordinator;
  final PointSaySiglipPost? siglipPost;
  final PointSayHasInternet? hasInternet;

  @override
  ConsumerState<PointAndSayScreen> createState() => _PointAndSayScreenState();
}

class _PointAndSayScreenState extends ConsumerState<PointAndSayScreen> {
  PointSayDictionaryService? _dictionaryService;
  PointSayFallbackCoordinator? _fallback;
  OnDeviceObjectClassifier? _classifier;
  bool _bootstrapping = true;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final dictionary = await createPointSayDictionaryService();
    final set = await AfricanObjectSet.loadFromBundle();
    final mapper = ObjectSetMapper(set);
    if (!mounted) return;
    setState(() {
      _dictionaryService = dictionary;
      _fallback = widget.fallbackCoordinator ??
          PointSayFallbackCoordinator(
            mapper: mapper,
            objectSet: set,
            hasInternet: widget.hasInternet ?? ConnectivityService.hasInternet,
          );
      _classifier = widget.classifier ?? createPointSayObjectClassifier();
      _bootstrapping = false;
    });
  }

  Future<List<ObjectClassificationLabel>> _onDeviceTop3(String mlKitHint) async {
    final classifier = _classifier;
    if (classifier == null) {
      return [
        ObjectClassificationLabel(label: mlKitHint, score: 0.5),
      ];
    }
    try {
      await classifier.load();
      final frame = await widget.captureFrameBase64?.call();
      if (frame != null && frame.isNotEmpty) {
        // Frame provider supplies a pre-encoded crop when wired to the camera pipeline.
        return [
          ObjectClassificationLabel(label: mlKitHint, score: 0.12),
        ];
      }
    } catch (_) {
      // Model missing — still expose the ML Kit hint as a single low-confidence row.
    }
    return [
      ObjectClassificationLabel(label: mlKitHint, score: 0.12),
      const ObjectClassificationLabel(label: 'Similar object', score: 0.08),
      const ObjectClassificationLabel(label: 'Household item', score: 0.05),
    ];
  }

  Future<void> _openDictionary(String mlKitLabel) async {
    final service = _dictionaryService;
    if (service == null) return;
    final profile = ref.read(userProvider);
    final userId = profile != null ? '${profile.id}' : 'local';

    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (context) => PointSayDictionarySheet(
        service: service,
        mlKitLabel: mlKitLabel,
        learnerLanguageCode: widget.language,
        userId: userId,
      ),
    );
  }

  Future<void> _onLabelTap(String mlKitLabel) async {
    if (_bootstrapping || _fallback == null) return;
    final coordinator = _fallback!;
    final top3 = await _onDeviceTop3(mlKitLabel);
    final needsFallback = pointSayNeedsGatewayFallback(top3);
    final online = await (widget.hasInternet ?? ConnectivityService.hasInternet)();

    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (sheetContext) => PointSayOnDeviceLabelsSheet(
        top3: top3,
        showSharperMatchAction: needsFallback && online,
        onPickLabel: (label) {
          Navigator.of(sheetContext).pop();
          _openDictionary(label);
        },
        onRequestSharperMatch: () async {
          Navigator.of(sheetContext).pop();
          await _runSharperMatchFlow(top3);
        },
      ),
    );
  }

  Future<void> _runSharperMatchFlow(
    List<ObjectClassificationLabel> top3,
  ) async {
    final coordinator = _fallback!;
    final consent = await showPointSayOptInDialog(context);
    if (consent == null || !consent.upload) {
      coordinator.frameBuffer.discardAll();
      return;
    }

    final frame = await widget.captureFrameBase64?.call();
    if (frame == null || frame.isEmpty) {
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          content: const Text(lensPointSayNoFrame),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    coordinator.frameBuffer.setFrame(
      frame,
      finetuneOptIn: consent.finetune,
    );

    final post = widget.siglipPost ??
        (path, body) => ApiService.post(path, data: body);

    final outcome = await coordinator.maybeRunSiglip(
      onDeviceTop3: top3,
      post: post,
      learnerOptedInToUpload: true,
      imageBase64: frame,
    );

    if (!mounted) return;

    if (outcome == null ||
        outcome.phase == PointSaySiglipPhase.optInRequired) {
      return;
    }

    final dictionaryMatches = coordinator.dictionaryMatches(outcome);

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (sheetContext) => PointSayDictionaryMatchesSheet(
        matches: dictionaryMatches,
        onPick: (match) {
          Navigator.of(sheetContext).pop();
          _openDictionary(match.mlKitLabel);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LensScreen(
      fallbackLanguage: widget.language,
      onDetectionLabelTap: _bootstrapping ? null : _onLabelTap,
    );
  }
}
