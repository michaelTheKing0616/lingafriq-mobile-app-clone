import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../providers/gamification_provider.dart';

/// Tribe Selection Screen
class TribeSelectionScreen extends ConsumerWidget {
  const TribeSelectionScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gamification = ref.watch(gamificationProvider.notifier);
    final currentTribe = gamification.gamification.tribe;
    final tribes = TribeDefinitions.tribes;

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
          ...tribes.map((tribe) => Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: currentTribe == tribe.id ? 4 : 1,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    child: Text(
                      tribe.emoji,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                  title: Text(
                    tribe.name,
                    style: TextStyle(
                      fontWeight: currentTribe == tribe.id
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  subtitle: Text(tribe.description),
                  trailing: currentTribe == tribe.id
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () async {
                    await gamification.selectTribe(tribe.id);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Joined ${tribe.name} tribe!'),
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

