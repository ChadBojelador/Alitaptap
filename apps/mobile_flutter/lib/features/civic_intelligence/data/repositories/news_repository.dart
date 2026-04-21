import 'package:alitaptap_mobile/core/models/news_article.dart';
import 'package:alitaptap_mobile/services/api_service.dart';

class NewsRepository {
  final _api = ApiService();

  Future<List<NewsArticle>> getNews() async {
    try {
      return await _api.getNews();
    } catch (e) {
      throw Exception('Failed to fetch news: $e');
    }
  }
}
