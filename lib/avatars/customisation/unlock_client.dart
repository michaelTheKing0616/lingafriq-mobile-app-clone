import 'package:dio/dio.dart';
import 'package:lingafriq/avatars/customisation/avatar_editor_screen.dart';

/// Fetches server-verified mastery entitlements for the avatar editor (P11-054).
class AvatarUnlockClient {
  AvatarUnlockClient(this._dio, {String? baseUrl}) : _baseUrl = baseUrl;

  final Dio _dio;
  final String? _baseUrl;

  static const String masteryEntitlementsPath = '/api/avatar/mastery-entitlements';

  String _url(String path) {
    final root = _baseUrl ?? _dio.options.baseUrl;
    final base = root.endsWith('/') ? root.substring(0, root.length - 1) : root;
    return '$base$path';
  }

  /// Client-side guard: never POST client-invented mastery ids (security AC).
  static void rejectLocalMasteryUnlockClaim(Map<String, dynamic> body) {
    final masteryList = body['unlockedMasteryIds'] ?? body['unlocked_mastery_ids'];
    if (masteryList is List && masteryList.isNotEmpty) {
      throw AvatarUnlockException(
        code: 'CLIENT_MASTERY_UNLOCK_FORBIDDEN',
        message: 'Mastery entitlements must come from the server',
      );
    }
    final itemId = (body['itemId'] ?? body['masteryId'] ?? body['entitlementId'])
        ?.toString();
    if (itemId != null && itemId.startsWith('mastery:')) {
      throw AvatarUnlockException(
        code: 'CLIENT_MASTERY_UNLOCK_FORBIDDEN',
        message: 'Mastery items unlock only from verified learning evidence',
      );
    }
  }

  Future<AvatarEditorEntitlements> fetchMasteryEntitlements() async {
    final response = await _dio.get<Map<String, dynamic>>(
      _url(masteryEntitlementsPath),
      options: Options(responseType: ResponseType.json),
    );
    final status = response.statusCode ?? 0;
    final body = response.data;
    if (status < 200 || status >= 300 || body == null) {
      throw AvatarUnlockException(
        code: body?['code']?.toString() ?? 'AVATAR_ENTITLEMENTS_FETCH_FAILED',
        message:
            body?['error']?.toString() ??
            body?['message']?.toString() ??
            'Could not load avatar unlocks',
        statusCode: status,
      );
    }
    final data = body['data'];
    final map = data is Map<String, dynamic> ? data : body;
    final raw = map['unlocked_mastery_ids'] ?? map['unlockedMasteryIds'];
    final ids = <String>{};
    if (raw is List) {
      for (final entry in raw) {
        final id = entry.toString().trim();
        if (id.isNotEmpty) ids.add(id);
      }
    }
    return AvatarEditorEntitlements(unlockedMasteryIds: ids);
  }
}

class AvatarUnlockException implements Exception {
  AvatarUnlockException({
    required this.code,
    required this.message,
    this.statusCode,
  });

  final String code;
  final String message;
  final int? statusCode;

  @override
  String toString() => 'AvatarUnlockException($code): $message';
}
