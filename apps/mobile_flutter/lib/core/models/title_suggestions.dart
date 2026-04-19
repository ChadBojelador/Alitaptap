/// Title suggestions response model for GET /issues/{issue_id}/title-suggestions.
class TitleSuggestions {
  const TitleSuggestions({
    required this.issueId,
    required this.suggestions,
    required this.generatedAt,
  });

  factory TitleSuggestions.fromJson(Map<String, dynamic> json) {
    return TitleSuggestions(
      issueId: json['issue_id'] as String? ?? '',
      suggestions: (json['suggestions'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const <String>[],
      generatedAt: json['generated_at'] as String? ?? '',
    );
  }

  final String issueId;
  final List<String> suggestions;
  final String generatedAt;
}
