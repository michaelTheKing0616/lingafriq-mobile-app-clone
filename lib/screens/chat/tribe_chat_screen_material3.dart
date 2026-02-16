import 'package:flutter/material.dart';
import 'package:lingafriq/screens/chat/tribe_chat_screen.dart';

/// Material 3 Tribe Chat Screen (wrapper/alias)
/// Uses the existing tribe_chat_screen.dart which already has Material 3 design
class TribeChatScreenMaterial3 extends StatelessWidget {
  final String tribeId;
  final String tribeName;

  const TribeChatScreenMaterial3({
    super.key,
    required this.tribeId,
    required this.tribeName,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Tribe chat. Messages, tribe info and send button below.',
      child: TribeChatScreen(
        tribeId: tribeId,
        tribeName: tribeName,
      ),
    );
  }
}

