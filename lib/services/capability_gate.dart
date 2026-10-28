import 'package:flutter/material.dart';
import 'package:lingafriq/screens/guardian/guardian_link_screen.dart';
import 'package:lingafriq/utils/api_service.dart';

/// P9-918 — server-owned learner capability matrix (minors gated on client + API).
const String capabilitiesBasePath = '/api/v2/capabilities';

class LearnerCapabilities {
  LearnerCapabilities({
    required this.isMinor,
    this.tier,
    this.socialEnabled = true,
    this.directMessagesOpen = true,
    this.snaps = true,
    this.publicSnapFeed = true,
    this.ads = true,
    this.purchases = true,
    this.guardianHubPath = '/guardian',
  });

  final bool isMinor;
  final String? tier;
  final bool socialEnabled;
  final bool directMessagesOpen;
  final bool snaps;
  final bool publicSnapFeed;
  final bool ads;
  final bool purchases;
  final String guardianHubPath;

  factory LearnerCapabilities.fromJson(Map<String, dynamic> json) {
    return LearnerCapabilities(
      isMinor: json['is_minor'] == true,
      tier: json['tier'] as String?,
      socialEnabled: json['social_enabled'] == true,
      directMessagesOpen: json['direct_messages_open'] == true,
      snaps: json['snaps'] == true,
      publicSnapFeed: json['public_snap_feed'] == true,
      ads: json['ads'] == true,
      purchases: json['purchases'] == true,
      guardianHubPath: json['guardian_hub_path'] as String? ?? '/guardian',
    );
  }

  static LearnerCapabilities permissiveFallback() => LearnerCapabilities(
        isMinor: false,
        directMessagesOpen: true,
        snaps: true,
        publicSnapFeed: true,
        ads: true,
        purchases: true,
      );
}

typedef CapabilityGet = Future<Map<String, dynamic>> Function(String path);

class CapabilityGate {
  CapabilityGate({CapabilityGet? get}) : _get = get ?? _defaultGet;

  final CapabilityGet _get;
  LearnerCapabilities? _cached;

  Future<LearnerCapabilities> load({bool forceRefresh = false}) async {
    if (_cached != null && !forceRefresh) return _cached!;
    try {
      final json = await _get('$capabilitiesBasePath/matrix');
      final caps = json['capabilities'];
      if (json['ok'] == true && caps is Map<String, dynamic>) {
        _cached = LearnerCapabilities.fromJson(caps);
        return _cached!;
      }
    } catch (_) {
      // Offline: fail closed for ads/purchases/snaps when unknown.
    }
    _cached = LearnerCapabilities.permissiveFallback();
    return _cached!;
  }

  void clearCache() => _cached = null;

  /// AC3 — never load an ad slot for minors.
  Future<bool> mayRequestAds() async {
    final caps = await load();
    return caps.ads;
  }

  Future<bool> mayPurchase() async {
    final caps = await load();
    return caps.purchases;
  }

  Future<bool> mayUseSnaps() async {
    final caps = await load();
    return caps.snaps;
  }

  static Future<Map<String, dynamic>> _defaultGet(String path) async {
    await ApiService.initialize();
    final response = await ApiService.get(path);
    final json = response.data;
    if (json is Map<String, dynamic>) return json;
    return <String, dynamic>{'ok': false};
  }
}

/// Blocked purchase sheet — routes to Family hub (AC4).
class CapabilityBlockedSheet extends StatelessWidget {
  const CapabilityBlockedSheet({
    super.key,
    required this.title,
    required this.body,
    this.actionLabel = 'Open Family hub',
  });

  static const String purchaseBlockedTitle = 'Purchases need a guardian';
  static const String purchaseBlockedBody =
      'Cowries shop and in-app purchases stay off until a parent approves your account in Family hub.';

  static const String dmBlockedTitle = 'Message not sent';
  static const String dmBlockedBody =
      'You can chat with people in a guardian-approved circle or classroom.';

  final String title;
  final String body;
  final String actionLabel;

  static Future<void> showPurchaseBlocked(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => CapabilityBlockedSheet(
        title: purchaseBlockedTitle,
        body: purchaseBlockedBody,
        actionLabel: 'Open Family hub',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: theme.textTheme.titleLarge),
          const SizedBox(height: 12),
          Text(body, style: theme.textTheme.bodyLarge),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const GuardianLinkScreen(),
                ),
              );
            },
            child: Text(actionLabel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Not now'),
          ),
        ],
      ),
    );
  }
}
