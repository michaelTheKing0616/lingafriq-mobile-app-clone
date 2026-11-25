/// On-device ML Kit label pipeline with curated object-set mapping (P7-903).
library;

import 'dart:async';

import 'package:lingafriq/services/lens/object_set_mapper.dart';

/// Display label for overlay boxes — never a fake dictionary word.
class LensMappedDetection {
  const LensMappedDetection({
    required this.rawMlKitLabel,
    required this.mapping,
    this.displayLabel,
  });

  final String rawMlKitLabel;
  final LensLabelMapping mapping;

  /// Curated object id when mapped; otherwise a fixed unsure / fallback string.
  final String? displayLabel;

  bool get offersServerFallback =>
      mapping.kind == LensLabelMappingKind.unmapped ||
      mapping.kind == LensLabelMappingKind.coarseUnsure;
}

enum LensDetectionSessionState {
  ready,
  timedOut,
  failed,
}

class LensOnDeviceDetector {
  LensOnDeviceDetector({
    required ObjectSetMapper mapper,
    this.detectionTimeout = const Duration(seconds: 3),
  }) : _mapper = mapper;

  final ObjectSetMapper _mapper;
  final Duration detectionTimeout;

  LensDetectionSessionState _sessionState = LensDetectionSessionState.ready;

  LensDetectionSessionState get sessionState => _sessionState;

  /// Maps generic ML Kit labels from one frame. Coarse buckets become Unsure.
  List<LensMappedDetection> mapFrameLabels(List<String> mlKitLabels) {
    final out = <LensMappedDetection>[];
    for (final raw in mlKitLabels) {
      final mapping = _mapper.mapLabel(raw);
      final display = _displayFor(mapping);
      out.add(
        LensMappedDetection(
          rawMlKitLabel: raw,
          mapping: mapping,
          displayLabel: display,
        ),
      );
    }
    return out;
  }

  String? _displayFor(LensLabelMapping mapping) {
    switch (mapping.kind) {
      case LensLabelMappingKind.mapped:
        return mapping.objectSetId;
      case LensLabelMappingKind.coarseUnsure:
        return 'Unsure';
      case LensLabelMappingKind.unmapped:
        return 'Unsure';
    }
  }

  /// Runs [detect] with a timeout; on failure exposes server tap-to-recognise.
  Future<List<LensMappedDetection>> detectWithTimeout(
    Future<List<String>> Function() detect,
  ) async {
    _sessionState = LensDetectionSessionState.ready;
    try {
      final labels = await detect().timeout(detectionTimeout);
      return mapFrameLabels(labels);
    } on TimeoutException {
      _sessionState = LensDetectionSessionState.timedOut;
      return const [];
    } catch (_) {
      _sessionState = LensDetectionSessionState.failed;
      return const [];
    }
  }

  bool get shouldOfferServerFallback =>
      _sessionState == LensDetectionSessionState.timedOut ||
      _sessionState == LensDetectionSessionState.failed;
}
