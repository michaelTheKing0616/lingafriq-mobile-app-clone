import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/providers/api_provider.dart';
import 'package:lingafriq/providers/user_provider.dart';

/// Logical subscription tiers used throughout the app.
/// Backend `subscription.tier` uses the same enum string values.
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
  /// Approximate Polie character/token quota per day for this user.
  /// This is populated from backend usage stats when available.
  final int? dailyPolieLimit;
  final int? dailyPolieUsed;

  const SubscriptionState({
    required this.tier,
    required this.isActive,
    this.expiresAt,
    this.dailyPolieLimit,
    this.dailyPolieUsed,
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
        return 4.99; // Individual African-market friendly price
      case SubscriptionTier.family:
        return 9.99; // Up to 4 family members
      case SubscriptionTier.lifetime:
        return 99.99; // One-time
    }
  }

  int get remainingPolieTokens {
    if (dailyPolieLimit == null || dailyPolieUsed == null) return 0;
    return (dailyPolieLimit! - dailyPolieUsed!).clamp(0, dailyPolieLimit!);
  }

  /// Feature-gating helper used across the app.
  bool hasFeature(String feature) {
    final active = isActive && !isExpired;
    switch (feature) {
      case 'offline_mode':
        return active && tier != SubscriptionTier.free;
      case 'polie':
        return active && tier != SubscriptionTier.free;
      default:
        // Conservative default: only premium+ gets unknown gated features.
        return active && tier != SubscriptionTier.free;
    }
  }
}

/// Subscription tier provider
class SubscriptionNotifier extends Notifier<SubscriptionState> {
  @override
  SubscriptionState build() {
    // Load subscription status from backend when the notifier is first built.
    _loadFromBackend();
    return const SubscriptionState(
      tier: SubscriptionTier.free,
      isActive: false,
      expiresAt: null,
      dailyPolieLimit: null,
      dailyPolieUsed: null,
    );
  }

  Future<void> _loadFromBackend() async {
    try {
      final user = ref.read(userProvider);
      if (user == null) return;

      final api = ref.read(apiProvider.notifier);
      final res = await api.getSubscription();

      final tierString = (res['tier'] as String?) ?? 'free';
      final expiresAtRaw = res['expiresAt'] as String?;
      final isActive = res['isActive'] == true;
      final dailyLimit = res['dailyPolieLimit'] as int?;
      final dailyUsed = res['dailyPolieUsed'] as int?;

      final tier = SubscriptionTier.values.firstWhere(
        (t) => t.toString().split('.').last == tierString,
        orElse: () => SubscriptionTier.free,
      );

      DateTime? expiresAt;
      if (expiresAtRaw != null) {
        expiresAt = DateTime.tryParse(expiresAtRaw);
      }

      state = SubscriptionState(
        tier: tier,
        isActive: isActive,
        expiresAt: expiresAt,
        dailyPolieLimit: dailyLimit,
        dailyPolieUsed: dailyUsed,
      );
    } catch (_) {
      // Fail silently; app will treat user as free tier
    }
  }

  Future<void> subscribe(SubscriptionTier tier) async {
    final api = ref.read(apiProvider.notifier);
    // For now we assume payment is handled externally and we only update the tier.
    final res = await api.updateSubscription(tier.name);

    final tierString = (res['tier'] as String?) ?? 'free';
    final expiresAtRaw = res['expiresAt'] as String?;
    final isActive = res['isActive'] == true;
    final dailyLimit = res['dailyPolieLimit'] as int?;
    final dailyUsed = res['dailyPolieUsed'] as int?;

    final mappedTier = SubscriptionTier.values.firstWhere(
      (t) => t.toString().split('.').last == tierString,
      orElse: () => SubscriptionTier.free,
    );

    DateTime? expiresAt;
    if (expiresAtRaw != null) {
      expiresAt = DateTime.tryParse(expiresAtRaw);
    }

    state = SubscriptionState(
      tier: mappedTier,
      isActive: isActive,
      expiresAt: expiresAt,
      dailyPolieLimit: dailyLimit,
      dailyPolieUsed: dailyUsed,
    );
  }

  Future<void> cancelSubscription() async {
    final api = ref.read(apiProvider.notifier);
    await api.cancelSubscription();
    state = const SubscriptionState(
      tier: SubscriptionTier.free,
      isActive: false,
      expiresAt: null,
      dailyPolieLimit: null,
      dailyPolieUsed: null,
    );
  }

  /// Feature-gating logic inspired by top language apps, but tuned for LingAfriq.
  bool hasFeature(String feature) {
    final tier = state.tier;

    switch (feature) {
      case 'all_games':
        // Free: core games only, Premium/Family/Lifetime: full game catalog
        return tier != SubscriptionTier.free;
      case 'unlimited_ai':
        // Free: capped daily AI turns (enforced elsewhere), paid tiers: unlimited
        return tier == SubscriptionTier.premium ||
            tier == SubscriptionTier.family ||
            tier == SubscriptionTier.lifetime;
      case 'offline_mode':
        // Offline downloads reserved for paying users
        return tier == SubscriptionTier.premium ||
            tier == SubscriptionTier.family ||
            tier == SubscriptionTier.lifetime;
      case 'no_ads':
        // Only free tier sees ads
        return tier != SubscriptionTier.free;
      case 'pronunciation_scoring':
        // Full MFA-based pronunciation scoring is a premium feature;
        // free tier may get occasional trials.
        return tier == SubscriptionTier.premium ||
            tier == SubscriptionTier.family ||
            tier == SubscriptionTier.lifetime;
      case 'family_dashboard':
        // Only family tier gets a family dashboard and multi-user tracking
        return tier == SubscriptionTier.family;
      default:
        // Unknown features default to allowed
        return true;
    }
  }
}

final subscriptionProvider =
    NotifierProvider<SubscriptionNotifier, SubscriptionState>(() {
  return SubscriptionNotifier();
});

