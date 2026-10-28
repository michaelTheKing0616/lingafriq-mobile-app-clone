import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/features/polie_workspace/polie_workspace.dart';
import 'package:lingafriq/providers/ai_chat_provider_groq.dart';

const _featureRoot = 'lib/features/polie_workspace';
const _maxLinesPerFile = 500;

void main() {
  test('P12-005: top-level module files <= $_maxLinesPerFile lines', () {
    for (final entity in Directory(_featureRoot).listSync()) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      if (entity.path.endsWith('polie_workspace.dart')) continue;
      final count = entity.readAsLinesSync().length;
      expect(count, lessThanOrEqualTo(_maxLinesPerFile), reason: entity.path);
    }
  });

  test('P12-005: import boundary — parts do not import provider internals', () {
    void checkDir(Directory dir) {
      for (final entity in dir.listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        if (entity.path.endsWith('polie_workspace_providers.dart')) continue;
        if (entity.path.endsWith('polie_workspace.dart')) continue;
        final src = entity.readAsStringSync();
        expect(src.contains("import 'package:lingafriq/providers/"), isFalse,
            reason: entity.path);
      }
    }

    checkDir(Directory(_featureRoot));
    final host = File(
      '$_featureRoot/build_host/polie_workspace_build_host_impl.dart',
    ).readAsStringSync();
    expect(host.contains('ai_gateway_client.dart'), isTrue);
    expect(host.contains('polie_workspace_providers.dart'), isTrue);
  });

  test('P12-005: workspace library compiles (smoke ctor)', () {
    expect(
      PolieWorkspaceScreen(
        sourceLanguage: 'English',
        targetLanguage: 'Yoruba',
        initialMode: PolieMode.translation,
      ),
      isA<PolieWorkspaceScreen>(),
    );
  });

  test('P12-005: public barrel exports PolieWorkspaceScreen', () {
    final barrel = File('$_featureRoot/polie_workspace.dart').readAsStringSync();
    expect(barrel.contains('PolieWorkspaceScreen'), isTrue);
    final shim =
        File('lib/screens/ai_chat/polie_workspace_screen.dart').readAsStringSync();
    expect(shim.contains('features/polie_workspace'), isTrue);
  });
}
