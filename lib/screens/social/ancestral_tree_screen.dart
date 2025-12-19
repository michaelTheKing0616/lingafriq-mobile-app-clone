import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Ancestral Tree - Visualize everyone you've helped
class AncestralTreeScreen extends ConsumerWidget {
  const AncestralTreeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Currently shows a local, illustrative tree based on your gifting activity.
    // Marked as beta until fully wired to backend gifting/social graph.
    final treeData = _generateMockTreeData();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ancestral Tree (beta)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Ancestral Tree'),
                  content: const Text(
                    'This tree shows everyone you\'ve helped learn African languages. '
                    'Each person you gift lessons to or help appears here. '
                    'Watch your tree grow as you share knowledge!',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Got it'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stats
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _StatItem(
                      label: 'People Helped',
                      value: '${treeData.length}',
                      icon: Icons.people,
                    ),
                    _StatItem(
                      label: 'Lessons Gifted',
                      value: '${treeData.fold(0, (sum, p) => sum + p.lessonsGifted)}',
                      icon: Icons.card_giftcard,
                    ),
                    _StatItem(
                      label: 'Total Impact',
                      value: '${treeData.fold(0, (sum, p) => sum + p.xpEarned)} XP',
                      icon: Icons.star,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Tree visualization
            Text(
              'Your Ancestral Tree',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            // Tree nodes
            ...treeData.map((person) => _TreeNodeCard(person: person)),
          ],
        ),
      ),
    );
  }

  List<_TreePerson> _generateMockTreeData() {
    return [
      _TreePerson(
        username: 'Kwame',
        avatar: null,
        joinedDate: DateTime.now().subtract(const Duration(days: 30)),
        lessonsGifted: 3,
        xpEarned: 150,
        languages: ['Yoruba', 'Swahili'],
      ),
      _TreePerson(
        username: 'Amina',
        avatar: null,
        joinedDate: DateTime.now().subtract(const Duration(days: 15)),
        lessonsGifted: 1,
        xpEarned: 50,
        languages: ['Hausa'],
      ),
      _TreePerson(
        username: 'Thabo',
        avatar: null,
        joinedDate: DateTime.now().subtract(const Duration(days: 7)),
        lessonsGifted: 2,
        xpEarned: 100,
        languages: ['Zulu', 'Xhosa'],
      ),
    ];
  }
}

class _TreePerson {
  final String username;
  final String? avatar;
  final DateTime joinedDate;
  final int lessonsGifted;
  final int xpEarned;
  final List<String> languages;

  _TreePerson({
    required this.username,
    this.avatar,
    required this.joinedDate,
    required this.lessonsGifted,
    required this.xpEarned,
    required this.languages,
  });
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _TreeNodeCard extends StatelessWidget {
  final _TreePerson person;

  const _TreeNodeCard({required this.person});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primary,
          child: Text(
            person.username[0].toUpperCase(),
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(person.username),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Joined ${_formatDate(person.joinedDate)}'),
            const SizedBox(height: 4),
            Wrap(
              spacing: 4,
              children: person.languages.map((lang) => Chip(
                    label: Text(lang),
                    padding: EdgeInsets.zero,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  )).toList(),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.card_giftcard, size: 16),
                const SizedBox(width: 4),
                Text('${person.lessonsGifted}'),
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star, size: 16, color: Colors.amber),
                const SizedBox(width: 4),
                Text('${person.xpEarned} XP'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return 'today';
    } else if (diff.inDays == 1) {
      return 'yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    } else if (diff.inDays < 30) {
      return '${(diff.inDays / 7).floor()} weeks ago';
    } else {
      return '${(diff.inDays / 30).floor()} months ago';
    }
  }
}

