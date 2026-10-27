/// MobileNetV4 → optional SigLIP gateway fallback with image opt-in (P7-950).
library;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:lingafriq/services/lens/object_set_mapper.dart';
import 'package:lingafriq/services/lens/on_device_object_classifier.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';

/// copy_keys: lens.point_say.ask_opt_in, lens.point_say.dictionary_matches
const String lensPointSayAskOptInTitle = 'Get a sharper match?';
const String lensPointSayAskOptInBody =
    'We can send this photo once to our server to compare it with words in your Living Dictionary. Nothing is saved unless you choose to help train recognition later.';
const String lensPointSayAskOptInConfirm = 'Send photo once';
const String lensPointSayAskOptInDecline = 'Keep on-device guesses';
const String lensPointSayFinetuneOptInLabel =
    'Also save this photo to improve Point and Say (optional)';
const String lensPointSayDictionaryMatchesTitle = 'Living Dictionary matches';
const String lensPointSayOnDeviceTitle = 'On-device guesses';
const String lensPointSayGatewayUnavailable =
    'Server matching is unavailable. Try another angle or check your connection.';
const String lensPointSayNoFrame =
    'We could not capture a photo from the camera. Point at the object and try again.';

const String kPointSaySiglipMatchPath = '/api/ai/point-and-say/siglip-match';

/// Top-1 softmax below this triggers an optional SigLIP pass when online.
const double kPointSayLowConfidenceThreshold = 0.28;

typedef PointSaySiglipPost = Future<Response<dynamic>> Function(
  String path,
  Map<String, dynamic> body,
);

typedef PointSayHasInternet = Future<bool> Function();

class SiglipGlossMatch {
  const SiglipGlossMatch({required this.gloss, required this.score});

  final String gloss;
  final double score;
}

enum PointSaySiglipPhase { matches, optInRequired, unavailable, invalidImage }

class PointSaySiglipOutcome {
  const PointSaySiglipOutcome({
    required this.phase,
    this.matches = const [],
    this.errorCode,
  });

  final PointSaySiglipPhase phase;
  final List<SiglipGlossMatch> matches;
  final String? errorCode;
}

class PointSayDictionaryGlossMatch {
  const PointSayDictionaryGlossMatch({
    required this.gloss,
    required this.mlKitLabel,
    required this.objectSetId,
    required this.score,
  });

  final String gloss;
  final String mlKitLabel;
  final String objectSetId;
  final double score;
}

bool pointSayNeedsGatewayFallback(List<ObjectClassificationLabel> top3) {
  if (top3.isEmpty) return true;
  return top3.first.score < kPointSayLowConfidenceThreshold;
}

List<String> collectLicensedObjectGlosses(AfricanObjectSet set) {
  final seen = <String>{};
  final out = <String>[];
  for (final entry in set.entries) {
    for (final label in entry.mlKitLabels) {
      final trimmed = label.trim();
      if (trimmed.isEmpty) continue;
      final key = trimmed.toLowerCase();
      if (seen.add(key)) out.add(trimmed);
    }
  }
  return out;
}

List<PointSayDictionaryGlossMatch> livingDictionaryMatchesFromSiglip({
  required List<SiglipGlossMatch> matches,
  required ObjectSetMapper mapper,
}) {
  final out = <PointSayDictionaryGlossMatch>[];
  for (final match in matches) {
    final mapping = mapper.mapLabel(match.gloss);
    if (mapping.kind != LensLabelMappingKind.mapped ||
        mapping.objectSetId == null) {
      continue;
    }
    out.add(
      PointSayDictionaryGlossMatch(
        gloss: match.gloss,
        mlKitLabel: match.gloss,
        objectSetId: mapping.objectSetId!,
        score: match.score,
      ),
    );
  }
  return out;
}

PointSaySiglipOutcome parseSiglipMatchBody(Map<String, dynamic> body) {
  if (body['ok'] != true) {
    final code = body['code']?.toString();
    if (code == 'IMAGE_OPT_IN_REQUIRED') {
      return const PointSaySiglipOutcome(phase: PointSaySiglipPhase.optInRequired);
    }
    return PointSaySiglipOutcome(
      phase: PointSaySiglipPhase.unavailable,
      errorCode: code,
    );
  }
  final raw = body['matches'];
  if (raw is! List) {
    return const PointSaySiglipOutcome(phase: PointSaySiglipPhase.unavailable);
  }
  final matches = <SiglipGlossMatch>[];
  for (final item in raw) {
    if (item is! Map) continue;
    final map = Map<String, dynamic>.from(item);
    final gloss = map['gloss']?.toString().trim() ?? '';
    final score = (map['score'] as num?)?.toDouble() ?? 0;
    if (gloss.isEmpty) continue;
    matches.add(SiglipGlossMatch(gloss: gloss, score: score));
  }
  return PointSaySiglipOutcome(
    phase: PointSaySiglipPhase.matches,
    matches: matches,
  );
}

