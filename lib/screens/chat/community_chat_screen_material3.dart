import 'package:flutter/material.dart';
import 'community_chat_screen.dart';

/// Material 3 Community Chat Screen (wrapper/alias)
/// Uses the existing community_chat_screen.dart which already has Material 3 design
class CommunityChatScreenMaterial3 extends StatelessWidget {
  final String villageId;
  final String villageName;

  const CommunityChatScreenMaterial3({
    Key? key,
    required this.villageId,
    required this.villageName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CommunityChatScreen(
      villageId: villageId,
      villageName: villageName,
    );
  }
}

