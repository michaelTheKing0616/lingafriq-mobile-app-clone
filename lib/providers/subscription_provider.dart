import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dio_provider.dart';
import 'user_provider.dart';
import '../models/revenuecat_mapping.dart';
import '../services/revenuecat_service.dart';
import 'package:lingafriq/config/api_contract.dart';
import '../utils/structured_logger.dart';

/// Subscription tier provider with backend integration
class SubscriptionNotifier extends Notifier<SubscriptionState> {
  static const bool _overrideAllAccess = true;
  static const SubscriptionTier _overrideTier = SubscriptionTier.premium;

  bool get isOverrideActive => _overrideAllAccess;

  @override
  SubscriptionState build() {
    // Load subscription status asynchronously
    Future.microtask(() => _loadSubscriptionStatus());
    if (_overrideAllAccess) {
      return SubscriptionState(
        tier: _overrideTier,
        isActive: true,
        expiresAt: null,
      );
    }
    return SubscriptionState(
      tier: SubscriptionTier.free,
      isActive: false,
      expiresAt: null,
    );
  }
  
  /// Load subscription status from backend and local storage
  Future<void> _loadSubscriptionStatus() async {
    if (_overrideAllAccess) {
      state = SubscriptionState(
        tier: _overrideTier,
        isActive: true,
        expiresAt: null,
      );
      return;
    }

    try {
      final fromRevenueCat = await _loadFromRevenueCat();
      if (fromRevenueCat) return;

      // Try to load from backend first
      final user = ref.read(userProvider);
      if (user != null) {
        final response = await ref.read(client).get(
          ApiContract.url(ApiContract.subscriptions.status),
        );
        
        if (response.statusCode == 200 && response.data is Map) {
          final data = response.data as Map<String, dynamic>;
          final tierStr = data['tier']?.toString().toLowerCase() ?? 'free';
          final tier = _parseTier(tierStr);
          final isActive = data['is_active'] as bool? ?? false;
          final expiresAtStr = data['expires_at']?.toString();
          
          final subscriptionState = SubscriptionState(
            tier: tier,
            isActive: isActive,
            expiresAt: expiresAtStr != null ? DateTime.parse(expiresAtStr) : null,
          );
          
          state = subscriptionState;
          await _saveSubscriptionStatus(subscriptionState);
          return;
        }
      }
      
      // Fallback to local storage
      await _loadFromLocalStorage();
    } catch (e) {
      logger.error('Error loading subscription status', tag: 'subscription', error: e);
      // Fallback to local storage on error
      await _loadFromLocalStorage();
    }
  }
  
