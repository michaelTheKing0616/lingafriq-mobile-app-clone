import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/widgets/chat/voice_note_transcript.dart';

void main() {
  testWidgets('shows machine transcript with uncertain hint', (tester) async {
    final controller = VoiceNoteTranscriptController(
      messageId: 'm1',
      languageCode: 'yo',
      e2ee: false,
      localAudioPath: '/tmp/voice.m4a',
      policyFetch: () async => VoiceNoteTranscriptPhase.idle,
      serverTranscribe: ({
        required messageId,
        required languageCode,
        required localAudioPath,
        required e2ee,
        required serverAssistConsent,
      }) async {
        return const VoiceNoteTranscriptPayload(
          transcript: 'bawo ni',
          lowConfidence: true,
          tokens: [
            VoiceNoteTranscriptToken(
              surface: 'bawo',
              glossEn: 'hello',
              uncertain: true,
            ),
            VoiceNoteTranscriptToken(
              surface: 'ni',
              uncertain: true,
            ),
          ],
        );
      },
    );

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(390, 844),
        builder: (_, __) => MaterialApp(
          home: Scaffold(
            body: VoiceNoteTranscriptPanel(controller: controller),
          ),
        ),
      ),
    );

    await tester.tap(find.text(VoiceNoteTranscriptCopy.transcribeAction));
    await tester.pumpAndSettle();

    expect(find.text(VoiceNoteTranscriptCopy.machineLabel), findsOneWidget);
    expect(find.text(VoiceNoteTranscriptCopy.uncertainHint), findsOneWidget);
    expect(find.text('hello'), findsOneWidget);
  });

  testWidgets('hidden for minor policy', (tester) async {
    final controller = VoiceNoteTranscriptController(
      messageId: 'm1',
      languageCode: 'yo',
      policyFetch: () async => VoiceNoteTranscriptPhase.hidden,
    );

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(390, 844),
        builder: (_, __) => MaterialApp(
          home: Scaffold(
            body: VoiceNoteTranscriptPanel(controller: controller),
          ),
        ),
      ),
    );

    await controller.prepareVisibility();
    await tester.pump();

    expect(find.text(VoiceNoteTranscriptCopy.transcribeAction), findsNothing);
  });
}
