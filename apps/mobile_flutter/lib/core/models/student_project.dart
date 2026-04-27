class StudentProject {
  final String projectId;
  final String authorId;
  final String title;
  final String description;
  final String sdg;
  final String mode;
  final String methodology;
  final String impact;
  final String feasibility;
  final String date;

  const StudentProject({
    required this.projectId,
    required this.authorId,
    required this.title,
    required this.description,
    required this.sdg,
    required this.mode,
    required this.methodology,
    required this.impact,
    required this.feasibility,
    required this.date,
  });

  factory StudentProject.fromJson(Map<String, dynamic> json) => StudentProject(
        projectId: json['project_id'] as String,
        authorId: json['author_id'] as String,
        title: json['title'] as String,
        description: json['description'] as String,
        sdg: json['sdg'] as String,
        mode: json['mode'] as String? ?? 'manual',
        methodology: json['methodology'] as String? ?? '',
        impact: json['impact'] as String? ?? '',
        feasibility: json['feasibility'] as String? ?? '',
        date: json['date'] as String? ?? '',
      );
}
