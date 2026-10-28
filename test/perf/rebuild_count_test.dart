import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/models/user_gamification_model.dart';
import 'package:lingafriq/providers/gamification_state.dart';

class _RebuildCounter extends StatefulWidget {
  const _RebuildCounter({required this.child});
  final Widget child;
  static int count = 0;
  @override
  State<_RebuildCounter> createState() => _RebuildCounterState();
}

class _RebuildCounterState extends State<_RebuildCounter> {
  @override
  Widget build(BuildContext context) {
    _RebuildCounter.count++;
    return widget.child;
  }
}

class _TestGamificationNotifier extends Notifier<GamificationState> {
  @override
  GamificationState build() => GamificationState();
}

final _testGamificationProvider =
    NotifierProvider<_TestGamificationNotifier, GamificationState>(
  _TestGamificationNotifier.new,
);

final _testCowriesSlice = Provider<int>(
  (ref) => ref.watch(
    _testGamificationProvider.select((s) => s.gamification.cowries),
  ),
);

final _testStreakSlice = Provider<int>(
  (ref) => ref.watch(
    _testGamificationProvider.select((s) => s.gamification.dailyStreak),
  ),
);

void main() {
  setUp(() {
    _RebuildCounter.count = 0;
  });

  test('P12-011 AC2: production slice providers use select on large providers', () {
    final src = File('lib/providers/rebuild_slice_providers.dart').readAsStringSync();
    expect(src.contains('.select('), isTrue);
    expect(src, contains('gamificationCowriesProvider'));
    expect(src, contains('heartsCountProvider'));
    expect(src, contains('apiLoadingProvider'));
  });

  testWidgets('P12-011 AC1: cowries slice ignores dailyStreak updates', (tester) async {
    final container = ProviderContainer();
    container.read(_testGamificationProvider.notifier).state = GamificationState(
      gamification: UserGamificationModel(cowries: 10, dailyStreak: 1),
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Consumer(
            builder: (context, ref, _) {
              ref.watch(_testCowriesSlice);
              return const _RebuildCounter(child: SizedBox());
            },
          ),
        ),
      ),
    );
    await tester.pump();
    final afterMount = _RebuildCounter.count;

    final prior = container.read(_testGamificationProvider);
    container.read(_testGamificationProvider.notifier).state = prior.copyWith(
      gamification: prior.gamification.copyWith(dailyStreak: 99),
    );
    await tester.pump();
    expect(_RebuildCounter.count, afterMount);
    container.dispose();
  });

  testWidgets('P12-011 AC1: streak slice rebuilds when dailyStreak changes', (tester) async {
    final container = ProviderContainer();
    container.read(_testGamificationProvider.notifier).state = GamificationState(
      gamification: UserGamificationModel(cowries: 10, dailyStreak: 1),
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Consumer(
            builder: (context, ref, _) {
              ref.watch(_testStreakSlice);
              return const _RebuildCounter(child: SizedBox());
            },
          ),
        ),
      ),
    );
    await tester.pump();
    final afterMount = _RebuildCounter.count;

    final prior = container.read(_testGamificationProvider);
    container.read(_testGamificationProvider.notifier).state = prior.copyWith(
      gamification: prior.gamification.copyWith(dailyStreak: 5),
    );
    await tester.pump();
    expect(_RebuildCounter.count, greaterThan(afterMount));
    container.dispose();
  });
}
