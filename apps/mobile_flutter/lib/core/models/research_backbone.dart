class FeasibilityScore {
  final String cost;
  final String time;
  final String dataAvailability;

  FeasibilityScore({
    required this.cost,
    required this.time,
    required this.dataAvailability,
  });

  factory FeasibilityScore.fromJson(Map<String, dynamic> json) {
    return FeasibilityScore(
      cost: json['cost'] as String,
      time: json['time'] as String,
      dataAvailability: json['data_availability'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'cost': cost,
        'time': time,
        'data_availability': dataAvailability,
      };
}

class CommunityImpact {
  final double social;
  final double environmental;
  final double economic;
  final double overall;
  final String summary;

  CommunityImpact({
    required this.social,
    required this.environmental,
    required this.economic,
    required this.overall,
    required this.summary,
  });

  factory CommunityImpact.fromJson(Map<String, dynamic> json) {
    return CommunityImpact(
      social: (json['social'] as num?)?.toDouble() ?? 0.0,
      environmental: (json['environmental'] as num?)?.toDouble() ?? 0.0,
      economic: (json['economic'] as num?)?.toDouble() ?? 0.0,
      overall: (json['overall'] as num?)?.toDouble() ?? 0.0,
      summary: json['summary'] as String? ?? '',
    );
  }

  /// Fallback: parse from legacy string like "Medium" or "High"
  factory CommunityImpact.fromLegacy(String level) {
    final val = switch (level.toLowerCase()) {
      'high' => 82.0,
      'medium' => 58.0,
      'low' => 35.0,
      _ => 50.0,
    };
    return CommunityImpact(
      social: val,
      environmental: val * 0.85,
      economic: val * 0.75,
      overall: val * 0.9,
      summary: 'Estimated $level community impact.',
    );
  }

  Map<String, dynamic> toJson() => {
        'social': social,
        'environmental': environmental,
        'economic': economic,
        'overall': overall,
        'summary': summary,
      };
}

class ResearchBackbone {
  final String researchTitle;
  final String methodology;
  final List<String> sdgAlignment;
  final FeasibilityScore feasibilityScore;
  final CommunityImpact communityImpact;

  ResearchBackbone({
    required this.researchTitle,
    required this.methodology,
    required this.sdgAlignment,
    required this.feasibilityScore,
    required this.communityImpact,
  });

  factory ResearchBackbone.fromJson(Map<String, dynamic> json) {
    final impactRaw = json['community_impact_level'];
    CommunityImpact impact;
    if (impactRaw is Map<String, dynamic>) {
      impact = CommunityImpact.fromJson(impactRaw);
    } else if (impactRaw is String) {
      impact = CommunityImpact.fromLegacy(impactRaw);
    } else {
      impact = CommunityImpact.fromLegacy('Medium');
    }

    return ResearchBackbone(
      researchTitle: json['research_title'] as String,
      methodology: json['methodology'] as String,
      sdgAlignment: List<String>.from(json['sdg_alignment'] as List),
      feasibilityScore: FeasibilityScore.fromJson(
        json['feasibility_score'] as Map<String, dynamic>,
      ),
      communityImpact: impact,
    );
  }

  Map<String, dynamic> toJson() => {
        'research_title': researchTitle,
        'methodology': methodology,
        'sdg_alignment': sdgAlignment,
        'feasibility_score': feasibilityScore.toJson(),
        'community_impact_level': communityImpact.toJson(),
      };
}
