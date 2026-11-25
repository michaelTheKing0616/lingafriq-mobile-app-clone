/// One in-flight refresh shared by every caller that arrives while it runs.
class RefreshGate {
  Future<String?>? _pending;

  Future<String?> run(Future<String?> Function() action) {
    final pending = _pending;
    if (pending != null) return pending;
    final next = action();
    _pending = next;
    return next.whenComplete(() {
      if (identical(_pending, next)) _pending = null;
    });
  }
}

/// Prefer the rotated refresh token from the response. Keep the previous one
/// when an older server returns only an access token.
String? rotatedRefresh(Object? body, String? previous) {
  if (body is Map) {
    final next = body['refresh'] ?? body['refreshToken'];
    if (next is String && next.isNotEmpty) return next;
  }
  if (previous != null && previous.isNotEmpty) return previous;
  return null;
}
