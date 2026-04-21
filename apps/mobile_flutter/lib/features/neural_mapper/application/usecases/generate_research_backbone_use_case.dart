import '../../../../core/models/research_backbone.dart';
import '../../domain/repositories/research_repository.dart';

class GenerateResearchBackboneInput {
  const GenerateResearchBackboneInput({
    required this.studentId,
    required this.problem,
    required this.sdgOrIdea,
    required this.approach,
  });

  final String studentId;
  final String problem;
  final String sdgOrIdea;
  final String approach;
}

class GenerateResearchBackboneUseCase {
  GenerateResearchBackboneUseCase(this._repository);

  final ResearchRepository _repository;

  Future<ResearchBackbone> call(GenerateResearchBackboneInput input) {
    return _repository.generateBackbone(
      studentId: input.studentId,
      problem: input.problem,
      sdgOrIdea: input.sdgOrIdea,
      approach: input.approach,
    );
  }
}
