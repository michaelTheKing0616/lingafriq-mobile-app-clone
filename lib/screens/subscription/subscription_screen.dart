import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lingafriq/providers/subscription_provider.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:lingafriq/utils/error_handler.dart';
import 'package:lingafriq/utils/integration_helpers.dart';
import 'package:lingafriq/widgets/animated/animated_button.dart';
import 'package:lingafriq/widgets/animated/animated_card.dart';

/// Subscription screen with tier selection
class SubscriptionScreen extends ConsumerWidget {
  const SubscriptionScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscription = ref.watch(subscriptionProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? PanAfricanColors.surfaceDark : PanAfricanColors.surfaceLight,
      appBar: AppBar(
        title: Text('Subscription', style: PanAfricanTypography.titleLarge(context)),
        backgroundColor: isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight,
        foregroundColor: isDark ? PanAfricanColors.textPrimaryDark : PanAfricanColors.textPrimaryLight,
        leading: IconButton(
          icon: Icon(PanAfricanIcons.back),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.of(context).pop();
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(PanAfricanSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Choose Your Plan',
              style: PanAfricanTypography.headlineMedium(context),
            )
                .animate()
                .fadeIn(duration: 300.ms)
                .slideX(begin: -0.1),
            SizedBox(height: PanAfricanSpacing.xs),
            Text(
              'Unlock all features and accelerate your learning',
              style: PanAfricanTypography.bodyMedium(context, color: isDark ? PanAfricanColors.textSecondaryDark : PanAfricanColors.textSecondaryLight),
            )
                .animate()
                .fadeIn(delay: 100.ms),
            SizedBox(height: PanAfricanSpacing.lg),
            _buildTierCard(
              context: context,
              tier: SubscriptionTier.free,
              title: 'Free',
              price: '\$0',
              period: 'Forever',
              features: const [
                '10 core games',
                '50 AI messages/day',
                'Basic progress tracking',
                'Ads',
              ],
              isCurrent: subscription.tier == SubscriptionTier.free,
              onTap: () {
                HapticFeedback.mediumImpact();
                ref.read(subscriptionProvider.notifier).subscribe(SubscriptionTier.free);
              },
            ),
            SizedBox(height: PanAfricanSpacing.md),
            _buildTierCard(
              context: context,
              tier: SubscriptionTier.premium,
              title: 'Premium',
              price: '\$4.99',
              period: 'per month',
              features: const [
                'All 35 games',
                'Unlimited AI chat',
                'Advanced progress tracking',
                'Offline mode',
                'Pronunciation scoring',
                'No ads',
              ],
              isCurrent: subscription.tier == SubscriptionTier.premium,
              isRecommended: true,
              onTap: () {
                HapticFeedback.mediumImpact();
                ref.read(subscriptionProvider.notifier).subscribe(SubscriptionTier.premium);
              },
            ),
            SizedBox(height: PanAfricanSpacing.md),
            _buildTierCard(
              context: context,
              tier: SubscriptionTier.family,
              title: 'Family',
              price: '\$9.99',
              period: 'per month (4 users)',
              features: const [
                'Everything in Premium',
                '4 user accounts',
                'Family progress tracking',
                'Family challenges',
                'Priority support',
              ],
              isCurrent: subscription.tier == SubscriptionTier.family,
              onTap: () {
                HapticFeedback.mediumImpact();
                ref.read(subscriptionProvider.notifier).subscribe(SubscriptionTier.family);
              },
            ),
            SizedBox(height: PanAfricanSpacing.md),
            _buildTierCard(
              context: context,
              tier: SubscriptionTier.lifetime,
              title: 'Lifetime',
              price: '\$99.99',
              period: 'one-time',
              features: const [
                'Everything in Premium',
                'Lifetime access',
                'All future updates',
                'Early access to features',
                'Exclusive content',
              ],
              isCurrent: subscription.tier == SubscriptionTier.lifetime,
              onTap: () {
                HapticFeedback.mediumImpact();
                ref.read(subscriptionProvider.notifier).subscribe(SubscriptionTier.lifetime);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTierCard({
    required BuildContext context,
    required SubscriptionTier tier,
    required String title,
    required String price,
    required String period,
    required List<String> features,
    required bool isCurrent,
    required VoidCallback onTap,
    bool isRecommended = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isRecommended
            ? PanAfricanColors.primary.withOpacity(0.05)
            : (isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight),
        borderRadius: PanAfricanRadius.lgBR,
        boxShadow: isRecommended ? PanAfricanShadows.md : PanAfricanShadows.sm,
        border: isRecommended ? Border.all(color: PanAfricanColors.primary.withOpacity(0.3), width: 2) : null,
      ),
      child: Padding(
        padding: EdgeInsets.all(PanAfricanSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isRecommended)
              Container(
                padding: EdgeInsets.symmetric(horizontal: PanAfricanSpacing.sm, vertical: PanAfricanSpacing.xxs),
                decoration: BoxDecoration(
                  gradient: PanAfricanGradients.forest,
                  borderRadius: PanAfricanRadius.roundBR,
                ),
                child: Text(
                  'RECOMMENDED',
                  style: PanAfricanTypography.labelSmall(context, color: Colors.white),
                ),
              )
                  .animate()
                  .scale(delay: 200.ms, duration: 300.ms),
            SizedBox(height: isRecommended ? PanAfricanSpacing.sm : 0),
            Row(
              children: [
                Text(
                  title,
                  style: PanAfricanTypography.headlineSmall(context),
                ),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      price,
                      style: PanAfricanTypography.headlineMedium(context, color: PanAfricanColors.primary),
                    ),
                    Text(
                      period,
                      style: PanAfricanTypography.labelSmall(context),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: PanAfricanSpacing.lg),
            ...features.map((feature) => Padding(
                  padding: EdgeInsets.only(bottom: PanAfricanSpacing.sm),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        color: PanAfricanColors.success,
                        size: 20.sp,
                      ),
                      SizedBox(width: PanAfricanSpacing.sm),
                      Expanded(
                        child: Text(
                          feature,
                          style: PanAfricanTypography.bodyMedium(context),
                        ),
                      ),
                    ],
                  ),
                )),
            SizedBox(height: PanAfricanSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: isCurrent ? null : onTap,
                style: FilledButton.styleFrom(
                  backgroundColor: isRecommended ? PanAfricanColors.primary : PanAfricanColors.secondary,
                  foregroundColor: isRecommended ? Colors.white : PanAfricanColors.textPrimaryLight,
                  padding: EdgeInsets.symmetric(vertical: PanAfricanSpacing.sm),
                  shape: RoundedRectangleBorder(borderRadius: PanAfricanRadius.lgBR),
                ),
                child: Text(isCurrent ? 'Current Plan' : 'Subscribe', style: PanAfricanTypography.labelLarge(context, color: isRecommended ? Colors.white : PanAfricanColors.textPrimaryLight)),
              ),
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.1, end: 0, duration: 400.ms);
  }
}

