import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../providers/gamification_provider.dart';
import '../../models/user_gamification_model.dart';

/// Tribe Selection Screen
class TribeSelectionScreen extends ConsumerWidget {
  const TribeSelectionScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gamification = ref.watch(gamificationProvider.notifier);
    final currentTribe = gamification.gamification.tribe;
    final tribes = Tribes.allTribes;

    // Map tribe names to emojis
    final Map<String, String> tribeEmojis = {
      'Zulu': '🇿🇦',
      'Yoruba': '🇳🇬',
      'Igbo': '🇳🇬',
      'Hausa': '🇳🇬',
      'Swahili': '🇰🇪',
      'Amhara': '🇪🇹',
      'Xhosa': '🇿🇦',
      'Shona': '🇿🇼',
      'Twi': '🇬🇭',
      'Wolof': '🇸🇳',
      'Somali': '🇸🇴',
      'Luo': '🇰🇪',
      'Kikuyu': '🇰🇪',
      'Oromo': '🇪🇹',
      'Mandinka': '🇬🇲',
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose Your Tribe'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Join a Tribe',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tribes compete in leaderboards and events. '
                    'Choose the tribe that represents your heritage or interests!',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          ...tribes.map((tribeName) => Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: currentTribe == tribeName ? 4 : 1,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    child: Text(
                      tribeEmojis[tribeName] ?? '🏛️',
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                  title: Text(
                    tribeName,
                    style: TextStyle(
                      fontWeight: currentTribe == tribeName
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  subtitle: Text('Join the $tribeName tribe and compete in leaderboards'),
                  trailing: currentTribe == tribeName
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () async {
                    await gamification.selectTribe(tribeName);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Joined $tribeName tribe!'),
                        ),
                      );
                    }
                  },
                ),
              )),
        ],
      ),
    );
  }
}

