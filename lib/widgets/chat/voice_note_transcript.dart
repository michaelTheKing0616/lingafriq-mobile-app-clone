import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lingafriq/services/age_tier_service.dart';
import 'package:lingafriq/services/capability_gate.dart';
import 'package:lingafriq/services/lexicon_lookup_service.dart';
import 'package:lingafriq/utils/api_service.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// copy_keys: transcript.label, transcript.uncertain
abstract final class VoiceNoteTranscriptCopy {
  static const machineLabel = 'Machine transcript';
  static const uncertainHint =
      'Some words may be wrong — this is not an exact quote.';
  static const transcribeAction = 'Transcribe';
  static const transcribing = 'Listening…';
  static const errorGeneric =
      'We could not transcribe this voice note. Try again when you are online.';
  static const consentTitle = 'Send this voice note to LingAfriq AI?';
  static const consentBody =
      'Only this recording is sent for transcription. It is not kept on our servers after processing.';
  static const consentAllow = 'Transcribe on server';
  static const consentDecline = 'Transcribe on device only';
  static const policyBlocked =
      'Transcription is off for your account until age is confirmed.';
  static const guardianBlocked =
      'Ask a parent in Family hub before using voice transcription.';
}

enum VoiceNoteTranscriptPhase {
  idle,
  transcribing,
  done,
  lowConfidence,
  error,
  hidden,
}

class VoiceNoteTranscriptToken {
  const VoiceNoteTranscriptToken({
    required this.surface,
    this.glossEn,
    this.uncertain = false,
  });

  final String surface;
  final String? glossEn;
  final bool uncertain;

  factory VoiceNoteTranscriptToken.fromJson(Map<String, dynamic> json) {
    return VoiceNoteTranscriptToken(
      surface: (json['surface'] ?? '').toString(),
      glossEn: json['gloss_en']?.toString(),
      uncertain: json['uncertain'] == true,
    );
  }
}

class VoiceNoteTranscriptPayload {
  const VoiceNoteTranscriptPayload({
    required this.transcript,
    required this.tokens,
    required this.lowConfidence,
    this.label = VoiceNoteTranscriptCopy.machineLabel,
  });

  final String label;
  final String transcript;
  final List<VoiceNoteTranscriptToken> tokens;
  final bool lowConfidence;

  factory VoiceNoteTranscriptPayload.fromServerJson(Map<String, dynamic> json) {
    final data = json['data'] is Map
        ? Map<String, dynamic>.from(json['data'] as Map)
        : json;
    final rawTokens = data['tokens'];
    final tokens = rawTokens is List
        ? rawTokens
            .whereType<Map>()
            .map((e) => VoiceNoteTranscriptToken.fromJson(
                  Map<String, dynamic>.from(e),
                ))
            .toList()
        : <VoiceNoteTranscriptToken>[];
    return VoiceNoteTranscriptPayload(
      transcript: (data['transcript'] ?? '').toString(),
      tokens: tokens,
      lowConfidence: data['low_confidence'] == true,
      label: VoiceNoteTranscriptCopy.machineLabel,
    );
  }
}

typedef VoiceNotePolicyFetch = Future<VoiceNoteTranscriptPhase> Function();

typedef VoiceNoteServerTranscribe = Future<VoiceNoteTranscriptPayload> Function({
  required String messageId,
  required String languageCode,
  required String localAudioPath,
  required bool e2ee,
  required bool serverAssistConsent,
});

typedef VoiceNoteOnDeviceTranscribe = Future<VoiceNoteTranscriptPayload?> Function({
  required String languageCode,
  required String localAudioPath,
});

typedef VoiceNoteGlossLookup = Future<String?> Function(
  String languageCode,
  String surface,
);

class VoiceNoteTranscriptController extends ChangeNotifier {
  VoiceNoteTranscriptController({
    required this.messageId,
    required this.languageCode,
    this.e2ee = true,
    this.localAudioPath,
    VoiceNotePolicyFetch? policyFetch,
    VoiceNoteServerTranscribe? serverTranscribe,
    VoiceNoteOnDeviceTranscribe? onDeviceTranscribe,
    VoiceNoteGlossLookup? glossLookup,
  })  : _policyFetch = policyFetch ?? _defaultPolicyFetch,
        _serverTranscribe = serverTranscribe ?? _defaultServerTranscribe,
        _onDeviceTranscribe = onDeviceTranscribe ?? _defaultOnDeviceTranscribe,
        _glossLookup = glossLookup ?? _defaultGlossLookup;

  final String messageId;
  final String languageCode;
  final bool e2ee;
  final String? localAudioPath;

  final VoiceNotePolicyFetch _policyFetch;
  final VoiceNoteServerTranscribe _serverTranscribe;
  final VoiceNoteOnDeviceTranscribe _onDeviceTranscribe;
  final VoiceNoteGlossLookup _glossLookup;

  VoiceNoteTranscriptPhase _phase = VoiceNoteTranscriptPhase.idle;
  VoiceNoteTranscriptPayload? _payload;
  String? _errorMessage;

