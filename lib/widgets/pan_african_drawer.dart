import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/features/global_chat/global_chat_policy.dart';
import 'package:lingafriq/navigation/feature_directory.dart';
import 'package:lingafriq/screens/tabs_view/all_features_screen.dart';

/// The drawer is the All features directory.
///
/// Global Chat stays off this list when the chat policy denies it. Hiding
/// that row does not remove it from the directory catalog.
class PanAfricanDrawer extends ConsumerWidget {
  const PanAfricanDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool chatVisible = ref.watch(globalChatEntryVisibleProvider);
    return Drawer(
      child: AllFeaturesScreen(
        hiddenKeys: chatVisible ? const <String>{} : kGlobalChatFeatureKeys,
      ),
    );
  }
}