  /// Load subscription status from local storage
  Future<void> _loadFromLocalStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final statusJson = prefs.getString('subscription_status');
      if (statusJson != null) {
        final data = jsonDecode(statusJson) as Map<String, dynamic>;
        final tierStr = data['tier']?.toString().toLowerCase() ?? 'free';
        final tier = _parseTier(tierStr);
        final isActive = data['is_active'] as bool? ?? false;
        final expiresAtStr = data['expires_at']?.toString();
        
        state = SubscriptionState(
          tier: tier,
          isActive: isActive && (expiresAtStr == null || DateTime.parse(expiresAtStr).isAfter(DateTime.now())),
          expiresAt: expiresAtStr != null ? DateTime.parse(expiresAtStr) : null,
        );
      }
    } catch (e) {
      logger.error('Error loading subscription from local storage', tag: 'subscription', error: e);
      // Keep default free tier
    }
  }

  Future<bool> _loadFromRevenueCat() async {
    final revenueCat = ref.read(revenueCatServiceProvider);
    final user = ref.read(userProvider);

    await revenueCat.initialize(appUserId: user?.id.toString());
    if (!revenueCat.isConfigured) return false;

    final info = await revenueCat.getCustomerInfo();
    if (info == null) return false;

    final rcTier = revenueCat.tierFromCustomerInfo(info);
    final tier = _mapRevenueCatTier(rcTier);
    final expiresAt = _getRevenueCatExpiration(info, rcTier);
    final isActive = tier != SubscriptionTier.free;

    final subscriptionState = SubscriptionState(
      tier: tier,
      isActive: isActive,
      expiresAt: expiresAt,
    );

    state = subscriptionState;
    await _saveSubscriptionStatus(subscriptionState);
    return true;
  }
  
  /// Save subscription status to local storage
  Future<void> _saveSubscriptionStatus(SubscriptionState status) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('subscription_status', jsonEncode({
        'tier': status.tier.name,
        'is_active': status.isActive,
        'expires_at': status.expiresAt?.toIso8601String(),
      }));
    } catch (e) {
      logger.error('Error saving subscription status', tag: 'subscription', error: e);
    }
  }
  
  /// Parse subscription tier from string
  SubscriptionTier _parseTier(String tierStr) {
    switch (tierStr.toLowerCase()) {
      case 'premium':
        return SubscriptionTier.premium;
      case 'family':
        return SubscriptionTier.family;
      case 'lifetime':
        return SubscriptionTier.lifetime;
      default:
        return SubscriptionTier.free;
    }
  }

  /// Subscribe to a subscription tier
  /// This integrates with backend payment processing
  Future<bool> subscribe(SubscriptionTier tier) async {
    if (_overrideAllAccess) {
      state = SubscriptionState(
        tier: tier,
        isActive: tier != SubscriptionTier.free,
        expiresAt: null,
      );
      await _saveSubscriptionStatus(state);
      return true;
    }

    try {
      if (tier == SubscriptionTier.free) {
        final newState = SubscriptionState(
          tier: SubscriptionTier.free,
          isActive: false,
          expiresAt: null,
        );
        state = newState;
        await _saveSubscriptionStatus(newState);
        return true;
      }

      final user = ref.read(userProvider);
      if (user == null) {
        throw Exception('User must be logged in to subscribe');
      }

      final revenueCat = ref.read(revenueCatServiceProvider);
      await revenueCat.initialize(appUserId: user.id.toString());

      final rcTier = _mapSubscriptionTier(tier);
      final info = await revenueCat.purchaseTier(rcTier);
      if (info == null) return false;

      final resolvedTier = _mapRevenueCatTier(revenueCat.tierFromCustomerInfo(info));
      final expiresAt = _getRevenueCatExpiration(info, rcTier);
      final newState = SubscriptionState(
        tier: resolvedTier,
        isActive: resolvedTier != SubscriptionTier.free,
        expiresAt: expiresAt,
      );
      state = newState;
      await _saveSubscriptionStatus(newState);
      return true;
    } catch (e) {
      logger.error('Error subscribing', tag: 'subscription', error: e);
      // Return false but don't throw - let UI handle the error
      return false;
    }
  }

  /// Cancel current subscription
  Future<bool> cancelSubscription() async {
    if (_overrideAllAccess) {
      state = SubscriptionState(
        tier: SubscriptionTier.free,
        isActive: false,
        expiresAt: null,
      );
      await _saveSubscriptionStatus(state);
      return true;
    }

    try {
      final user = ref.read(userProvider);
      if (user == null) {
        throw Exception('User must be logged in to cancel subscription');
      }

      final revenueCat = ref.read(revenueCatServiceProvider);
      if (revenueCat.isConfigured && state.tier != SubscriptionTier.free) {
        logger.warn('RevenueCat subscriptions must be managed in-store', tag: 'subscription');
        return false;
      }

      // Call backend to cancel subscription
      final response = await ref.read(client).post(
        ApiContract.url(ApiContract.subscriptions.cancel),
        data: {
          'user_id': user.id.toString(),
        },
      );
      
      if (response.statusCode == 200 || response.statusCode == 204) {
        final newState = SubscriptionState(
          tier: SubscriptionTier.free,
          isActive: false,
          expiresAt: state.expiresAt, // Keep expiration date but mark as inactive
        );
        
        state = newState;
        await _saveSubscriptionStatus(newState);
        return true;
      } else {
        throw Exception('Cancellation failed: ${response.statusCode}');
      }
    } catch (e) {
      logger.error('Error canceling subscription', tag: 'subscription', error: e);
      // Still update local state to free tier
      final newState = SubscriptionState(
        tier: SubscriptionTier.free,
        isActive: false,
        expiresAt: null,
      );
      state = newState;
      await _saveSubscriptionStatus(newState);
      return false;
    }
  }

  /// Check if user has access to a specific feature based on subscription tier
  bool hasFeature(String feature) {
    if (_overrideAllAccess) return true;
    // Check if subscription is active and not expired
    if (!state.isActive || state.isExpired) {
      return false;
    }
    
    switch (feature) {
      case 'all_games':
        return state.tier != SubscriptionTier.free;
      case 'unlimited_ai':
        return state.tier != SubscriptionTier.free;
      case 'offline_mode':
        return state.tier != SubscriptionTier.free;
      case 'no_ads':
        return state.tier != SubscriptionTier.free;
      case 'pronunciation_scoring':
        return state.tier != SubscriptionTier.free;
      case 'advanced_analytics':
        return state.tier == SubscriptionTier.premium || 
               state.tier == SubscriptionTier.family || 
               state.tier == SubscriptionTier.lifetime;
      case 'family_sharing':
        return state.tier == SubscriptionTier.family || 
               state.tier == SubscriptionTier.lifetime;
      case 'priority_support':
        return state.tier == SubscriptionTier.family || 
               state.tier == SubscriptionTier.lifetime;
      default:
        // Free features available to all
        return true;
    }
  }
  
  /// Refresh subscription status from backend
  Future<void> refresh() async {
    await _loadSubscriptionStatus();
  }

  Future<bool> restorePurchases() async {
    if (_overrideAllAccess) {
      state = SubscriptionState(
        tier: _overrideTier,
        isActive: true,
        expiresAt: null,
      );
      await _saveSubscriptionStatus(state);
      return true;
    }

    try {
      final revenueCat = ref.read(revenueCatServiceProvider);
      final user = ref.read(userProvider);
      await revenueCat.initialize(appUserId: user?.id.toString());
      if (!revenueCat.isConfigured) return false;

      final info = await revenueCat.restorePurchases();
      if (info == null) return false;

      final resolvedTier = _mapRevenueCatTier(revenueCat.tierFromCustomerInfo(info));
      final expiresAt = _getRevenueCatExpiration(info, _mapSubscriptionTier(resolvedTier));
      final newState = SubscriptionState(
        tier: resolvedTier,
        isActive: resolvedTier != SubscriptionTier.free,
        expiresAt: expiresAt,
      );
      state = newState;
      await _saveSubscriptionStatus(newState);
      return true;
    } catch (e) {
      logger.error('Error restoring purchases', tag: 'subscription', error: e);
      return false;
    }
  }

  bool canAccessFamilyDashboard() {
    return hasFeature('family_sharing');
  }

  SubscriptionTier _mapRevenueCatTier(RevenueCatTier tier) {
    switch (tier) {
      case RevenueCatTier.premium:
        return SubscriptionTier.premium;
      case RevenueCatTier.family:
        return SubscriptionTier.family;
      case RevenueCatTier.lifetime:
        return SubscriptionTier.lifetime;
      case RevenueCatTier.free:
        return SubscriptionTier.free;
    }
  }

  RevenueCatTier _mapSubscriptionTier(SubscriptionTier tier) {
    switch (tier) {
      case SubscriptionTier.premium:
        return RevenueCatTier.premium;
      case SubscriptionTier.family:
        return RevenueCatTier.family;
      case SubscriptionTier.lifetime:
        return RevenueCatTier.lifetime;
      case SubscriptionTier.free:
        return RevenueCatTier.free;
    }
  }

  DateTime? _getRevenueCatExpiration(CustomerInfo info, RevenueCatTier tier) {
    final entitlementId = _entitlementIdForTier(tier);
    if (entitlementId == null) return null;
    final entitlement = info.entitlements.all[entitlementId];
    return entitlement?.expirationDate;
  }

  String? _entitlementIdForTier(RevenueCatTier tier) {
    switch (tier) {
      case RevenueCatTier.premium:
        return RevenueCatEntitlements.premium;
      case RevenueCatTier.family:
        return RevenueCatEntitlements.family;
      case RevenueCatTier.lifetime:
        return RevenueCatEntitlements.lifetime;
      case RevenueCatTier.free:
        return null;
    }
  }
}

final subscriptionProvider = NotifierProvider<SubscriptionNotifier, SubscriptionState>(() {
  return SubscriptionNotifier();
});

final revenueCatServiceProvider = Provider<RevenueCatService>((ref) {
  return RevenueCatService();
});

enum SubscriptionTier {
  free,
  premium,
  family,
  lifetime,
}

class SubscriptionState {
  final SubscriptionTier tier;
  final bool isActive;
  final DateTime? expiresAt;

  SubscriptionState({
    required this.tier,
    required this.isActive,
    this.expiresAt,
  });

  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  String get tierName {
    switch (tier) {
      case SubscriptionTier.free:
        return 'Free';
      case SubscriptionTier.premium:
        return 'Premium';
      case SubscriptionTier.family:
        return 'Family';
      case SubscriptionTier.lifetime:
        return 'Lifetime';
    }
  }

  double get monthlyPrice {
    switch (tier) {
      case SubscriptionTier.free:
        return 0.0;
      case SubscriptionTier.premium:
        return 4.99;
      case SubscriptionTier.family:
        return 9.99;
      case SubscriptionTier.lifetime:
        return 99.99; // One-time
    }
  }
}

