import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Subscription tier provider
class SubscriptionNotifier extends Notifier<SubscriptionState> {
  @override
  SubscriptionState build() {
    // Load subscription status from backend or local storage
    return SubscriptionState(
      tier: SubscriptionTier.free,
      isActive: false,
      expiresAt: null,
    );
  }

  Future<void> subscribe(SubscriptionTier tier) async {
    // Implement subscription logic
    // This would typically call a payment API (Stripe, RevenueCat, etc.)
    state = SubscriptionState(
      tier: tier,
      isActive: true,
      expiresAt: DateTime.now().add(const Duration(days: 30)), // Monthly
    );
  }

  Future<void> cancelSubscription() async {
    state = SubscriptionState(
      tier: SubscriptionTier.free,
      isActive: false,
      expiresAt: null,
    );
  }

  bool hasFeature(String feature) {
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
      default:
        return true;
    }
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

