import 'package:json_annotation/json_annotation.dart';

part 'research_backbone.g.dart';

@JsonSerializable()
class FeasibilityScore {
  final String cost;
  final String time;
  @JsonKey(name: 'data_availability')
  final String dataAvailability;

  FeasibilityScore({
    required this.cost,
    required this.time,
    required this.dataAvailability,
  });

  factory FeasibilityScore.fromJson(Map<String, dynamic> json) =>
      _$FeasibilityScoreFromJson(json);

  Map<String, dynamic> toJson() => _$FeasibilityScoreToJson(this);
}

@JsonSerializable()
class ResearchBackbone {
  @JsonKey(name: 'research_title')
  final String researchTitle;
  final String methodology;
  @JsonKey(name: 'sdg_alignment')
  final List<String> sdgAlignment;
  @JsonKey(name: 'feasibility_score')
  final FeasibilityScore feasibilityScore;
  @JsonKey(name: 'community_impact_level')
  final String communityImpactLevel;

  ResearchBackbone({
    required this.researchTitle,
    required this.methodology,
    required this.sdgAlignment,
    required this.feasibilityScore,
    required this.communityImpactLevel,
  });

  factory ResearchBackbone.fromJson(Map<String, dynamic> json) =>
      _$ResearchBackboneFromJson(json);

  Map<String, dynamic> toJson() => _$ResearchBackboneToJson(this);
}
