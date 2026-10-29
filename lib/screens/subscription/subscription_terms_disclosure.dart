import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lingafriq/config/url_constants.dart';
import 'package:lingafriq/l10n/generated/app_localizations.dart';
import 'package:lingafriq/models/revenuecat_mapping.dart';
import 'package:lingafriq/providers/subscription_provider.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

/// Store prices shown in the auto-renewal disclosure.
@immutable
class StorePrices {
  const StorePrices({
    required this.premium,
    required this.family,
    required this.lifetime,
    this.trialDays,
  });

  /// Used until (or if) RevenueCat offerings load. Matches the catalogue.
  static const fallback = StorePrices(
    premium: r'$4.99',
    family: r'$9.99',
    lifetime: r'$99.99',
  );

  final String premium;
  final String family;
  final String lifetime;

  /// Free-trial length on the Premium package, when the store offers one.
  final int? trialDays;

  static int? _trialDays(IntroductoryPrice? intro) {
    if (intro == null || intro.price > 0) return null;
    final n = intro.periodNumberOfUnits * intro.cycles;
    return switch (intro.periodUnit) {
      PeriodUnit.day => n,
      PeriodUnit.week => n * 7,
      PeriodUnit.month => n * 30,
      PeriodUnit.year => n * 365,
      _ => null,
    };
  }

  /// Localised store prices from RevenueCat packages, per-field fallback.
  static StorePrices fromPackages({
    Package? premium,
    Package? family,
    Package? lifetime,
  }) => StorePrices(
    premium: premium?.storeProduct.priceString ?? fallback.premium,
    family: family?.storeProduct.priceString ?? fallback.family,
    lifetime: lifetime?.storeProduct.priceString ?? fallback.lifetime,
    trialDays: _trialDays(premium?.storeProduct.introductoryPrice),
  );
}

final storePricesProvider = FutureProvider<StorePrices>((ref) async {
  try {
    final rc = ref.watch(revenueCatServiceProvider);
    final offerings = await rc.getOfferings();
    if (offerings == null) return StorePrices.fallback;
    return StorePrices.fromPackages(
      premium: rc.packageForTier(offerings, RevenueCatTier.premium),
      family: rc.packageForTier(offerings, RevenueCatTier.family),
      lifetime: rc.packageForTier(offerings, RevenueCatTier.lifetime),
    );
  } catch (_) {
    return StorePrices.fallback;
  }
});

/// Auto-renewal disclosure shown beside the paywall CTAs (Cal. BPC §17602,
/// ROSCA, Apple 3.1.2, Play subscriptions policy). One global wording.
class SubscriptionTermsDisclosure extends ConsumerWidget {
  const SubscriptionTermsDisclosure({super.key, this.renewsOn, this.isApple});

  /// Next renewal date of the active auto-renewing plan, if any.
  final DateTime? renewsOn;

  /// Overrides platform detection (tests).
  final bool? isApple;

  static const appleManageUrl = 'https://apps.apple.com/account/subscriptions';
  static const playManageUrl =
      'https://play.google.com/store/account/subscriptions';

  /// First-strong isolate so prices / store names keep their own direction
  /// inside RTL sentences.
  static String _iso(String s) => '\u2068$s\u2069';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final apple = isApple ?? defaultTargetPlatform == TargetPlatform.iOS;
    final prices = ref.watch(storePricesProvider).value ?? StorePrices.fallback;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final body = theme.textTheme.bodyMedium;

    return Container(
      key: const ValueKey('subscription-terms'),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(
              l.paywallTermsTitle,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 8),
          _TermRow(
            key: const ValueKey('row-price'),
            label: l.paywallRowPrice,
            values: [
              l.paywallPriceValue(
                _iso(prices.premium),
                _iso(prices.family),
                _iso(prices.lifetime),
              ),
              l.paywallChargedTo(_iso(apple ? 'App Store' : 'Google Play')),
            ],
          ),
          _TermRow(
            key: const ValueKey('row-renews'),
            label: l.paywallRowRenews,
            values: [
              if (renewsOn != null)
                l.paywallRenewsOn(DateFormat.yMMMd(locale).format(renewsOn!)),
              l.paywallRenewsAuto,
            ],
            emphasiseFirst: renewsOn != null,
          ),
          _TermRow(
            key: const ValueKey('row-trial'),
            label: l.paywallRowTrial,
            values: [
              prices.trialDays != null
                  ? l.paywallTrialOffered(
                      prices.trialDays!,
                      _iso(prices.premium),
                    )
                  : l.paywallTrialGeneric,
            ],
          ),
          _TermRow(
            key: const ValueKey('how-to-cancel'),
            label: l.paywallRowCancel,
            values: [
              apple ? l.paywallCancelApple : l.paywallCancelGoogle,
              l.paywallFreeStays,
            ],
            divider: false,
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            key: const ValueKey('manage-subscription'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
            icon: const Icon(Icons.open_in_new_rounded, size: 18),
            onPressed: () => launchUrl(
              Uri.parse(apple ? appleManageUrl : playManageUrl),
              mode: LaunchMode.externalApplication,
            ),
            label: Text(l.paywallManage, textAlign: TextAlign.center),
          ),
          // Each link is one tap target that moves as a unit: no orphaned
          // words when the row wraps at 320 dp / 200 % text.
          Wrap(
            alignment: WrapAlignment.center,
            children: [
              TextButton(
                key: const ValueKey('terms-link'),
                style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
                onPressed: () => launchUrl(Uri.parse(UrlConstants.termsUrl)),
                child: Text(l.paywallTerms, style: body),
              ),
              TextButton(
                key: const ValueKey('privacy-link'),
                style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
                onPressed: () => launchUrl(Uri.parse(UrlConstants.privacyUrl)),
                child: Text(l.paywallPrivacy, style: body),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TermRow extends StatelessWidget {
  const _TermRow({
    super.key,
    required this.label,
    required this.values,
    this.emphasiseFirst = false,
    this.divider = true,
  });

  final String label;
  final List<String> values;
  final bool emphasiseFirst;
  final bool divider;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final labelText = Text(
      label,
      style: theme.textTheme.labelLarge?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.w700,
      ),
    );
    final valueText = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (i, v) in values.indexed)
          Padding(
            padding: EdgeInsets.only(top: i == 0 ? 0 : 4),
            child: Text(
              v,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: i == 0 && emphasiseFirst ? FontWeight.w700 : null,
              ),
            ),
          ),
      ],
    );
    return Semantics(
      container: true,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: divider
            ? BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: theme.colorScheme.outlineVariant),
                ),
              )
            : null,
        child: LayoutBuilder(
          builder: (context, c) {
            final scale = MediaQuery.textScalerOf(context).scale(1);
            // Side-by-side when there is room; stacked at large text / narrow.
            if (c.maxWidth >= 300 && scale < 1.3) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: 88, child: labelText),
                  const SizedBox(width: 12),
                  Expanded(child: valueText),
                ],
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [labelText, const SizedBox(height: 4), valueText],
            );
          },
        ),
      ),
    );
  }
}
