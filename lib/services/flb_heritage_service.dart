import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/models/culture_content_model.dart';
import 'package:lingafriq/providers/dio_provider.dart';
import 'package:lingafriq/utils/api.dart';

/// FLB Heritage: curated archive entries tagged `flb-heritage` on the culture-magazine API,
/// with a bundled JSON fallback when offline or when the API errors.
class FlbHeritageService {
  FlbHeritageService(this.ref);

  final WidgetRef ref;

  static const _heritageTag = 'flb-heritage';
  static const _bundleAsset = 'assets/data/flb_heritage_archive.json';

  Future<List<CultureContent>> loadItems({String? searchQuery}) async {
    try {
      final dio = ref.read(client);
      final qp = <String, dynamic>{
        'published': 'true',
        'limit': 50,
        'page': 1,
        'tags': _heritageTag,
      };
      final q = searchQuery?.trim();
      if (q != null && q.isNotEmpty) {
        qp['search'] = q;
      }

      final response = await dio.get(
        Api.cultureArticles(published: true),
        queryParameters: qp,
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'];
        final rawList = data is List
            ? data
            : (data is Map<String, dynamic>
                ? (data['docs'] ?? data['data'] ?? [])
                : []);
        if (rawList is! List) return _loadBundled();
        final out = rawList
            .map((e) =>
                CultureContent.fromBackendMap(Map<String, dynamic>.from(e as Map)))
            .toList();
        if (out.isEmpty) return _loadBundled();
        return out;
      }
    } catch (e, st) {
      debugPrint('FlbHeritageService API fallback: $e\n$st');
    }
    return _loadBundled();
  }

  Future<List<CultureContent>> _loadBundled() async {
    try {
      final raw = await rootBundle.loadString(_bundleAsset);
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final items = decoded['items'] as List<dynamic>? ?? [];
      return items
          .map((e) => CultureContent.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (e, st) {
      debugPrint('FlbHeritageService bundle load failed: $e\n$st');
      return [];
    }
  }
}
