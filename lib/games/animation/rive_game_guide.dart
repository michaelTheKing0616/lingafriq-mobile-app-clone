import 'package:flutter/material.dart';

import '../../avatars/cast/cast_stage.dart';
import '../../avatars/director/avatar_director.dart';
import '../../avatars/personality_system.dart';

/// Game guide. The cast file is the only character; legacy SMI inputs are gone.
class RiveGameGuideController {
  final AvatarController avatar = AvatarController(
    type: AvatarType.polie,
    personality: PersonalitySystem().getPersonality('polie')!,
  );

  void setListening(bool listening) {
    if (listening) {
      avatar.startListening();
    } else {
      avatar.stopListening();
    }
  }

  void setSpeaking(bool speaking) {
    if (speaking) {
      avatar.startSpeaking();
    } else {
      avatar.stopSpeaking();
    }
  }

  void setConfidence(double confidence) => avatar.setConfidence(confidence);

  void setEmotion(GuideEmotion emotion) => avatar.setEmotion(_emotion(emotion));

  void celebrate() => avatar.celebrate();

  void fail() {
    avatar.session.fire('incorrect');
    avatar.setEmotion(AvatarEmotion.disappointed);
  }
}

enum GuideEmotion { idle, thinking, encouraging, proud, disappointed, happy }

AvatarEmotion _emotion(GuideEmotion emotion) {
  switch (emotion) {
    case GuideEmotion.idle:
      return AvatarEmotion.idle;
    case GuideEmotion.thinking:
      return AvatarEmotion.thinking;
    case GuideEmotion.encouraging:
      return AvatarEmotion.encouraging;
    case GuideEmotion.proud:
      return AvatarEmotion.proud;
    case GuideEmotion.disappointed:
      return AvatarEmotion.disappointed;
    case GuideEmotion.happy:
      return AvatarEmotion.happy;
  }
}

class RiveGameGuide extends StatelessWidget {
  const RiveGameGuide({
    super.key,
    required this.controller,
    this.width,
    this.height,
  });

  final RiveGameGuideController controller;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? 100,
      height: height ?? 100,
      child: CastStage(session: controller.avatar.session),
    );
  }
}
