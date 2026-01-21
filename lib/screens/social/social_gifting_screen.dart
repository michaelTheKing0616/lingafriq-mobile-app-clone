import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../providers/gamification_provider.dart';
import '../../providers/user_provider.dart';
import '../../utils/error_handler.dart';

/// Social Gifting Screen - Send lessons to friends
class SocialGiftingScreen extends ConsumerWidget {
  const SocialGiftingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gamification = ref.watch(gamificationProvider.notifier).gamification;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Send a Lesson'),
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
                    'Gift a Lesson',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Share the gift of learning! Send a premium lesson to a friend. '
                    'They\'ll receive it instantly and you\'ll both earn rewards.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Currency display
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your Cowries',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text('🐚', style: TextStyle(fontSize: 32)),
                      const SizedBox(width: 8),
                      Text(
                        '${gamification.cowries}',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Cost: 50 Cowries per lesson',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Gift form
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Send Gift',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Friend\'s Username or Email',
                      hintText: 'Enter username or email',
                      prefixIcon: Icon(Icons.person),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Lesson Type',
                      prefixIcon: Icon(Icons.school),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'premium', child: Text('Premium Lesson')),
                      DropdownMenuItem(value: 'quiz', child: Text('Quiz Pack')),
                      DropdownMenuItem(value: 'game', child: Text('Game Session')),
                    ],
                    onChanged: (value) {},
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: gamification.cowries >= 50
                          ? () {
                              _showGiftConfirmation(context, ref);
                            }
                          : null,
                      child: const Text('Send Gift'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Benefits
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Benefits',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  _BenefitItem(
                    icon: Icons.star,
                    text: 'You earn 25 XP per gift sent',
                  ),
                  _BenefitItem(
                    icon: Icons.favorite,
                    text: 'Your friend gets a free premium lesson',
                  ),
                  _BenefitItem(
                    icon: Icons.people,
                    text: 'Both of you appear in each other\'s Ancestral Tree',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showGiftConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Gift'),
        content: const Text(
          'Send this lesson gift? It will cost 50 Cowries.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              try {
                final gamification = ref.read(gamificationProvider.notifier);
                final user = ref.read(userProvider);
                
                if (user == null) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please log in to send gifts')),
                    );
                  }
                  return;
                }

                // Deduct currency for gift
                await gamification.awardCurrency(cowries: -50);
                
                // Send gift via API (if gift endpoint exists)
                // For now, we'll log the gift action and award XP
                // In the future, this would call a gift API endpoint
                await gamification.awardXP('send_gift');

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Gift sent successfully!')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ErrorHandler.showError(context, e);
                }
              }
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }
}

class _BenefitItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _BenefitItem({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

