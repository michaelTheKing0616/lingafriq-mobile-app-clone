import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/services/chat/wa_private_chat_service.dart';
import 'package:lingafriq/widgets/chat/voice_note_recorder.dart';

void main() {
  group('WaReadReceiptPolicy', () {
    test('shows read receipts only for mutual 1:1 contacts', () {
      expect(
        WaReadReceiptPolicy.showReadReceipts(
          isDirectMessage: true,
          isMutualContact: true,
        ),
        isTrue,
      );
      expect(
        WaReadReceiptPolicy.showReadReceipts(
          isDirectMessage: true,
          isMutualContact: false,
        ),
        isFalse,
      );
      expect(
        WaReadReceiptPolicy.showReadReceipts(
          isDirectMessage: false,
          isMutualContact: true,
        ),
        isFalse,
      );
    });
  });

  group('VoiceNoteGestureLogic', () {
    test('cancel when slide passes threshold', () {
      expect(
        VoiceNoteGestureLogic.shouldCancelOnRelease(
          totalSlideX: -80,
          cancellingFlag: false,
        ),
        isTrue,
      );
    });

    test('lock when slide up passes threshold', () {
      expect(
        VoiceNoteGestureLogic.shouldLock(
          totalSlideY: -60,
          alreadyLocked: false,
        ),
        isTrue,
      );
    });
  });
}
