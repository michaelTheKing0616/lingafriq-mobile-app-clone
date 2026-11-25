import 'dart:convert';

import 'package:lingafriq/services/age_tier_service.dart';
import 'package:lingafriq/services/capability_gate.dart';
import 'package:lingafriq/services/chat/on_device_overlay_service.dart';
import 'package:lingafriq/services/learning/spaced_repetition_service.dart';
import 'package:lingafriq/services/lexicon_lookup_service.dart';
import 'package:lingafriq/utils/api_service.dart';

/// Server-owned visibility for peer language badges (AC4).
const String chatPeerLanguageStatusPath = '/api/v2/chat/users';

enum ChatLearningSurfacePolicy {
  available,
  hiddenForMinorOrUnknownAge,
  guardianGated,
}

enum ChatLanguageRole {
  learning,
  native,
}

class ChatLanguageStatusEntry {
  const ChatLanguageStatusEntry({
    required this.languageCode,
    required this.role,
    required this.visibleToViewer,
    this.displayName,
  });

  final String languageCode;
  final ChatLanguageRole role;
  final bool visibleToViewer;
  final String? displayName;

  factory ChatLanguageStatusEntry.fromJson(Map<String, dynamic> json) {
    final roleRaw = (json['role'] ?? json['status'] ?? '').toString();
    final role = roleRaw == 'native'
        ? ChatLanguageRole.native
        : ChatLanguageRole.learning;
    return ChatLanguageStatusEntry(
      languageCode: (json['language_code'] ?? json['language'] ?? '').toString(),
      role: role,
      visibleToViewer: json['visible_to_viewer'] == true ||
          json['visible'] == true,
      displayName: json['display_name']?.toString(),
    );
  }
}

class ChatMessageCheckResult {
  const ChatMessageCheckResult({
    required this.originalText,
    required this.suggestedText,
    required this.explanation,
    this.unavailable = false,
  });

  final String originalText;
  final String suggestedText;
  final String explanation;
  final bool unavailable;

  bool get hasSuggestion =>
      !unavailable && suggestedText.trim() != originalText.trim();

  ChatMessageCheckResult withOriginalText(String original) {
    return ChatMessageCheckResult(
      originalText: original,
      suggestedText: original,
      explanation: explanation,
      unavailable: unavailable,
    );
  }

  static const unavailableState = ChatMessageCheckResult(
    originalText: '',
    suggestedText: '',
    explanation: 'Polie could not check this message right now. You can still send it.',
    unavailable: true,
  );
}

class ChatSaveToReviewResult {
  const ChatSaveToReviewResult({
    required this.itemId,
    required this.created,
  });

  final String itemId;
  final bool created;
}

typedef ChatLearningPolicyFetch = Future<ChatLearningSurfacePolicy> Function();

typedef ChatPeerLanguageStatusFetch = Future<List<ChatLanguageStatusEntry>>
    Function(int peerUserId);

typedef ChatMessageCheckInvoke = Future<ChatMessageCheckResult> Function({
  required String draftText,
  required String languageCode,
});

typedef ChatGatewayComplete = Future<Map<String, dynamic>> Function({
  required String mode,
  required List<Map<String, String>> messages,
  required String languageCode,
});

/// P9-945 — gloss, Tone Lens, pre-send check, and language status for chat rooms.
class ChatRoomLearningService {
  ChatRoomLearningService({
    required this.languageCode,
    required this.learnerUserId,
    OnDeviceOverlayService? overlay,
    SpacedRepetitionService? spacedRepetition,
    ChatLearningPolicyFetch? policyFetch,
    ChatPeerLanguageStatusFetch? peerStatusFetch,
    ChatMessageCheckInvoke? messageCheck,
    ChatGatewayComplete? gatewayComplete,
  })  : _overlay = overlay ??
            OnDeviceOverlayService(languageCode: languageCode),
        _sr = spacedRepetition ?? SpacedRepetitionService(),
        _policyFetch = policyFetch ?? _defaultPolicyFetch,
        _peerStatusFetch = peerStatusFetch ?? _defaultPeerStatusFetch,
        _messageCheck = messageCheck ?? _defaultMessageCheck(gatewayComplete);

  final String languageCode;
  final String learnerUserId;
  final OnDeviceOverlayService _overlay;
  final SpacedRepetitionService _sr;
  final ChatLearningPolicyFetch _policyFetch;
  final ChatPeerLanguageStatusFetch _peerStatusFetch;
  final ChatMessageCheckInvoke _messageCheck;

  static String reviewItemIdForLexeme(String lexemeId) => 'chat:$lexemeId';

