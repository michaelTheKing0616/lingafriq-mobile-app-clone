import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/features/polie_workspace/polie_workspace_build_host.dart';
import 'package:lingafriq/features/polie_workspace/polie_workspace_providers.dart';
import 'package:lingafriq/screens/ai_chat/polie_workspace_shared.dart';

class PolieWorkspaceScreen extends HookConsumerWidget {
  final String sourceLanguage;
  final String targetLanguage;
  final PolieMode initialMode;
  final String? initialRoleplayScene;

  /// When true, only the free-form [PolieMode.conversation] surface is shown (no mode rail).
  final bool conversationOnly;

  const PolieWorkspaceScreen({
    super.key,
    required this.sourceLanguage,
    required this.targetLanguage,
    required this.initialMode,
    this.initialRoleplayScene,
    this.conversationOnly = false,
  });

  static const modeItems = <ModeChipItem>[
    ModeChipItem(mode: PolieMode.translation, icon: '⇄', label: 'Translation'),
    ModeChipItem(mode: PolieMode.tutor, icon: '📖', label: 'Tutor'),
    ModeChipItem(mode: PolieMode.roleplay, icon: '🎭', label: 'Roleplay'),
    ModeChipItem(mode: PolieMode.vocab, icon: '✦', label: 'Vocabulary'),
    ModeChipItem(mode: PolieMode.review, icon: '📊', label: 'Review'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PolieWorkspaceBuildHost(screen: this);
  }
}
