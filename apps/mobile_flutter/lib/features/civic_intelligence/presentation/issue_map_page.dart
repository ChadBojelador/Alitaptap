import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/models/issue.dart';
import '../../../services/api_service.dart';
import 'issue_detail_page.dart';

/// Full-screen OpenStreetMap view showing validated community issues as pins.
class IssueMapPage extends StatefulWidget {
  const IssueMapPage({super.key});

  @override
  State<IssueMapPage> createState() => _IssueMapPageState();
}

class _IssueMapPageState extends State<IssueMapPage> {
  final _api = ApiService();
  List<Issue> _issues = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadIssues();
  }

  Future<void> _loadIssues() async {
    try {
      final issues = await _api.getIssues(status: 'validated');
      if (mounted) {
        setState(() {
          _issues = issues;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading issues: $e')),
        );
      }
    }
  }

  void _onPinTapped(Issue issue) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => IssueDetailPage(issueId: issue.issueId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Community Problems Map'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() => _loading = true);
              _loadIssues();
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // --- Map ---
          FlutterMap(
            options: const MapOptions(
              initialCenter: LatLng(14.6, 121.0),
              initialZoom: 10,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.alitaptap.mobile',
              ),
              MarkerLayer(
                markers: _issues
                    .map(
                      (issue) => Marker(
                        point: LatLng(issue.lat, issue.lng),
                        width: 44,
                        height: 44,
                        child: GestureDetector(
                          onTap: () => _onPinTapped(issue),
                          child: const Icon(
                            Icons.location_pin,
                            color: Colors.red,
                            size: 40,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
              const RichAttributionWidget(
                attributions: [
                  TextSourceAttribution('© OpenStreetMap contributors'),
                ],
              ),
            ],
          ),

          // --- Loading overlay ---
          if (_loading)
            Container(
              color: Colors.black26,
              child: const Center(child: CircularProgressIndicator()),
            ),

          // --- Issue count badge ---
          if (!_loading)
            Positioned(
              bottom: 16,
              left: 16,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.pin_drop,
                        size: 18, color: theme.colorScheme.onPrimaryContainer),
                    const SizedBox(width: 6),
                    Text(
                      '${_issues.length} validated issues',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // --- Issue list sheet ---
          if (!_loading && _issues.isNotEmpty)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _IssueListSheet(
                issues: _issues,
                onTap: _onPinTapped,
              ),
            ),
        ],
      ),
    );
  }
}

/// Draggable bottom sheet listing issues for quick browsing.
class _IssueListSheet extends StatelessWidget {
  const _IssueListSheet({required this.issues, required this.onTap});

  final List<Issue> issues;
  final ValueChanged<Issue> onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.15,
      minChildSize: 0.08,
      maxChildSize: 0.55,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: ListView.builder(
            controller: scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: issues.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return Column(
                  children: [
                    const SizedBox(height: 8),
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color:
                            theme.colorScheme.onSurfaceVariant.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text('Reported Issues', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                  ],
                );
              }

              final issue = issues[index - 1];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Icon(Icons.warning_amber_rounded,
                        color: theme.colorScheme.onPrimaryContainer),
                  ),
                  title: Text(issue.title,
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text(issue.description,
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => onTap(issue),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
