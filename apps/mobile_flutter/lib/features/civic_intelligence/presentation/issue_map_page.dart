import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../../../core/models/issue.dart';
import '../../../services/api_service.dart';
import '../../neural_mapper/presentation/idea_match_page.dart';
import 'issue_detail_page.dart';

/// Full-screen OpenFreeMap view showing validated community issues as pins.
class IssueMapPage extends StatefulWidget {
  const IssueMapPage({
    super.key,
    this.showIdeaDock = false,
    this.studentId,
  });

  final bool showIdeaDock;
  final String? studentId;

  @override
  State<IssueMapPage> createState() => _IssueMapPageState();
}

class _IssueMapPageState extends State<IssueMapPage> {
  static const _openFreeMapStyle = 'https://tiles.openfreemap.org/styles/liberty';
  static const _defaultCenter = LatLng(14.6, 121.0);
  static const _defaultZoom = 10.0;
  static const _userZoom = 15.5;

  final _api = ApiService();
  final _ideaController = TextEditingController();

  List<Issue> _issues = [];
  String? _errorMessage;
  Position? _userPosition;

  bool _loading = true;
  bool _styleLoaded = false;
  bool _cameraMovedToUser = false;
  bool _matchingIdea = false;
  MapLibreMapController? _mapController;

  @override
  void initState() {
    super.initState();
    _resolveCurrentLocation();
    _loadIssues();
  }

  @override
  void dispose() {
    _ideaController.dispose();
    super.dispose();
  }

  Future<void> _loadIssues() async {
    try {
      final issues = await _api.getIssues(status: 'validated');
      if (mounted) {
        setState(() {
          _issues = issues;
          _errorMessage = null;
          _loading = false;
        });
        await _renderIssuePins();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _errorMessage = e.toString();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading issues: $e')),
        );
      }
    }
  }

  void _onMapCreated(MapLibreMapController controller) {
    _mapController = controller;
  }

  Future<void> _onStyleLoaded() async {
    _styleLoaded = true;
    await _moveCameraToUserLocation();
    await _renderIssuePins();
  }

  Future<void> _resolveCurrentLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      if (!mounted) return;
      setState(() => _userPosition = position);
      await _moveCameraToUserLocation(force: true);
    } catch (_) {
      // Keep default center when location is unavailable.
    }
  }

  Future<void> _moveCameraToUserLocation({bool force = false}) async {
    if (!force && _cameraMovedToUser) return;

    final controller = _mapController;
    final userPosition = _userPosition;
    if (!_styleLoaded || controller == null || userPosition == null) return;

    await controller.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(userPosition.latitude, userPosition.longitude),
        _userZoom,
      ),
    );

    _cameraMovedToUser = true;
  }

  Future<void> _renderIssuePins() async {
    final controller = _mapController;
    if (!_styleLoaded || controller == null) return;

    await controller.clearCircles();

    for (final issue in _issues) {
      await controller.addCircle(
        CircleOptions(
          geometry: LatLng(issue.lat, issue.lng),
          circleRadius: 7,
          circleColor: '#D32F2F',
          circleStrokeColor: '#FFFFFF',
          circleStrokeWidth: 2,
        ),
      );
    }
  }

  void _onMapTap(Point<double> point, LatLng latLng) {
    const tapThresholdDegrees = 0.006;
    Issue? issue;

    for (final candidate in _issues) {
      final latDelta = (candidate.lat - latLng.latitude).abs();
      final lngDelta = (candidate.lng - latLng.longitude).abs();
      if (latDelta <= tapThresholdDegrees && lngDelta <= tapThresholdDegrees) {
        issue = candidate;
        break;
      }
    }

    if (issue != null) {
      _onPinTapped(issue);
    }
  }

  void _onPinTapped(Issue issue) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => IssueDetailPage(issueId: issue.issueId),
      ),
    );
  }

  Future<void> _submitIdea() async {
    final idea = _ideaController.text.trim();
    if (idea.length < 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter at least 5 characters.')),
      );
      return;
    }

    final studentId = widget.studentId;
    if (studentId == null || studentId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Student session not found. Please sign in again.')),
      );
      return;
    }

    setState(() => _matchingIdea = true);
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => IdeaMatchPage(
          studentId: studentId,
          initialIdeaText: idea,
          autoRun: true,
        ),
      ),
    );
    if (mounted) {
      setState(() => _matchingIdea = false);
    }
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
            icon: const Icon(Icons.my_location),
            tooltip: 'Go to my location',
            onPressed: () async {
              await _resolveCurrentLocation();
              await _moveCameraToUserLocation(force: true);
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _loading = true;
                _errorMessage = null;
              });
              _loadIssues();
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // --- Map ---
          MapLibreMap(
            styleString: _openFreeMapStyle,
            initialCameraPosition: CameraPosition(
              target: _defaultCenter,
              zoom: _defaultZoom,
            ),
            onMapCreated: _onMapCreated,
            onStyleLoadedCallback: _onStyleLoaded,
            onMapClick: _onMapTap,
            compassEnabled: true,
            myLocationEnabled: true,
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
                  color: Colors.white.withValues(alpha: 0.78),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.42)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.pin_drop,
                        size: 18, color: theme.colorScheme.primary),
                    const SizedBox(width: 6),
                    Text(
                      '${_issues.length} validated issues',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: const Color(0xFF1C1C1E),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          if (!_loading && _errorMessage != null)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Card(
                color: Colors.white.withValues(alpha: 0.86),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.wifi_off_rounded,
                        color: theme.colorScheme.error,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Could not load issues. Check backend/network, then refresh.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: const Color(0xFF1C1C1E),
                          ),
                        ),
                      ),
                    ],
                  ),
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

          if (widget.showIdeaDock)
            Positioned(
              left: 16,
              right: 16,
              bottom: _issues.isNotEmpty ? 120 : 16,
              child: SafeArea(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white.withValues(alpha: 0.52),
                            Colors.white.withValues(alpha: 0.30),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.46),
                          width: 1.1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.11),
                            blurRadius: 18,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 14),
                          Icon(
                            Icons.search,
                            color: const Color(0xFF8E8E93).withValues(alpha: 0.95),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _ideaController,
                              textInputAction: TextInputAction.search,
                              onSubmitted: (_) => _submitIdea(),
                              style: const TextStyle(
                                color: Color(0xFF1C1C1E),
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                              decoration: const InputDecoration(
                                hintText: 'Match your ideas',
                                hintStyle: TextStyle(
                                  color: Color(0xFF8E8E93),
                                  fontWeight: FontWeight.w400,
                                ),
                                border: InputBorder.none,
                                filled: false,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: IconButton.filled(
                              style: IconButton.styleFrom(
                                backgroundColor:
                                    theme.colorScheme.primary.withValues(alpha: 0.96),
                                foregroundColor: Colors.white,
                              ),
                              onPressed: _matchingIdea ? null : _submitIdea,
                              icon: _matchingIdea
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.arrow_upward_rounded),
                              tooltip: 'Match idea',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
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
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withValues(alpha: 0.82),
                    Colors.white.withValues(alpha: 0.70),
                  ],
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                border: Border.all(color: Colors.white.withValues(alpha: 0.42)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 14,
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
                            color: const Color(0xFF8E8E93).withValues(alpha: 0.45),
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
                    color: Colors.white.withValues(alpha: 0.74),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.16),
                        child: Icon(
                          Icons.warning_amber_rounded,
                          color: theme.colorScheme.primary,
                        ),
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
            ),
          ),
        );
      },
    );
  }
}
