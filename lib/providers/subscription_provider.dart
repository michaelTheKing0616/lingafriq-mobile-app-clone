import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'api_provider.dart';
import 'dio_provider.dart';
import 'user_provider.dart';
import '../utils/api.dart';
import 'base_provider.dart';

/// Subscription tier provider with backend integration
class SubscriptionNotifier extends Notifier<SubscriptionState> {
  @override
  SubscriptionState build() {
    // Load subscription status asynchronously
    Future.microtask(() => _loadSubscriptionStatus());
    return SubscriptionState(
      tier: SubscriptionTier.free,
      isActive: false,
      expiresAt: null,
    );
  }
  
  /// Load subscription status from backend and local storage
  Future<void> _loadSubscriptionStatus() async {
    try {
      // Try to load from backend first
      final user = ref.read(userProvider);
      if (user != null) {
        final response = await ref.read(client).get(
          '${Api.baseurl}api/subscriptions/status',
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
      debugPrint('Error loading subscription status: $e');
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
      debugPrint('Error loading subscription from local storage: $e');
      // Keep default free tier
    }
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
      debugPrint('Error saving subscription status: $e');
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
    try {
      final user = ref.read(userProvider);
      if (user == null) {
        throw Exception('User must be logged in to subscribe');
      }
      
      // Call backend subscription endpoint
      final response = await ref.read(client).post(
        '${Api.baseurl}api/subscriptions/subscribe',
        data: {
          'tier': tier.name,
          'user_id': user.id.toString(),
        },
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data as Map<String, dynamic>;
        final expiresAtStr = data['expires_at']?.toString();
        final expiresAt = expiresAtStr != null 
            ? DateTime.parse(expiresAtStr) 
            : (tier == SubscriptionTier.lifetime 
                ? null 
                : DateTime.now().add(const Duration(days: 30)));
        
        final newState = SubscriptionState(
          tier: tier,
          isActive: true,
          expiresAt: expiresAt,
        );
        
        state = newState;
        await _saveSubscriptionStatus(newState);
        return true;
      } else {
        throw Exception('Subscription failed: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error subscribing: $e');
      // Return false but don't throw - let UI handle the error
      return false;
    }
  }

  /// Cancel current subscription
  Future<bool> cancelSubscription() async {
    try {
      final user = ref.read(userProvider);
      if (user == null) {
        throw Exception('User must be logged in to cancel subscription');
      }
      
      // Call backend to cancel subscription
      final response = await ref.read(client).post(
        '${Api.baseurl}api/subscriptions/cancel',
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
      debugPrint('Error canceling subscription: $e');
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
}

final subscriptionProvider = NotifierProvider<SubscriptionNotifier, SubscriptionState>(() {
  return SubscriptionNotifier();
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

