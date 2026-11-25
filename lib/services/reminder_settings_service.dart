import 'package:lingafriq/config/api_contract.dart';
import 'package:lingafriq/utils/api_service.dart';

/// Server-backed study reminder preferences (survives reinstall).
class ReminderSettingsService {
  static const String path = '/notifications';

  static Future<Map<String, dynamic>?> fetchRemote() async {
    final res = await ApiService.get(ApiContract.url(path));
    if (res.statusCode != 200) return null;
    final body = res.data;
    if (body is Map<String, dynamic>) return body;
    return null;
  }

  static Future<bool> pushRemote(Map<String, dynamic> payload) async {
    final res = await ApiService.put(ApiContract.url(path), data: payload);
    final code = res.statusCode ?? 0;
    return code >= 200 && code < 300;
  }
}
