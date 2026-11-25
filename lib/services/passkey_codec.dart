import 'package:dio/dio.dart';
import 'package:lingafriq/screens/auth/passkey_prompt.dart';
import 'package:passkeys/types.dart';

List<PasskeySummary> passkeySummaries(Object? body) {
  final raw = body is Map ? body['credentials'] : null;
  if (raw is! List) return const [];
  return raw.whereType<Map>().map((row) {
    return PasskeySummary(
      id: row['id']?.toString() ?? '',
      backedUp: row['backedUp'] == true,
    );
  }).where((row) => row.id.isNotEmpty).toList();
}

String passkeyErrorText(Object error) {
  if (error is DioException) {
    final data = error.response?.data;
    if (data is Map && data['error'] is Map) {
      final message = data['error']['message'];
      if (message is String && message.isNotEmpty) return message;
    }
  }
  return 'The passkey could not be verified';
}

AuthenticateRequestType authenticationRequest(Map<String, dynamic> options) {
  return AuthenticateRequestType.fromJson(options);
}

RegisterRequestType registrationRequest(Map<String, dynamic> options) {
  return RegisterRequestType.fromJson(options);
}
