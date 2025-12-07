import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../providers/language_village_provider.dart';
import '../../models/language_village_model.dart';

/// Language Villages Screen - Voice rooms for target-language-only practice
class LanguageVillagesScreen extends ConsumerWidget {
  const LanguageVillagesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final villageProvider = ref.watch(languageVillageProvider.notifier);
    final villages = villageProvider.villages;
    final currentVillage = villageProvider.currentVillage;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Language Villages'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              _showCreateVillageDialog(context, ref);
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              villageProvider.refresh();
            },
          ),
        ],
      ),
      body: currentVillage != null
          ? _buildCurrentVillageView(context, ref, currentVillage)
          : _buildVillageList(context, ref, villages),
    );
  }

  Widget _buildVillageList(
    BuildContext context,
    WidgetRef ref,
    List<LanguageVillage> villages,
  ) {
    if (villages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.village, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'No villages available',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey,
                  ),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                _showCreateVillageDialog(context, ref);
              },
              child: const Text('Create Village'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: villages.length,
      itemBuilder: (context, index) {
        final village = villages[index];
        return _VillageCard(
          village: village,
          onJoin: () async {
            final success = await ref
                .read(languageVillageProvider.notifier)
                .joinVillage(village.id);
            if (context.mounted) {
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Joined ${village.name}!')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Village is full')),
                );
              }
            }
          },
        );
      },
    );
  }

  Widget _buildCurrentVillageView(
    BuildContext context,
    WidgetRef ref,
    LanguageVillage village,
  ) {
    return Column(
      children: [
        // Village header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          village.name,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        Text(
                          village.description,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.exit_to_app),
                    onPressed: () async {
                      await ref.read(languageVillageProvider.notifier).leaveVillage();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.people, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    '${village.currentParticipants}/${village.maxParticipants}',
                  ),
                  const SizedBox(width: 16),
                  const Icon(Icons.language, size: 16),
                  const SizedBox(width: 4),
                  Text('${village.language} only'),
                ],
              ),
            ],
          ),
        ),
        // Rules
        if (village.rules.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Village Rules',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                ...village.rules.map((rule) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle, size: 16, color: Colors.green),
                          const SizedBox(width: 8),
                          Expanded(child: Text(rule)),
                        ],
                      ),
                    )),
              ],
            ),
          ),
        // Participants (placeholder for voice room UI)
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.mic, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  'Voice Room',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Voice room integration coming soon',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey,
                      ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showCreateVillageDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final languageController = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Language Village'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Village Name',
                hintText: 'e.g., Yoruba Village',
              ),
            ),
            TextField(
              controller: languageController,
              decoration: const InputDecoration(
                labelText: 'Language',
                hintText: 'e.g., Yoruba',
              ),
            ),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'What is this village about?',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final success = await ref
                  .read(languageVillageProvider.notifier)
                  .createVillage(
                    name: nameController.text,
                    language: languageController.text,
                    description: descriptionController.text,
                  );
              if (context.mounted) {
                Navigator.pop(context);
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Village created!')),
                  );
                }
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}

class _VillageCard extends StatelessWidget {
  final LanguageVillage village;
  final VoidCallback onJoin;

  const _VillageCard({
    required this.village,
    required this.onJoin,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primary,
          child: const Icon(Icons.village, color: Colors.white),
        ),
        title: Text(village.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(village.description),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.people, size: 16),
                const SizedBox(width: 4),
                Text(
                  '${village.currentParticipants}/${village.maxParticipants}',
                ),
                const SizedBox(width: 16),
                const Icon(Icons.language, size: 16),
                const SizedBox(width: 4),
                Text('${village.language} only'),
              ],
            ),
          ],
        ),
        trailing: ElevatedButton(
          onPressed: village.currentParticipants >= village.maxParticipants
              ? null
              : onJoin,
          child: const Text('Join'),
        ),
      ),
    );
  }
}

