import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../providers/api_provider.dart';

/// Ancestral Tree - Visualize everyone you've helped
class AncestralTreeScreen extends ConsumerWidget {
  const AncestralTreeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<_AncestrySnapshot>(
      future: _loadTreeData(ref),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Ancestral Tree')),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 48),
                    const SizedBox(height: 12),
                    const Text(
                      'Unable to load your ancestry graph right now.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () {
                        // Rebuild FutureBuilder by pushing a new route instance.
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (_) => const AncestralTreeScreen()),
                        );
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final data = snapshot.data ?? _AncestrySnapshot.empty();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ancestral Tree'),
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
                      label: 'Mentees',
                      value: '${data.mentees.length}',
                      icon: Icons.people,
                    ),
                    _StatItem(
                      label: 'Mentors',
                      value: '${data.mentors.length}',
                      icon: Icons.school,
                    ),
                    _StatItem(
                      label: 'Connections',
                      value: '${data.mentors.length + data.mentees.length}',
                      icon: Icons.hub,
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
            if (data.mentors.isEmpty && data.mentees.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: Text(
                  'No ancestry links yet. As you connect with mentors or help other learners, your tree will grow here.',
                ),
              )
            else ...[
              if (data.mentors.isNotEmpty) ...[
                Text('Mentors', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                ...data.mentors.map((person) => _TreeNodeCard(person: person)),
                const SizedBox(height: 16),
              ],
              if (data.mentees.isNotEmpty) ...[
                Text('Mentees', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                ...data.mentees.map((person) => _TreeNodeCard(person: person)),
              ],
            ],
          ],
        ),
      ),
    );
      },
    );
  }

  Future<_AncestrySnapshot> _loadTreeData(WidgetRef ref) async {
    final api = ref.read(apiProvider.notifier);
    final raw = await api.getAncestryMe();

    final mentorsRaw = (raw['mentors'] is List) ? (raw['mentors'] as List) : const [];
    final menteesRaw = (raw['mentees'] is List) ? (raw['mentees'] as List) : const [];

    List<_TreePerson> parsePeople(List rows, {required String kind, required String key}) {
      final out = <_TreePerson>[];
      for (final r in rows) {
        if (r is! Map) continue;
        final person = r[key];
        if (person is! Map) continue;
        out.add(
          _TreePerson(
            kind: kind,
            username: (person['username'] ?? person['global_id'] ?? 'Unknown').toString(),
            globalId: person['global_id']?.toString(),
            avatar: person['avater']?.toString(),
          ),
        );
      }
      return out;
    }

    return _AncestrySnapshot(
      mentors: parsePeople(mentorsRaw, kind: 'Mentor', key: 'mentor_id'),
      mentees: parsePeople(menteesRaw, kind: 'Mentee', key: 'mentee_id'),
    );
  }
}

class _TreePerson {
  final String kind; // Mentor | Mentee
  final String username;
  final String? avatar;
  final String? globalId;

  _TreePerson({
    required this.kind,
    required this.username,
    this.avatar,
    this.globalId,
  });
}

class _AncestrySnapshot {
  final List<_TreePerson> mentors;
  final List<_TreePerson> mentees;

  const _AncestrySnapshot({required this.mentors, required this.mentees});

  factory _AncestrySnapshot.empty() => const _AncestrySnapshot(mentors: [], mentees: []);
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
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                Chip(
                  label: Text(person.kind),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                if (person.globalId != null && person.globalId!.trim().isNotEmpty)
                  Chip(
                    label: Text('@${person.globalId}'),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

