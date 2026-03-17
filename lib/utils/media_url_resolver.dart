import 'package:lingafriq/config/api_contract.dart';
import 'package:lingafriq/services/env_config.dart';

/// Resolves relative media paths to absolute URLs.
String? resolveMediaUrl(String? rawUrl) {
  final value = rawUrl?.trim();
  if (value == null || value.isEmpty) return null;

  final lower = value.toLowerCase();
  if (lower.startsWith('http://') ||
      lower.startsWith('https://') ||
      lower.startsWith('data:') ||
      lower.startsWith('blob:') ||
      lower.startsWith('file:') ||
      lower.startsWith('content:')) {
    return value;
  }

  if (value.startsWith('//')) {
    return 'https:$value';
  }

  final normalizedPath = value.startsWith('/') ? value : '/$value';

  // Media files are served by nginx at CDN/base host and should not depend
  // on API proxy path assumptions.
  if (normalizedPath.startsWith('/media/')) {
    final cdnBase = EnvConfig.cdnUrl.trim().replaceAll(RegExp(r'/+$'), '');
    return '$cdnBase$normalizedPath';
  }

  final base = ApiContract.baseUrl.trim().replaceAll(RegExp(r'/+$'), '');
  return '$base$normalizedPath';
}
