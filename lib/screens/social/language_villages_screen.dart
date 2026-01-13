import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../services/voice/audio_recording_service.dart';
import '../../providers/language_village_provider.dart';
import '../../models/language_village_model.dart';
import '../../widgets/audio_player_widget.dart';

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
            const Icon(Icons.location_city, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'No villages available',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey,
                  ),
            ),
            const SizedBox(height: 8),
            FilledButton(
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
        // Voice room: live voice messages list + record button
        Expanded(
          child: _VillageVoiceRoom(
            village: village,
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
          FilledButton(
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

class _VillageVoiceRoom extends ConsumerWidget {
  final LanguageVillage village;

  const _VillageVoiceRoom({Key? key, required this.village}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = ref.watch(languageVillageProvider.notifier);
    final messages = provider.voiceMessages;
    final polieRecap = provider.polieRecap;
    final isAskingPolie = provider.isAskingPolieRecap;
    final isLiveConnected = provider.isLiveConnected;
    final isLiveConnecting = provider.isLiveConnecting;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Voice Room',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        isLiveConnected
                            ? Icons.podcasts_rounded
                            : Icons.podcasts_outlined,
                        size: 16,
                        color: isLiveConnected
                            ? Colors.greenAccent
                            : Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isLiveConnected
                            ? 'Live village circle connected'
                            : 'Tap to join live circle (beta)',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
              Row(
                children: [
                  TextButton.icon(
                    onPressed: isLiveConnecting
                        ? null
                        : () {
                            if (isLiveConnected) {
                              provider.disconnectLiveRoom();
                            } else {
                              provider.connectLiveRoom();
                            }
                          },
                    icon: isLiveConnecting
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child:
                                CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            isLiveConnected
                                ? Icons.call_end_rounded
                                : Icons.call_rounded,
                            size: 16,
                          ),
                    label: Text(
                      isLiveConnected ? 'Leave live circle' : 'Join live circle',
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.auto_awesome),
                    tooltip: 'Ask Polie for a recap',
                    onPressed: isAskingPolie
                        ? null
                        : () => provider.askPolieForRecap(),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Refresh messages',
                    onPressed: () => provider.refreshVoiceMessages(),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (polieRecap != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              color: isDark
                  ? Colors.green.withOpacity(0.2)
                  : Colors.green.shade50,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.smart_toy_rounded, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Polie’s Recap',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      polieRecap,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
          ),
        if (messages.isEmpty)
          Expanded(
            child: Center(
              child: Text(
                'No voice messages yet.\nBe the first to greet the village!',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey,
                    ),
              ),
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];
                final title = (msg['title'] as String?) ?? 'Voice message';
                final createdAtStr = msg['createdAt']?.toString() ?? '';
                final fileUrl = msg['fileUrl']?.toString() ?? '';

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  color: isDark
                      ? Colors.white.withOpacity(0.06)
                      : Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          createdAtStr,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 8),
                        if (fileUrl.isNotEmpty)
                          AudioPlayerWidget(audioUrl: fileUrl),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                icon: const Icon(Icons.mic),
                label: const Text('Record voice message'),
                onPressed: () async {
                  await _showVoiceRecorderSheet(context, ref, village);
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showVoiceRecorderSheet(
      BuildContext context, WidgetRef ref, LanguageVillage village) async {
    final recorder = AudioRecordingService();
    bool isRecording = false;
    String? recordedPath;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'New voice message',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isRecording
                        ? 'Recording… tap to stop when you’re done.'
                        : 'Tap the mic to start recording a short greeting or message.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  IconButton.filled(
                    iconSize: 40,
                    icon: Icon(isRecording ? Icons.stop : Icons.mic),
                    onPressed: () async {
                      if (!isRecording) {
                        final path = await recorder.startRecording();
                        if (path != null) {
                          setState(() {
                            recordedPath = path;
                            isRecording = true;
                          });
                        }
                      } else {
                        final path = await recorder.stopRecording();
                        setState(() {
                          recordedPath = path ?? recordedPath;
                          isRecording = false;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  if (!isRecording && recordedPath != null)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Ready to send to ${village.name}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        FilledButton.icon(
                          icon: const Icon(Icons.send),
                          label: const Text('Send'),
                          onPressed: () async {
                            if (recordedPath == null) return;
                            final ok = await ref
                                .read(languageVillageProvider.notifier)
                                .sendRecordedVoiceMessage(recordedPath!);
                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    ok
                                        ? 'Voice message sent to ${village.name}!'
                                        : 'Could not send voice message. Please try again.',
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  const SizedBox(height: 8),
                ],
              );
            },
          ),
        );
      },
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
          child: const Icon(Icons.location_city, color: Colors.white),
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
        trailing: FilledButton(
          onPressed: village.currentParticipants >= village.maxParticipants
              ? null
              : onJoin,
          child: const Text('Join'),
        ),
      ),
    );
  }
}

