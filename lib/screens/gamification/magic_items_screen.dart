import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../models/magic_item_model.dart';
import '../../providers/gamification_provider.dart';
import '../../providers/gamification_services_provider.dart';
import '../../providers/user_provider.dart';
import '../../services/gamification/items_service.dart';
import '../../widgets/error_boundary.dart';
import '../../screens/loading/dynamic_loading_screen.dart';

/// Magic Items & Boosters Screen
class MagicItemsScreen extends ConsumerStatefulWidget {
  const MagicItemsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<MagicItemsScreen> createState() => _MagicItemsScreenState();
}

class _MagicItemsScreenState extends ConsumerState<MagicItemsScreen> {
  bool _isLoading = false;
  List<dynamic> _userInventory = [];
  List<dynamic> _availableItems = [];

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    setState(() => _isLoading = true);
    try {
      final itemsService = ref.read(itemsServiceProvider);
      final user = ref.read(userProvider);
      
      if (user != null) {
        final allItems = await itemsService.getAllItems();
        final inventory = await itemsService.getUserInventory(user.id.toString());
        
        setState(() {
          _availableItems = allItems;
          _userInventory = inventory;
        });
      } else {
        // Fallback to local items
        setState(() {
          _availableItems = MagicItemDefinitions.allItems.map((item) => {
            'code': item.id,
            'name': item.name,
            'description': item.description,
            'effect': item.effect.toString(),
            'duration_seconds': item.durationHours * 3600,
            'cost_cowries': item.costCowries,
            'cost_beads': item.costBeads,
          }).toList();
        });
      }
    } catch (e) {
      debugPrint('Error loading items: $e');
      // Fallback to local items
      setState(() {
        _availableItems = MagicItemDefinitions.allItems.map((item) => {
          'code': item.id,
          'name': item.name,
          'description': item.description,
        }).toList();
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _claimItem(String itemCode) async {
    setState(() => _isLoading = true);
    try {
      final itemsService = ref.read(itemsServiceProvider);
      final user = ref.read(userProvider);
      
      if (user != null) {
        await itemsService.claimItem(user.id.toString(), itemCode);
        await _loadItems(); // Reload inventory
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Item claimed successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error claiming item: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to claim item: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _useItem(String itemId) async {
    setState(() => _isLoading = true);
    try {
      final itemsService = ref.read(itemsServiceProvider);
      final user = ref.read(userProvider);
      
      if (user != null) {
        final result = await itemsService.useItem(user.id.toString(), itemId);
        await _loadItems(); // Reload inventory
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Item used! Effect: ${result['effect']}'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error using item: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to use item: ${e.toString()}'),
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
    final items = _availableItems.isNotEmpty 
        ? _availableItems 
        : MagicItemDefinitions.allItems.map((item) => {
            'code': item.id,
            'name': item.name,
            'description': item.description,
          }).toList();
    final gamification = ref.watch(gamificationProvider.notifier).gamification;
    
    if (_isLoading && _availableItems.isEmpty) {
      return const Scaffold(
        body: DynamicLoadingScreen(),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Magic Items & Boosters'),
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
          // Currency display
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      const Text('🐚', style: TextStyle(fontSize: 24)),
                      Text(
                        '${gamification.cowries}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        'Cowries',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      const Text('💎', style: TextStyle(fontSize: 24)),
                      Text(
                        '${gamification.ancestralBeads}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        'Beads',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Items list
          ...items.map((itemData) {
            // Find the MagicItem from definitions
            final item = MagicItemDefinitions.allItems.firstWhere(
              (i) => i.id == itemData['code'],
              orElse: () => MagicItemDefinitions.allItems.first,
            );
            return _MagicItemCard(
              item: item,
              onPurchase: () {
                _purchaseItem(context, ref, item);
              },
            );
          }),
        ],
      ),
    );
  }

  void _purchaseItem(BuildContext context, WidgetRef ref, MagicItem item) {
    final gamification = ref.read(gamificationProvider.notifier);
    final currentGamification = gamification.gamification;

    // Check if user has enough currency
    if (item.costBeads > 0 && currentGamification.ancestralBeads < item.costBeads) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Not enough Ancestral Beads')),
      );
      return;
    }

    if (item.costCowries > 0 && currentGamification.cowries < item.costCowries) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Not enough Cowries')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Purchase ${item.name}?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.description),
            const SizedBox(height: 16),
            if (item.durationHours > 0)
              Text('Duration: ${item.durationHours} hours')
            else
              const Text('One-time use'),
            const SizedBox(height: 8),
            Row(
              children: [
                if (item.costCowries > 0) ...[
                  const Text('🐚'),
                  const SizedBox(width: 4),
                  Text('${item.costCowries} Cowries'),
                ],
                if (item.costCowries > 0 && item.costBeads > 0)
                  const Text(' + '),
                if (item.costBeads > 0) ...[
                  const Text('💎'),
                  const SizedBox(width: 4),
                  Text('${item.costBeads} Beads'),
                ],
              ],
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
              // Deduct currency
              if (item.costCowries > 0) {
                await gamification.awardCurrency(cowries: -item.costCowries);
              }
              if (item.costBeads > 0) {
                await gamification.awardCurrency(ancestralBeads: -item.costBeads);
              }

              // Activate item
              await gamification.activateBooster(item.id, item.durationHours);

              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${item.name} activated!')),
                );
              }
            },
            child: const Text('Purchase'),
          ),
        ],
      ),
    );
  }
}

class _MagicItemCard extends StatelessWidget {
  final MagicItem item;
  final VoidCallback onPurchase;

  const _MagicItemCard({
    required this.item,
    required this.onPurchase,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Text(
            item.icon,
            style: const TextStyle(fontSize: 24),
          ),
        ),
        title: Text(item.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.description),
            const SizedBox(height: 4),
            Row(
              children: [
                if (item.durationHours > 0)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.timer, size: 14),
                      const SizedBox(width: 4),
                      Text('${item.durationHours}h'),
                    ],
                  )
                else
                  const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.access_time, size: 14),
                      SizedBox(width: 4),
                      Text('One-time'),
                    ],
                  ),
                const SizedBox(width: 16),
                if (item.costCowries > 0) ...[
                  const Text('🐚', style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 2),
                  Text('${item.costCowries}'),
                ],
                if (item.costCowries > 0 && item.costBeads > 0)
                  const Text(' + '),
                if (item.costBeads > 0) ...[
                  const Text('💎', style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 2),
                  Text('${item.costBeads}'),
                ],
              ],
            ),
          ],
        ),
        trailing: FilledButton(
          onPressed: onPurchase,
          child: const Text('Buy'),
        ),
      ),
    );
  }
}

