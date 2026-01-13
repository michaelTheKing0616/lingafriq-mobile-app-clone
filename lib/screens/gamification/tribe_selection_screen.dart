import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../providers/gamification_provider.dart';
import '../../providers/gamification_services_provider.dart';
import '../../providers/user_provider.dart';
import '../../models/user_gamification_model.dart';
import '../../services/gamification/tribes_service.dart';
import '../../widgets/error_boundary.dart';
import '../../screens/loading/dynamic_loading_screen.dart';
import 'classroom_dashboard_screen.dart';

/// Tribe Selection Screen
class TribeSelectionScreen extends ConsumerStatefulWidget {
  const TribeSelectionScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<TribeSelectionScreen> createState() => _TribeSelectionScreenState();
}

class _TribeSelectionScreenState extends ConsumerState<TribeSelectionScreen> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _availableTribes = [];
  String? _currentTribeId;
  List<Map<String, dynamic>> _myClassrooms = [];
  final TextEditingController _classCodeController = TextEditingController();

  @override
  void dispose() {
    _classCodeController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadTribes();
  }

  Future<void> _loadTribes() async {
    setState(() => _isLoading = true);
    try {
      final user = ref.read(userProvider);
      final tribesService = ref.read(tribesServiceProvider);

      // Load dynamic tribe catalog from backend, fall back to curated list.
      try {
        final apiTribes = await tribesService.getTribes();
        if (apiTribes.isNotEmpty) {
          _availableTribes = apiTribes
              .map((t) => {
                    'name': t['name']?.toString() ?? '',
                    'id': t['id']?.toString() ?? t['slug']?.toString() ?? '',
                    'language_tag': t['language_tag']?.toString(),
                  })
              .where((t) => (t['name'] as String).isNotEmpty)
              .toList();
        } else {
          _availableTribes = Tribes.allTribes
              .map((name) => {
                    'name': name,
                    'id': name.toLowerCase().replaceAll(' ', '_'),
                  })
              .toList();
        }
      } catch (e) {
        debugPrint('Error loading tribes from API, using curated list: $e');
        _availableTribes = Tribes.allTribes
            .map((name) => {
                  'name': name,
                  'id': name.toLowerCase().replaceAll(' ', '_'),
                })
            .toList();
      }

      // Load teacher-owned classroom tribes
      if (user != null) {
        try {
          final classrooms = await tribesService.getMyClassrooms();
          _myClassrooms = classrooms;
        } catch (_) {
          _myClassrooms = [];
        }
      }
    } catch (e) {
      debugPrint('Error loading tribes: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _joinTribe(String tribeId, String tribeName) async {
    setState(() => _isLoading = true);
    try {
      final tribesService = ref.read(tribesServiceProvider);
      await tribesService.joinTribe(tribeId);
      
      final gamification = ref.read(gamificationProvider.notifier);
      await gamification.selectTribe(tribeName);
      
      setState(() => _currentTribeId = tribeId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Joined $tribeName tribe!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error joining tribe: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to join tribe: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final gamification = ref.watch(gamificationProvider.notifier);
    final currentTribe = gamification.gamification.tribe;
    
    if (_isLoading && _availableTribes.isEmpty) {
      return const Scaffold(
        body: DynamicLoadingScreen(),
      );
    }
    
    final tribes = _availableTribes.isNotEmpty 
        ? _availableTribes 
        : Tribes.allTribes.map((name) => {'name': name, 'id': name.toLowerCase()}).toList();

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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ],
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
          _buildClassroomSection(context),
          const SizedBox(height: 16),
          ...tribes.map((tribe) => Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: currentTribe == tribe['name'] ? 4 : 1,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    child: Text(
                      tribeEmojis[tribe['name']] ?? '🏛️',
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                  title: Text(
                    tribe['name'],
                    style: TextStyle(
                      fontWeight: currentTribe == tribe['name']
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  subtitle: Text(
                    'Join the ${tribe['name']} tribe and compete in leaderboards',
                  ),
                  trailing: currentTribe == tribe['name'] ||
                          _currentTribeId == tribe['id']
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: _isLoading
                      ? null
                      : () => _joinTribe(tribe['id'], tribe['name']),
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildClassroomSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Classroom Mode (Teachers)',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create a private “class tribe” for your learners with shared '
              'progress and Polie-powered activities, or join an existing '
              'classroom using a code from your teacher.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _classCodeController,
                    decoration: const InputDecoration(
                      labelText: 'Join with class code',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isLoading ? null : _joinByCode,
                  child: _isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Join'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _isLoading ? null : _createClassroomPrompt,
                icon: const Icon(Icons.add_circle_outline_rounded),
                label: const Text('Create a classroom'),
              ),
            ),
            if (_myClassrooms.isNotEmpty) ...[
              const Divider(),
              Text(
                'Your Classrooms',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              ..._myClassrooms.map(
                (c) => ListTile(
                  leading: const Icon(Icons.class_rounded),
                  title: Text(c['name']?.toString() ?? 'Classroom'),
                  subtitle: Text(
                    'Code: ${c['classroom_code'] ?? '—'} • ${c['language_tag'] ?? ''}',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ClassroomDashboardScreen(
                          tribeId: c['_id']?.toString() ?? '',
                          tribeName: c['name']?.toString() ?? 'Classroom',
                          languageTag:
                              c['language_tag']?.toString() ?? 'english',
                          classroomCode: c['classroom_code']?.toString(),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _joinByCode() async {
    final code = _classCodeController.text.trim();
    if (code.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      final service = ref.read(tribesServiceProvider);
      await service.joinClassroomByCode(code);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Joined classroom successfully')),
        );
      }
      await _loadTribes();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to join classroom: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _createClassroomPrompt() async {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    String languageTag = 'english';

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Create Classroom'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Class name',
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description (optional)',
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: languageTag,
                  items: const [
                    DropdownMenuItem(
                        value: 'english', child: Text('English')),
                    DropdownMenuItem(
                        value: 'yoruba', child: Text('Yoruba')),
                    DropdownMenuItem(value: 'hausa', child: Text('Hausa')),
                    DropdownMenuItem(
                        value: 'swahili', child: Text('Swahili')),
                    DropdownMenuItem(value: 'igbo', child: Text('Igbo')),
                  ],
                  onChanged: (v) {
                    languageTag = v ?? 'english';
                  },
                  decoration: const InputDecoration(
                    labelText: 'Teaching language',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isEmpty) return;
                Navigator.of(context).pop();
                await _createClassroom(
                  name,
                  descriptionController.text,
                  languageTag,
                );
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _createClassroom(
    String name,
    String description,
    String languageTag,
  ) async {
    setState(() => _isLoading = true);
    try {
      final service = ref.read(tribesServiceProvider);
      await service.createClassroom(
        name: name,
        languageTag: languageTag,
        description: description.isEmpty ? null : description,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Classroom "$name" created'),
          ),
        );
      }
      await _loadTribes();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create classroom: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}

