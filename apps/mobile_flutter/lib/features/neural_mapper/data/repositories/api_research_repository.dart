import '../../../../core/models/research_backbone.dart';
import '../../../../services/api_service.dart';
import '../../domain/repositories/research_repository.dart';

class ApiResearchRepository implements ResearchRepository {
  ApiResearchRepository({ApiService? apiService})
      : _apiService = apiService ?? ApiService();

  final ApiService _apiService;

  @override
  Future<ResearchBackbone> generateBackbone({
    required String studentId,
    required String problem,
    required String sdgOrIdea,
    required String approach,
  }) {
    return _apiService.generateResearchBackbone(
      studentId: studentId,
      problem: problem,
      sdgOrIdea: sdgOrIdea,
      approach: approach,
    );
  }
}
