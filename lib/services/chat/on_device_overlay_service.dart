import 'package:flutter/material.dart';
import 'package:lingafriq/services/age_tier_service.dart';
import 'package:lingafriq/services/capability_gate.dart';
import 'package:lingafriq/services/lexicon_lookup_service.dart';
import 'package:lingafriq/services/offline/lexicon_pack_service.dart';
import 'package:lingafriq/widgets/chat/server_assist_consent_sheet.dart'
    show
        ServerAssistConsentChoice,
        ServerAssistFeature,
        showServerAssistConsentSheet;
import 'package:lingafriq/widgets/tone_contour_line.dart';

/// Plan copy keys: `overlay.serverassist.title`, `overlay.serverassist.body`.
abstract final class ChatOverlayCopy {
  static const serverAssistUnavailableTitle = 'On-device only for this chat';
  static const serverAssistUnavailableBody =
      'This message stays on your phone. Download a language pack or try again when you are online with guardian approval.';
  static const guardianGatedTitle = 'Learning tools need Family hub';
  static const guardianGatedBody =
      'Word help and Tone Lens in encrypted chats stay off until your age is confirmed and a parent approves where needed.';
}

enum ChatOverlaySurfacePolicy {
  available,
  hiddenForMinorOrUnknownAge,
  guardianGated,
}

enum OnDeviceOverlayKind {
  wordGloss,
  toneLens,
}

enum ServerAssistOutcome {
  completed,
  declined,
  unavailable,
  blockedPolicy,
  guardianGated,
}

class WordGlossOverlayResult {
  const WordGlossOverlayResult({
    required this.surface,
    required this.lookup,
    this.networkCallsAttempted = 0,
  });

  final String surface;
  final LexiconLookupResult lookup;
  final int networkCallsAttempted;
}

class ToneLensOverlayResult {
  const ToneLensOverlayResult({
    required this.surface,
    required this.toneData,
    this.lexemeLemma,
    this.networkCallsAttempted = 0,
  });

  final String surface;
  final LensLemmaToneData toneData;
  final String? lexemeLemma;
  final int networkCallsAttempted;
}

class ServerAssistRequest {
  const ServerAssistRequest({
    required this.messageId,
    required this.messagePlaintext,
    required this.feature,
    required this.languageCode,
    this.e2ee = true,
  });

  final String messageId;
  final String messagePlaintext;
  final ServerAssistFeature feature;
  final String languageCode;
  final bool e2ee;
}

typedef ServerAssistInvoke = Future<void> Function(ServerAssistRequest request);

typedef LearningOverlayPolicyFetch = Future<ChatOverlaySurfacePolicy> Function();

/// P9-940 — on-device gloss/Tone Lens for E2EE; per-message server opt-in.
class OnDeviceOverlayService {
  OnDeviceOverlayService({
    required this.languageCode,
    LexiconPackService? packService,
    LearningOverlayPolicyFetch? policyFetch,
    ServerAssistInvoke? serverAssistInvoke,
  })  : _pack = packService,
        _policyFetch = policyFetch ?? _defaultPolicyFetch,
        _serverAssist = serverAssistInvoke ?? _noopServerAssist;

  final String languageCode;
  final LexiconPackService? _pack;
  final LearningOverlayPolicyFetch _policyFetch;
  final ServerAssistInvoke _serverAssist;

  final Set<String> _consentedMessageKeys = <String>{};

  @visibleForTesting
  Set<String> get consentedMessageKeys => Set<String>.from(_consentedMessageKeys);

  static String consentKey(String messageId, ServerAssistFeature feature) =>
      '$messageId:${feature.name}';

  static Future<void> _noopServerAssist(ServerAssistRequest request) async {}

  static Future<ChatOverlaySurfacePolicy> _defaultPolicyFetch() async {
    final age = AgeTierService();
    final caps = CapabilityGate();
    final status = await age.fetchStatus();
    final matrix = await caps.load();
    if (!status.assigned || matrix.isMinor) {
      if (!status.assigned) {
        return ChatOverlaySurfacePolicy.hiddenForMinorOrUnknownAge;
      }
      return ChatOverlaySurfacePolicy.guardianGated;
    }
    return ChatOverlaySurfacePolicy.available;
  }

  Future<ChatOverlaySurfacePolicy> resolveSurfacePolicy() => _policyFetch();

  LexiconLookupService _offlineLookup() {
    return LexiconLookupService(
      languageCode: languageCode,
      packService: _pack,
      assumeOffline: true,
      fetchLexemeById: (_) async => null,
      searchLexemes: (_, __) async => const [],
    );
  }

  Future<WordGlossOverlayResult> glossWord({
    required String messageId,
    required String word,
    required bool e2ee,
  }) async {
    assert(messageId.isNotEmpty);
    final lookup = await _offlineLookup().lookupSurface(word);
    return WordGlossOverlayResult(
      surface: word.trim(),
      lookup: lookup,
      networkCallsAttempted: 0,
    );
  }

  Future<ToneLensOverlayResult> toneLensForWord({
    required String messageId,
    required String word,
    required bool e2ee,
  }) async {
    final gloss = await glossWord(
      messageId: messageId,
      word: word,
      e2ee: e2ee,
    );
    final lexeme = gloss.lookup.lexeme;
    LensLemmaToneData toneData = const LensLemmaToneData();
    if (lexeme != null) {
      toneData = lensLemmaToneFromEntry(lexeme.raw);
    }
    return ToneLensOverlayResult(
      surface: gloss.surface,
      toneData: toneData,
      lexemeLemma: lexeme?.lemma,
      networkCallsAttempted: 0,
    );
  }

  Future<ServerAssistOutcome> requestServerAssist({
    required BuildContext context,
    required ServerAssistRequest request,
  }) async {
    if (!request.e2ee) {
      await _serverAssist(request);
      return ServerAssistOutcome.completed;
    }

    final policy = await resolveSurfacePolicy();
    if (policy == ChatOverlaySurfacePolicy.hiddenForMinorOrUnknownAge) {
      return ServerAssistOutcome.blockedPolicy;
    }
    if (policy == ChatOverlaySurfacePolicy.guardianGated) {
      return ServerAssistOutcome.guardianGated;
    }

    final key = consentKey(request.messageId, request.feature);
    if (!_consentedMessageKeys.contains(key)) {
      if (!context.mounted) return ServerAssistOutcome.declined;
      final consent = await showServerAssistConsentSheet(
        context: context,
        messagePreview: _previewSnippet(request.messagePlaintext),
        feature: request.feature,
      );
      if (consent != ServerAssistConsentChoice.allowOnce) {
        return ServerAssistOutcome.declined;
      }
      _consentedMessageKeys.add(key);
    }

    await _serverAssist(request);
    return ServerAssistOutcome.completed;
  }

  static String _previewSnippet(String text) {
    final trimmed = text.trim();
    if (trimmed.length <= 120) return trimmed;
    return '${trimmed.substring(0, 117)}…';
  }
}
