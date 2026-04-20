import '../../../../core/models/issue.dart';
import '../../domain/repositories/issue_repository.dart';

class GetValidatedIssuesUseCase {
  GetValidatedIssuesUseCase(this._repository);

  final IssueRepository _repository;

  Future<List<Issue>> call() {
    return _repository.getValidatedIssues();
  }
}
