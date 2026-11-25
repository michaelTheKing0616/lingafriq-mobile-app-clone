import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/services/chat/on_device_overlay_service.dart';
import 'package:lingafriq/services/lexicon_lookup_service.dart';
import 'package:lingafriq/services/offline/lexicon_pack_service.dart';
import 'package:lingafriq/widgets/chat/server_assist_consent_sheet.dart';

Future<LexiconPackService> _packWithEntry(LexiconPackEntry entry) async {
  final pack = LexiconPackService();
  final manifest = LexiconPackManifest(
    language: 'yo',
    version: '1.0.0',
    entryCount: 1,
    entriesSha256: lexiconPackEntriesDigest([entry]),
    audioBytesEstimate: 0,
  );
  await pack.installVerifiedPack(manifest: manifest, entries: [entry]);
  return pack;
}

Widget _app(Widget child) {
  return ScreenUtilInit(
    designSize: const Size(390, 844),
    builder: (_, __) => MaterialApp(home: Scaffold(body: child)),
  );
}

void main() {
  test('P9-940 E2EE gloss uses offline lookup only', () async {
    final entry = LexiconPackEntry(
      lexemeId: 'yo-001',
      lemma: 'ọkọ',
      standard: 'ọkọ',
      adjustedRank: 1,
      audioUris: const [],
      verificationStatus: 'expert_reviewed',
    );
    final pack = await _packWithEntry(entry);
    final service = OnDeviceOverlayService(
      languageCode: 'yo',
      packService: pack,
    );

    final result = await service.glossWord(
      messageId: 'm1',
      word: 'ọkọ',
      e2ee: true,
    );

    expect(result.networkCallsAttempted, 0);
    expect(result.lookup.kind, LexiconLookupKind.hit);
    expect(result.lookup.usedOfflinePack, isTrue);
  });

  test('P9-940 tone lens derives contour from pack lexeme without network', () async {
    final entry = LexiconPackEntry(
      lexemeId: 'yo-002',
      lemma: 'ọkọ́',
      standard: 'ọkọ́',
      adjustedRank: 2,
      audioUris: const [],
      verificationStatus: 'expert_reviewed',
    );
    final pack = await _packWithEntry(entry);
    final service = OnDeviceOverlayService(
      languageCode: 'yo',
      packService: pack,
    );

    final tone = await service.toneLensForWord(
      messageId: 'm2',
      word: 'ọkọ́',
      e2ee: true,
    );

    expect(tone.networkCallsAttempted, 0);
    expect(tone.lexemeLemma, 'ọkọ́');
  });

  testWidgets('P9-940 consent sheet allow-once triggers single server invoke', (tester) async {
    var networkCalls = 0;
    ServerAssistRequest? captured;
    final service = OnDeviceOverlayService(
      languageCode: 'yo',
      policyFetch: () async => ChatOverlaySurfacePolicy.available,
      serverAssistInvoke: (req) async {
        networkCalls++;
        captured = req;
      },
    );

    late ServerAssistOutcome outcome;
    await tester.pumpWidget(
      _app(
        Builder(
          builder: (context) {
            return FilledButton(
              onPressed: () async {
                outcome = await service.requestServerAssist(
                  context: context,
                  request: const ServerAssistRequest(
                    messageId: 'cipher-1',
                    messagePlaintext: 'Ẹ kú àárọ̀',
                    feature: ServerAssistFeature.aiGloss,
                    languageCode: 'yo',
                    e2ee: true,
                  ),
                );
              },
              child: const Text('assist'),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('assist'));
    await tester.pumpAndSettle();
    expect(find.text(ServerAssistConsentCopy.title), findsOneWidget);
    await tester.tap(find.text(ServerAssistConsentCopy.allowOnceLabel));
    await tester.pumpAndSettle();

    expect(outcome, ServerAssistOutcome.completed);
    expect(networkCalls, 1);
    expect(captured?.messagePlaintext, 'Ẹ kú àárọ̀');
    expect(service.consentedMessageKeys, contains('cipher-1:aiGloss'));
  });

  testWidgets('P9-940 decline sends no message text to server', (tester) async {
    var networkCalls = 0;
    final service = OnDeviceOverlayService(
      languageCode: 'yo',
      policyFetch: () async => ChatOverlaySurfacePolicy.available,
      serverAssistInvoke: (_) async {
        networkCalls++;
      },
    );

    late ServerAssistOutcome outcome;
    await tester.pumpWidget(
      _app(
        Builder(
          builder: (context) {
            return FilledButton(
              onPressed: () async {
                outcome = await service.requestServerAssist(
                  context: context,
                  request: const ServerAssistRequest(
                    messageId: 'cipher-2',
                    messagePlaintext: 'Bawo ni',
                    feature: ServerAssistFeature.aiToneExplain,
                    languageCode: 'yo',
                  ),
                );
              },
              child: const Text('assist'),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('assist'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text(ServerAssistConsentCopy.declineLabel));
    await tester.tap(find.text(ServerAssistConsentCopy.declineLabel));
    await tester.pumpAndSettle();

    expect(outcome, ServerAssistOutcome.declined);
    expect(networkCalls, 0);
  });

  test('P9-940 guardian policy blocks server assist without invoke', () async {
    var networkCalls = 0;
    final service = OnDeviceOverlayService(
      languageCode: 'yo',
      policyFetch: () async => ChatOverlaySurfacePolicy.guardianGated,
      serverAssistInvoke: (_) async {
        networkCalls++;
      },
    );

    final outcome = await service.requestServerAssist(
      context: _MinimalContext(),
      request: const ServerAssistRequest(
        messageId: 'm-minor',
        messagePlaintext: 'hello',
        feature: ServerAssistFeature.aiGloss,
        languageCode: 'yo',
      ),
    );

    expect(outcome, ServerAssistOutcome.guardianGated);
    expect(networkCalls, 0);
  });
}

class _MinimalContext extends Fake implements BuildContext {}
