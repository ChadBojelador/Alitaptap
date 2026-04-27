/// Title suggestions response model for GET /issues/{issue_id}/title-suggestions.
class TitleSuggestions {
  const TitleSuggestions({
    required this.issueId,
    required this.suggestions,
    required this.suggestionDetails,
    required this.generatedAt,
  });

  factory TitleSuggestions.fromJson(Map<String, dynamic> json) {
    return TitleSuggestions(
      issueId: json['issue_id'] as String? ?? '',
      suggestions: (json['suggestions'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const <String>[],
      suggestionDetails: (json['suggestion_details'] as List<dynamic>?)
              ?.map((e) => TitleSuggestionItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <TitleSuggestionItem>[],
      generatedAt: json['generated_at'] as String? ?? '',
    );
  }

  final String issueId;
  final List<String> suggestions;
  final List<TitleSuggestionItem> suggestionDetails;
  final String generatedAt;
}


/// A single title suggestion with its impact prediction.
class TitleSuggestionItem {
  const TitleSuggestionItem({
    required this.title,
    required this.impact,
  });

  factory TitleSuggestionItem.fromJson(Map<String, dynamic> json) {
    return TitleSuggestionItem(
      title: json['title'] as String? ?? '',
      impact: ImpactPrediction.fromJson(
        json['impact'] as Map<String, dynamic>? ?? const {},
      ),
    );
  }

  final String title;
  final ImpactPrediction impact;
}


/// Predicted impact percentages for a research title suggestion.
class ImpactPrediction {
  const ImpactPrediction({
    required this.social,
    required this.environmental,
    required this.economic,
    required this.overall,
    required this.summary,
  });

  factory ImpactPrediction.fromJson(Map<String, dynamic> json) {
    return ImpactPrediction(
      social: (json['social'] as num?)?.toDouble() ?? 0.0,
      environmental: (json['environmental'] as num?)?.toDouble() ?? 0.0,
      economic: (json['economic'] as num?)?.toDouble() ?? 0.0,
      overall: (json['overall'] as num?)?.toDouble() ?? 0.0,
      summary: json['summary'] as String? ?? '',
    );
  }

  final double social;
  final double environmental;
  final double economic;
  final double overall;
  final String summary;
}
