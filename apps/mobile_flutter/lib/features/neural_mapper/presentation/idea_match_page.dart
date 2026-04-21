import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/models/issue.dart';
import '../../../core/models/match_result.dart';
import '../../civic_intelligence/application/usecases/get_issue_by_id_use_case.dart';
import '../../civic_intelligence/data/repositories/api_issue_repository.dart';
import '../application/usecases/match_idea_use_case.dart';
import '../data/repositories/api_mapper_repository.dart';
import '../../civic_intelligence/presentation/issue_detail_page.dart';

/// Student flow for matching a research idea to validated community problems.
class IdeaMatchPage extends StatefulWidget {
  const IdeaMatchPage({
    super.key,
    required this.studentId,
    this.initialIdeaText,
    this.autoRun = false,
  });

  final String studentId;
  final String? initialIdeaText;
  final bool autoRun;

  @override
  State<IdeaMatchPage> createState() => _IdeaMatchPageState();
}

class _IdeaMatchPageState extends State<IdeaMatchPage> {
  final _mapperRepository = ApiMapperRepository();
  final _issueRepository = ApiIssueRepository();
  final _ideaController = TextEditingController();

  late final MatchIdeaUseCase _matchIdeaUseCase =
      MatchIdeaUseCase(_mapperRepository);
  late final GetIssueByIdUseCase _getIssueByIdUseCase =
      GetIssueByIdUseCase(_issueRepository);

  bool _loading = false;
  String? _error;
  MapperRunResult? _runResult;
  String? _connectedIssueId;
  final Map<String, Issue> _issueById = {};

  @override
  void initState() {
    super.initState();
    final initialText = widget.initialIdeaText?.trim();
    if (initialText != null && initialText.isNotEmpty) {
      _ideaController.text = initialText;
      if (widget.autoRun && initialText.length >= 5) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _matchIdea();
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _ideaController.dispose();
    super.dispose();
  }

  Future<void> _matchIdea() async {
    final ideaText = _ideaController.text.trim();
    if (ideaText.length < 5) {
      setState(() => _error = 'Please enter at least 5 characters.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _runResult = null;
      _connectedIssueId = null;
      _issueById.clear();
    });

    try {
      final result = await _matchIdeaUseCase(
        MatchIdeaInput(
          studentId: widget.studentId,
          ideaText: ideaText,
        ),
      );

      for (final match in result.matches) {
        try {
          final issue = await _getIssueByIdUseCase(match.issueId);
          _issueById[match.issueId] = issue;
        } catch (e) {
          debugPrint('Failed to load issue ${match.issueId}: $e');
        }
      }

      if (mounted) {
        setState(() {
          _runResult = result;
          _connectedIssueId =
              result.matches.isNotEmpty ? result.matches.first.issueId : null;
          _loading = false;
        });

        if (result.matches.isNotEmpty) {
          final bestMatch = result.matches.first;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Connected to the most related community problem.',
              ),
            ),
          );

          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => IssueDetailPage(issueId: bestMatch.issueId),
            ),
          );
        }
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = error.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final matches = _runResult?.matches ?? const <MatchResult>[];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Match Your Idea',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFD60A).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFFFD60A).withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.lightbulb_outline_rounded,
                    color: Color(0xFFFFD60A), size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Describe your research idea to find the most relevant community problems.',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: isDark
                          ? const Color(0xFFF0F0F0)
                          : const Color(0xFF1A1A1A),
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Research Idea',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFFF0F0F0) : const Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _ideaController,
            minLines: 4,
            maxLines: 6,
            style: GoogleFonts.poppins(fontSize: 14),
            decoration: InputDecoration(
              hintText:
                  'Example: Low-cost flood warning system for urban neighborhoods',
              hintStyle: GoogleFonts.poppins(
                fontSize: 13,
                color: isDark
                    ? const Color(0xFF616161)
                    : const Color(0xFF9E9E9E),
              ),
              prefixIcon: const Icon(Icons.edit_note_rounded,
                  color: Color(0xFFFFD60A), size: 22),
              filled: true,
              fillColor:
                  isDark ? const Color(0xFF242424) : const Color(0xFFF5F5F5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: const Color(0xFFFFD60A).withValues(alpha: 0.2),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: const Color(0xFFFFD60A).withValues(alpha: 0.2),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide:
                    const BorderSide(color: Color(0xFFFFD60A), width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: _loading ? null : _matchIdea,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: _loading
                    ? const Color(0xFFFFD60A).withValues(alpha: 0.5)
                    : const Color(0xFFFFD60A),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFFD60A).withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_loading)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF1A1A1A),
                      ),
                    )
                  else
                    const Icon(Icons.auto_awesome_rounded,
                        color: Color(0xFF1A1A1A), size: 20),
                  const SizedBox(width: 10),
                  Text(
                    _loading ? 'Finding Matches...' : 'Find Matches',
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF1A1A1A),
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          if (_error != null && !_loading)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.red.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded,
                      color: Colors.red, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _error!,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (matches.isNotEmpty && !_loading) ...[
            const SizedBox(height: 8),
            if (_connectedIssueId != null)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD60A).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFFFD60A).withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD60A),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.link_rounded,
                          color: Color(0xFF1A1A1A), size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Connected Problem',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? const Color(0xFFF0F0F0)
                                  : const Color(0xFF1A1A1A),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _issueById[_connectedIssueId!]?.title ??
                                'Most related community problem',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: isDark
                                  ? const Color(0xFF9E9E9E)
                                  : const Color(0xFF666666),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            Text(
              'Top Matches',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color:
                    isDark ? const Color(0xFFF0F0F0) : const Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 12),
            for (var index = 0; index < matches.length; index++)
              _MatchCard(
                rank: index + 1,
                match: matches[index],
                issue: _issueById[matches[index].issueId],
                isConnected: matches[index].issueId == _connectedIssueId,
              ),
          ],
        ],
      ),
    );
  }
}

class _MatchCard extends StatelessWidget {
  const _MatchCard({
    required this.rank,
    required this.match,
    required this.issue,
    required this.isConnected,
  });

  final int rank;
  final MatchResult match;
  final Issue? issue;
  final bool isConnected;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => IssueDetailPage(issueId: match.issueId),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isConnected
              ? const Color(0xFFFFD60A).withValues(alpha: 0.12)
              : isDark
                  ? const Color(0xFF242424)
                  : const Color(0xFFFFFFFF),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isConnected
                ? const Color(0xFFFFD60A).withValues(alpha: 0.4)
                : isDark
                    ? const Color(0xFF3A3A3A)
                    : const Color(0xFFE0E0E0),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isConnected
                    ? const Color(0xFFFFD60A)
                    : isDark
                        ? const Color(0xFF3A3A3A)
                        : const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isConnected
                      ? const Color(0xFFFFD60A)
                      : isDark
                          ? const Color(0xFF4A4A4A)
                          : const Color(0xFFE0E0E0),
                ),
              ),
              child: isConnected
                  ? const Icon(Icons.link_rounded,
                      color: Color(0xFF1A1A1A), size: 20)
                  : Text(
                      '$rank',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? const Color(0xFFF0F0F0)
                            : const Color(0xFF1A1A1A),
                      ),
                    ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    issue?.title ?? 'Community Problem',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? const Color(0xFFF0F0F0)
                          : const Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    match.reason,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: isDark
                          ? const Color(0xFF9E9E9E)
                          : const Color(0xFF666666),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD60A).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFFFFD60A).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    '${(match.score * 100).toStringAsFixed(0)}%',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFFFD60A),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: isDark
                      ? const Color(0xFF616161)
                      : const Color(0xFF9E9E9E),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

