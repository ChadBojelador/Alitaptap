import '../../../../core/models/match_result.dart';
import '../../domain/repositories/mapper_repository.dart';

class MatchIdeaInput {
  const MatchIdeaInput({
    required this.studentId,
    required this.ideaText,
    this.maxResults = 5,
  });

  final String studentId;
  final String ideaText;
  final int maxResults;
}

class MatchIdeaUseCase {
  MatchIdeaUseCase(this._repository);

  final MapperRepository _repository;

  Future<MapperRunResult> call(MatchIdeaInput input) {
    return _repository.matchIdea(
      studentId: input.studentId,
      ideaText: input.ideaText,
      maxResults: input.maxResults,
    );
  }
}
