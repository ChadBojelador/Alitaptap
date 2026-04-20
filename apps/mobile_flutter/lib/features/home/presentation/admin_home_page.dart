import 'package:flutter/material.dart';

import '../../../core/models/issue.dart';
import '../../../services/api_service.dart';
import '../../civic_intelligence/presentation/issue_detail_page.dart';

/// Admin home page showing pending issues for validation.
class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage>
    with SingleTickerProviderStateMixin {
  final _api = ApiService();
  late TabController _tabCtrl;

  List<Issue> _pendingIssues = [];
  List<Issue> _validatedIssues = [];
  List<Issue> _rejectedIssues = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _loadAll();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    try {
      final pending = await _api.getIssues(status: 'pending');
      final validated = await _api.getIssues(status: 'validated');
      final rejected = await _api.getIssues(status: 'rejected');
      if (mounted) {
        setState(() {
          _pendingIssues = pending;
          _validatedIssues = validated;
          _rejectedIssues = rejected;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _updateStatus(String issueId, String status) async {
    try {
      await _api.updateIssueStatus(issueId: issueId, status: status);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Issue ${status == 'validated' ? 'approved' : 'rejected'}'),
          backgroundColor: status == 'validated' ? Colors.green : Colors.red,
        ),
      );
      _loadAll();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Admin Dashboard',
          style: theme.textTheme.titleLarge,
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAll,
          ),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          tabs: [
            Tab(
              icon: Badge(
                label: Text('${_pendingIssues.length}'),
                isLabelVisible: _pendingIssues.isNotEmpty,
                child: const Icon(Icons.pending_actions),
              ),
              text: 'Pending',
            ),
            Tab(
              icon: Badge(
                label: Text('${_validatedIssues.length}'),
                isLabelVisible: _validatedIssues.isNotEmpty,
                child: const Icon(Icons.check_circle_outline),
              ),
              text: 'Validated',
            ),
            Tab(
              icon: Badge(
                label: Text('${_rejectedIssues.length}'),
                isLabelVisible: _rejectedIssues.isNotEmpty,
                child: const Icon(Icons.cancel_outlined),
              ),
              text: 'Rejected',
            ),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabCtrl,
              children: [
                _buildList(_pendingIssues, showActions: true),
                _buildList(_validatedIssues),
                _buildList(_rejectedIssues),
              ],
            ),
    );
  }

  Widget _buildList(List<Issue> issues, {bool showActions = false}) {
    if (issues.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_rounded,
                size: 64, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 12),
            Text('No issues here',
                style: Theme.of(context).textTheme.bodyLarge),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAll,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: issues.length,
        itemBuilder: (context, index) {
          final issue = issues[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => IssueDetailPage(issueId: issue.issueId),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title row
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            issue.title,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Icon(Icons.location_on,
                            size: 16,
                            color: Theme.of(context).colorScheme.primary),
                        Text(
                          ' ${issue.lat.toStringAsFixed(2)}, ${issue.lng.toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Description
                    Text(
                      issue.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),

                    // Actions
                    if (showActions) ...[
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () =>
                                _updateStatus(issue.issueId, 'rejected'),
                            icon: const Icon(Icons.close, size: 18),
                            label: const Text('Reject'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                            ),
                          ),
                          const SizedBox(width: 10),
                          FilledButton.icon(
                            onPressed: () =>
                                _updateStatus(issue.issueId, 'validated'),
                            icon: const Icon(Icons.check, size: 18),
                            label: const Text('Approve'),
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
