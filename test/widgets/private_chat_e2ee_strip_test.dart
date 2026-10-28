import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/services/chat/mls_session_service.dart';

void main() {
  testWidgets('encrypted strip shows lock copy', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            final cs = Theme.of(context).colorScheme;
            return Semantics(
              label: const MlsSessionSnapshot(
                uiState: MlsEncryptionUiState.encrypted,
                e2eeActive: true,
                requiresModeration: false,
              ).accessibilityLabel(MlsEncryptionUiState.encrypted),
              child: Material(
                color: cs.primaryContainer,
                child: SizedBox(
                  height: 48,
                  child: Row(
                    children: const [
                      Icon(Icons.lock_rounded),
                      Text(kE2eeOnLabel),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
    expect(find.text(kE2eeOnLabel), findsOneWidget);
    expect(find.byIcon(Icons.lock_rounded), findsOneWidget);
  });
}
