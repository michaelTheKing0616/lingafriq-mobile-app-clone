import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../providers/tribe_vs_tribe_provider.dart';
import '../../providers/gamification_provider.dart';

/// Tribe vs Tribe Events Screen
class TribeVsTribeScreen extends ConsumerWidget {
  const TribeVsTribeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventProvider = ref.watch(tribeVsTribeProvider.notifier);
    final currentEvent = eventProvider.currentEvent;
    final leaderboard = eventProvider.getLeaderboard();
    final gamification = ref.watch(gamificationProvider.notifier).gamification;

    if (currentEvent == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Tribe vs Tribe'),
        ),
        body: const Center(
          child: Text('No active event'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tribe vs Tribe'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              eventProvider.loadCurrentEvent();
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Event header
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    currentEvent.name,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(currentEvent.description),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.timer, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        currentEvent.isActive
                            ? 'Ends in: ${_formatDuration(currentEvent.timeRemaining)}'
                            : 'Starts: ${_formatDate(currentEvent.startDate)}',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Leaderboard
          Text(
            'Tribe Leaderboard',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          ...leaderboard.asMap().entries.map((entry) {
            final index = entry.key;
            final tribeEntry = entry.value;
            final isUserTribe = tribeEntry.key == gamification.tribe;

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              elevation: isUserTribe ? 4 : 1,
              color: isUserTribe
                  ? Theme.of(context).colorScheme.primaryContainer
                  : null,
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: _getRankColor(index),
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  _getTribeName(tribeEntry.key),
                  style: TextStyle(
                    fontWeight: isUserTribe ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star, size: 16, color: Colors.amber),
                    const SizedBox(width: 4),
                    Text(
                      '${tribeEntry.value}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 16),
          // Your contribution
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Contribute to Your Tribe',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Every XP you earn contributes to your tribe\'s score! '
                    'Keep learning to help your tribe win!',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  if (gamification.tribe != null)
                    ElevatedButton(
                      onPressed: () {
                        // XP contribution happens automatically via gamification
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Your XP automatically contributes to your tribe!'),
                          ),
                        );
                      },
                      child: const Text('Learn Now'),
                    )
                  else
                    ElevatedButton(
                      onPressed: () {
                        // Navigate to tribe selection
                        Navigator.pushNamed(context, '/tribe-selection');
                      },
                      child: const Text('Join a Tribe First'),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getRankColor(int rank) {
    if (rank == 0) return Colors.amber;
    if (rank == 1) return Colors.grey;
    if (rank == 2) return Colors.brown;
    return Colors.blue;
  }

  String _getTribeName(String tribeId) {
    // Map tribe IDs to names
    final tribeNames = {
      'yoruba': 'Yoruba',
      'igbo': 'Igbo',
      'hausa': 'Hausa',
      'swahili': 'Swahili',
      'zulu': 'Zulu',
    };
    return tribeNames[tribeId] ?? tribeId;
  }

  String _formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays} day${duration.inDays > 1 ? 's' : ''}';
    } else if (duration.inHours > 0) {
      return '${duration.inHours} hour${duration.inHours > 1 ? 's' : ''}';
    } else {
      return '${duration.inMinutes} minute${duration.inMinutes > 1 ? 's' : ''}';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }
}

