/// Client flag cache. A failure or a stale cache uses [safeDefault].
class FeatureFlagService {
  FeatureFlagService({
    this.ttl = const Duration(seconds: 60),
    this.safeDefault = false,
    this.log,
  });

  final Duration ttl;
  final bool safeDefault;
  final void Function(String message)? log;

  Map<String, bool> _values = {};
  DateTime? _fetchedAt;

  bool isOn(String key, DateTime now) {
    final fetchedAt = _fetchedAt;
    if (fetchedAt == null || now.difference(fetchedAt) > ttl) return safeDefault;
    return _values[key] ?? safeDefault;
  }

  void apply(Map<String, bool> values, DateTime now) {
    _values = Map<String, bool>.from(values);
    _fetchedAt = now;
  }

  void failed(Object error, DateTime now) {
    _values = {};
    _fetchedAt = now;
    final message = 'feature flag evaluation failed';
    log?.call('$message: $error');
  }
}
