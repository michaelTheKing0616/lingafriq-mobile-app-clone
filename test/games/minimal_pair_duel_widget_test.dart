import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/games/minimal_pair_duel/minimal_pair_duel_game.dart';

void main() {
  testWidgets('minimal pair duel picture tiles meet tap target height', (tester) async {
    const options = [
      MinimalPairDuelOption(
        id: 'a',
        form: 'ọkọ́',
        glossEn: 'hoe',
        audioUri: 'audio/a.ogg',
        imageUri: 'images/a.png',
      ),
      MinimalPairDuelOption(
        id: 'b',
        form: 'ọkọ̀',
        glossEn: 'vehicle',
        audioUri: 'audio/b.ogg',
        imageUri: 'images/b.png',
      ),
    ];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListView(
            children: options
                .map(
                  (opt) => Semantics(
                    button: true,
                    label: '${opt.form}, ${opt.glossEn}',
                    child: SizedBox(
                      height: 48,
                      child: ListTile(
                        title: Text(opt.glossEn),
                        subtitle: Text(opt.form),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
    expect(find.text('hoe'), findsOneWidget);
    expect(find.text('vehicle'), findsOneWidget);
  });
}
