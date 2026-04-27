import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'package:alitaptap_mobile/core/models/issue.dart';
import 'package:alitaptap_mobile/core/models/match_result.dart';
import 'package:alitaptap_mobile/core/models/news_article.dart';
import 'package:alitaptap_mobile/core/models/research_backbone.dart';
import 'package:alitaptap_mobile/core/models/research_post.dart';
import 'package:alitaptap_mobile/core/models/story_post.dart';
import 'package:alitaptap_mobile/core/models/title_suggestions.dart';


/// HTTP client wrapper for calling the FastAPI backend.
class ApiService {
  ApiService({String? baseUrl})
      : _baseUrl = baseUrl ?? _resolveDefaultBaseUrl();

  final String _baseUrl;
  static const _requestTimeout = Duration(seconds: 12);

  static String _resolveDefaultBaseUrl() {
    const envBaseUrl = String.fromEnvironment('API_BASE_URL');
    if (envBaseUrl.isNotEmpty) {
      return envBaseUrl;
    }

    if (kIsWeb) {
      return 'http://127.0.0.1:8000/api/v1';
    }

    // Android emulators map host localhost via 10.0.2.2.
    if (defaultTargetPlatform == TargetPlatform.android) {
      // Physical device: use your PC's LAN IP. Emulator: use 10.0.2.2.
      return 'http://192.168.0.139:8000/api/v1';
    }

    return 'http://127.0.0.1:8000/api/v1';
  }

  Future<http.Response> _sendWithTimeout(Future<http.Response> request) async {
    try {
      return await request.timeout(_requestTimeout);
    } on http.ClientException catch (e) {
      throw Exception(
        'Network request failed (${e.message}). Ensure the API is running and API_BASE_URL points to a reachable host: $_baseUrl',
      );
    } on TimeoutException {
      throw Exception(
        'Request timed out. Please check if the backend is running and reachable.',
      );
    }
  }

  // -----------------------------------------------------------------------
  // Auth
  // -----------------------------------------------------------------------

