/// RevenueCat product and entitlement mapping.
///
/// Keep these values in sync with RevenueCat dashboard.
/// Do not log the values. These are identifiers, not secrets.
class RevenueCatEntitlements {
  RevenueCatEntitlements._();

  static const String premium = 'premium';
  static const String family = 'family';
  static const String lifetime = 'lifetime';
}

class RevenueCatProductIds {
  RevenueCatProductIds._();

  // Premium
  static const String premiumMonthly = 'lingafriq_premium_monthly';
  static const String premiumAnnual = 'lingafriq_premium_annual';

  // Family
  static const String familyMonthly = 'lingafriq_family_monthly';
  static const String familyAnnual = 'lingafriq_family_annual';

  // Lifetime
  static const String lifetime = 'lingafriq_lifetime';
}

enum RevenueCatTier {
  free,
  premium,
  family,
  lifetime,
}
