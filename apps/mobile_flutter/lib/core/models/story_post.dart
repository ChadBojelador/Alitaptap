class StoryPost {
  const StoryPost({
    required this.storyId,
    required this.bubbleLabel,
    required this.title,
    required this.description,
    required this.sdgLabel,
    required this.sdgName,
    required this.imagePath,
  });

  final String storyId;
  final String bubbleLabel;
  final String title;
  final String description;
  final String sdgLabel;
  final String sdgName;
  final String imagePath;

  factory StoryPost.fromJson(Map<String, dynamic> json) => StoryPost(
        storyId: json['story_id'] as String? ?? '',
        bubbleLabel: json['bubble_label'] as String? ?? '',
        title: json['title'] as String? ?? '',
        description: json['description'] as String? ?? '',
        sdgLabel: json['sdg_label'] as String? ?? '',
        sdgName: json['sdg_name'] as String? ?? '',
        imagePath: json['image_url'] as String? ?? '',
      );
}
