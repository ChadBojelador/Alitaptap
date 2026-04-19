import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/models/issue.dart';
import '../core/models/match_result.dart';

/// HTTP client wrapper for calling the FastAPI backend.
class ApiService {
  ApiService({String? baseUrl})
      : _baseUrl = baseUrl ?? 'http://10.0.2.2:8000/api/v1';

  final String _baseUrl;

  // -----------------------------------------------------------------------
  // Issues
  // -----------------------------------------------------------------------

  /// Submit a new community problem report.
  Future<Map<String, dynamic>> submitIssue({
    required String reporterId,
    required String title,
    required String description,
    required double lat,
    required double lng,
    String? imageUrl,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/issues'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'reporter_id': reporterId,
        'title': title,
        'description': description,
        'lat': lat,
        'lng': lng,
        'image_url': imageUrl,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to submit issue: ${response.body}');
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// Get issues, optionally filtered by status.
  Future<List<Issue>> getIssues({String? status}) async {
    final uri = status != null
        ? Uri.parse('$_baseUrl/issues?status=$status')
        : Uri.parse('$_baseUrl/issues');

    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch issues: ${response.body}');
    }

    final list = jsonDecode(response.body) as List<dynamic>;
    return list
        .map((e) => Issue.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Get a single issue by ID.
  Future<Issue> getIssue(String issueId) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/issues/$issueId'),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch issue: ${response.body}');
    }

    return Issue.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  /// Admin: update issue status (validate or reject).
  Future<Map<String, dynamic>> updateIssueStatus({
    required String issueId,
    required String status,
  }) async {
    final response = await http.patch(
      Uri.parse('$_baseUrl/issues/$issueId/status'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'status': status}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update issue status: ${response.body}');
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  // -----------------------------------------------------------------------
  // Neural Mapper
  // -----------------------------------------------------------------------

  /// Match a student idea against validated issues.
  Future<MapperRunResult> matchIdea({
    required String studentId,
    required String ideaText,
    int maxResults = 5,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/mapper/match'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'student_id': studentId,
        'idea_text': ideaText,
        'max_results': maxResults,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to match idea: ${response.body}');
    }

    return MapperRunResult.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }
}
