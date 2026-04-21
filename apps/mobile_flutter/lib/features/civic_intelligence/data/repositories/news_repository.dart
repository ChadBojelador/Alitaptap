import 'package:alitaptap_mobile/core/models/news_article.dart';
import 'package:alitaptap_mobile/services/api_service.dart';

class NewsRepository {
  final _api = ApiService();

  Future<List<NewsArticle>> getNews({
    String? keywords,
    int? sdg,
    String country = 'ph',
    int pageSize = 10,
  }) async {
    try {
      final params = <String, dynamic>{
        'country': country,
        'page_size': pageSize,
      };

      if (keywords != null) {
        params['keywords'] = keywords;
      }
      if (sdg != null) {
        params['sdg'] = sdg;
      }

      final response = await _api.get('/news', queryParameters: params);
      final articles = (response as List)
          .map((item) => NewsArticle.fromJson(item as Map<String, dynamic>))
          .toList();
      return articles;
    } catch (e) {
      throw Exception('Failed to fetch news: $e');
    }
  }

  Future<List<NewsArticle>> getSdgNews({
    required int sdgNumber,
    int pageSize = 10,
  }) async {
    try {
      final response = await _api.get('/news/sdg/$sdgNumber',
          queryParameters: {'page_size': pageSize});
      final articles = (response as List)
          .map((item) => NewsArticle.fromJson(item as Map<String, dynamic>))
          .toList();
      return articles;
    } catch (e) {
      throw Exception('Failed to fetch SDG news: $e');
    }
  }

  Future<List<NewsArticle>> getResearchNews({int pageSize = 10}) async {
    try {
      final response = await _api.get('/news/research',
          queryParameters: {'page_size': pageSize});
      final articles = (response as List)
          .map((item) => NewsArticle.fromJson(item as Map<String, dynamic>))
          .toList();
      return articles;
    } catch (e) {
      throw Exception('Failed to fetch research news: $e');
    }
  }

  Future<List<NewsArticle>> getPhilippinesNews({int pageSize = 10}) async {
    try {
      final response = await _api.get('/news/philippines',
          queryParameters: {'page_size': pageSize});
      final articles = (response as List)
          .map((item) => NewsArticle.fromJson(item as Map<String, dynamic>))
          .toList();
      return articles;
    } catch (e) {
      throw Exception('Failed to fetch Philippines news: $e');
    }
  }
}
