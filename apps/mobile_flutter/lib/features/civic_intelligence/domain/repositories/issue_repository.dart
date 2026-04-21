import '../../../../core/models/issue.dart';
import '../../../../core/models/title_suggestions.dart';

abstract class IssueRepository {
  Future<List<Issue>> getValidatedIssues();

  Future<List<Issue>> getExpoIssues();

  Future<Map<String, dynamic>> submitIssue({
    required String reporterId,
    required String title,
    required String description,
    required double lat,
    required double lng,
    String? imageUrl,
    String? reporterName,
  });

  Future<Issue> getIssueById(String issueId);

  Future<TitleSuggestions> getTitleSuggestions(String issueId);
}
