/// Match result returned by POST /mapper/match and POST /mapper/nearest.
class MatchResult {
  const MatchResult({
    required this.issueId,
    required this.score,
    required this.reason,
    this.lat,
    this.lng,
  });

  factory MatchResult.fromJson(Map<String, dynamic> json) {
    return MatchResult(
      issueId: json['issue_id'] as String,
      score: (json['score'] as num).toDouble(),
      reason: json['reason'] as String,
      lat: (json['lat'] as num?)?.toDouble(),
      lng: (json['lng'] as num?)?.toDouble(),
    );
  }

  /// Firestore document ID of the matched issue.
  final String issueId;

  /// Cosine similarity score, 0.0 – 1.0.
  final double score;

  /// Human-readable explanation of why this issue matches.
  final String reason;

  /// Geographic coordinates of the issue (populated by /mapper/nearest).
  final double? lat;
  final double? lng;

  Map<String, dynamic> toJson() => {
        'issue_id': issueId,
        'score': score,
        'reason': reason,
        if (lat != null) 'lat': lat,
        if (lng != null) 'lng': lng,
      };
}


/// Full response from the mapper/match endpoint.
class MapperRunResult {
  const MapperRunResult({required this.runId, required this.matches});

  factory MapperRunResult.fromJson(Map<String, dynamic> json) {
    final rawMatches = json['matches'] as List<dynamic>;
    return MapperRunResult(
      runId: json['run_id'] as String,
      matches: rawMatches
          .map((e) => MatchResult.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  final String runId;
  final List<MatchResult> matches;
}
