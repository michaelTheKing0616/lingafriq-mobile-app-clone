import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final repo = Directory.current;
  final gate = repo.uri.resolve('scripts/avatars/check_layer_isolation.py');

  test('P11-038 layer isolation gate passes on lingafriq_cast.riv', () async {
    final proc = await Process.run(
      'python3',
      [gate.toFilePath(), '--gate'],
      workingDirectory: repo.path,
    );
    expect(
      proc.exitCode,
      0,
      reason: '${proc.stdout}\n${proc.stderr}',
    );
  });

  test('P11-038 script lists keyed properties per L1–L5 layer', () async {
    final proc = await Process.run(
      'python3',
      [gate.toFilePath(), '--list', '--json'],
      workingDirectory: repo.path,
    );
    expect(proc.exitCode, 0, reason: proc.stderr.toString());
    final decoded = jsonDecode(proc.stdout as String) as Map<String, dynamic>;
    const layers = [
      'L1 Body',
      'L2 Face',
      'L3 Gaze/Head',
      'L4 Blink',
      'L5 Mouth',
    ];
    for (final layer in layers) {
      expect(decoded.containsKey(layer), isTrue);
      final keys = decoded[layer] as List<dynamic>;
      expect(keys, isNotEmpty, reason: '$layer should list keyed properties');
    }
  });

  test('P11-038 detects keyed-property overlap between layers', () async {
    final proc = await Process.run(
      'python3',
      [gate.toFilePath(), '--self-test'],
      workingDirectory: repo.path,
    );
    expect(proc.exitCode, 0, reason: proc.stderr.toString());
  });
}
