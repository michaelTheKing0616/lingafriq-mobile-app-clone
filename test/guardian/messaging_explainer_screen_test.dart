import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/screens/guardian/messaging_explainer_screen.dart';
import 'package:lingafriq/services/guardian_link_service.dart';

Widget _wrap(Widget child) {
  return ScreenUtilInit(
    designSize: const Size(390, 844),
    builder: (_, __) => ProviderScope(child: MaterialApp(home: child)),
  );
}

class _FakeExplainerService extends GuardianMessagingExplainerService {
  _FakeExplainerService(this.payload, {this.throwsOffline = false});

  final GuardianMessagingExplainer payload;
  final bool throwsOffline;

  @override
  Future<GuardianMessagingExplainer> fetchExplainer() async {
    if (throwsOffline) {
      throw const GuardianOfflineException();
    }
    return payload;
  }
}

void main() {
  testWidgets('shows explainer copy from service', (tester) async {
    await tester.pumpWidget(
      _wrap(
        GuardianMessagingExplainerScreen(
          explainerService: _FakeExplainerService(
            GuardianMessagingExplainer(
              title: 'Test title',
              body: 'Test body about moderation.',
              moderatorsSee: const ['Line one'],
              e2eeTradeoff: 'Tradeoff copy.',
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Test body about moderation.'), findsOneWidget);
    expect(find.text('Line one'), findsOneWidget);
    expect(find.text('Tradeoff copy.'), findsOneWidget);
  });

  testWidgets('hub tile opens explainer screen', (tester) async {
    final fake = _FakeExplainerService(
      GuardianMessagingExplainer(
        title: 'T',
        body: 'B',
        moderatorsSee: const [],
        e2eeTradeoff: 'E',
      ),
    );
    await tester.pumpWidget(
      _wrap(
        Scaffold(
          body: ListView(
            children: [GuardianMessagingExplainerHubTile(explainerService: fake)],
          ),
        ),
      ),
    );
    await tester.tap(find.text(GuardianMessagingExplainerHubTile.tileTitle));
    await tester.pumpAndSettle();
    expect(find.text('B'), findsOneWidget);
  });
}
