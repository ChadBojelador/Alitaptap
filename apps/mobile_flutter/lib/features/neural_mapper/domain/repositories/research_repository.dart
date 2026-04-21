import '../../../../core/models/research_backbone.dart';

abstract class ResearchRepository {
  Future<ResearchBackbone> generateBackbone({
    required String studentId,
    required String problem,
    required String sdgOrIdea,
    required String approach,
  });
}
