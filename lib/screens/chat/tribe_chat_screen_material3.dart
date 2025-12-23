import 'package:flutter/material.dart';
import 'package:lingafriq/screens/chat/tribe_chat_screen.dart';

/// Material 3 Tribe Chat Screen (wrapper/alias)
/// Uses the existing tribe_chat_screen.dart which already has Material 3 design
class TribeChatScreenMaterial3 extends StatelessWidget {
  final String tribeId;
  final String tribeName;

  const TribeChatScreenMaterial3({
    Key? key,
    required this.tribeId,
    required this.tribeName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TribeChatScreen(
      tribeId: tribeId,
      tribeName: tribeName,
    );
  }
}

