import 'package:dio/dio.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/models/culture_content_model.dart';
import 'package:lingafriq/providers/dio_provider.dart';
import 'package:lingafriq/utils/api.dart';

class CultureMagazineService {
  final WidgetRef ref;

  CultureMagazineService(this.ref);

  /// Fetches all published articles, optionally filtered by category
  Future<List<CultureContent>> getArticles({
    String? category,
    int page = 1,
    int limit = 100,
    bool featured = false,
  }) async {
    try {
      final dio = ref.read(client);
      String url = Api.cultureMagazineArticles;
      
      // Build query parameters
      final queryParams = <String, dynamic>{
        'published': 'true',
        'page': page.toString(),
        'limit': limit.toString(),
      };
      
      if (category != null && category.isNotEmpty && category != 'all') {
        queryParams['category'] = category;
      }
      
      if (featured) {
        queryParams['featured'] = 'true';
      }

      final response = await dio.get(
        url,
        queryParameters: queryParams,
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'];
        final articles = data['docs'] ?? data['data'] ?? [];
        
        return (articles as List)
            .map((article) => CultureContent.fromBackendMap(article))
            .toList();
      } else {
        throw Exception('Failed to fetch articles: ${response.data}');
      }
    } catch (e) {
      throw Exception('Error fetching articles: $e');
    }
  }

  /// Fetches featured articles
  Future<List<CultureContent>> getFeaturedArticles() async {
    try {
      final dio = ref.read(client);
      final response = await dio.get(Api.cultureMagazineFeaturedArticles);

      if (response.statusCode == 200 && response.data['success'] == true) {
        final articles = response.data['data'] ?? [];
        return (articles as List)
            .map((article) => CultureContent.fromBackendMap(article))
            .toList();
      } else {
        throw Exception('Failed to fetch featured articles');
      }
    } catch (e) {
      throw Exception('Error fetching featured articles: $e');
    }
  }

  /// Fetches a single article by slug
  Future<CultureContent> getArticleBySlug(String slug) async {
    try {
      final dio = ref.read(client);
      final response = await dio.get(Api.cultureMagazineArticleBySlug(slug));

      if (response.statusCode == 200 && response.data['success'] == true) {
        return CultureContent.fromBackendMap(response.data['data']);
      } else {
        throw Exception('Failed to fetch article');
      }
    } catch (e) {
      throw Exception('Error fetching article: $e');
    }
  }
}

