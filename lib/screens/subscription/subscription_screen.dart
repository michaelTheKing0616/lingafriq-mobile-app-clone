import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/providers/subscription_provider.dart';
import 'package:lingafriq/utils/african_theme.dart';
import 'package:lingafriq/utils/design_system.dart';
import 'package:lingafriq/widgets/animated/animated_button.dart';
import 'package:lingafriq/widgets/animated/animated_card.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Subscription screen with tier selection
class SubscriptionScreen extends ConsumerWidget {
  const SubscriptionScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscription = ref.watch(subscriptionProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Subscription'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Choose Your Plan',
              style: TextStyle(
                fontSize: 28.sp,
                fontWeight: FontWeight.bold,
              ),
            )
                .animate()
                .fadeIn(duration: 300.ms)
                .slideX(begin: -0.1),
            SizedBox(height: 8.h),
            Text(
              'Unlock all features and accelerate your learning',
              style: TextStyle(
                fontSize: 16.sp,
                color: Colors.grey[600],
              ),
            )
                .animate()
                .fadeIn(delay: 100.ms),
            SizedBox(height: 24.h),
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
              onTap: () {},
            ),
            SizedBox(height: 16.h),
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
                ref.read(subscriptionProvider.notifier).subscribe(SubscriptionTier.premium);
              },
            ),
            SizedBox(height: 16.h),
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
                ref.read(subscriptionProvider.notifier).subscribe(SubscriptionTier.family);
              },
            ),
            SizedBox(height: 16.h),
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
    return AnimatedCard(
      elevation: isRecommended ? 6 : 2,
      color: isRecommended
          ? AfricanTheme.primaryGreen.withOpacity(0.05)
          : null,
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isRecommended)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AfricanTheme.primaryGreen,
                        AfricanTheme.accentGold,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(DesignSystem.radiusRound),
                  ),
                  child: Text(
                    'RECOMMENDED',
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                )
                    .animate()
                    .scale(delay: 200.ms, duration: 300.ms),
              SizedBox(height: isRecommended ? 12.h : 0),
              Row(
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 24.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        price,
                        style: TextStyle(
                          fontSize: 28.sp,
                          fontWeight: FontWeight.bold,
                          color: AfricanTheme.primaryGreen,
                        ),
                      ),
                      Text(
                        period,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 20.h),
              ...features.map((feature) => Padding(
                    padding: EdgeInsets.only(bottom: 12.h),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle_rounded,
                          color: AfricanTheme.primaryGreen,
                          size: 20.sp,
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Text(
                            feature,
                            style: TextStyle(fontSize: 14.sp),
                          ),
                        ),
                      ],
                    ),
                  )),
              SizedBox(height: 20.h),
              AnimatedButton(
                text: isCurrent ? 'Current Plan' : 'Subscribe',
                onPressed: isCurrent ? null : onTap,
                backgroundColor: isRecommended
                    ? AfricanTheme.primaryGreen
                    : AfricanTheme.accentGold,
              ),
            ],
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.1, end: 0, duration: 400.ms);
  }
}

