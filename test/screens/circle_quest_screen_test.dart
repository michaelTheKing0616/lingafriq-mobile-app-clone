import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/providers/base_provider.dart';
import 'package:lingafriq/providers/gamification_provider.dart';
import 'package:lingafriq/screens/village/circle_quest_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _QuestGamification extends GamificationProvider {
  @override
  BaseProviderState build() => BaseProviderState();

  @override
  CircleQuestSnapshot? get circleQuest => const CircleQuestSnapshot(
        empty: true,
        goalXp: 0,
        progressXp: 0,
        members: [],
      );

  @override
  FamilyPhraseSnapshot? get familyPhrase => const FamilyPhraseSnapshot(empty: true);

  @override
  Future<void> refreshCircleQuest(String groupId) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('quest_progress_golden empty circle quest', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    await ScreenUtil.ensureScreenSize();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          gamificationProvider.overrideWith(() => _QuestGamification()),
        ],
        child: ScreenUtilInit(
          designSize: const Size(390, 844),
          builder: (_, __) => const MaterialApp(
            home: CircleQuestScreen(groupId: 'demo-circle'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Circle quest'), findsOneWidget);
    expect(find.textContaining('learning goal'), findsOneWidget);
  });
}