class PointSaySiglipClient {
  const PointSaySiglipClient({this.matchPath = kPointSaySiglipMatchPath});

  final String matchPath;

  Future<PointSaySiglipOutcome> matchFrame({
    required PointSaySiglipPost post,
    required String imageBase64,
    required List<String> glosses,
    required bool imageOptIn,
    int topK = 5,
  }) async {
    if (!imageOptIn) {
      return const PointSaySiglipOutcome(
        phase: PointSaySiglipPhase.optInRequired,
      );
    }
    try {
      final response = await post(
        matchPath,
        {
          'imageOptIn': true,
          'imageBase64': imageBase64,
          'glosses': glosses,
          'topK': topK,
        },
      );
      final status = response.statusCode ?? 0;
      final raw = response.data;
      final body =
          raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
      if (status == 403 && body['code'] == 'IMAGE_OPT_IN_REQUIRED') {
        return const PointSaySiglipOutcome(
          phase: PointSaySiglipPhase.optInRequired,
        );
      }
      if (status == 400 && body['code'] == 'IMAGE_INVALID') {
        return const PointSaySiglipOutcome(
          phase: PointSaySiglipPhase.invalidImage,
        );
      }
      if (status != 200) {
        return PointSaySiglipOutcome(
          phase: PointSaySiglipPhase.unavailable,
          errorCode: body['code']?.toString(),
        );
      }
      return parseSiglipMatchBody(body);
    } catch (_) {
      return const PointSaySiglipOutcome(
        phase: PointSaySiglipPhase.unavailable,
      );
    }
  }
}

/// Holds a frame only until the learner reply completes; never retained for finetune unless opted in.
class PointSayFrameBuffer {
  String? _base64;
  bool _finetuneOptIn = false;

  void setFrame(String base64, {required bool finetuneOptIn}) {
    _base64 = base64;
    _finetuneOptIn = finetuneOptIn;
  }

  String? takeForGateway() => _base64;

  bool get finetuneOptIn => _finetuneOptIn;

  void clearAfterReply() {
    if (!_finetuneOptIn) {
      _base64 = null;
    }
  }

  void discardAll() {
    _base64 = null;
    _finetuneOptIn = false;
  }
}

class PointSayFallbackCoordinator {
  PointSayFallbackCoordinator({
    required ObjectSetMapper mapper,
    required AfricanObjectSet objectSet,
    PointSaySiglipClient? siglipClient,
    PointSayHasInternet? hasInternet,
    PointSayFrameBuffer? frameBuffer,
  })  : _mapper = mapper,
        _glosses = collectLicensedObjectGlosses(objectSet),
        _siglip = siglipClient ?? const PointSaySiglipClient(),
        _hasInternet = hasInternet ?? (() async => true),
        frameBuffer = frameBuffer ?? PointSayFrameBuffer();

  final ObjectSetMapper _mapper;
  final List<String> _glosses;
  final PointSaySiglipClient _siglip;
  final PointSayHasInternet _hasInternet;
  final PointSayFrameBuffer frameBuffer;

  List<String> get glosses => _glosses;

  Future<PointSaySiglipOutcome?> maybeRunSiglip({
    required List<ObjectClassificationLabel> onDeviceTop3,
    required PointSaySiglipPost post,
    required bool learnerOptedInToUpload,
    required String? imageBase64,
  }) async {
    if (!pointSayNeedsGatewayFallback(onDeviceTop3)) {
      return null;
    }
    final online = await _hasInternet();
    if (!online) {
      return null;
    }
    if (!learnerOptedInToUpload) {
      return const PointSaySiglipOutcome(phase: PointSaySiglipPhase.optInRequired);
    }
    final payload = imageBase64 ?? frameBuffer.takeForGateway();
    if (payload == null || payload.isEmpty) {
      return const PointSaySiglipOutcome(phase: PointSaySiglipPhase.unavailable);
    }
    final outcome = await _siglip.matchFrame(
      post: post,
      imageBase64: payload,
      glosses: glosses,
      imageOptIn: true,
    );
    frameBuffer.clearAfterReply();
    return outcome;
  }

