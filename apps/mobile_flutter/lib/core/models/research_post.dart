class ResearchPost {
  ResearchPost({
    required this.postId,
    required this.authorId,
    required this.authorEmail,
    required this.title,
    required this.abstract,
    required this.problemSolved,
    required this.sdgTags,
    required this.fundingGoal,
    required this.fundingRaised,
    required this.likes,
    required this.createdAt,
    this.likedBy = const [],
    this.imageUrl,
    this.shares = 0,
    this.reactions = const {},
  });

  final String postId;
  final String authorId;
  final String authorEmail;
  final String title;
  final String abstract;
  final String problemSolved;
  final List<String> sdgTags;
  final double fundingGoal;
  final double fundingRaised;
  final int likes;
  final String createdAt;
  final List<String> likedBy;
  final String? imageUrl;
  final int shares;
  final Map<String, int> reactions; // e.g. {'like':5,'love':2,'haha':1}

  factory ResearchPost.fromJson(Map<String, dynamic> json) => ResearchPost(
        postId: json['post_id'] as String? ?? '',
        authorId: json['author_id'] as String? ?? '',
        authorEmail: json['author_email'] as String? ?? '',
        title: json['title'] as String? ?? '',
        abstract: json['abstract'] as String? ?? '',
        problemSolved: json['problem_solved'] as String? ?? '',
        sdgTags: (json['sdg_tags'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [],
        fundingGoal: (json['funding_goal'] as num?)?.toDouble() ?? 0,
        fundingRaised: (json['funding_raised'] as num?)?.toDouble() ?? 0,
        likes: (json['likes'] as num?)?.toInt() ?? 0,
        createdAt: json['created_at'] as String? ?? '',
        likedBy: (json['liked_by'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [],
        imageUrl: json['image_url'] as String?,
        shares: (json['shares'] as num?)?.toInt() ?? 0,
        reactions: (json['reactions'] as Map<String, dynamic>?)
                ?.map((k, v) => MapEntry(k, (v as num).toInt())) ??
            {},
      );
}
