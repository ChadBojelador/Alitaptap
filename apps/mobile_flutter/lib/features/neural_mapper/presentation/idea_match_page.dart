import 'package:flutter/material.dart';

import '../../../core/models/issue.dart';
import '../../../core/models/match_result.dart';
import '../../../services/api_service.dart';
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
  final _api = ApiService();
  final _ideaController = TextEditingController();

  bool _loading = false;
  String? _error;
  MapperRunResult? _runResult;
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
      _issueById.clear();
    });

    try {
      final result = await _api.matchIdea(
        studentId: widget.studentId,
        ideaText: ideaText,
      );

      for (final match in result.matches) {
        try {
          final issue = await _api.getIssue(match.issueId);
          _issueById[match.issueId] = issue;
        } catch (_) {
          // Keep rendering match even if issue details fail to load.
        }
      }

      if (mounted) {
        setState(() {
          _runResult = result;
          _loading = false;
        });
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
  });

  final int rank;
  final MatchResult match;
  final Issue? issue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: CircleAvatar(
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

