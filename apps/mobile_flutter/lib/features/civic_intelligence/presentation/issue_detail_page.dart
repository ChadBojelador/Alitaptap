import 'package:flutter/material.dart';

import '../../../core/models/issue.dart';
import '../../../core/models/title_suggestions.dart';
import '../../../services/api_service.dart';

/// Detail page for a single community issue.
class IssueDetailPage extends StatefulWidget {
  const IssueDetailPage({super.key, required this.issueId});

  final String issueId;

  @override
  State<IssueDetailPage> createState() => _IssueDetailPageState();
}

class _IssueDetailPageState extends State<IssueDetailPage> {
  final _api = ApiService();
  Issue? _issue;
  TitleSuggestions? _titleSuggestions;
  bool _loading = true;
  bool _loadingSuggestions = false;
  String? _suggestionError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final issue = await _api.getIssue(widget.issueId);
      if (mounted) {
        setState(() {
          _issue = issue;
          _loading = false;
        });
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

  Future<void> _loadTitleSuggestions() async {
    if (!mounted) return;

    setState(() {
      _loadingSuggestions = true;
      _suggestionError = null;
    });

    try {
      final suggestions = await _api.getTitleSuggestions(widget.issueId);
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Issue Detail'),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _issue == null
              ? const Center(child: Text('Issue not found'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- Status chip ---
                      Row(
                        children: [
                          Chip(
                            label: Text(
                              _issue!.status.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            backgroundColor: _statusColor(_issue!.status),
                          ),
                          const Spacer(),
                          Icon(Icons.access_time,
                              size: 16,
                              color: theme.colorScheme.onSurfaceVariant),
                          const SizedBox(width: 4),
                          Text(
                            _issue!.createdAt.split('T').first,
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // --- Title ---
                      Text(
                        _issue!.title,
                        style: theme.textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),

                      // --- Description ---
                      Text(
                        _issue!.description,
                        style: theme.textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 20),

                      // --- Location ---
                      Card(
                        child: ListTile(
                          leading: Icon(Icons.location_on,
                              color: theme.colorScheme.primary),
                          title: const Text('Location'),
                          subtitle: Text(
                            '${_issue!.lat.toStringAsFixed(5)}, ${_issue!.lng.toStringAsFixed(5)}',
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // --- Tags ---
                      if (_issue!.tags.isNotEmpty) ...[
                        Text('Tags', style: theme.textTheme.titleSmall),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: _issue!.tags
                              .map((t) => Chip(label: Text(t)))
                              .toList(),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // --- AI Title Suggestions (M4) ---
                      Row(
                        children: [
                          Text(
                            'Research Title Suggestions',
                            style: theme.textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const Spacer(),
                          TextButton.icon(
                            onPressed:
                                _loadingSuggestions ? null : _loadTitleSuggestions,
                            icon: const Icon(Icons.refresh, size: 18),
                            label: const Text('Regenerate'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (_loadingSuggestions)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (_suggestionError != null)
                        Card(
                          color: theme.colorScheme.errorContainer,
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Text(
                              _suggestionError!,
                              style: TextStyle(
                                color: theme.colorScheme.onErrorContainer,
                              ),
                            ),
                          ),
                        )
                      else if ((_titleSuggestions?.suggestions ?? []).isEmpty)
                        Text(
                          'No suggestions yet.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        )
                      else
                        Column(
                          children: [
                            for (var i = 0;
                                i < _titleSuggestions!.suggestions.length;
                                i++)
                              Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  leading: CircleAvatar(child: Text('${i + 1}')),
                                  title: Text(_titleSuggestions!.suggestions[i]),
                                ),
                              ),
                            const SizedBox(height: 4),
                            Text(
                              'Generated: ${_titleSuggestions!.generatedAt.split('T').first}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
    );
  }
}
