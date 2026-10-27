/// Village Lens Clip sharing — blur-first, minor-gated (P7-911).
library;

import 'dart:typed_data';

import 'package:lingafriq/services/lens/face_blur.dart';
import 'package:lingafriq/services/lens/lens_privacy_policy.dart';

/// Copy key: lens.share.blocked
const String lensShareBlockedCopyKey = 'lens.share.blocked';

enum LensClipShareBlockReason {
  faceDetectionFailed,
  faceDecodeFailed,
  minorVillageSharingBlocked,
  uploadFailed,
}

enum LensClipSharePhase {
  idle,
  blurring,
  uploading,
  done,
  blocked,
  cancelled,
}

class LensClipDraft {
  const LensClipDraft({
    required this.sessionId,
    required this.sourceJpegBytes,
    required this.phraseOverlay,
    required this.languageCode,
  });

  final String sessionId;
  final Uint8List sourceJpegBytes;
  final String phraseOverlay;
  final String languageCode;
}

class LensClipShareRequest {
  const LensClipShareRequest({
    required this.draft,
    required this.privacy,
    this.guardianSocialConsentRecorded = false,
  });

  final LensClipDraft draft;
  final LensLearnerPrivacyContext privacy;
  final bool guardianSocialConsentRecorded;
}

class LensClipUploadPayload {
  const LensClipUploadPayload({
    required this.jpegBytes,
    required this.phraseOverlay,
    required this.languageCode,
    required this.sessionId,
    required this.facesBlurred,
  });

  final Uint8List jpegBytes;
  final String phraseOverlay;
  final String languageCode;
  final String sessionId;
  final bool facesBlurred;
}

class LensVillageClipUploadResult {
  const LensVillageClipUploadResult({required this.clipId});

  final String clipId;
}

abstract class LensVillageClipUploader {
  Future<LensVillageClipUploadResult> upload(LensClipUploadPayload payload);
}

class LensClipShareResult {
  const LensClipShareResult({
    required this.phase,
    this.clipId,
    this.blockReason,
    this.blockCopyKey = lensShareBlockedCopyKey,
  });

  final LensClipSharePhase phase;
  final String? clipId;
  final LensClipShareBlockReason? blockReason;
  final String blockCopyKey;
}

/// Under-18 learners may not publish Village Clips without guardian social consent.
bool lensVillageClipSharingAllowed({
  required LensLearnerPrivacyContext privacy,
  required bool guardianSocialConsentRecorded,
}) {
  if (!privacy.isMinor) return true;
  return guardianSocialConsentRecorded;
}

LensClipShareBlockReason? lensClipSharePrecheck(LensClipShareRequest request) {
  if (!lensVillageClipSharingAllowed(
    privacy: request.privacy,
    guardianSocialConsentRecorded: request.guardianSocialConsentRecorded,
  )) {
    return LensClipShareBlockReason.minorVillageSharingBlocked;
  }
  return null;
}

class LensClipService {
  LensClipService({
    required LensFaceDetector faceDetector,
    required LensVillageClipUploader uploader,
  })  : _faceDetector = faceDetector,
        _uploader = uploader;

  final LensFaceDetector _faceDetector;
  final LensVillageClipUploader _uploader;
  bool _cancelled = false;

  void cancelShare() {
    _cancelled = true;
  }

  void resetCancellation() {
    _cancelled = false;
  }

  /// Never sends [LensClipDraft.sourceJpegBytes] to the network without a blur pass when faces exist.
  Future<LensClipShareResult> shareToVillage(LensClipShareRequest request) async {
    _cancelled = false;
    final pre = lensClipSharePrecheck(request);
    if (pre != null) {
      return LensClipShareResult(
        phase: LensClipSharePhase.blocked,
        blockReason: pre,
      );
    }

    final blur = await blurFacesInJpeg(
      jpegBytes: request.draft.sourceJpegBytes,
      detector: _faceDetector,
    );
    if (_cancelled) {
      return const LensClipShareResult(phase: LensClipSharePhase.cancelled);
    }

    switch (blur.outcome) {
      case LensFaceBlurOutcome.detectionFailed:
        return const LensClipShareResult(
          phase: LensClipSharePhase.blocked,
          blockReason: LensClipShareBlockReason.faceDetectionFailed,
        );
      case LensFaceBlurOutcome.decodeFailed:
        return const LensClipShareResult(
          phase: LensClipSharePhase.blocked,
          blockReason: LensClipShareBlockReason.faceDecodeFailed,
        );
      case LensFaceBlurOutcome.noFaces:
      case LensFaceBlurOutcome.blurred:
        break;
    }

    final bytes = blur.bytes;
    if (bytes == null || bytes.isEmpty) {
      return const LensClipShareResult(
        phase: LensClipSharePhase.blocked,
        blockReason: LensClipShareBlockReason.faceDecodeFailed,
      );
    }

    if (_cancelled) {
      return const LensClipShareResult(phase: LensClipSharePhase.cancelled);
    }

    try {
      final uploaded = await _uploader.upload(
        LensClipUploadPayload(
          jpegBytes: bytes,
          phraseOverlay: request.draft.phraseOverlay,
          languageCode: request.draft.languageCode,
          sessionId: request.draft.sessionId,
          facesBlurred: blur.outcome == LensFaceBlurOutcome.blurred,
        ),
      );
      if (_cancelled) {
        return const LensClipShareResult(phase: LensClipSharePhase.cancelled);
      }
      return LensClipShareResult(
        phase: LensClipSharePhase.done,
        clipId: uploaded.clipId,
      );
    } catch (_) {
      return const LensClipShareResult(
        phase: LensClipSharePhase.blocked,
        blockReason: LensClipShareBlockReason.uploadFailed,
      );
    }
  }
}
