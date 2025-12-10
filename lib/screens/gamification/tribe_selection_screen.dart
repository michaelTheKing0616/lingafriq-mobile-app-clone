import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../providers/gamification_provider.dart';
import '../../providers/gamification_services_provider.dart';
import '../../providers/user_provider.dart';
import '../../models/user_gamification_model.dart';
import '../../services/gamification/tribes_service.dart';
import '../../widgets/error_boundary.dart';
import '../../screens/loading/dynamic_loading_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _loadTribes();
  }

  Future<void> _loadTribes() async {
    setState(() => _isLoading = true);
    try {
      final tribesService = ref.read(tribesServiceProvider);
      final user = ref.read(userProvider);
      
      // TODO: Implement get all tribes endpoint
      // For now, use static list
      _availableTribes = Tribes.allTribes.map((name) => {
        'name': name,
        'id': name.toLowerCase().replaceAll(' ', '_'),
      }).toList();
      
      // Get user's current tribe if exists
      if (user != null) {
        // TODO: Get user's tribe from API
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
                  trailing: currentTribe == tribeName || _currentTribeId == tribe['id']
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
}

