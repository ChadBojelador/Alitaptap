class CommunityProblemPost {
  CommunityProblemPost({
    required this.postId,
    required this.reporterName,
    required this.title,
    required this.description,
    required this.createdAt,
    this.likes = 0,
    this.likedBy = const [],
    this.shares = 0,
    this.imageUrl,
    List<String>? imageUrls,
  }) : _imageUrls = imageUrls;

  final String postId;
  final String reporterName;
  final String title;
  final String description;
  final String createdAt;
  final int likes;
  final List<String> likedBy;
  final int shares;
  final String? imageUrl;
  final List<String>? _imageUrls;

  List<String> get imageUrls => _imageUrls ?? const <String>[];

  factory CommunityProblemPost.fromJson(Map<String, dynamic> json) =>
      CommunityProblemPost(
        postId: json['post_id'] as String? ?? '',
        reporterName: json['reporter_name'] as String? ?? '',
        title: json['title'] as String? ?? '',
        description: json['description'] as String? ?? '',
        createdAt: json['created_at'] as String? ?? '',
        likes: (json['likes'] as num?)?.toInt() ?? 0,
        likedBy: (json['liked_by'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [],
        shares: (json['shares'] as num?)?.toInt() ?? 0,
        imageUrl: json['image_url'] as String?,
        imageUrls: (json['image_urls'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            (((json['image_url'] as String?)?.isNotEmpty ?? false)
                ? [json['image_url'] as String]
                : []),
      );
}
