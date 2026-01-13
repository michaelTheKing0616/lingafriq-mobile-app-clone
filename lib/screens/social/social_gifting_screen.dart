import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../providers/api_provider.dart';
import '../../providers/gamification_provider.dart';

/// Social Gifting Screen - Send lessons to friends
class SocialGiftingScreen extends ConsumerStatefulWidget {
  const SocialGiftingScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SocialGiftingScreen> createState() => _SocialGiftingScreenState();
}

class _SocialGiftingScreenState extends ConsumerState<SocialGiftingScreen> {
  final TextEditingController _queryController = TextEditingController();
  String? _selectedRecipientLabel;
  int? _selectedRecipientUserId;
  String _lessonType = 'premium';
  bool _isSending = false;

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gamification = ref.watch(gamificationProvider.notifier).gamification;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: const [
            Text('Send a Lesson'),
            SizedBox(width: 8),
            Text(
              'beta',
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
            ),
          ],
        ),
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
                    controller: _queryController,
                    decoration: const InputDecoration(
                      labelText: 'Friend\'s Username or Email',
                      hintText: 'Enter username or email',
                      prefixIcon: Icon(Icons.person),
                    ),
                  ),
                  if (_selectedRecipientLabel != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Selected: $_selectedRecipientLabel',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
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
                    value: _lessonType,
                    onChanged: _isSending
                        ? null
                        : (value) {
                            if (value == null) return;
                            setState(() => _lessonType = value);
                          },
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: !_isSending && gamification.cowries >= 50
                          ? () {
                              _showGiftConfirmation(context, ref);
                            }
                          : null,
                      child: Text(_isSending ? 'Sending…' : 'Send Gift'),
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
              Navigator.pop(context);
              await _sendGift(ref);

              if (context.mounted) {
                // snack shown inside _sendGift
              }
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  Future<void> _sendGift(WidgetRef ref) async {
    if (_isSending) return;

    final query = _queryController.text.trim();
    if (query.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a username, @handle, or email.')),
      );
      return;
    }

    setState(() => _isSending = true);
    try {
      final api = ref.read(apiProvider.notifier);

      // Resolve recipient (reuse backend lookup; avoids duplicating matching logic on mobile)
      final results = await api.lookupUsers(query);
      if (results.isEmpty) {
        throw Exception('No user found for "$query". Try their @handle.');
      }

      // If multiple results returned, take the first exact-ish match.
      final recipient = results.first;
      final recipientId = (recipient['id'] as num?)?.toInt();
      if (recipientId == null) {
        throw Exception('Invalid recipient user id.');
      }

      setState(() {
        _selectedRecipientUserId = recipientId;
        _selectedRecipientLabel = recipient['username']?.toString() ??
            recipient['global_id']?.toString() ??
            recipient['email']?.toString();
      });

      // 1) Transfer cowries (server-authoritative)
      final transferred = await api.transferCowries(
        recipientUserId: recipientId,
        amount: 50,
      );
      if (!transferred) {
        throw Exception('Transfer failed. Please try again.');
      }

      // 2) Create ancestry gift edge (best-effort)
      await api.createGiftLink(recipientUserId: recipientId);

      // 3) Update local UI state (best-effort)
      await ref.read(gamificationProvider.notifier).awardXP('send_gift');

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gift sent to ${_selectedRecipientLabel ?? 'friend'}!'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gift failed: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
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

