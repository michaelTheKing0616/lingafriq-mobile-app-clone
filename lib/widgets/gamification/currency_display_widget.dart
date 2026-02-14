import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../providers/gamification_provider.dart';

/// Displays the three currencies: Ngwenya, Cowries, and Ancestral Beads
class CurrencyDisplayWidget extends ConsumerWidget {
  final bool compact;
  final bool showLabels;

  const CurrencyDisplayWidget({
    super.key,
    this.compact = false,
    this.showLabels = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gamification = ref.watch(gamificationProvider.notifier).gamification;

    if (compact) {
      return _buildCompact(context, gamification);
    }

    return _buildFull(context, gamification);
  }

  Widget _buildCompact(BuildContext context, gamification) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildCurrencyItem(
          context,
          icon: '🪙',
          amount: gamification.ngwenya,
          label: 'Ngwenya',
          color: Colors.amber,
          compact: true,
        ),
        const SizedBox(width: 8),
        _buildCurrencyItem(
          context,
          icon: '🐚',
          amount: gamification.cowries,
          label: 'Cowries',
          color: Colors.orange,
          compact: true,
        ),
        const SizedBox(width: 8),
        _buildCurrencyItem(
          context,
          icon: '💎',
          amount: gamification.ancestralBeads,
          label: 'Beads',
          color: Colors.purple,
          compact: true,
        ),
      ],
    );
  }

  Widget _buildFull(BuildContext context, gamification) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildCurrencyItem(
              context,
              icon: '🪙',
              amount: gamification.ngwenya,
              label: 'Ngwenya',
              color: Colors.amber,
            ),
            Container(
              width: 1,
              height: 40,
              color: Colors.grey[300],
            ),
            _buildCurrencyItem(
              context,
              icon: '🐚',
              amount: gamification.cowries,
              label: 'Cowries',
              color: Colors.orange,
            ),
            Container(
              width: 1,
              height: 40,
              color: Colors.grey[300],
            ),
            _buildCurrencyItem(
              context,
              icon: '💎',
              amount: gamification.ancestralBeads,
              label: 'Beads',
              color: Colors.purple,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrencyItem(
    BuildContext context, {
    required String icon,
    required int amount,
    required String label,
    required Color color,
    bool compact = false,
  }) {
    if (compact) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            icon,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(width: 4),
          Text(
            _formatAmount(amount),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 14,
            ),
          ),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          icon,
          style: const TextStyle(fontSize: 24),
        ),
        const SizedBox(height: 4),
        Text(
          _formatAmount(amount),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
            fontSize: 16,
          ),
        ),
        if (showLabels) ...[
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: 10,
                ),
          ),
        ],
      ],
    );
  }

  String _formatAmount(int amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K';
    }
    return amount.toString();
  }
}

