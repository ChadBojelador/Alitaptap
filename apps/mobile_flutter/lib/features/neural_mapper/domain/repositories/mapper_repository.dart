import '../../../../core/models/match_result.dart';

abstract class MapperRepository {
  Future<MapperRunResult> matchIdea({
    required String studentId,
    required String ideaText,
    int maxResults,
  });
}