  VoiceNoteTranscriptPhase get phase => _phase;
  VoiceNoteTranscriptPayload? get payload => _payload;
  String? get errorMessage => _errorMessage;

  bool get isVisible => _phase != VoiceNoteTranscriptPhase.hidden;

  Future<void> prepareVisibility() async {
    final policyPhase = await _policyFetch();
    if (policyPhase == VoiceNoteTranscriptPhase.hidden) {
      _phase = VoiceNoteTranscriptPhase.hidden;
      notifyListeners();
    }
  }

  Future<void> requestTranscript({required BuildContext context}) async {
    final policyPhase = await _policyFetch();
    if (policyPhase == VoiceNoteTranscriptPhase.hidden) {
      _phase = VoiceNoteTranscriptPhase.hidden;
      notifyListeners();
      return;
    }
    if (localAudioPath == null || localAudioPath!.isEmpty) {
      _phase = VoiceNoteTranscriptPhase.error;
      _errorMessage = VoiceNoteTranscriptCopy.errorGeneric;
      notifyListeners();
      return;
    }

    _phase = VoiceNoteTranscriptPhase.transcribing;
    _errorMessage = null;
    notifyListeners();

    try {
      VoiceNoteTranscriptPayload? result;
      if (e2ee) {
        if (!context.mounted) return;
        final consent = await _showConsentSheet(context);
        if (!context.mounted) return;
        if (consent == _VoiceNoteConsentChoice.server) {
          result = await _serverTranscribe(
            messageId: messageId,
            languageCode: languageCode,
            localAudioPath: localAudioPath!,
            e2ee: e2ee,
            serverAssistConsent: true,
          );
        } else if (consent == _VoiceNoteConsentChoice.onDevice) {
          result = await _onDeviceTranscribe(
            languageCode: languageCode,
            localAudioPath: localAudioPath!,
          );
        } else {
          _phase = VoiceNoteTranscriptPhase.idle;
          notifyListeners();
          return;
        }
      } else {
        result = await _serverTranscribe(
          messageId: messageId,
          languageCode: languageCode,
          localAudioPath: localAudioPath!,
          e2ee: false,
          serverAssistConsent: true,
        );
      }

      if (result == null || result.transcript.trim().isEmpty) {
        _phase = VoiceNoteTranscriptPhase.error;
        _errorMessage = VoiceNoteTranscriptCopy.errorGeneric;
        notifyListeners();
        return;
      }

      _payload = result;
      _phase = result.lowConfidence
          ? VoiceNoteTranscriptPhase.lowConfidence
          : VoiceNoteTranscriptPhase.done;
      notifyListeners();
    } catch (_) {
      _phase = VoiceNoteTranscriptPhase.error;
      _errorMessage = VoiceNoteTranscriptCopy.errorGeneric;
      notifyListeners();
    }
  }

  static Future<VoiceNoteTranscriptPhase> _defaultPolicyFetch() async {
    final age = AgeTierService();
    final caps = CapabilityGate();
    final status = await age.fetchStatus();
    final matrix = await caps.load();
    if (!status.assigned || matrix.isMinor) {
      return VoiceNoteTranscriptPhase.hidden;
    }
    if (status.status == 'pending_guardian') {
      return VoiceNoteTranscriptPhase.hidden;
    }
    return VoiceNoteTranscriptPhase.idle;
  }

  static Future<String?> _defaultGlossLookup(
    String languageCode,
    String surface,
  ) async {
    final lookup = LexiconLookupService(languageCode: languageCode);
    final hit = await lookup.lookupSurface(surface);
    if (hit.kind != LexiconLookupKind.hit || hit.lexeme == null) {
      return null;
    }
    final raw = hit.lexeme!.raw;
    final gloss = raw['gloss_en'] ?? raw['meaning'] ?? raw['gloss'];
    final text = gloss?.toString().trim();
    return (text != null && text.isNotEmpty) ? text : null;
  }

  static Future<VoiceNoteTranscriptPayload> _defaultServerTranscribe({
    required String messageId,
    required String languageCode,
    required String localAudioPath,
    required bool e2ee,
    required bool serverAssistConsent,
  }) async {
    final file = File(localAudioPath);
    final form = FormData.fromMap({
      'language_code': languageCode,
      'e2ee': e2ee.toString(),
      'server_assist_consent': serverAssistConsent.toString(),
      'audio': await MultipartFile.fromFile(
        localAudioPath,
        filename: file.uri.pathSegments.isNotEmpty
            ? file.uri.pathSegments.last
            : 'voice.m4a',
      ),
    });
    await ApiService.initialize();
    final response = await ApiService.post(
      '/api/wa/messages/$messageId/voice-note/transcribe',
      data: form,
      options: Options(
        contentType: 'multipart/form-data',
        receiveTimeout: const Duration(seconds: 60),
      ),
    );
    final body = response.data is Map
        ? Map<String, dynamic>.from(response.data as Map)
        : <String, dynamic>{};
    return VoiceNoteTranscriptPayload.fromServerJson(body);
  }

