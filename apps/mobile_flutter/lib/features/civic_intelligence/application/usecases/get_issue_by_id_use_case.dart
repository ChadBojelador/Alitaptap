import '../../../../core/models/issue.dart';
import '../../domain/repositories/issue_repository.dart';

class GetIssueByIdUseCase {
  GetIssueByIdUseCase(this._repository);

  final IssueRepository _repository;

  Future<Issue> call(String issueId) {
    return _repository.getIssueById(issueId);
  }
}
