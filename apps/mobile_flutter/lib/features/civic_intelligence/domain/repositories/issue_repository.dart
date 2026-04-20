import '../../../../core/models/issue.dart';
import '../../../../core/models/title_suggestions.dart';

abstract class IssueRepository {
  Future<List<Issue>> getValidatedIssues();

  Future<Map<String, dynamic>> submitIssue({
    required String reporterId,
    required String title,
    required String description,
    required double lat,
    required double lng,
    String? imageUrl,
  });

  Future<Issue> getIssueById(String issueId);

  Future<TitleSuggestions> getTitleSuggestions(String issueId);
}