  /// Sign in with email and password.
  Future<Map<String, dynamic>> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _sendWithTimeout(
      http.post(
        Uri.parse('$_baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      ),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to sign in: ${response.body}');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// Register a new user.
  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String role,
  }) async {
    final response = await _sendWithTimeout(
      http.post(
        Uri.parse('$_baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password, 'role': role}),
      ),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to register: ${response.body}');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// Sign in or register via social provider (Google / Facebook).
  Future<Map<String, dynamic>> socialLogin({
    required String email,
    required String provider,
    required String providerId,
    String displayName = '',
    String role = 'student',
  }) async {
    final response = await _sendWithTimeout(
      http.post(
        Uri.parse('$_baseUrl/auth/social'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'provider': provider,
          'provider_id': providerId,
          'display_name': displayName,
          'role': role,
        }),
      ),
    );
    if (response.statusCode != 200) {
      throw Exception('Social login failed: ${response.body}');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// Save user role to backend.
  Future<void> setUserRole({
    required String userId,
    required String role,
  }) async {
    final response = await _sendWithTimeout(
      http.post(
        Uri.parse('$_baseUrl/auth/role'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId, 'role': role}),
      ),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to save role: ${response.body}');
    }
  }

  /// Fetch user role from backend.
  Future<String?> getUserRole(String userId) async {
    final response = await _sendWithTimeout(
      http.get(Uri.parse('$_baseUrl/auth/role/$userId')),
    );
    if (response.statusCode != 200) return null;
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return data['role'] as String?;
  }

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
    String? reporterName,
  }) async {
    final response = await _sendWithTimeout(
      http.post(
        Uri.parse('$_baseUrl/issues'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'reporter_id': reporterId,
          'reporter_name': reporterName,
          'title': title,
          'description': description,
          'lat': lat,
          'lng': lng,
          'image_url': imageUrl,
        }),
      ),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to submit issue: ${response.body}');
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// Get issues, optionally filtered by status.
  Future<List<Issue>> getIssues({String? status}) async {
    List<Issue> results = [];
    try {
      final uri = Uri.parse('$_baseUrl/issues').replace(
        queryParameters: status != null ? {'status': status} : null,
      );

      final response = await _sendWithTimeout(http.get(uri));

      if (response.statusCode == 200) {
        final list = jsonDecode(response.body) as List<dynamic>;
        results = list.map((e) => Issue.fromJson(e as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      if (kDebugMode) print('ApiService.getIssues failed: $e. Returning fallback mocks.');
    }

    return results;
  }

  /// Get all AI-validated issues for the expo page.
  Future<List<Issue>> getExpoIssues() async {
    final response = await _sendWithTimeout(
      http.get(Uri.parse('$_baseUrl/issues/expo/validated')),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch expo issues: ${response.body}');
    }

    final list = jsonDecode(response.body) as List<dynamic>;
    return list.map((e) => Issue.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Get a single issue by ID.
  Future<Issue> getIssue(String issueId) async {
    final response = await _sendWithTimeout(
      http.get(
        Uri.parse('$_baseUrl/issues/$issueId'),
      ),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch issue: ${response.body}');
    }

    return Issue.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  /// Update an issue.
  Future<Issue> updateIssue({
    required String issueId,
    String? title,
    String? description,
    double? lat,
    double? lng,
    String? imageUrl,
    List<String>? imageUrls,
    String? caption,
  }) async {
    final body = <String, dynamic>{};
    if (title != null) body['title'] = title;
    if (description != null) body['description'] = description;
    if (lat != null) body['lat'] = lat;
    if (lng != null) body['lng'] = lng;
    if (imageUrl != null) body['image_url'] = imageUrl;
    if (imageUrls != null) body['image_urls'] = imageUrls;
    if (caption != null) body['caption'] = caption;

    final response = await _sendWithTimeout(
      http.put(
        Uri.parse('$_baseUrl/issues/$issueId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      ),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update issue: ${response.body}');
    }

    return Issue.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  /// Delete an issue.
  Future<void> deleteIssue(String issueId) async {
    final response = await _sendWithTimeout(
      http.delete(Uri.parse('$_baseUrl/issues/$issueId')),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete issue: ${response.body}');
    }
  }

  /// Admin: update issue status (validate or reject).
  Future<Map<String, dynamic>> updateIssueStatus({
    required String issueId,
    required String status,
  }) async {
    final response = await _sendWithTimeout(
      http.patch(
        Uri.parse('$_baseUrl/issues/$issueId/status'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'status': status}),
      ),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update issue status: ${response.body}');
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// Generate and fetch research title suggestions for an issue.
  Future<TitleSuggestions> getTitleSuggestions(String issueId) async {
    final response = await _sendWithTimeout(
      http.get(
        Uri.parse('$_baseUrl/issues/$issueId/title-suggestions'),
      ),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch title suggestions: ${response.body}');
    }

    return TitleSuggestions.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  // -----------------------------------------------------------------------
  // Expo / Research Posts
  // -----------------------------------------------------------------------

  Future<List<ResearchPost>> getPosts() async {
    List<ResearchPost> results = [];
    try {
      final response = await _sendWithTimeout(
        http.get(Uri.parse('$_baseUrl/posts')),
      );
      if (response.statusCode == 200) {
        final list = jsonDecode(response.body) as List<dynamic>;
        results = list.map((e) => ResearchPost.fromJson(e as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      if (kDebugMode) print('ApiService.getPosts failed: $e. Using local mocks.');
    }

    results.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return results;
  }

  Future<ResearchPost> createPost({
    required String authorId,
    required String authorEmail,
    required String title,
    required String abstract,
    required String problemSolved,
    required List<String> sdgTags,
    required double fundingGoal,
  }) async {
    final response = await _sendWithTimeout(
      http.post(
        Uri.parse('$_baseUrl/posts'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'author_id': authorId,
          'author_email': authorEmail,
          'title': title,
          'abstract': abstract,
          'problem_solved': problemSolved,
          'sdg_tags': sdgTags,
          'funding_goal': fundingGoal,
        }),
      ),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to create post: ${response.body}');
    }
    return ResearchPost.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<ResearchPost> toggleLike({
    required String postId,
    required String userId,
  }) async {
    final response = await _sendWithTimeout(
      http.post(
        Uri.parse('$_baseUrl/posts/$postId/like'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId}),
      ),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to toggle like: ${response.body}');
    }
    return ResearchPost.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<ResearchPost> fundPost({
    required String postId,
    required String userId,
    required double amount,
  }) async {
    final response = await _sendWithTimeout(
      http.post(
        Uri.parse('$_baseUrl/posts/$postId/fund'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId, 'amount': amount}),
      ),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to fund post: ${response.body}');
    }
    return ResearchPost.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>);
  }

  /// Get a single research post by ID.
  Future<ResearchPost> getPost(String postId) async {
    final response = await _sendWithTimeout(
      http.get(Uri.parse('$_baseUrl/posts/$postId')),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to fetch post: ${response.body}');
    }
    return ResearchPost.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>);
  }

  /// Update a research post.
  Future<ResearchPost> updatePost({
    required String postId,
    String? title,
    String? abstract,
    String? problemSolved,
    String? imageUrl,
    List<String>? imageUrls,
    String? caption,
    List<String>? sdgTags,
    double? fundingGoal,
  }) async {
    final body = <String, dynamic>{};
    if (title != null) body['title'] = title;
    if (abstract != null) body['abstract'] = abstract;
    if (problemSolved != null) body['problem_solved'] = problemSolved;
    if (imageUrl != null) body['image_url'] = imageUrl;
    if (imageUrls != null) body['image_urls'] = imageUrls;
    if (caption != null) body['caption'] = caption;
    if (sdgTags != null) body['sdg_tags'] = sdgTags;
    if (fundingGoal != null) body['funding_goal'] = fundingGoal;

    final response = await _sendWithTimeout(
      http.put(
        Uri.parse('$_baseUrl/posts/$postId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      ),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update post: ${response.body}');
    }
    return ResearchPost.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>);
  }

  /// Delete a research post.
  Future<void> deletePost(String postId) async {
    final response = await _sendWithTimeout(
      http.delete(Uri.parse('$_baseUrl/posts/$postId')),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to delete post: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> addComment({
    required String postId,
    required String authorId,
    required String authorEmail,
    required String text,
  }) async {
    final response = await _sendWithTimeout(
      http.post(
        Uri.parse('$_baseUrl/posts/$postId/comments'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'author_id': authorId,
          'author_email': authorEmail,
          'text': text,
        }),
      ),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to add comment: ${response.body}');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> getComments(String postId) async {
    final response = await _sendWithTimeout(
      http.get(Uri.parse('$_baseUrl/posts/$postId/comments')),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to fetch comments: ${response.body}');
    }
    final list = jsonDecode(response.body) as List<dynamic>;
    return list.map((e) => e as Map<String, dynamic>).toList();
  }

  // -----------------------------------------------------------------------
  // Stories
  // -----------------------------------------------------------------------

  Future<List<StoryPost>> getStories() async {
    try {
      final response = await _sendWithTimeout(
        http.get(Uri.parse('$_baseUrl/stories')),
      );
      if (response.statusCode == 200) {
        final list = jsonDecode(response.body) as List<dynamic>;
        return list.map((e) => StoryPost.fromJson(e as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      if (kDebugMode) print('ApiService.getStories failed: $e');
    }
    return [];
  }

  // -----------------------------------------------------------------------
  // Neural Mapper
  // -----------------------------------------------------------------------

  Future<List<NewsArticle>> getNews() async {
    final response = await _sendWithTimeout(
      http.get(Uri.parse('$_baseUrl/news')),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to fetch news: ${response.body}');
    }
    final list = jsonDecode(response.body) as List<dynamic>;
    return list
        .map((e) => NewsArticle.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Match a student idea against validated issues.
  Future<MapperRunResult> matchIdea({
    required String studentId,
    required String ideaText,
    int maxResults = 5,
  }) async {
    final response = await _sendWithTimeout(
      http.post(
        Uri.parse('$_baseUrl/mapper/match'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'student_id': studentId,
          'idea_text': ideaText,
          'max_results': maxResults,
        }),
      ),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to match idea: ${response.body}');
    }

    return MapperRunResult.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  /// Find nearest issues to a given location.
  Future<List<MatchResult>> findNearestIssues({
    required double lat,
    required double lng,
    int maxResults = 5,
  }) async {
    final response = await _sendWithTimeout(
      http.post(
        Uri.parse('$_baseUrl/mapper/nearest'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'lat': lat,
          'lng': lng,
          'max_results': maxResults,
        }),
      ),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to find nearest issues: ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final matches = data['matches'] as List<dynamic>;
    return matches
        .map((e) => MatchResult.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Generate AI-guided research backbone from problem, idea, and approach.
  Future<ResearchBackbone> generateResearchBackbone({
    required String studentId,
    required String problem,
    required String sdgOrIdea,
    required String approach,
  }) async {
    final response = await _sendWithTimeout(
      http.post(
        Uri.parse('$_baseUrl/research/backbone/generate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'student_id': studentId,
          'problem': problem,
          'sdg_or_idea': sdgOrIdea,
          'approach': approach,
        }),
      ),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to generate research backbone: ${response.body}');
    }

    return ResearchBackbone.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }
}
