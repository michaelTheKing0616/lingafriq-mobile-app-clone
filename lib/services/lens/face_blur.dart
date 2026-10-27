/// On-device face blur before any Lens Clip leaves the device (P7-911).
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;

/// Normalised face bounds in image pixel coordinates.
class LensFaceRect {
  const LensFaceRect({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });

  final int left;
  final int top;
  final int width;
  final int height;
}

enum LensFaceBlurOutcome {
  /// No faces detected — original bytes may be used.
  noFaces,
  /// Faces blurred successfully.
  blurred,
  /// Detector error — fail closed (no upload).
  detectionFailed,
  /// JPEG could not be decoded.
  decodeFailed,
}

class LensFaceBlurResult {
  const LensFaceBlurResult({
    required this.outcome,
    this.bytes,
    this.faceCount = 0,
  });

  final LensFaceBlurOutcome outcome;
  final Uint8List? bytes;
  final int faceCount;
}

/// Injectable for unit tests and ML Kit wiring.
abstract class LensFaceDetector {
  Future<List<LensFaceRect>> detectFacesInJpeg(Uint8List jpegBytes);
}

/// Applies a strong box blur inside each [faces] region (expanded padding).
Uint8List blurFacesInDecodedImage(img.Image decoded, List<LensFaceRect> faces) {
  final out = img.Image.from(decoded);
  for (final face in faces) {
    if (face.width <= 0 || face.height <= 0) continue;
    final padX = (face.width * 0.15).round();
    final padY = (face.height * 0.15).round();
    final x = (face.left - padX).clamp(0, out.width - 1);
    final y = (face.top - padY).clamp(0, out.height - 1);
    final w = (face.width + padX * 2).clamp(1, out.width - x);
    final h = (face.height + padY * 2).clamp(1, out.height - y);
    final patch = img.copyCrop(out, x: x, y: y, width: w, height: h);
    final blurred = img.gaussianBlur(patch, radius: 14);
    img.compositeImage(out, blurred, dstX: x, dstY: y);
  }
  return Uint8List.fromList(img.encodeJpg(out, quality: 92));
}

Future<LensFaceBlurResult> blurFacesInJpeg({
  required Uint8List jpegBytes,
  required LensFaceDetector detector,
}) async {
  img.Image? decoded;
  try {
    decoded = img.decodeImage(jpegBytes);
  } catch (_) {
    decoded = null;
  }
  if (decoded == null) {
    return const LensFaceBlurResult(outcome: LensFaceBlurOutcome.decodeFailed);
  }

  List<LensFaceRect> faces;
  try {
    faces = await detector.detectFacesInJpeg(jpegBytes);
  } catch (_) {
    return const LensFaceBlurResult(outcome: LensFaceBlurOutcome.detectionFailed);
  }

  if (faces.isEmpty) {
    return LensFaceBlurResult(
      outcome: LensFaceBlurOutcome.noFaces,
      bytes: jpegBytes,
      faceCount: 0,
    );
  }

  final blurred = blurFacesInDecodedImage(decoded, faces);
  return LensFaceBlurResult(
    outcome: LensFaceBlurOutcome.blurred,
    bytes: blurred,
    faceCount: faces.length,
  );
}

/// Google ML Kit face detector (on-device, commercial licence).
class MlKitLensFaceDetector implements LensFaceDetector {
  MlKitLensFaceDetector({FaceDetector? detector})
      : _detector = detector ??
            FaceDetector(
              options: FaceDetectorOptions(
                performanceMode: FaceDetectorMode.accurate,
                enableTracking: false,
              ),
            );

  final FaceDetector _detector;

  @override
  Future<List<LensFaceRect>> detectFacesInJpeg(Uint8List jpegBytes) async {
    final dir = await Directory.systemTemp.createTemp('lens_face_');
    final file = File('${dir.path}/frame.jpg');
    await file.writeAsBytes(jpegBytes, flush: true);
    try {
      final faces = await _detector.processImage(InputImage.fromFilePath(file.path));
      return faces
          .map(
            (f) => LensFaceRect(
              left: f.boundingBox.left.round(),
              top: f.boundingBox.top.round(),
              width: f.boundingBox.width.round(),
              height: f.boundingBox.height.round(),
            ),
          )
          .toList();
    } finally {
      try {
        await file.delete();
        await dir.delete();
      } catch (_) {}
    }
  }

  Future<void> dispose() => _detector.close();
}
