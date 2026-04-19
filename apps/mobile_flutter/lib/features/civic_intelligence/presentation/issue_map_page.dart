import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../../../core/models/issue.dart';
import '../../../services/api_service.dart';
import '../../neural_mapper/presentation/idea_match_page.dart';
import 'issue_detail_page.dart';

/// Full-screen map page showing validated community issues as pins.
/// Uses OpenFreeMap (liberty style) with 3D building tilt.
/// UI overlays use semi-transparent dark panels with yellow (#FFD60A) accents
/// so the 3D map remains visible beneath them.
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
  static const _defaultCenter = LatLng(12.8797, 121.7740);
  static const _defaultZoom = 5.5;
  static const _userZoom = 15.5;
  static final _philippinesBounds = LatLngBounds(
    southwest: LatLng(4.5, 116.0),
    northeast: LatLng(21.5, 127.0),
  );

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
  Circle? _userLocationCircle;
  Offset? _userScreenPosition;

  @override
  void initState() {
    super.initState();
    _resolveCurrentLocation();
    _loadIssues();
  }

  @override
  void dispose() {
    _mapController?.removeListener(_onCameraMove);
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
    controller.addListener(_onCameraMove);
  }

  Future<void> _onStyleLoaded() async {
    _styleLoaded = true;
    await _moveCameraToUserLocation();
    await _renderIssuePins();
  }

  Future<void> _updateUserScreenPosition() async {
    final controller = _mapController;
    final userPosition = _userPosition;
    if (controller == null || userPosition == null) return;
    final point = await controller.toScreenLocation(
      LatLng(userPosition.latitude, userPosition.longitude),
    );
    if (mounted) setState(() => _userScreenPosition = Offset(point.x.toDouble(), point.y.toDouble()));
  }

  void _onCameraMove() => _updateUserScreenPosition();

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

    final userLatLng = LatLng(userPosition.latitude, userPosition.longitude);

    if (_userLocationCircle != null) {
      await controller.removeCircle(_userLocationCircle!);
      _userLocationCircle = null;
    }

    await controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: userLatLng,
          zoom: _userZoom,
          tilt: 60,
        ),
      ),
    );

    await _updateUserScreenPosition();
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
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(0),
        child: AppBar(backgroundColor: Colors.transparent),
      ),
      body: Stack(
        children: [
          // --- Map ---
          MapLibreMap(
            styleString: _openFreeMapStyle,
            initialCameraPosition: CameraPosition(
              target: _defaultCenter,
              zoom: _defaultZoom,
              tilt: 60,
            ),
            cameraTargetBounds: CameraTargetBounds(_philippinesBounds),
            minMaxZoomPreference: const MinMaxZoomPreference(5.0, 20.0),
            onMapCreated: _onMapCreated,
            onStyleLoadedCallback: _onStyleLoaded,
            onMapClick: _onMapTap,
            compassEnabled: true,
            myLocationEnabled: true,
          ),

          // --- You're Here overlay ---
          if (_userScreenPosition != null)
            Positioned(
              left: _userScreenPosition!.dx - 40,
              top: _userScreenPosition!.dy - 72,
              child: const _YouAreHereMarker(),
            ),

          // --- Floating compact header ---
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1C1C1E).withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFFFFD60A).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.map_rounded, color: Color(0xFFFFD60A), size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Community Problems Map',
                              style: GoogleFonts.poppins(
                                color: const Color(0xFFF5F5F5),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.my_location, color: Color(0xFFFFD60A), size: 18),
                            tooltip: 'Go to my location',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () async {
                              await _resolveCurrentLocation();
                              await _moveCameraToUserLocation(force: true);
                            },
                          ),
                          const SizedBox(width: 12),
                          IconButton(
                            icon: const Icon(Icons.refresh_rounded, color: Color(0xFFFFD60A), size: 18),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
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
                    ),
                  ),
                ),
              ),
            ),
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF1C1C1E).withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFFFD60A).withValues(alpha: 0.5)),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFD60A).withValues(alpha: 0.18),
                      blurRadius: 12,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.pin_drop, size: 18, color: Color(0xFFFFD60A)),
                    const SizedBox(width: 6),
                    Text(
                      '${_issues.length} validated issues',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: const Color(0xFFF5F5F5),
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
                color: const Color(0xFF2C2C2E).withValues(alpha: 0.95),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    children: [
                      const Icon(Icons.wifi_off_rounded, color: Color(0xFFFFD60A)),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Could not load issues. Check backend/network, then refresh.',
                          style: TextStyle(color: Color(0xFFF5F5F5)),
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
                            const Color(0xFF2C2C2E).withValues(alpha: 0.92),
                            const Color(0xFF1C1C1E).withValues(alpha: 0.88),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: const Color(0xFFFFD60A).withValues(alpha: 0.35),
                          width: 1.1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFFD60A).withValues(alpha: 0.12),
                            blurRadius: 20,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 14),
                          const Icon(Icons.search, color: Color(0xFFFFD60A)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _ideaController,
                              textInputAction: TextInputAction.search,
                              onSubmitted: (_) => _submitIdea(),
                              style: const TextStyle(
                                color: Color(0xFFF5F5F5),
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
                                backgroundColor: const Color(0xFFFFD60A),
                                foregroundColor: const Color(0xFF1C1C1E),
                              ),
                              onPressed: _matchingIdea ? null : _submitIdea,
                              icon: _matchingIdea
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Color(0xFF1C1C1E),
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

/// Glowing yellow "You're here" location pin overlay.
class _YouAreHereMarker extends StatefulWidget {
  const _YouAreHereMarker();

  @override
  State<_YouAreHereMarker> createState() => _YouAreHereMarkerState();
}

class _YouAreHereMarkerState extends State<_YouAreHereMarker>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _anim, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 80,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF1C1C1E).withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFFD60A).withValues(alpha: 0.6)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFD60A).withValues(alpha: 0.3),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: const Text(
              "You're here",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFFFFD60A),
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.3,
              ),
            ),
          ),
          const SizedBox(height: 4),
          AnimatedBuilder(
            animation: _pulse,
            builder: (_, __) => Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 36 * _pulse.value,
                  height: 36 * _pulse.value,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFFFD60A).withValues(alpha: 0.25 * _pulse.value),
                  ),
                ),
                Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFFFD60A),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFFD60A).withValues(alpha: 0.7),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.location_on, size: 12, color: Color(0xFF1C1C1E)),
                ),
              ],
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
                color: const Color(0xFF1C1C1E).withValues(alpha: 0.55),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                border: Border.all(color: const Color(0xFFFFD60A).withValues(alpha: 0.25)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFFD60A).withValues(alpha: 0.08),
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
                        Text(
                          'Reported Issues',
                          style: GoogleFonts.poppins(
                            color: const Color(0xFFF5F5F5),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    );
                  }

                  final issue = issues[index - 1];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    color: const Color(0xFF2C2C2E),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFFFFD60A).withValues(alpha: 0.16),
                        child: const Icon(
                          Icons.warning_amber_rounded,
                          color: Color(0xFFFFD60A),
                        ),
                      ),
                      title: Text(issue.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Color(0xFFF5F5F5))),
                      subtitle: Text(issue.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Color(0xFF8E8E93))),
                      trailing: const Icon(Icons.chevron_right, color: Color(0xFFFFD60A)),
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
