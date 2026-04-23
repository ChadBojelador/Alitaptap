/// Issue model matching the Firestore `issues` collection schema.
class Issue {
  Issue({
    required this.issueId,
    required this.reporterId,
    this.reporterName,
    required this.title,
    required this.description,
    required this.lat,
    required this.lng,
    this.imageUrl,
    required this.status,
    this.tags = const [],
    this.aiSummary,
    this.aiSdgTag,
    this.locationName,
    required this.createdAt,
    this.updatedAt,
  });

  final String issueId;
  final String reporterId;
  final String? reporterName;
  final String title;
  final String description;
  final double lat;
  final double lng;
  final String? imageUrl;
  final String status;
  final List<String> tags;
  final String? aiSummary;
  final String? aiSdgTag;
  final String? locationName;
  final String createdAt;
  final String? updatedAt;

  factory Issue.fromJson(Map<String, dynamic> json) {
    return Issue(
      issueId: json['issue_id'] as String? ?? '',
      reporterId: json['reporter_id'] as String? ?? '',
      reporterName: json['reporter_name'] as String?,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      lat: (json['lat'] as num?)?.toDouble() ?? 0.0,
      lng: (json['lng'] as num?)?.toDouble() ?? 0.0,
      imageUrl: json['image_url'] as String?,
      status: json['status'] as String? ?? 'pending',
      tags: (json['tags'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      aiSummary: json['ai_summary'] as String?,
      aiSdgTag: json['ai_sdg_tag'] as String?,
      locationName: json['location_name'] as String?,
      createdAt: json['created_at'] as String? ?? '',
      updatedAt: json['updated_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'issue_id': issueId,
      'reporter_id': reporterId,
      'reporter_name': reporterName,
      'title': title,
      'description': description,
      'lat': lat,
      'lng': lng,
      'image_url': imageUrl,
      'status': status,
      'tags': tags,
      'ai_summary': aiSummary,
      'ai_sdg_tag': aiSdgTag,
      'location_name': locationName,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}
