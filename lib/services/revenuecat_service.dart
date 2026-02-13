import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:lingafriq/config/secrets_manager.dart';
import 'package:lingafriq/models/revenuecat_mapping.dart';
import 'package:lingafriq/utils/structured_logger.dart' hide LogLevel;

class RevenueCatService {
  bool _configured = false;
  String? _currentAppUserId;

  bool get isConfigured => _configured;

  Future<void> initialize({String? appUserId}) async {
    if (_configured && _currentAppUserId == appUserId) return;

    final secrets = SecretsManager();
    await secrets.initialize();

    final apiKey = Platform.isIOS
        ? secrets.getSecret('REVENUECAT_API_KEY_IOS')
        : secrets.getSecret('REVENUECAT_API_KEY_ANDROID');

    if (apiKey == null || apiKey.isEmpty) {
      logger.warn('RevenueCat API key missing', tag: 'revenuecat');
      return;
    }

    try {
      await Purchases.setLogLevel(kDebugMode ? LogLevel.debug : LogLevel.warn);
      final configuration = PurchasesConfiguration(apiKey)
        ..appUserID = appUserId;
      await Purchases.configure(configuration);

      if (appUserId != null && appUserId.isNotEmpty) {
        await Purchases.logIn(appUserId);
      }

      _configured = true;
      _currentAppUserId = appUserId;
    } catch (e) {
      logger.error('Failed to initialize RevenueCat', tag: 'revenuecat', error: e);
    }
  }

  Future<CustomerInfo?> getCustomerInfo() async {
    if (!_configured) return null;
    try {
      return await Purchases.getCustomerInfo();
    } catch (e) {
      logger.error('Failed to fetch RevenueCat customer info', tag: 'revenuecat', error: e);
      return null;
    }
  }

  Future<Offerings?> getOfferings() async {
    if (!_configured) return null;
    try {
      return await Purchases.getOfferings();
    } catch (e) {
      logger.error('Failed to fetch RevenueCat offerings', tag: 'revenuecat', error: e);
      return null;
    }
  }

  RevenueCatTier tierFromCustomerInfo(CustomerInfo info) {
    final entitlements = info.entitlements.active;
    if (entitlements.containsKey(RevenueCatEntitlements.lifetime)) {
      return RevenueCatTier.lifetime;
    }
    if (entitlements.containsKey(RevenueCatEntitlements.family)) {
      return RevenueCatTier.family;
    }
    if (entitlements.containsKey(RevenueCatEntitlements.premium)) {
      return RevenueCatTier.premium;
    }
    return RevenueCatTier.free;
  }

  Package? packageForTier(Offerings offerings, RevenueCatTier tier) {
    final packages = offerings.current?.availablePackages ?? [];
    if (packages.isEmpty) return null;

    final preferredIds = _productIdsForTier(tier);
    for (final id in preferredIds) {
      final match = packages.firstWhere(
        (p) => p.storeProduct.identifier == id,
        orElse: () => packages.first,
      );
      if (match.storeProduct.identifier == id) return match;
    }

    return null;
  }

  Future<CustomerInfo?> purchaseTier(RevenueCatTier tier) async {
    if (!_configured) return null;
    try {
      final offerings = await getOfferings();
      if (offerings == null) return null;

      final package = packageForTier(offerings, tier);
      if (package == null) {
        logger.warn('RevenueCat package not found', tag: 'revenuecat');
        return null;
      }

      final result = await Purchases.purchasePackage(package);
      return result.customerInfo;
    } catch (e) {
      logger.error('RevenueCat purchase failed', tag: 'revenuecat', error: e);
      return null;
    }
  }

  Future<CustomerInfo?> restorePurchases() async {
    if (!_configured) return null;
    try {
      return await Purchases.restorePurchases();
    } catch (e) {
      logger.error('RevenueCat restore failed', tag: 'revenuecat', error: e);
      return null;
    }
  }

  List<String> _productIdsForTier(RevenueCatTier tier) {
    switch (tier) {
      case RevenueCatTier.premium:
        return [
          RevenueCatProductIds.premiumMonthly,
          RevenueCatProductIds.premiumAnnual,
        ];
      case RevenueCatTier.family:
        return [
          RevenueCatProductIds.familyMonthly,
          RevenueCatProductIds.familyAnnual,
        ];
      case RevenueCatTier.lifetime:
        return [
          RevenueCatProductIds.lifetime,
        ];
      case RevenueCatTier.free:
        return const [];
    }
  }
}
