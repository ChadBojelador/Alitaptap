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

class ResearchBackbone {
  final String researchTitle;
  final String methodology;
  final List<String> sdgAlignment;
  final FeasibilityScore feasibilityScore;
  final String communityImpactLevel;

  ResearchBackbone({
    required this.researchTitle,
    required this.methodology,
    required this.sdgAlignment,
    required this.feasibilityScore,
    required this.communityImpactLevel,
  });

  factory ResearchBackbone.fromJson(Map<String, dynamic> json) {
    return ResearchBackbone(
      researchTitle: json['research_title'] as String,
      methodology: json['methodology'] as String,
      sdgAlignment: List<String>.from(json['sdg_alignment'] as List),
      feasibilityScore: FeasibilityScore.fromJson(
        json['feasibility_score'] as Map<String, dynamic>,
      ),
      communityImpactLevel: json['community_impact_level'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'research_title': researchTitle,
        'methodology': methodology,
        'sdg_alignment': sdgAlignment,
        'feasibility_score': feasibilityScore.toJson(),
        'community_impact_level': communityImpactLevel,
      };
}
