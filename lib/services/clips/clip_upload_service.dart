import 'dart:convert';
import 'dart:io';

import 'package:lingafriq/utils/api_service.dart';
import 'package:lingafriq/utils/structured_logger.dart';

/// Village clip post client — POST `/api/v2/clips` (P9-948).
class ClipUploadService {
  ClipUploadService();

  static const minDurationSec = 15;
  static const maxDurationSec = 60;

  static String? validateDurationSec(double seconds) {
    if (seconds.isNaN || seconds.isInfinite) {
      return 'CLIP_DURATION_INVALID';
    }
    if (seconds < minDurationSec || seconds > maxDurationSec) {
      return 'CLIP_DURATION_INVALID';
    }
    return null;
  }

  Future<ClipUploadResult> postClip({
    required File mediaFile,
    required double durationSec,
    required String languageTag,
    required String caption,
    required ClipVisibility visibility,
    String? circleId,
    required ClipMediaKind mediaKind,
  }) async {
    final durationCode = validateDurationSec(durationSec);
    if (durationCode != null) {
      return ClipUploadResult.failure(
        code: durationCode,
        message:
            'Clips need to be between $minDurationSec and $maxDurationSec seconds.',
      );
    }

    final tag = languageTag.trim().toLowerCase();
    if (tag.isEmpty) {
      return ClipUploadResult.failure(
        code: 'LANGUAGE_TAG_REQUIRED',
        message: 'Pick the language you are practising in this clip.',
      );
    }

    final trimmedCaption = caption.trim();
    if (trimmedCaption.isEmpty) {
      return ClipUploadResult.failure(
        code: 'CAPTION_REQUIRED',
        message: 'Add a warm caption before you share.',
      );
    }

    if (visibility == ClipVisibility.circle &&
        (circleId == null || circleId.trim().isEmpty)) {
      return ClipUploadResult.failure(
        code: 'CIRCLE_REQUIRED',
        message: 'Choose a circle to share with.',
      );
    }

    try {
      final bytes = await mediaFile.readAsBytes();
      final response = await ApiService.post(
        '/api/v2/clips',
        data: {
          'durationSec': durationSec,
          'languageTag': tag,
          'caption': trimmedCaption,
          'visibility': visibility.apiValue,
          if (circleId != null && circleId.trim().isNotEmpty)
            'circleId': circleId.trim(),
          'mediaKind': mediaKind.apiValue,
          'mediaBase64': base64Encode(bytes),
        },
      );
      final data = response.data;
      if (data is Map && data['ok'] == true) {
        final status = data['status'] as String? ?? 'posted';
        return ClipUploadResult.success(
          clipId: data['clipId'] as String? ?? '',
          heldForReview: status == 'held_for_review' || data['held'] == true,
        );
      }
      if (data is Map) {
        return ClipUploadResult.failure(
          code: data['code'] as String? ?? 'CLIP_POST_FAILED',
          message: data['message'] as String? ??
              'We could not post your clip right now.',
        );
      }
      return ClipUploadResult.failure(
        code: 'CLIP_POST_FAILED',
        message: 'We could not post your clip right now.',
      );
    } catch (error, stack) {
      logger.error('Clip upload failed', tag: 'clips', error: error, stackTrace: stack);
      return ClipUploadResult.failure(
        code: 'NETWORK_ERROR',
        message: 'You are offline. Your clip will stay on this screen until you reconnect.',
      );
    }
  }
}

enum ClipVisibility {
  publicFeed('public_feed'),
  circle('circle');

  const ClipVisibility(this.apiValue);
  final String apiValue;
}

enum ClipMediaKind {
  video('video'),
  audio('audio');

  const ClipMediaKind(this.apiValue);
  final String apiValue;
}

class ClipUploadResult {
  const ClipUploadResult._({
    required this.ok,
    this.clipId,
    this.heldForReview = false,
    this.code,
    this.message,
  });

  factory ClipUploadResult.success({
    required String clipId,
    bool heldForReview = false,
  }) =>
      ClipUploadResult._(
        ok: true,
        clipId: clipId,
        heldForReview: heldForReview,
      );

  factory ClipUploadResult.failure({
    required String code,
    required String message,
  }) =>
      ClipUploadResult._(ok: false, code: code, message: message);

  final bool ok;
  final String? clipId;
  final bool heldForReview;
  final String? code;
  final String? message;
}
