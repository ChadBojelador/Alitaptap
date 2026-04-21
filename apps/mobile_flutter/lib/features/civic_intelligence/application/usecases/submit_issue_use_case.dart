import '../../domain/repositories/issue_repository.dart';

class SubmitIssueInput {
  const SubmitIssueInput({
    required this.reporterId,
    required this.title,
    required this.description,
    required this.lat,
    required this.lng,
    this.imageUrl,
    this.reporterName,
  });

  final String reporterId;
  final String title;
  final String description;
  final double lat;
  final double lng;
  final String? imageUrl;
  final String? reporterName;
}

class SubmitIssueUseCase {
  SubmitIssueUseCase(this._repository);

  final IssueRepository _repository;

  Future<Map<String, dynamic>> call(SubmitIssueInput input) {
    return _repository.submitIssue(
      reporterId: input.reporterId,
      title: input.title,
      description: input.description,
      lat: input.lat,
      lng: input.lng,
      imageUrl: input.imageUrl,
      reporterName: input.reporterName,
    );
  }
}
