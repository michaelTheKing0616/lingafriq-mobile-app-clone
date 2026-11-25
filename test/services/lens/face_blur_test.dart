import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:lingafriq/services/lens/face_blur.dart';
import 'package:lingafriq/services/lens/lens_clip_service.dart';
import 'package:lingafriq/services/lens/lens_privacy_policy.dart';

Uint8List _solidJpeg(int width, int height, {int r = 200, int g = 180, int b = 160}) {
  final image = img.Image(width: width, height: height);
  img.fill(image, color: img.ColorRgb8(r, g, b));
  return Uint8List.fromList(img.encodeJpg(image));
}

class _FakeFaceDetector implements LensFaceDetector {
  _FakeFaceDetector(
    this._faces, {
    this.throwOnDetect = false,
    this.holdUntil,
  });

  final List<LensFaceRect> _faces;
  final bool throwOnDetect;
  final Completer<void>? holdUntil;

  @override
  Future<List<LensFaceRect>> detectFacesInJpeg(Uint8List jpegBytes) async {
    if (holdUntil != null) {
      await holdUntil!.future;
    }
    if (throwOnDetect) throw StateError('detector_failed');
    return _faces;
  }
}

class _RecordingUploader implements LensVillageClipUploader {
  LensClipUploadPayload? lastPayload;
  int uploadCalls = 0;

  @override
  Future<LensVillageClipUploadResult> upload(LensClipUploadPayload payload) async {
    uploadCalls++;
    lastPayload = payload;
    return const LensVillageClipUploadResult(clipId: 'clip-test-1');
  }
}

void main() {
  group('blurFacesInJpeg', () {
    test('blurs region when faces detected', () async {
      final original = _solidJpeg(120, 80);
      final detector = _FakeFaceDetector([
        const LensFaceRect(left: 40, top: 20, width: 30, height: 30),
      ]);
      final result = await blurFacesInJpeg(jpegBytes: original, detector: detector);
      expect(result.outcome, LensFaceBlurOutcome.blurred);
      expect(result.bytes, isNotNull);
      expect(result.bytes, isNot(equals(original)));
      expect(result.faceCount, 1);
    });

    test('passes through when no faces', () async {
      final original = _solidJpeg(64, 64);
      final result = await blurFacesInJpeg(
        jpegBytes: original,
        detector: _FakeFaceDetector(const []),
      );
      expect(result.outcome, LensFaceBlurOutcome.noFaces);
      expect(result.bytes, original);
    });

    test('fail-closed when detector throws', () async {
      final original = _solidJpeg(64, 64);
      final result = await blurFacesInJpeg(
        jpegBytes: original,
        detector: _FakeFaceDetector(const [], throwOnDetect: true),
      );
      expect(result.outcome, LensFaceBlurOutcome.detectionFailed);
      expect(result.bytes, isNull);
    });
  });

  group('LensClipService', () {
    test('uploads blurred bytes only after blur pass', () async {
      final original = _solidJpeg(100, 100);
      final uploader = _RecordingUploader();
      final service = LensClipService(
        faceDetector: _FakeFaceDetector([
          const LensFaceRect(left: 10, top: 10, width: 40, height: 40),
        ]),
        uploader: uploader,
      );
      final draft = LensClipDraft(
        sessionId: 'sess-1',
        sourceJpegBytes: original,
        phraseOverlay: 'Ẹ kú àárọ̀',
        languageCode: 'yo',
      );
      final privacy = lensPrivacyContextFromPrefs(ageCategory: 'adult');
      final result = await service.shareToVillage(
        LensClipShareRequest(draft: draft, privacy: privacy),
      );
      expect(result.phase, LensClipSharePhase.done);
      expect(uploader.uploadCalls, 1);
      expect(uploader.lastPayload!.facesBlurred, isTrue);
      expect(uploader.lastPayload!.jpegBytes, isNot(equals(original)));
      expect(uploader.lastPayload!.phraseOverlay, 'Ẹ kú àárọ̀');
    });

    test('blocks minor without guardian social consent', () async {
      final uploader = _RecordingUploader();
      final service = LensClipService(
        faceDetector: _FakeFaceDetector(const []),
        uploader: uploader,
      );
      final result = await service.shareToVillage(
        LensClipShareRequest(
          draft: LensClipDraft(
            sessionId: 's',
            sourceJpegBytes: _solidJpeg(32, 32),
            phraseOverlay: 'hello',
            languageCode: 'pcm',
          ),
          privacy: lensPrivacyContextFromPrefs(ageCategory: 'teen'),
        ),
      );
      expect(result.phase, LensClipSharePhase.blocked);
      expect(result.blockReason, LensClipShareBlockReason.minorVillageSharingBlocked);
      expect(uploader.uploadCalls, 0);
    });

    test('cancelled share never uploads', () async {
      final hold = Completer<void>();
      final uploader = _RecordingUploader();
      final service = LensClipService(
        faceDetector: _FakeFaceDetector(const [], holdUntil: hold),
        uploader: uploader,
      );
      final resultFuture = service.shareToVillage(
        LensClipShareRequest(
          draft: LensClipDraft(
            sessionId: 's',
            sourceJpegBytes: _solidJpeg(32, 32),
            phraseOverlay: 'x',
            languageCode: 'sw',
          ),
          privacy: lensPrivacyContextFromPrefs(ageCategory: 'adult'),
        ),
      );
      service.cancelShare();
      hold.complete();
      final result = await resultFuture;
      expect(result.phase, LensClipSharePhase.cancelled);
      expect(uploader.uploadCalls, 0);
    });

    test('face detection failure blocks upload', () async {
      final uploader = _RecordingUploader();
      final service = LensClipService(
        faceDetector: _FakeFaceDetector(const [], throwOnDetect: true),
        uploader: uploader,
      );
      final result = await service.shareToVillage(
        LensClipShareRequest(
          draft: LensClipDraft(
            sessionId: 's',
            sourceJpegBytes: _solidJpeg(48, 48),
            phraseOverlay: 'x',
            languageCode: 'ig',
          ),
          privacy: lensPrivacyContextFromPrefs(ageCategory: 'adult'),
        ),
      );
      expect(result.blockReason, LensClipShareBlockReason.faceDetectionFailed);
      expect(uploader.uploadCalls, 0);
    });
  });
}
