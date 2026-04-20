import '../../../../core/models/title_suggestions.dart';
import '../../domain/repositories/issue_repository.dart';

class GetTitleSuggestionsUseCase {
  GetTitleSuggestionsUseCase(this._repository);

  final IssueRepository _repository;

  Future<TitleSuggestions> call(String issueId) {
    return _repository.getTitleSuggestions(issueId);
  }
}
