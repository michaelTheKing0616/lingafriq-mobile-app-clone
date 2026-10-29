import 'package:lingafriq/utils/api_service.dart';

/// P9-912 — server-owned age tier assignment (no client tier tampering).
const String ageAssuranceBasePath = '/api/v2/age-assurance';

class AgeTierAssignmentResult {
  AgeTierAssignmentResult({
    required this.ok,
    this.tier,
    this.status,
    this.pendingGuardian = false,
    this.socialEnabled = false,
    this.chatEnabled = false,
    this.purchaseEnabled = false,
    this.code,
    this.message,
  });

  final bool ok;
  final String? tier;
  final String? status;
  final bool pendingGuardian;
  final bool socialEnabled;
  final bool chatEnabled;
  final bool purchaseEnabled;
  final String? code;
  final String? message;

  factory AgeTierAssignmentResult.fromJson(Map<String, dynamic> json) {
    return AgeTierAssignmentResult(
      ok: json['ok'] == true,
      tier: json['tier'] as String?,
      status: json['status'] as String?,
      pendingGuardian: json['pending_guardian'] == true,
      socialEnabled: json['social_enabled'] == true,
      chatEnabled: json['chat_enabled'] == true,
      purchaseEnabled: json['purchase_enabled'] == true,
      code: json['code'] as String?,
      message: json['message'] as String?,
    );
  }
}

class AgeTierStatus {
  AgeTierStatus({
    required this.assigned,
    this.tier,
    this.status,
    this.socialEnabled = false,
  });

  final bool assigned;
  final String? tier;
  final String? status;
  final bool socialEnabled;

  factory AgeTierStatus.fromJson(Map<String, dynamic> json) {
    return AgeTierStatus(
      assigned: json['assigned'] == true,
      tier: json['tier'] as String?,
      status: json['status'] as String?,
      socialEnabled: json['social_enabled'] == true,
    );
  }
}

typedef AgeTierPost =
    Future<Map<String, dynamic>> Function(
      String path, {
      Map<String, Object?>? data,
    });

typedef AgeTierGet = Future<Map<String, dynamic>> Function(String path);

class AgeTierService {
  AgeTierService({AgeTierPost? post, AgeTierGet? get})
    : _post = post ?? _defaultPost,
      _get = get ?? _defaultGet;

  final AgeTierPost _post;
  final AgeTierGet _get;

  static Future<Map<String, dynamic>> _defaultPost(
    String path, {
    Map<String, Object?>? data,
  }) async {
    await ApiService.initialize();
    final response = await ApiService.post(path, data: data);
    final json = response.data;
    if (json is Map<String, dynamic>) return json;
    return <String, dynamic>{'ok': false};
  }

  static Future<Map<String, dynamic>> _defaultGet(String path) async {
    await ApiService.initialize();
    final response = await ApiService.get(path);
    final json = response.data;
    if (json is Map<String, dynamic>) return json;
    return <String, dynamic>{'ok': false};
  }

  Future<AgeTierStatus> fetchStatus() async {
    final json = await _get('$ageAssuranceBasePath/status');
    return AgeTierStatus.fromJson(json);
  }

  Future<AgeTierAssignmentResult> assignBirthDate({
    required int birthYear,
    required String deviceKey,
    String? nationality,
  }) async {
    final json = await _post(
      '$ageAssuranceBasePath/assign',
      data: <String, Object?>{
        'birth_year': birthYear,
        'device_key': deviceKey,
        if (nationality != null) 'nationality': nationality,
      },
    );
    return AgeTierAssignmentResult.fromJson(json);
  }
}
