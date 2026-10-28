import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/screens/guardian/guardian_link_screen.dart';
import 'package:lingafriq/services/guardian_link_service.dart';

Widget _wrap(Widget child) {
  return ScreenUtilInit(
    designSize: const Size(390, 844),
    builder: (_, __) => ProviderScope(child: MaterialApp(home: child)),
  );
}

Finder _hubScrollable() {
  return find.descendant(
    of: find.byType(RefreshIndicator),
    matching: find.byType(Scrollable),
  );
}

class _FakeGuardianService extends GuardianLinkService {
  _FakeGuardianService({required this.hubLinks});

  final List<GuardianHubLink> hubLinks;

  @override
  Future<List<GuardianHubLink>> fetchHubLinks() async => hubLinks;

  @override
  Future<void> flushPending() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('empty hub shows honest empty state (AC5)', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      _wrap(
        GuardianLinkScreen(
          guardianLinkService: _FakeGuardianService(hubLinks: []),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text(GuardianLinkScreen.guardianHubEmptyTitle),
      400,
      scrollable: _hubScrollable(),
    );
    expect(find.text(GuardianLinkScreen.guardianHubEmptyTitle), findsOneWidget);
    expect(find.textContaining('invite code'), findsWidgets);
  });

  testWidgets('linked learner tile is tappable with semantics', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      _wrap(
        GuardianLinkScreen(
          guardianLinkService: _FakeGuardianService(
            hubLinks: [
              GuardianHubLink(childUserId: 100, status: 'verifying', regime: 'NDPA_2023'),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Learner #100'),
      400,
      scrollable: _hubScrollable(),
    );
    expect(find.text('Learner #100'), findsOneWidget);
    expect(find.bySemanticsLabel('Learner 100, Needs your consent'), findsOneWidget);
  });
}
