import 'dart:async';
import 'dart:convert';
import 'dart:io';

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
  static const _headers = {'Content-Type': 'application/json'};
  static const _requestTimeout = Duration(seconds: 12);

  static String _resolveDefaultBaseUrl() {
    const envBaseUrl = String.fromEnvironment('API_BASE_URL');
    if (envBaseUrl.isNotEmpty) return envBaseUrl;
    if (kIsWeb) return 'http://127.0.0.1:8000/api/v1';
    // Use 10.0.2.2 for emulator, override via API_BASE_URL env for physical device
    if (defaultTargetPlatform == TargetPlatform.android) return 'http://10.0.2.2:8000/api/v1';
    return 'http://127.0.0.1:8000/api/v1';
  }

  /// Rewrites image URLs so they are reachable from the device.
  /// FastAPI returns `http://127.0.0.1:8000/uploads/...` which is its own
  /// loopback. On an Android emulator the host PC is `10.0.2.2`, so we
  /// replace the host accordingly.  On web / desktop / physical device we
  /// leave the URL untouched (caller may pass API_BASE_URL at build time).
  static String fixImageUrl(String? url) {
    if (url == null || url.isEmpty) return url ?? '';
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return url
          .replaceFirst('http://127.0.0.1:', 'http://10.0.2.2:')
          .replaceFirst('http://localhost:', 'http://10.0.2.2:');
    }
    return url;
  }

  Uri _uri(String path) => Uri.parse('$_baseUrl$path');

  /// Sends request, throws a clean user-facing message on error.
  Future<Map<String, dynamic>> _post(String path, Map<String, dynamic> body) async {
    try {
      final res = await http.post(_uri(path), headers: _headers, body: jsonEncode(body))
          .timeout(_requestTimeout);
      final decoded = jsonDecode(res.body);
      if (res.statusCode != 200) {
        final detail = decoded is Map ? (decoded['detail'] ?? decoded['error'] ?? res.body) : res.body;
        throw Exception(detail.toString());
      }
      return decoded as Map<String, dynamic>;
    } on TimeoutException {
      throw Exception('Request timed out. Is the backend running?');
    } on http.ClientException catch (e) {
      throw Exception('Cannot reach server: ${e.message}');
    }
  }

  Future<Map<String, dynamic>> _get(String path) async {
    try {
      final res = await http.get(_uri(path), headers: _headers).timeout(_requestTimeout);
      if (res.statusCode != 200) throw Exception('Request failed: ${res.body}');
      return jsonDecode(res.body) as Map<String, dynamic>;
    } on TimeoutException {
      throw Exception('Request timed out.');
    } on http.ClientException catch (e) {
      throw Exception('Cannot reach server: ${e.message}');
    }
  }

  Future<http.Response> _sendWithTimeout(Future<http.Response> request) async {
    try {
      return await request.timeout(_requestTimeout);
    } on http.ClientException catch (e) {
      throw Exception('Network request failed (${e.message}). $_baseUrl');
    } on TimeoutException {
      throw Exception('Request timed out.');
    }
  }

  /// Sign in with email and password.
  Future<Map<String, dynamic>> signIn({required String email, required String password}) =>
      _post('/auth/login', {'email': email, 'password': password});

  /// Register a new user.
  Future<Map<String, dynamic>> register({required String email, required String password, required String role}) =>
      _post('/auth/register', {'email': email, 'password': password, 'role': role});

  /// Sign in or register via social provider.
  Future<Map<String, dynamic>> socialLogin({
    required String email,
    required String provider,
    required String providerId,
    String displayName = '',
    String role = 'student',
  }) => _post('/auth/social', {
    'email': email,
    'provider': provider,
    'provider_id': providerId,
    'display_name': displayName,
    'role': role,
  });

  /// Save user role to backend.
  Future<void> setUserRole({required String userId, required String role}) =>
      _post('/auth/role', {'user_id': userId, 'role': role});

  /// Fetch user role from backend.
  Future<String?> getUserRole(String userId) async {
    try {
      final data = await _get('/auth/role/$userId');
      return data['role'] as String?;
    } catch (_) { return null; }
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
  /// Returns only real user-submitted issues from the API.
  Future<List<Issue>> getIssues({String? status}) async {
    try {
      final uri = Uri.parse('$_baseUrl/issues').replace(
        queryParameters: status != null ? {'status': status} : null,
      );

      final response = await _sendWithTimeout(http.get(uri));

      if (response.statusCode == 200) {
        final list = jsonDecode(response.body) as List<dynamic>;
        return list.map((e) => Issue.fromJson(e as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      if (kDebugMode) print('ApiService.getIssues failed: $e');
    }

    // Return empty list if backend is unreachable — no mock fallback.
    return [];
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

  /// Rewrites image_url / image_urls in a raw post JSON map so that URLs
  /// like `http://127.0.0.1:8000/uploads/...` become reachable on the device.
  /// Also filters out null / empty URLs so Image.network is never called
  /// with an empty string (which causes silent failures on Android).
  static Map<String, dynamic> _fixPostJson(Map<String, dynamic> json) {
    final rawUrl = json['image_url'] as String?;
    final fixedUrl = fixImageUrl(rawUrl);
    final rawUrls = (json['image_urls'] as List<dynamic>?)
        ?.map((e) => fixImageUrl(e as String?))
        .where((u) => u.isNotEmpty)  // drop empty/null entries
        .toList();
    return <String, dynamic>{
      ...json,
      // Only set image_url if it's non-empty after fix
      'image_url': fixedUrl.isNotEmpty ? fixedUrl : null,
      if (rawUrls != null) 'image_urls': rawUrls,
    };
  }

  Future<List<ResearchPost>> getPosts() async {
    try {
      final response = await _sendWithTimeout(
        http.get(Uri.parse('$_baseUrl/posts')),
      );
      if (response.statusCode == 200) {
        final list = jsonDecode(response.body) as List<dynamic>;
        final results = list
            .map((e) => ResearchPost.fromJson(_fixPostJson(e as Map<String, dynamic>)))
            .toList();
        // Sort by "created_at" descending
        results.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return results;
      }
    } catch (e) {
      if (kDebugMode) print('ApiService.getPosts failed: $e');
    }

    return [];
  }

  Future<ResearchPost> createPost({
    required String authorId,
    required String authorEmail,
    required String title,
    required String abstract,
    required String problemSolved,
    required List<String> sdgTags,
    required double fundingGoal,
    String? imageUrl,
    List<String>? imageUrls,
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
          if (imageUrl != null) 'image_url': imageUrl,
          if (imageUrls != null) 'image_urls': imageUrls,
        }),
      ),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to create post: ${response.body}');
    }
    return ResearchPost.fromJson(
        _fixPostJson(jsonDecode(response.body) as Map<String, dynamic>));
  }

  Future<String> uploadImage(File file) async {
    final request = http.MultipartRequest('POST', Uri.parse('$_baseUrl/posts/upload'));
    request.files.add(await http.MultipartFile.fromPath('file', file.path));
    
    final streamedResponse = await request.send().timeout(const Duration(seconds: 15));
    final response = await http.Response.fromStream(streamedResponse);
    
    if (response.statusCode != 200) {
      throw Exception('Failed to upload image: ${response.body}');
    }
    
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    // Fix the URL so Android emulator can reach the host machine.
    return fixImageUrl(data['image_url'] as String?);
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
        _fixPostJson(jsonDecode(response.body) as Map<String, dynamic>));
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
        _fixPostJson(jsonDecode(response.body) as Map<String, dynamic>));
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
        _fixPostJson(jsonDecode(response.body) as Map<String, dynamic>));
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
        _fixPostJson(jsonDecode(response.body) as Map<String, dynamic>));
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
    try {
      final response = await _sendWithTimeout(
        http.get(Uri.parse('$_baseUrl/news')),
      );
      if (response.statusCode == 200) {
        final list = jsonDecode(response.body) as List<dynamic>;
        return list.map((e) => NewsArticle.fromJson(e as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      if (kDebugMode) print('ApiService.getNews failed: $e');
    }
    return [];
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
