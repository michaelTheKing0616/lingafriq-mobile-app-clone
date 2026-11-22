/// Server-backed checks for revived chat, family, and Plus.
///
/// Callers pass the HTTP functions. A missing or failed server result never
/// becomes a success, a child list, or a Plus entitlement.

typedef SocialGet = Future<Map<String, dynamic>> Function(String path);
typedef SocialPost = Future<Map<String, dynamic>> Function(
  String path,
  Map<String, dynamic> body,
);

/// Age band the server reports. Unknown and minor stay locked.
enum SocialAgeBand { adult, minor, unknown }

class SocialAgeGate {
  const SocialAgeGate({required this.band, this.message});

  final SocialAgeBand band;
  final String? message;

  bool get allowsChat => band == SocialAgeBand.adult;
}

class SafetyActionResult {
  const SafetyActionResult._({required this.accepted, required this.message});

  const SafetyActionResult.accepted(String message)
    : this._(accepted: true, message: message);

  const SafetyActionResult.retry(String message)
    : this._(accepted: false, message: message);

  final bool accepted;
  final String message;
}

class ModerationAccess {
  const ModerationAccess({required this.isModerator, this.denial});

  final bool isModerator;
  final String? denial;
}

class FamilyDashboardData {
  const FamilyDashboardData({
    required this.isGuardian,
    required this.childLabels,
    required this.approvalLabels,
    this.denial,
  });

  final bool isGuardian;
  final List<String> childLabels;
  final List<String> approvalLabels;
  final String? denial;
}

class PlusEntitlement {
  const PlusEntitlement({
    required this.storeConfigured,
    required this.serverConfirmed,
    this.message,
  });

  /// The store key is missing. No purchase may start.
  final bool storeConfigured;

  /// True only when the server says the entitlement is confirmed.
  final bool serverConfirmed;
  final String? message;

  bool get canPurchase => storeConfigured && !serverConfirmed;
}

class ChatWelcomeStore {
  final Set<String> _accepted = <String>{};

  bool hasAccepted(String userId) => _accepted.contains(userId);

  void accept(String userId) {
    final String id = userId.trim();
    if (id.isEmpty) return;
    _accepted.add(id);
  }
}

SocialAgeGate ageGateFromJson(Map<String, dynamic> json) {
  final String band = json['band']?.toString().trim().toLowerCase() ?? '';
  final SocialAgeBand parsed = switch (band) {
    'adult' => SocialAgeBand.adult,
    'minor' => SocialAgeBand.minor,
    _ => SocialAgeBand.unknown,
  };
  if (json['ok'] != true) {
    return SocialAgeGate(
      band: SocialAgeBand.unknown,
      message: json['message']?.toString(),
    );
  }
  return SocialAgeGate(band: parsed, message: json['message']?.toString());
}

SafetyActionResult safetyActionFromJson(
  Map<String, dynamic> json, {
  required String successMessage,
  required String failureMessage,
}) {
  final bool accepted = json['ok'] == true || json['accepted'] == true;
  if (!accepted) return SafetyActionResult.retry(failureMessage);
  return SafetyActionResult.accepted(successMessage);
}

ModerationAccess moderationFromJson(
  Map<String, dynamic> json, {
  required String denial,
}) {
  final bool allowed = json['ok'] == true && json['moderator'] == true;
  if (!allowed) {
    return ModerationAccess(isModerator: false, denial: denial);
  }
  return const ModerationAccess(isModerator: true);
}

FamilyDashboardData familyFromJson(Map<String, dynamic> json) {
  if (json['ok'] != true || json['guardian'] != true) {
    return FamilyDashboardData(
      isGuardian: false,
      childLabels: const <String>[],
      approvalLabels: const <String>[],
      denial: json['message']?.toString(),
    );
  }
  final List<String> children = _labels(json['children']);
  final List<String> approvals = _labels(json['approvals']);
  return FamilyDashboardData(
    isGuardian: true,
    childLabels: children,
    approvalLabels: approvals,
  );
}

PlusEntitlement plusFromJson(
  Map<String, dynamic> json, {
  required bool storeConfigured,
}) {
  if (!storeConfigured) {
    return const PlusEntitlement(storeConfigured: false, serverConfirmed: false);
  }
  final bool confirmed =
      json['ok'] == true &&
      json['entitled'] == true &&
      json['source'] == 'server';
  return PlusEntitlement(
    storeConfigured: true,
    serverConfirmed: confirmed,
    message: json['message']?.toString(),
  );
}

List<String> _labels(Object? raw) {
  if (raw is! List) return const <String>[];
  return raw
      .whereType<Map>()
      .map((Map row) => row['label']?.toString().trim() ?? '')
      .where((String label) => label.isNotEmpty)
      .toList(growable: false);
}

/// Live calls. Tests pass their own [get] and [post].
class RevivedSocialClient {
  const RevivedSocialClient({required this.get, required this.post});

  final SocialGet get;
  final SocialPost post;

  Future<SocialAgeGate> readAgeGate() async {
    return ageGateFromJson(await get('/api/safety/age-gate'));
  }

  Future<SafetyActionResult> block(
    String userId, {
    required String successMessage,
    required String failureMessage,
  }) async {
    final Map<String, dynamic> json = await post('/safety/block', {
      'targetUserId': userId,
    });
    return safetyActionFromJson(
      json,
      successMessage: successMessage,
      failureMessage: failureMessage,
    );
  }

  Future<SafetyActionResult> report(
    String userId, {
    required String successMessage,
    required String failureMessage,
  }) async {
    final Map<String, dynamic> json = await post('/safety/reports', {
      'targetType': 'user',
      'targetId': userId,
      'reason': 'other',
    });
    return safetyActionFromJson(
      json,
      successMessage: successMessage,
      failureMessage: failureMessage,
    );
  }

  Future<ModerationAccess> readModeration({required String denial}) async {
    return moderationFromJson(
      await get('/chat/moderation/access'),
      denial: denial,
    );
  }

  Future<List<String>> searchChats(String query) async {
    final Map<String, dynamic> json = await get(
      '/chat/search?q=${Uri.encodeQueryComponent(query)}',
    );
    if (json['ok'] != true) {
      throw SocialRequestException(json['message']?.toString());
    }
    return _labels(json['messages']);
  }

  Future<FamilyDashboardData> readFamily() async {
    return familyFromJson(await get('/api/guardian/hub'));
  }

  Future<PlusEntitlement> confirmPlus({required bool storeConfigured}) async {
    if (!storeConfigured) {
      return const PlusEntitlement(
        storeConfigured: false,
        serverConfirmed: false,
      );
    }
    return plusFromJson(
      await post('/api/billing/entitlement', const <String, dynamic>{}),
      storeConfigured: true,
    );
  }
}

class SocialRequestException implements Exception {
  const SocialRequestException(this.message);

  final String? message;
}

/// Used when a screen is opened without a server client. It does not pretend
/// the server accepted anything.
RevivedSocialClient offlineSocialClient() {
  Future<Map<String, dynamic>> fail(String path, [Map<String, dynamic>? body]) {
    throw const SocialRequestException(
      'The server did not return a result.',
    );
  }

  return RevivedSocialClient(
    get: fail,
    post: (String path, Map<String, dynamic> body) => fail(path, body),
  );
}
