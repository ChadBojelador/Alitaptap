import 'package:alitaptap_mobile/core/models/issue.dart';
import 'package:alitaptap_mobile/core/models/title_suggestions.dart';
import 'package:alitaptap_mobile/features/civic_intelligence/application/usecases/get_validated_issues_use_case.dart';
import 'package:alitaptap_mobile/features/civic_intelligence/domain/repositories/issue_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeIssueRepository implements IssueRepository {
  @override
  Future<List<Issue>> getValidatedIssues() async {
    return [
      Issue(
        issueId: 'i-1',
        reporterId: 'r-1',
        title: 'Garbage buildup',
        description: 'Waste accumulates near drainage',
        lat: 10,
        lng: 11,
        status: 'validated',
        createdAt: '2026-04-21T00:00:00Z',
      ),
    ];
  }

  @override
  Future<Issue> getIssueById(String issueId) {
    throw UnimplementedError();
  }

  @override
  Future<TitleSuggestions> getTitleSuggestions(String issueId) {
    throw UnimplementedError();
  }

  @override
  Future<List<Issue>> getExpoIssues() {
    throw UnimplementedError();
  }

  @override
  Future<Map<String, dynamic>> submitIssue({
    required String reporterId,
    String? reporterName,
    required String title,
    required String description,
    required double lat,
    required double lng,
    String? imageUrl,
  }) {
    throw UnimplementedError();
  }
}

void main() {
  test('GetValidatedIssuesUseCase returns validated issues from repository', () async {
    final useCase = GetValidatedIssuesUseCase(_FakeIssueRepository());

    final issues = await useCase();

    expect(issues, hasLength(1));
    expect(issues.first.issueId, 'i-1');
    expect(issues.first.status, 'validated');
  });
}
