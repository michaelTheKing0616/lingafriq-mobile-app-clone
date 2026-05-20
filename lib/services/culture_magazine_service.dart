import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/models/culture_content_model.dart';
import 'package:lingafriq/providers/dio_provider.dart';
import 'package:lingafriq/utils/api.dart';

/// One page of culture magazine articles from the paginated API.
class CultureMagazinePageResult {
  final List<CultureContent> articles;
  final bool hasNextPage;
  final int page;
  final int totalPages;
  final int totalDocs;

  const CultureMagazinePageResult({
    required this.articles,
    required this.hasNextPage,
    required this.page,
    required this.totalPages,
    required this.totalDocs,
  });
}

class CultureMagazineService {
  final WidgetRef ref;

  CultureMagazineService(this.ref);

  /// Fetches one page of published articles (mongoose-paginate shape).
  Future<CultureMagazinePageResult> getArticlesPage({
    String? category,
    int page = 1,
    int limit = 24,
    bool featured = false,
  }) async {
    try {
      final dio = ref.read(client);
      final url = Api.cultureArticles(published: true);

      final queryParams = <String, dynamic>{
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (category != null && category.isNotEmpty && category != 'all') {
        queryParams['category'] = category;
      }

      if (featured) {
        queryParams['featured'] = 'true';
      }

      final response = await dio.get(url, queryParameters: queryParams);

      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'];
        if (data == null) {
          return const CultureMagazinePageResult(
            articles: [],
            hasNextPage: false,
            page: 1,
            totalPages: 0,
            totalDocs: 0,
          );
        }

        if (data is List) {
          final list = data
              .map(
                (article) => CultureContent.fromBackendMap(
                  article as Map<String, dynamic>,
                ),
              )
              .toList();
          return CultureMagazinePageResult(
            articles: list,
            hasNextPage: false,
            page: page,
            totalPages: 1,
            totalDocs: list.length,
          );
        }

        final rawDocs = data['docs'] ?? data['data'] ?? [];
        final docs = rawDocs is List ? rawDocs : [];
        final articles = docs
            .map(
              (article) => CultureContent.fromBackendMap(
                article as Map<String, dynamic>,
              ),
            )
            .toList();

        final totalPages = (data['totalPages'] as num?)?.toInt() ?? 1;
        final currentPage = (data['page'] as num?)?.toInt() ?? page;
        final hasNextPage = data['hasNextPage'] == true ||
            (currentPage < totalPages && articles.isNotEmpty);

        return CultureMagazinePageResult(
          articles: articles,
          hasNextPage: hasNextPage,
          page: currentPage,
          totalPages: totalPages,
          totalDocs: (data['totalDocs'] as num?)?.toInt() ?? articles.length,
        );
      }
      throw Exception('Failed to fetch articles: ${response.data}');
    } catch (e) {
      throw Exception('Error fetching articles: $e');
    }
  }

  /// Fetches all published articles across pages, optionally filtered by category.
  Future<List<CultureContent>> getArticles({
    String? category,
    int page = 1,
    int limit = 24,
    bool featured = false,
  }) async {
    final result = await getArticlesPage(
      category: category,
      page: page,
      limit: limit,
      featured: featured,
    );
    return result.articles;
  }

  /// Fetches featured articles
  Future<List<CultureContent>> getFeaturedArticles() async {
    try {
      final dio = ref.read(client);
      final response = await dio.get(
        Api.cultureArticles(published: true),
        queryParameters: {'featured': 'true'},
      );

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
      // Backend uses id-based path today; slug lookups aren't wired in Api constants.
      final response = await dio.get(Api.cultureArticle(slug));

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

