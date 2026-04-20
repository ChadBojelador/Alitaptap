import 'package:flutter/material.dart';

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
        } catch (_) {
          // Keep rendering match even if issue details fail to load.
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
    final theme = Theme.of(context);
    final matches = _runResult?.matches ?? const <MatchResult>[];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Match Your Idea'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Describe your research idea to find the most relevant community problems.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _ideaController,
            minLines: 4,
            maxLines: 6,
            decoration: const InputDecoration(
              labelText: 'Research idea',
              hintText: 'Example: Low-cost flood warning system for urban neighborhoods',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _loading ? null : _matchIdea,
            icon: const Icon(Icons.auto_awesome),
            label: const Text('Find Matches'),
          ),
          const SizedBox(height: 12),
          if (_loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            ),
          if (_error != null && !_loading)
            Card(
              color: theme.colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  _error!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onErrorContainer,
                  ),
                ),
              ),
            ),
          if (matches.isNotEmpty && !_loading) ...[
            const SizedBox(height: 8),
            if (_connectedIssueId != null)
              Card(
                color: theme.colorScheme.primaryContainer,
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: Icon(
                    Icons.link,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                  title: Text(
                    'Connected Problem',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: Text(
                    _issueById[_connectedIssueId!]?.title ??
                        'Most related community problem selected',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ),
            Text(
              'Top Matches',
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
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
    final theme = Theme.of(context);

    return Card(
      color: isConnected ? theme.colorScheme.secondaryContainer : null,
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: isConnected
            ? Icon(
                Icons.link,
                color: theme.colorScheme.onSecondaryContainer,
              )
            : CircleAvatar(
                child: Text('$rank'),
              ),
        title: Text(
          issue?.title ?? 'Community Problem',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            match.reason,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        trailing: Chip(
          label: Text('${(match.score * 100).toStringAsFixed(1)}%'),
          visualDensity: VisualDensity.compact,
          backgroundColor: theme.colorScheme.primaryContainer,
        ),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => IssueDetailPage(issueId: match.issueId),
          ),
        ),
      ),
    );
  }
}

