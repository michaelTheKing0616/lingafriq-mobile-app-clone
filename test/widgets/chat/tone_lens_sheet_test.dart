import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/services/chat/chat_room_learning_service.dart';
import 'package:lingafriq/services/chat/on_device_overlay_service.dart';
import 'package:lingafriq/services/lexicon_lookup_service.dart';
import 'package:lingafriq/services/offline/lexicon_pack_service.dart';
import 'package:lingafriq/widgets/chat/tone_lens_sheet.dart';

Future<LexiconPackService> _packWithToneEntry() async {
  final pack = LexiconPackService();
  final entry = LexiconPackEntry(
    lexemeId: 'yo-tone-1',
    lemma: 'ọkọ́',
    standard: 'ọkọ́',
    adjustedRank: 1,
    audioUris: const [],
    verificationStatus: 'expert_reviewed',
  );
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

void main() {
  testWidgets('ToneLensSheet shows unsure when tone pattern missing', (tester) async {
    final pack = await _packWithToneEntry();
    final overlay = OnDeviceOverlayService(
      languageCode: 'yo',
      packService: pack,
      policyFetch: () async => ChatOverlaySurfacePolicy.available,
    );
    final service = ChatRoomLearningService(
      languageCode: 'yo',
      learnerUserId: 'u1',
      overlay: overlay,
      policyFetch: () async => ChatLearningSurfacePolicy.available,
    );

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(390, 844),
        builder: (_, __) => MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: Center(
                  child: FilledButton(
                    onPressed: () {
                      showToneLensSheet(
                        context: context,
                        service: service,
                        messageId: 'm1',
                        word: 'ọkọ́',
                      );
                    },
                    child: const Text('Open'),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text(ToneLensSheetCopy.title), findsOneWidget);
    expect(find.text(ToneLensSheetCopy.unsure), findsOneWidget);
    expect(find.text(ToneLensSheetCopy.save), findsOneWidget);
  });
}
