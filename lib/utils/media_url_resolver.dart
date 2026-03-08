import 'package:lingafriq/config/api_contract.dart';

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

  final base = ApiContract.baseUrl.trim().replaceAll(RegExp(r'/+$'), '');
  final path = value.startsWith('/') ? value : '/$value';
  return '$base$path';
}
