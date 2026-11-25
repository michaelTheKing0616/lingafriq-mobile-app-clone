import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/avatars/contract/character_vm.dart';
import 'package:lingafriq/avatars/director/avatar_director.dart';

void main() {
  group('characterVmForLearningEvent', () {
    test('graded correct → encouraging proud', () {
      final vm = characterVmForLearningEvent(
        AvatarLearningEvent.answerGraded,
        correct: true,
      );
      expect(vm.activity, CharacterVmActivity.encouraging);
      expect(vm.expression, CharacterVmExpression.proud);
    });

    test('mic open → listening curious', () {
      final vm = characterVmForLearningEvent(AvatarLearningEvent.micOpen);
      expect(vm.activity, CharacterVmActivity.listening);
      expect(vm.expression, CharacterVmExpression.curious);
    });

    test('lesson complete → celebrating proud', () {
      final vm = characterVmForLearningEvent(AvatarLearningEvent.lessonComplete);
      expect(vm.activity, CharacterVmActivity.celebrating);
      expect(vm.expression, CharacterVmExpression.proud);
      expect(vm.intensity, 1);
    });
  });

  test('lib/screens do not import package:rive directly', () {
    final screens = Directory('lib/screens');
    final offenders = <String>[];
    for (final entity in screens.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final text = entity.readAsStringSync();
      if (text.contains("import 'package:rive/rive.dart'") ||
          text.contains('import "package:rive/rive.dart"')) {
        offenders.add(entity.path);
      }
    }
    expect(offenders, isEmpty, reason: offenders.join(', '));
  });
}
