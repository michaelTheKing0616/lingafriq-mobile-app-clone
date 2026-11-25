import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/services/lens/on_device_object_classifier.dart';

class _FakeEngine implements PointSayInferenceEngine {
  _FakeEngine(this._logits);

  final List<double> _logits;

  @override
  void run(
    List<List<List<List<double>>>> input,
    List<List<double>> output,
  ) {
    expect(input.length, 1);
    expect(input.first.length, 224);
    output[0] = List<double>.from(_logits);
  }

  @override
  void close() {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final registerPath = File(
    'curriculum/sources/licence_register.json',
  );

  Float32List blankFrame() => Float32List(224 * 224 * 3);

  OnDeviceObjectClassifier buildClassifier({
    required List<double> logits,
    PointSayLatencyRecorder? latency,
  }) {
    return OnDeviceObjectClassifier(
      latencyRecorder: latency,
      loadAsset: (_) async => ByteData(4),
      engineFactory: (_) => _FakeEngine(logits),
    );
  }

  group('PointSayModelLicence', () {
    test('matches licence register row for mobilenetv4_conv_small', () {
      expect(registerPath.existsSync(), isTrue);
      final rows = jsonDecode(registerPath.readAsStringSync()) as List<dynamic>;
      final row = rows.cast<Map<String, dynamic>>().firstWhere(
        (r) => r['id'] == PointSayModelLicence.registerId,
      );
      expect(row['licence'], PointSayModelLicence.licence);
      expect(row['url'], contains(PointSayModelLicence.sourceRevision));
      expect(row['url'], contains('model.safetensors'));
    });
  });

  group('OnDeviceObjectClassifier', () {
    test('returns top-3 labels with scores and skips ML Kit scene buckets', () async {
      final logits = List<double>.filled(1000, -10.0);
      logits[0] = 4.0; // tench
      logits[1] = 3.0; // goldfish
      logits[2] = 2.0; // great white shark

      final classifier = buildClassifier(logits: logits);
      final results = await classifier.classifyFrame(blankFrame());

      expect(results, hasLength(3));
      expect(results[0].label, 'tench');
      expect(results[1].label, 'goldfish');
      expect(results[2].label, 'great white shark');
      expect(results.every((r) => r.score > 0 && r.score < 1), isTrue);
      for (final r in results) {
        expect(mlKitSceneCategoryLabels.contains(r.label), isFalse);
      }
      await classifier.close();
    });

    test('offline contract never touches network', () async {
      final logits = List<double>.filled(1000, 0.0);
      logits[10] = 5.0;
      final classifier = buildClassifier(logits: logits);
      await classifier.classifyFrame(blankFrame());
      expect(classifier.isLoaded, isTrue);
      await classifier.close();
    });

    test('rejects wrong frame size', () async {
      final classifier = buildClassifier(logits: List.filled(1000, 0.0));
      expect(
        () => classifier.classifyFrame(Float32List(10)),
        throwsArgumentError,
      );
      await classifier.close();
    });
  });

  group('PointSayLatencyRecorder', () {
    test('fails bar when p50 above 150 ms', () {
      final recorder = PointSayLatencyRecorder();
      recorder.record(200);
      recorder.record(180);
      recorder.record(160);
      expect(recorder.p50Ms(), 180);
      expect(recorder.meetsLatencyBar(), isFalse);
    });

    test('passes bar when p50 at or below 150 ms', () {
      final recorder = PointSayLatencyRecorder();
      recorder.record(120);
      recorder.record(140);
      recorder.record(150);
      expect(recorder.meetsLatencyBar(), isTrue);
    });
  });

  group('PointAndSayScreen route', () {
    test('bundled model asset path is stable', () {
      expect(
        PointSayModelLicence.bundledAsset,
        'assets/models/point_say_mobilenetv4.tflite',
      );
    });
  });
}
