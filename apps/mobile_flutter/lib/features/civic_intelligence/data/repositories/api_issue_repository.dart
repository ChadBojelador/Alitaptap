import '../../../../core/models/issue.dart';
import '../../../../core/models/title_suggestions.dart';
import '../../../../services/api_service.dart';
import '../../domain/repositories/issue_repository.dart';

class ApiIssueRepository implements IssueRepository {
  ApiIssueRepository({ApiService? apiService})
      : _apiService = apiService ?? ApiService();

  final ApiService _apiService;

  @override
  Future<List<Issue>> getValidatedIssues() {
    return _apiService.getIssues(status: 'validated');
  }

  @override
  Future<List<Issue>> getExpoIssues() {
    return _apiService.getExpoIssues();
  }

  @override
  Future<Map<String, dynamic>> submitIssue({
    required String reporterId,
    required String title,
    required String description,
    required double lat,
    required double lng,
    String? imageUrl,
    String? reporterName,
  }) {
    return _apiService.submitIssue(
      reporterId: reporterId,
      reporterName: reporterName,
      title: title,
      description: description,
      lat: lat,
      lng: lng,
      imageUrl: imageUrl,
    );
  }

  @override
  Future<Issue> getIssueById(String issueId) {
    return _apiService.getIssue(issueId);
  }

  @override
  Future<TitleSuggestions> getTitleSuggestions(String issueId) {
    return _apiService.getTitleSuggestions(issueId);
  }
}
