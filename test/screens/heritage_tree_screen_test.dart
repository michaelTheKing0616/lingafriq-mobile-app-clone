import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/providers/base_provider.dart';
import 'package:lingafriq/providers/gamification_provider.dart';
import 'package:lingafriq/screens/village/heritage_tree_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _TreeGamification extends GamificationProvider {
  @override
  BaseProviderState build() => BaseProviderState();

  @override
  HeritageTreeSnapshot? get heritageTree => const HeritageTreeSnapshot(
        canDoCount: 12,
        stage: 'sapling',
        members: [
          CircleQuestMemberLabel(slot: 'Circle learner 1', isViewer: true),
        ],
      );

  @override
  Future<void> refreshHeritageTree(String groupId) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('heritage_tree_title golden sapling stage', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    await ScreenUtil.ensureScreenSize();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          gamificationProvider.overrideWith(() => _TreeGamification()),
        ],
        child: ScreenUtilInit(
          designSize: const Size(390, 844),
          builder: (_, __) => const MaterialApp(
            home: HeritageTreeScreen(groupId: 'demo-circle'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Heritage Tree'), findsWidgets);
    expect(find.textContaining('12 verified can-dos'), findsOneWidget);
  });
}
