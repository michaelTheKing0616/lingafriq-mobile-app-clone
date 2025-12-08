import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../models/magic_item_model.dart';
import '../../providers/gamification_provider.dart';

/// Magic Items & Boosters Screen
class MagicItemsScreen extends ConsumerWidget {
  const MagicItemsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = MagicItemDefinitions.allItems;
    final gamification = ref.watch(gamificationProvider.notifier).gamification;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Magic Items & Boosters'),
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
          ...items.map((item) => _MagicItemCard(
                item: item,
                onPurchase: () {
                  _purchaseItem(context, ref, item);
                },
              )),
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
                await gamification.awardCurrency('cowries', -item.costCowries);
              }
              if (item.costBeads > 0) {
                await gamification.awardCurrency('beads', -item.costBeads);
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
                      Icon(Icons.one_time, size: 14),
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

