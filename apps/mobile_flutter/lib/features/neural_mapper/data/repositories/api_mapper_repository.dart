import '../../../../core/models/match_result.dart';
import '../../../../services/api_service.dart';
import '../../domain/repositories/mapper_repository.dart';

class ApiMapperRepository implements MapperRepository {
  ApiMapperRepository({ApiService? apiService})
      : _apiService = apiService ?? ApiService();

  final ApiService _apiService;

  @override
  Future<MapperRunResult> matchIdea({
    required String studentId,
    required String ideaText,
    int maxResults = 5,
  }) {
    return _apiService.matchIdea(
      studentId: studentId,
      ideaText: ideaText,
      maxResults: maxResults,
    );
  }
}
