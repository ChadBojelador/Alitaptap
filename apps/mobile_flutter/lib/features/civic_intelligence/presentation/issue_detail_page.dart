import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

import '../../../core/models/issue.dart';
import '../../../core/models/title_suggestions.dart';
import '../application/usecases/get_issue_by_id_use_case.dart';
import '../application/usecases/get_title_suggestions_use_case.dart';
import '../data/repositories/api_issue_repository.dart';

/// Detail page for a single community issue.
class IssueDetailPage extends StatefulWidget {
  const IssueDetailPage({super.key, required this.issueId});

  final String issueId;

  @override
  State<IssueDetailPage> createState() => _IssueDetailPageState();
}

class _IssueDetailPageState extends State<IssueDetailPage> {
  final _issueRepository = ApiIssueRepository();

  late final GetIssueByIdUseCase _getIssueByIdUseCase =
      GetIssueByIdUseCase(_issueRepository);
  late final GetTitleSuggestionsUseCase _getTitleSuggestionsUseCase =
      GetTitleSuggestionsUseCase(_issueRepository);

  Issue? _issue;
  TitleSuggestions? _titleSuggestions;
  bool _loading = true;
  bool _loadingSuggestions = false;
  String? _suggestionError;
  String? _address;
  bool _resolvingAddress = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final issue = await _getIssueByIdUseCase(widget.issueId);
      if (mounted) {
        setState(() {
          _issue = issue;
          _loading = false;
        });
        _resolveAddress();
      }
      await _loadTitleSuggestions();
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _resolveAddress() async {
    if (_issue == null) return;
    try {
      setState(() => _resolvingAddress = true);
      final url = 'https://nominatim.openstreetmap.org/reverse?format=json&lat=${_issue!.lat}&lon=${_issue!.lng}&zoom=16';
      final response = await http.get(Uri.parse(url), headers: {
        'User-Agent': 'AlitaptapApp/1.0',
      });
      
      if (mounted) {
        setState(() => _resolvingAddress = false);
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final address = data['display_name'] ?? '';
          final parts = address.split(', ');
          if (parts.length > 3) {
            setState(() => _address = '${parts[0]}, ${parts[1]}, ${parts[2]}');
          } else {
            setState(() => _address = address);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _resolvingAddress = false;
          _address = 'Location coordinates: ${_issue!.lat.toStringAsFixed(4)}, ${_issue!.lng.toStringAsFixed(4)}';
        });
      }
    }
  }

  Future<void> _loadTitleSuggestions() async {
    if (!mounted) return;

    setState(() {
      _loadingSuggestions = true;
      _suggestionError = null;
    });

    try {
      final suggestions = await _getTitleSuggestionsUseCase(widget.issueId);
      if (mounted) {
        setState(() {
          _titleSuggestions = suggestions;
          _loadingSuggestions = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingSuggestions = false;
          _suggestionError = e.toString();
        });
      }
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'validated':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  Widget _buildImpactSection(ImpactPrediction impact, bool isDark) {
    Color _overallColor() {
      if (impact.overall >= 75) return const Color(0xFF30D158);
      if (impact.overall >= 50) return const Color(0xFFFFD60A);
      return const Color(0xFFFF9F0A);
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF000000).withValues(alpha: 0.4)
            : const Color(0xFFF2F2F7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with overall score
          Row(
            children: [
              Icon(
                Icons.insights_rounded,
                size: 16,
                color: _overallColor(),
              ),
              const SizedBox(width: 6),
              Text(
                'Impact Prediction',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? const Color(0xFFE5E5EA)
                      : const Color(0xFF3C3C43),
                  letterSpacing: 0.3,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _overallColor().withValues(alpha: 0.2),
                      _overallColor().withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${impact.overall.toStringAsFixed(0)}%',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _overallColor(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Impact bars
          _buildImpactBar(
            label: 'Social',
            value: impact.social,
            icon: Icons.people_rounded,
            color: const Color(0xFF5E5CE6),
            isDark: isDark,
          ),
          const SizedBox(height: 10),
          _buildImpactBar(
            label: 'Environmental',
            value: impact.environmental,
            icon: Icons.eco_rounded,
            color: const Color(0xFF30D158),
            isDark: isDark,
          ),
          const SizedBox(height: 10),
          _buildImpactBar(
            label: 'Economic',
            value: impact.economic,
            icon: Icons.trending_up_rounded,
            color: const Color(0xFFFF9F0A),
            isDark: isDark,
          ),

          // Summary
          if (impact.summary.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              impact.summary,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: isDark
                    ? const Color(0xFF8E8E93)
                    : const Color(0xFF6C6C70),
                height: 1.4,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildImpactBar({
    required String label,
    required double value,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    final fraction = (value / 100).clamp(0.0, 1.0);

    return Row(
      children: [
        Icon(icon, size: 14, color: color.withValues(alpha: 0.8)),
        const SizedBox(width: 6),
        SizedBox(
          width: 88,
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isDark
                  ? const Color(0xFFAEAEB2)
                  : const Color(0xFF48484A),
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 8,
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF2C2C2E)
                  : const Color(0xFFE5E5EA),
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: fraction,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      color.withValues(alpha: 0.7),
                      color,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 36,
          child: Text(
            '${value.toStringAsFixed(0)}%',
            textAlign: TextAlign.right,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF000000) : const Color(0xFFF2F2F7),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Issue Details',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 17,
          ),
        ),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _issue == null
              ? Center(
                  child: Text(
                    'Issue not found',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      color: isDark
                          ? const Color(0xFF8E8E93)
                          : const Color(0xFF8E8E93),
                    ),
                  ),
                )
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Image Header
                      if (_issue!.imageUrl != null && _issue!.imageUrl!.isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: AspectRatio(
                            aspectRatio: 16 / 9,
                            child: Image.network(
                              _issue!.imageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7),
                                child: const Icon(Icons.broken_image_rounded, color: Colors.grey, size: 40),
                              ),
                            ),
                          ),
                        )
                      else
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            height: 200,
                            color: isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF2F2F7),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.image_rounded, color: isDark ? const Color(0xFF3A3A3C) : const Color(0xFFC7C7CC), size: 48),
                                const SizedBox(height: 8),
                                Text(
                                  'No Photo Attached',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: isDark ? const Color(0xFF48484A) : const Color(0xFF8E8E93),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(height: 20),
                    // Status chip
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _statusColor(_issue!.status),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _issue!.status.toUpperCase(),
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          Icons.calendar_today_rounded,
                          size: 14,
                          color: isDark
                              ? const Color(0xFF8E8E93)
                              : const Color(0xFF8E8E93),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _issue!.createdAt.split('T').first,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: isDark
                                ? const Color(0xFF8E8E93)
                                : const Color(0xFF8E8E93),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Title
                    Text(
                      _issue!.title,
                      style: GoogleFonts.inter(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? const Color(0xFFFFFFFF)
                            : const Color(0xFF000000),
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Description
                    Text(
                      _issue!.description,
                      style: GoogleFonts.inter(
                        fontSize: 17,
                        color: isDark
                            ? const Color(0xFFE5E5EA)
                            : const Color(0xFF3C3C43),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Location card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1C1C1E)
                            : const Color(0xFFFFFFFF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFD60A).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.location_on_rounded,
                              color: Color(0xFFFFD60A),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Location',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: isDark
                                        ? const Color(0xFF8E8E93)
                                        : const Color(0xFF8E8E93),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                if (_resolvingAddress)
                                  const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFFFD60A)),
                                  )
                                else
                                  Text(
                                    _address ?? '${_issue!.lat.toStringAsFixed(5)}, ${_issue!.lng.toStringAsFixed(5)}',
                                    style: GoogleFonts.inter(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                      color: isDark
                                          ? const Color(0xFFFFFFFF)
                                          : const Color(0xFF000000),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Tags
                    if (_issue!.tags.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _issue!.tags
                            .map(
                              (tag) => Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF1C1C1E)
                                      : const Color(0xFFE5E5EA),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  tag,
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: isDark
                                        ? const Color(0xFFFFFFFF)
                                        : const Color(0xFF3C3C43),
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ],

                    const SizedBox(height: 32),

                    // Research Title Suggestions header
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Research Title Suggestions',
                            style: GoogleFonts.inter(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? const Color(0xFFFFFFFF)
                                  : const Color(0xFF000000),
                            ),
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: _loadingSuggestions
                              ? null
                              : _loadTitleSuggestions,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF1C1C1E)
                                  : const Color(0xFFE5E5EA),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.refresh_rounded,
                                  size: 16,
                                  color: const Color(0xFFFFD60A),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Regenerate',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFFFFD60A),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    if (_loadingSuggestions)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else if (_suggestionError != null)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.error_outline_rounded,
                              color: Colors.red,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _suggestionError!,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: Colors.red,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    else if ((_titleSuggestions?.suggestions ?? []).isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Text(
                            'No suggestions yet.',
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              color: isDark
                                  ? const Color(0xFF8E8E93)
                                  : const Color(0xFF8E8E93),
                            ),
                          ),
                        ),
                      )
                    else
                      Column(
                        children: [
                          for (var i = 0;
                              i < _titleSuggestions!.suggestions.length;
                              i++)
                            Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF1C1C1E)
                                    : const Color(0xFFFFFFFF),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isDark
                                      ? const Color(0xFF2C2C2E)
                                      : const Color(0xFFE5E5EA),
                                  width: 0.5,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Title row
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 32,
                                        height: 32,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFFD60A)
                                              .withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          '${i + 1}',
                                          style: GoogleFonts.inter(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                            color: const Color(0xFFFFD60A),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          _titleSuggestions!.suggestions[i],
                                          style: GoogleFonts.inter(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w500,
                                            color: isDark
                                                ? const Color(0xFFFFFFFF)
                                                : const Color(0xFF000000),
                                            height: 1.4,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),

                                  // Impact prediction section
                                  if (i < _titleSuggestions!.suggestionDetails.length) ...[
                                    const SizedBox(height: 16),
                                    _buildImpactSection(
                                      _titleSuggestions!.suggestionDetails[i].impact,
                                      isDark,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          const SizedBox(height: 8),
                          Text(
                            'Generated: ${_titleSuggestions!.generatedAt.split('T').first}',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: isDark
                                  ? const Color(0xFF8E8E93)
                                  : const Color(0xFF8E8E93),
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 24),
                  ],
                ),
    );
  }
}
