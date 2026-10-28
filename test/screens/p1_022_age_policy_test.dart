import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/providers/age_policy_provider.dart';
import 'package:lingafriq/screens/chat/chat_list_screen.dart';
import 'package:lingafriq/screens/home_screen.dart';

void main() {
  testWidgets('restricted teen sees explainer on ChatListScreen', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          agePolicyProvider.overrideWith(
            () => _FixedAgePolicy(
              const AgePolicyState(
                ageBand: 'teen',
                socialSurfacesBlocked: true,
              ),
            ),
          ),
        ],
        child: const MaterialApp(home: ChatListScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(AgeRestrictedSurfaceScreen.title), findsOneWidget);
    expect(find.text('Back to learning'), findsOneWidget);
  });

  testWidgets('adult sees learning CTA copy on restricted route shell', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          agePolicyProvider.overrideWith(
            () => _FixedAgePolicy(
              const AgePolicyState(
                ageBand: 'adult',
                socialSurfacesBlocked: false,
              ),
            ),
          ),
        ],
        child: MaterialApp(
          home: AgePolicyRouteShell(
            child: Scaffold(body: Text('social child')),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('social child'), findsOneWidget);
  });

  testWidgets('AgeRestrictedSurfaceScreen exposes heading semantics', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AgeRestrictedSurfaceScreen(showBack: true),
      ),
    );
    expect(find.text(AgeRestrictedSurfaceScreen.title), findsOneWidget);
  });
}

class _FixedAgePolicy extends AgePolicyNotifier {
  _FixedAgePolicy(this._state);

  final AgePolicyState _state;

  @override
  Future<AgePolicyState> build() async => _state;
}