  static Future<ChatLearningSurfacePolicy> _defaultPolicyFetch() async {
    final age = AgeTierService();
    final caps = CapabilityGate();
    final status = await age.fetchStatus();
    final matrix = await caps.load();
    if (!status.assigned || matrix.isMinor) {
      if (!status.assigned) {
        return ChatLearningSurfacePolicy.hiddenForMinorOrUnknownAge;
      }
      return ChatLearningSurfacePolicy.guardianGated;
    }
    return ChatLearningSurfacePolicy.available;
  }

  static ChatMessageCheckInvoke _defaultMessageCheck(
    ChatGatewayComplete? gatewayComplete,
  ) {
    final complete = gatewayComplete ?? _defaultGatewayComplete;
    return ({
      required String draftText,
      required String languageCode,
    }) async {
      try {
        final response = await complete(
          mode: 'tutor_correct',
          messages: [
            {
              'role': 'user',
              'content': jsonEncode({
                'learner_text': draftText,
                'target_language': languageCode,
              }),
            },
          ],
          languageCode: languageCode,
        );
        final content = response['content']?.toString() ??
            response['answer']?.toString() ??
            '';
        if (content.isEmpty) {
          return ChatMessageCheckResult.unavailableState.withOriginalText(
            draftText,
          );
        }
        Map<String, dynamic> parsed;
        try {
          parsed = jsonDecode(content) as Map<String, dynamic>;
        } catch (_) {
          parsed = response;
        }
        final corrected =
            parsed['corrected_text']?.toString() ?? draftText;
        final explanation = parsed['explanation']?.toString() ??
            'Polie spotted a small tweak you might like.';
        return ChatMessageCheckResult(
          originalText: draftText,
          suggestedText: corrected,
          explanation: explanation,
        );
      } catch (_) {
        return ChatMessageCheckResult.unavailableState.withOriginalText(
          draftText,
        );
      }
    };
  }

  static Future<Map<String, dynamic>> _defaultGatewayComplete({
    required String mode,
    required List<Map<String, String>> messages,
    required String languageCode,
  }) async {
    final res = await ApiService.post(
      '/api/ai/chat/completion',
      data: {
        'mode': mode,
        'messages': messages,
        'languageCode': languageCode,
        'response_format': {'type': 'json_object'},
      },
    );
    final raw = res.data;
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return const {};
  }

  static Future<List<ChatLanguageStatusEntry>> _defaultPeerStatusFetch(
    int peerUserId,
  ) async {
    try {
      final res = await ApiService.get(
        '$chatPeerLanguageStatusPath/$peerUserId/language-status',
      );
      final json = res.data;
      if (json is! Map<String, dynamic> || json['ok'] != true) {
        return const [];
      }
      final rows = json['languages'];
      if (rows is! List) return const [];
      return rows
          .whereType<Map>()
          .map((e) => ChatLanguageStatusEntry.fromJson(
                Map<String, dynamic>.from(e),
              ))
          .where((e) => e.languageCode.isNotEmpty && e.visibleToViewer)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<ChatLearningSurfacePolicy> resolveSurfacePolicy() => _policyFetch();

  Future<WordGlossOverlayResult> glossWord({
    required String messageId,
    required String word,
    bool e2ee = true,
  }) {
    return _overlay.glossWord(
      messageId: messageId,
      word: word,
      e2ee: e2ee,
    );
  }

  Future<ToneLensOverlayResult> toneLensForWord({
    required String messageId,
    required String word,
    bool e2ee = true,
  }) {
    return _overlay.toneLensForWord(
      messageId: messageId,
      word: word,
      e2ee: e2ee,
    );
  }

  Future<ChatSaveToReviewResult> saveWordToReview({
    required LexiconLookupResult lookup,
  }) async {
    final lexeme = lookup.lexeme;
    if (lexeme == null || lexeme.lexemeId.isEmpty) {
      throw StateError('Cannot save without a verified lexeme');
    }
    await _sr.initializeUser(learnerUserId);
    final itemId = reviewItemIdForLexeme(lexeme.lexemeId);
    final hadCard = _sr
        .getDueCards(learnerUserId, limit: 10000)
        .any((c) => c.lessonItemId == itemId);
    _sr.getOrCreateCard(learnerUserId, itemId);
    final created = !hadCard;
    return ChatSaveToReviewResult(itemId: itemId, created: created);
  }

  Future<ChatMessageCheckResult> checkMessageBeforeSend(String draftText) {
    return _messageCheck(
      draftText: draftText.trim(),
      languageCode: languageCode,
    );
  }

  Future<List<ChatLanguageStatusEntry>> fetchPeerLanguageStatus(
    int peerUserId,
  ) async {
    final policy = await resolveSurfacePolicy();
    if (policy != ChatLearningSurfacePolicy.available) {
      return const [];
    }
    return _peerStatusFetch(peerUserId);
  }
}
