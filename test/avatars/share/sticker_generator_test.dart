import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/avatars/share/sticker_generator.dart';

void main() {
  test('AvatarStickerRequest maps reaction onto CastPose without extra art', () {
    const request = AvatarStickerRequest(
      preset: 'Polie',
      reaction: AvatarReactionSticker.wave,
    );
    final pose = request.toPose();
    expect(pose.preset, 'Polie');
    expect(pose.activity, 'idle');
    expect(pose.expression, 'happy');
    expect(pose.viseme, 'aa');
  });

  test('exportMetadataIsPiiFree rejects learner identifiers', () {
    expect(
      AvatarStickerGenerator.exportMetadataIsPiiFree({'reaction': 'wave'}),
      isTrue,
    );
    expect(
      AvatarStickerGenerator.exportMetadataIsPiiFree({
        'displayName': 'Ada',
      }),
      isFalse,
    );
    expect(
      AvatarStickerGenerator.exportMetadataIsPiiFree({
        'note': 'reach me@home.com',
      }),
      isFalse,
    );
  });
}
