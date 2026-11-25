import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/avatars/a11y/avatar_semantics.dart';
import 'package:lingafriq/avatars/cast/cast_contract.dart';
import 'package:lingafriq/avatars/cast/cast_file_cache.dart';
import 'package:lingafriq/avatars/cast/cast_session.dart';
import 'package:rive/rive.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('semantics label reads like Polie looks proud', () {
    expect(
      avatarSemanticsLabel(
        name: 'Polie',
        expression: 'proud',
        activity: 'idle',
      ),
      'Polie looks proud',
    );
    expect(
      castSemanticsLabel(
        name: 'Polie',
        expression: 'proud',
        activity: 'listening',
      ),
      'Polie looks proud and is listening',
    );
  });

  testWidgets('expression change updates semantics label once per value', (
    tester,
  ) async {
    final session = CastSession(preset: 'Polie');
    addTearDown(session.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => AvatarCastSemantics(
            session: session,
            child: const SizedBox(width: 48, height: 48, key: Key('avatar')),
          ),
        ),
      ),
    );
    await tester.pump();

    String? label() {
      final node = tester.getSemantics(find.byKey(const Key('avatar')));
      return node.label;
    }

    session.expression('proud');
    await tester.pump();
    final proudLabel = label();
    expect(proudLabel, 'Polie looks proud');

    session.expression('proud');
    await tester.pump();
    expect(label(), proudLabel);

    session.expression('happy');
    await tester.pump();
    expect(label(), 'Polie looks happy');
  });

  testWidgets('reducedMotion sets VM flag while controller stays active', (
    tester,
  ) async {
    await RiveNative.init();
    CastFileCache.instance.renderer = Factory.flutter;
    final session = CastSession(preset: 'Polie');
    addTearDown(session.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: AvatarCastSemantics(
              session: session,
              child: const SizedBox.shrink(),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(session.pose.reducedMotion, isTrue);

    final file = await CastFileCache.instance.load();
    final instance = file
        .viewModelByName('CharacterVM')!
        .createInstanceByName('Polie')!;
    session.bind(file, instance);
    expect(instance.boolean('reducedMotion')?.value, isTrue);
    instance.dispose();
  });
}
