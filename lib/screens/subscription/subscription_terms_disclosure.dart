import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lingafriq/config/url_constants.dart';
import 'package:url_launcher/url_launcher.dart';

/// Auto-renewal disclosure shown beside the paywall CTAs (Cal. BPC §17602,
/// ROSCA, Apple 3.1.2, Play subscriptions policy). One global wording.
class SubscriptionTermsDisclosure extends StatelessWidget {
  const SubscriptionTermsDisclosure({super.key, this.renewsOn, this.isApple});

  /// Next renewal date of the active auto-renewing plan, if any.
  final DateTime? renewsOn;

  /// Overrides platform detection (tests).
  final bool? isApple;

  static const appleManageUrl = 'https://apps.apple.com/account/subscriptions';
  static const playManageUrl =
      'https://play.google.com/store/account/subscriptions';

  static String formatDate(DateTime d) {
    const m = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${d.day} ${m[d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final apple = isApple ?? defaultTargetPlatform == TargetPlatform.iOS;
    final store = apple ? 'App Store' : 'Google Play';
    final settings = apple
        ? 'Settings > your name > Subscriptions'
        : 'Google Play > Profile > Payments & subscriptions > Subscriptions';
    final style = Theme.of(context).textTheme.bodySmall;
    return Column(
      key: const ValueKey('subscription-terms'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (renewsOn != null)
          Text(
            'Your plan renews automatically on ${formatDate(renewsOn!)}.',
            key: const ValueKey('renewal-date'),
            style: style?.copyWith(fontWeight: FontWeight.w600),
          ),
        Text(
          'Premium (\$4.99/month) and Family (\$9.99/month) renew '
          'automatically each month at that price until you cancel. '
          'Payment is charged to your $store account. If a free trial is '
          'offered, you will be charged the plan price when the trial ends '
          'unless you cancel at least 24 hours before it ends. Lifetime is '
          'a one-time payment and does not renew.',
          style: style,
        ),
        const SizedBox(height: 4),
        Text(
          'Cancel any time in $settings. Cancelling stops the next renewal; '
          'you keep access until the end of the paid period. Free features '
          'stay available.',
          key: const ValueKey('how-to-cancel'),
          style: style,
        ),
        Wrap(
          spacing: 4,
          children: [
            TextButton(
              key: const ValueKey('manage-subscription'),
              onPressed: () => launchUrl(
                Uri.parse(apple ? appleManageUrl : playManageUrl),
                mode: LaunchMode.externalApplication,
              ),
              child: const Text('Manage or cancel subscription'),
            ),
            TextButton(
              onPressed: () => launchUrl(Uri.parse(UrlConstants.termsUrl)),
              child: const Text('Terms'),
            ),
            TextButton(
              onPressed: () => launchUrl(Uri.parse(UrlConstants.privacyUrl)),
              child: const Text('Privacy'),
            ),
          ],
        ),
      ],
    );
  }
}