  static Future<VoiceNoteTranscriptPayload?> _defaultOnDeviceTranscribe({
    required String languageCode,
    required String localAudioPath,
  }) async {
    final speech = SpeechToText();
    final available = await speech.initialize();
    if (!available) return null;
    // On-device file transcription is not supported by speech_to_text; return
    // an honest empty result so callers fall back or show error.
    await speech.stop();
    return null;
  }

  Future<List<VoiceNoteTranscriptToken>> enrichOnDeviceTokens(
    String transcript,
  ) async {
    final parts = transcript
        .split(RegExp(r'(\s+)'))
        .where((p) => p.trim().isNotEmpty)
        .toList();
    final tokens = <VoiceNoteTranscriptToken>[];
    for (final surface in parts) {
      final gloss = await _glossLookup(languageCode, surface);
      final uncertain = gloss == null && surface.length > 1;
      tokens.add(
        VoiceNoteTranscriptToken(
          surface: surface,
          glossEn: gloss,
          uncertain: uncertain,
        ),
      );
    }
    return tokens;
  }

  Future<_VoiceNoteConsentChoice?> _showConsentSheet(BuildContext context) {
    return showModalBottomSheet<_VoiceNoteConsentChoice>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.all(PanAfricanSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  VoiceNoteTranscriptCopy.consentTitle,
                  style: Theme.of(ctx).textTheme.titleLarge,
                ),
                SizedBox(height: PanAfricanSpacing.md),
                Text(
                  VoiceNoteTranscriptCopy.consentBody,
                  style: Theme.of(ctx).textTheme.bodyLarge,
                ),
                SizedBox(height: PanAfricanSpacing.lg),
                FilledButton(
                  onPressed: () =>
                      Navigator.pop(ctx, _VoiceNoteConsentChoice.server),
                  child: const Text(VoiceNoteTranscriptCopy.consentAllow),
                ),
                SizedBox(height: PanAfricanSpacing.sm),
                TextButton(
                  onPressed: () =>
                      Navigator.pop(ctx, _VoiceNoteConsentChoice.onDevice),
                  child: const Text(VoiceNoteTranscriptCopy.consentDecline),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

enum _VoiceNoteConsentChoice { server, onDevice }

class VoiceNoteTranscriptPanel extends StatefulWidget {
  const VoiceNoteTranscriptPanel({
    super.key,
    required this.controller,
  });

  final VoiceNoteTranscriptController controller;

  @override
  State<VoiceNoteTranscriptPanel> createState() =>
      _VoiceNoteTranscriptPanelState();
}

class _VoiceNoteTranscriptPanelState extends State<VoiceNoteTranscriptPanel> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChange);
    unawaited(widget.controller.prepareVisibility());
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    if (!c.isVisible) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final spacing = PanAfricanSpacing.md;

    return Semantics(
      label: VoiceNoteTranscriptCopy.machineLabel,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (c.phase == VoiceNoteTranscriptPhase.idle)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => c.requestTranscript(context: context),
                icon: const Icon(Icons.subtitles_outlined),
                label: const Text(VoiceNoteTranscriptCopy.transcribeAction),
              ),
            ),
          if (c.phase == VoiceNoteTranscriptPhase.transcribing)
            Row(
              children: [
                SizedBox(
                  width: 20.w,
                  height: 20.w,
                  child: CircularProgressIndicator(strokeWidth: 2.w),
                ),
                SizedBox(width: spacing),
                Text(
                  VoiceNoteTranscriptCopy.transcribing,
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          if (c.phase == VoiceNoteTranscriptPhase.error)
            Text(
              c.errorMessage ?? VoiceNoteTranscriptCopy.errorGeneric,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          if (c.payload != null &&
              (c.phase == VoiceNoteTranscriptPhase.done ||
                  c.phase == VoiceNoteTranscriptPhase.lowConfidence)) ...[
            Text(
              c.payload!.label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
            SizedBox(height: PanAfricanSpacing.sm),
            _TokenWrap(tokens: c.payload!.tokens),
            if (c.phase == VoiceNoteTranscriptPhase.lowConfidence) ...[
              SizedBox(height: PanAfricanSpacing.sm),
              Text(
                VoiceNoteTranscriptCopy.uncertainHint,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.tertiary,
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _TokenWrap extends StatelessWidget {
  const _TokenWrap({required this.tokens});

  final List<VoiceNoteTranscriptToken> tokens;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Wrap(
      spacing: PanAfricanSpacing.sm,
      runSpacing: PanAfricanSpacing.xs,
      children: [
        for (final token in tokens)
          Semantics(
            label: token.glossEn != null
                ? '${token.surface}, ${token.glossEn}'
                : token.surface,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  token.surface,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    decoration: token.uncertain
                        ? TextDecoration.underline
                        : TextDecoration.none,
                    decorationStyle: TextDecorationStyle.dotted,
                  ),
                ),
                if (token.glossEn != null)
                  Text(
                    token.glossEn!,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