  List<PointSayDictionaryGlossMatch> dictionaryMatches(
    PointSaySiglipOutcome outcome,
  ) {
    return livingDictionaryMatchesFromSiglip(
      matches: outcome.matches,
      mapper: _mapper,
    );
  }
}

/// Returns upload consent; when true, second value is finetune-set opt-in.
Future<({bool upload, bool finetune})?> showPointSayOptInDialog(
  BuildContext context, {
  bool finetuneDefault = false,
}) async {
  var finetune = finetuneDefault;
  final upload = await showDialog<bool>(
    context: context,
    barrierColor: Colors.black54,
    builder: (ctx) {
      return Semantics(
        label: lensPointSayAskOptInTitle,
        child: AlertDialog(
          title: const Text(lensPointSayAskOptInTitle),
          content: SingleChildScrollView(
            child: StatefulBuilder(
              builder: (context, setState) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(lensPointSayAskOptInBody),
                    SizedBox(height: PanAfricanSpacing.md),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: finetune,
                      onChanged: (v) => setState(() => finetune = v ?? false),
                      title: const Text(lensPointSayFinetuneOptInLabel),
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                  ],
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text(lensPointSayAskOptInDecline),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text(lensPointSayAskOptInConfirm),
            ),
          ],
        ),
      );
    },
  );
  if (upload != true) return null;
  return (upload: true, finetune: finetune);
}

class PointSayOnDeviceLabelsSheet extends StatelessWidget {
  const PointSayOnDeviceLabelsSheet({
    super.key,
    required this.top3,
    required this.onPickLabel,
    required this.onRequestSharperMatch,
    required this.showSharperMatchAction,
  });

  final List<ObjectClassificationLabel> top3;
  final ValueChanged<String> onPickLabel;
  final VoidCallback onRequestSharperMatch;
  final bool showSharperMatchAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.all(PanAfricanSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              lensPointSayOnDeviceTitle,
              style: theme.textTheme.titleMedium,
            ),
            SizedBox(height: PanAfricanSpacing.sm),
            if (top3.isEmpty)
              Text(
                'We are still looking — try holding steady on the object.',
                style: theme.textTheme.bodyMedium,
              )
            else
              ...top3.map(
                (row) => Padding(
                  padding: EdgeInsets.only(bottom: PanAfricanSpacing.xs),
                  child: Material(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(PanAfricanRadius.md),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(PanAfricanRadius.md),
                      onTap: () => onPickLabel(row.label),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: PanAfricanSpacing.md,
                          vertical: PanAfricanSpacing.sm + 4,
                        ),
                        child: Row(
                          children: [
                            Expanded(child: Text(row.label)),
                            Text(
                              '${(row.score * 100).round()}%',
                              style: theme.textTheme.labelMedium,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            if (showSharperMatchAction) ...[
              SizedBox(height: PanAfricanSpacing.md),
              FilledButton.tonal(
                onPressed: onRequestSharperMatch,
                child: const Text(lensPointSayAskOptInConfirm),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class PointSayDictionaryMatchesSheet extends StatelessWidget {
  const PointSayDictionaryMatchesSheet({
    super.key,
    required this.matches,
    required this.onPick,
  });

  final List<PointSayDictionaryGlossMatch> matches;
  final ValueChanged<PointSayDictionaryGlossMatch> onPick;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.all(PanAfricanSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: Text(
                lensPointSayDictionaryMatchesTitle,
                style: theme.textTheme.titleMedium,
              ),
            ),
            SizedBox(height: PanAfricanSpacing.sm),
            if (matches.isEmpty)
              Text(
                lensPointSayGatewayUnavailable,
                style: theme.textTheme.bodyMedium,
              )
            else
              ...matches.map(
                (m) => Padding(
                  padding: EdgeInsets.only(bottom: PanAfricanSpacing.xs),
                  child: Material(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(PanAfricanRadius.md),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(PanAfricanRadius.md),
                      onTap: () => onPick(m),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: PanAfricanSpacing.md,
                          vertical: PanAfricanSpacing.sm + 4,
                        ),
                        child: Row(
                          children: [
                            Expanded(child: Text(m.gloss)),
                            Text(
                              '${(m.score * 100).round()}%',
                              style: theme.textTheme.labelMedium,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
