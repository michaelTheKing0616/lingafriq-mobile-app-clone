import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import '../../providers/gamification_provider.dart';
import '../../providers/user_provider.dart';
import '../../utils/error_handler.dart';
import '../../utils/pan_african_design_system.dart';
import '../../utils/api_service.dart';
import '../../config/api_contract.dart';

/// Social Gifting Screen - Send lessons to friends
class SocialGiftingScreen extends HookConsumerWidget {
  const SocialGiftingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gamification = ref.watch(gamificationProvider.notifier).gamification;
    final receiverController = useTextEditingController();
    final selectedGiftType = useState<String?>('premium');
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: isDark ? PanAfricanColors.backgroundDark : PanAfricanColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Send a Lesson'),
        backgroundColor: isDark ? PanAfricanColors.surfaceContainerDark : PanAfricanColors.surfaceContainerLight,
        foregroundColor: isDark ? PanAfricanColors.textPrimaryDark : PanAfricanColors.textPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.of(context).pop();
          },
        ),
      ),
      body: ListView(
        padding: EdgeInsets.all(PanAfricanSpacing.md),
        children: [
          // Header card
          Container(
            padding: EdgeInsets.all(PanAfricanSpacing.md),
            decoration: BoxDecoration(
              color: isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight,
              borderRadius: PanAfricanRadius.lgBR,
              boxShadow: PanAfricanShadows.sm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(PanAfricanSpacing.sm),
                      decoration: BoxDecoration(
                        color: PanAfricanColors.primary.withOpacity(0.1),
                        borderRadius: PanAfricanRadius.mdBR,
                      ),
                      child: Icon(Icons.card_giftcard, color: PanAfricanColors.primary, size: 24.sp),
                    ),
                    SizedBox(width: PanAfricanSpacing.sm),
                    Expanded(
                      child: Text(
                        'Gift a Lesson',
                        style: PanAfricanTypography.titleLarge(context).copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: PanAfricanSpacing.sm),
                Text(
                  'Share the gift of learning! Send a premium lesson to a friend. '
                  'They\'ll receive it instantly and you\'ll both earn rewards.',
                  style: PanAfricanTypography.bodyMedium(context),
                ),
              ],
            ),
          ),
          SizedBox(height: PanAfricanSpacing.md),
          // Currency display
          Container(
            padding: EdgeInsets.all(PanAfricanSpacing.md),
            decoration: BoxDecoration(
              gradient: PanAfricanGradients.kente,
              borderRadius: PanAfricanRadius.lgBR,
              boxShadow: PanAfricanShadows.sm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Cowries',
                  style: PanAfricanTypography.titleMedium(context).copyWith(
                    color: colorScheme.onPrimary,
                  ),
                ),
                SizedBox(height: PanAfricanSpacing.sm),
                Row(
                  children: [
                    Text('🐚', style: TextStyle(fontSize: 32.sp)),
                    SizedBox(width: PanAfricanSpacing.sm),
                    Text(
                      '${gamification.cowries}',
                      style: PanAfricanTypography.headlineLarge(context).copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onPrimary,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: PanAfricanSpacing.xs),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: PanAfricanSpacing.sm,
                    vertical: PanAfricanSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.onPrimary.withOpacity(0.2),
                    borderRadius: PanAfricanRadius.roundBR,
                  ),
                  child: Text(
                    'Cost: 50 Cowries per lesson',
                    style: PanAfricanTypography.labelLarge(context).copyWith(
                      color: colorScheme.onPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: PanAfricanSpacing.md),
          // Gift form
          Container(
            padding: EdgeInsets.all(PanAfricanSpacing.md),
            decoration: BoxDecoration(
              color: isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight,
              borderRadius: PanAfricanRadius.lgBR,
              boxShadow: PanAfricanShadows.sm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Send Gift',
                  style: PanAfricanTypography.titleMedium(context).copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: PanAfricanSpacing.md),
                TextField(
                  controller: receiverController,
                  decoration: InputDecoration(
                    labelText: 'Friend\'s Username or Email',
                    hintText: 'Enter username or email',
                    prefixIcon: Icon(Icons.person, color: PanAfricanColors.primary),
                    border: OutlineInputBorder(
                      borderRadius: PanAfricanRadius.mdBR,
                    ),
                    contentPadding: EdgeInsets.all(PanAfricanSpacing.md),
                  ),
                ),
                SizedBox(height: PanAfricanSpacing.md),
                DropdownButtonFormField<String>(
                  value: selectedGiftType.value,
                  decoration: InputDecoration(
                    labelText: 'Gift Type',
                    prefixIcon: Icon(Icons.school, color: PanAfricanColors.primary),
                    border: OutlineInputBorder(
                      borderRadius: PanAfricanRadius.mdBR,
                    ),
                    contentPadding: EdgeInsets.all(PanAfricanSpacing.md),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'lesson_pack', child: Text('Lesson Pack')),
                    DropdownMenuItem(value: 'hearts', child: Text('Hearts')),
                    DropdownMenuItem(value: 'xp_boost', child: Text('XP Boost')),
                    DropdownMenuItem(value: 'streak_freeze', child: Text('Streak Freeze')),
                  ],
                  onChanged: (value) {
                    selectedGiftType.value = value;
                  },
                ),
                SizedBox(height: PanAfricanSpacing.lg),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: PanAfricanColors.primary,
                      padding: EdgeInsets.symmetric(vertical: PanAfricanSpacing.md),
                      shape: RoundedRectangleBorder(
                        borderRadius: PanAfricanRadius.lgBR,
                      ),
                    ),
                    onPressed: gamification.cowries >= 50 && receiverController.text.isNotEmpty && selectedGiftType.value != null
                        ? () {
                            HapticFeedback.mediumImpact();
                            _showGiftConfirmation(context, ref, receiverController.text, selectedGiftType.value!);
                          }
                        : null,
                    child: Text(
                      'Send Gift',
                      style: PanAfricanTypography.titleMedium(context).copyWith(
                        color: colorScheme.onPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: PanAfricanSpacing.md),
          // Benefits
          Container(
            padding: EdgeInsets.all(PanAfricanSpacing.md),
            decoration: BoxDecoration(
              color: isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight,
              borderRadius: PanAfricanRadius.lgBR,
              boxShadow: PanAfricanShadows.sm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Benefits',
                  style: PanAfricanTypography.titleMedium(context).copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: PanAfricanSpacing.sm),
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
        ],
      ),
    );
  }

  void _showGiftConfirmation(BuildContext context, WidgetRef ref, String receiverId, String giftType) {
    final giftCosts = {
      'hearts': 50,
      'xp_boost': 100,
      'lesson_pack': 200,
      'streak_freeze': 150,
    };
    final cost = giftCosts[giftType] ?? 50;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Gift'),
        content: Text(
          'Send ${giftType.replaceAll('_', ' ')} to $receiverId? It will cost $cost Cowries.',
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

                // Send gift via API
                final response = await ApiService.post(
                  ApiContract.url('/api/social/gift'),
                  data: {
                    'receiverId': receiverId,
                    'giftType': giftType,
                    'amount': 1,
                  },
                );

                if (response.statusCode == 200 || response.statusCode == 201) {
                  // Refresh gamification to update cowries
                  await gamification.refreshGamification();
                  
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Gift sent successfully!')),
                    );
                  }
                } else {
                  throw Exception('Failed to send gift: ${response.data?['error'] ?? 'Unknown error'}');
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context);
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
      padding: EdgeInsets.only(bottom: PanAfricanSpacing.sm),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(PanAfricanSpacing.xs),
            decoration: BoxDecoration(
              color: PanAfricanColors.primary.withOpacity(0.1),
              borderRadius: PanAfricanRadius.smBR,
            ),
            child: Icon(icon, size: 18.sp, color: PanAfricanColors.primary),
          ),
          SizedBox(width: PanAfricanSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: PanAfricanTypography.bodyMedium(context),
            ),
          ),
        ],
      ),
    );
  }
}

