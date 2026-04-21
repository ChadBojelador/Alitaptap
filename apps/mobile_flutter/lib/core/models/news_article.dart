class NewsArticle {
  final String title;
  final String source;
  final String url;
  final String summary;
  final DateTime publishedAt;

  NewsArticle({
    required this.title,
    required this.source,
    required this.url,
    required this.summary,
    required this.publishedAt,
  });

  factory NewsArticle.fromJson(Map<String, dynamic> json) {
    return NewsArticle(
      title: json['title'] ?? '',
      source: json['source'] ?? 'Unknown',
      url: json['url'] ?? '',
      summary: json['summary'] ?? '',
      publishedAt: DateTime.tryParse(json['published_at'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'source': source,
      'url': url,
      'summary': summary,
      'published_at': publishedAt.toIso8601String(),
    };
  }
}
