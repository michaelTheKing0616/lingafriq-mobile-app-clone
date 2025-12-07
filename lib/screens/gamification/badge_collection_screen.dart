import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../providers/gamification_provider.dart';
import '../../models/badge_model.dart';

/// Screen displaying all badges with unlock status
class BadgeCollectionScreen extends ConsumerStatefulWidget {
  const BadgeCollectionScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<BadgeCollectionScreen> createState() => _BadgeCollectionScreenState();
}

class _BadgeCollectionScreenState extends ConsumerState<BadgeCollectionScreen> {
  BadgeCategory? _selectedCategory;
  BadgeRarity? _selectedRarity;

  @override
  Widget build(BuildContext context) {
    final gamification = ref.watch(gamificationProvider.notifier);
    final allBadges = gamification.allBadges;
    final unlockedBadges = gamification.unlockedBadges;

    // Filter badges
    var filteredBadges = allBadges;
    if (_selectedCategory != null) {
      filteredBadges = filteredBadges.where((b) => b.category == _selectedCategory).toList();
    }
    if (_selectedRarity != null) {
      filteredBadges = filteredBadges.where((b) => b.rarity == _selectedRarity).toList();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Badge Collection'),
        actions: [
          Text(
            '${unlockedBadges.length}/${allBadges.length}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _buildFilterChip(
                  context,
                  label: 'All',
                  selected: _selectedCategory == null && _selectedRarity == null,
                  onSelected: () {
                    setState(() {
                      _selectedCategory = null;
                      _selectedRarity = null;
                    });
                  },
                ),
                const SizedBox(width: 8),
                ...BadgeCategory.values.map((category) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _buildFilterChip(
                        context,
                        label: category.name.toUpperCase(),
                        selected: _selectedCategory == category,
                        onSelected: () {
                          setState(() {
                            _selectedCategory = category;
                            _selectedRarity = null;
                          });
                        },
                      ),
                    )),
                const SizedBox(width: 8),
                ...BadgeRarity.values.map((rarity) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _buildFilterChip(
                        context,
                        label: rarity.name.toUpperCase(),
                        selected: _selectedRarity == rarity,
                        onSelected: () {
                          setState(() {
                            _selectedRarity = rarity;
                            _selectedCategory = null;
                          });
                        },
                      ),
                    )),
              ],
            ),
          ),
          // Badge grid
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.85,
              ),
              itemCount: filteredBadges.length,
              itemBuilder: (context, index) {
                final badge = filteredBadges[index];
                final isUnlocked = unlockedBadges.contains(badge);
                return _BadgeCard(
                  badge: badge,
                  isUnlocked: isUnlocked,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    BuildContext context, {
    required String label,
    required bool selected,
    required VoidCallback onSelected,
  }) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
      selectedColor: Theme.of(context).colorScheme.primaryContainer,
    );
  }
}

class _BadgeCard extends StatelessWidget {
  final Badge badge;
  final bool isUnlocked;

  const _BadgeCard({
    required this.badge,
    required this.isUnlocked,
  });

  Color _getRarityColor(BadgeRarity rarity) {
    switch (rarity) {
      case BadgeRarity.common:
        return Colors.grey;
      case BadgeRarity.uncommon:
        return Colors.green;
      case BadgeRarity.rare:
        return Colors.blue;
      case BadgeRarity.epic:
        return Colors.purple;
      case BadgeRarity.legendary:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final rarityColor = _getRarityColor(badge.rarity);

    return Card(
      elevation: isUnlocked ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isUnlocked ? rarityColor : Colors.grey.shade300,
          width: isUnlocked ? 2 : 1,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: isUnlocked ? null : Colors.grey.shade100,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Badge icon
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isUnlocked ? rarityColor.withOpacity(0.1) : Colors.grey.shade200,
                shape: BoxShape.circle,
              ),
              child: Text(
                badge.icon,
                style: TextStyle(
                  fontSize: 40,
                  color: isUnlocked ? rarityColor : Colors.grey,
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Badge name
            Text(
              badge.name,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isUnlocked ? null : Colors.grey,
                  ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            // Rarity indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: rarityColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                badge.rarity.name.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: rarityColor,
                ),
              ),
            ),
            if (!isUnlocked) ...[
              const SizedBox(height: 4),
              Icon(
                Icons.lock,
                size: 16,
                color: Colors.grey.shade400,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

