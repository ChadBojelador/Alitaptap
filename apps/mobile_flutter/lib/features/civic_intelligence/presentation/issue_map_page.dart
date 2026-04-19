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
///
/// Always uses OpenFreeMap 'liberty' style so 3D buildings are visible in
/// both light and dark mode. In dark mode a semi-transparent dark tint is
/// layered over the map to reduce brightness without hiding buildings or labels.
///
/// UI overlays adapt to the current [ThemeMode] using [Theme.of(context)] so
/// colors stay harmonious across both modes.
class IssueMapPage extends StatefulWidget {
  const IssueMapPage({
    super.key,
    this.showIdeaDock = false,
    this.studentId,
    this.onToggleTheme,
    this.themeMode = ThemeMode.dark,
  });

  final bool showIdeaDock;
  final String? studentId;

  /// Callback to toggle between light and dark mode at the app level.
  final VoidCallback? onToggleTheme;

  /// Current theme mode — used to adapt overlay colors and map tint.
  final ThemeMode themeMode;

  @override
  State<IssueMapPage> createState() => _IssueMapPageState();
}

class _IssueMapPageState extends State<IssueMapPage> {
  // Liberty style has full 3D buildings and crisp labels in both modes.
  static const _mapStyle = 'https://tiles.openfreemap.org/styles/liberty';
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

  bool get _isDark => widget.themeMode == ThemeMode.dark;

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
    final pos = _userPosition;
    if (controller == null || pos == null) return;
    final point = await controller.toScreenLocation(
      LatLng(pos.latitude, pos.longitude),
    );
    if (mounted) {
      setState(() => _userScreenPosition =
          Offset(point.x.toDouble(), point.y.toDouble()));
    }
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
          permission == LocationPermission.deniedForever) return;

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      if (!mounted) return;
      setState(() => _userPosition = position);
      await _moveCameraToUserLocation(force: true);
    } catch (_) {}
  }

  Future<void> _moveCameraToUserLocation({bool force = false}) async {
    if (!force && _cameraMovedToUser) return;
    final controller = _mapController;
    final pos = _userPosition;
    if (!_styleLoaded || controller == null || pos == null) return;

    final userLatLng = LatLng(pos.latitude, pos.longitude);

    if (_userLocationCircle != null) {
      await controller.removeCircle(_userLocationCircle!);
      _userLocationCircle = null;
    }

    await controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: userLatLng, zoom: _userZoom, tilt: 60),
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
          circleColor: '#E53935',
          circleStrokeColor: '#FFFFFF',
          circleStrokeWidth: 2,
        ),
      );
    }
  }

  void _onMapTap(Point<double> point, LatLng latLng) {
    const threshold = 0.006;
    for (final candidate in _issues) {
      if ((candidate.lat - latLng.latitude).abs() <= threshold &&
          (candidate.lng - latLng.longitude).abs() <= threshold) {
        _onPinTapped(candidate);
        return;
      }
    }
  }

  void _onPinTapped(Issue issue) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => IssueDetailPage(issueId: issue.issueId)),
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
    if (mounted) setState(() => _matchingIdea = false);
  }

  // ---------------------------------------------------------------------------
  // Theme helpers — all overlay colors derived from these so they stay in sync.
  // ---------------------------------------------------------------------------

  /// Panel background: dark charcoal in dark mode, warm cream in light mode.
  Color get _panelBg => _isDark
      ? const Color(0xFF1C1C1E).withValues(alpha: 0.72)
      : const Color(0xFFFFFDE7).withValues(alpha: 0.82);

  /// Text color on panels.
  Color get _textColor =>
      _isDark ? const Color(0xFFF5F5F5) : const Color(0xFF1C1C1E);

  /// Subtle text / hint color.
  Color get _subtleText =>
      _isDark ? const Color(0xFF9E9E9E) : const Color(0xFF757575);

  /// Card background inside the bottom sheet.
  Color get _cardBg => _isDark
      ? const Color(0xFF2A2A2A).withValues(alpha: 0.9)
      : const Color(0xFFFFF9C4).withValues(alpha: 0.9);

  static const _yellow = Color(0xFFFFD60A);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: Size.zero,
        child: AppBar(backgroundColor: Colors.transparent),
      ),
      body: Stack(
        children: [
          // ── Map (liberty style — 3D buildings always on) ──────────────────
          MapLibreMap(
            styleString: _mapStyle,
            initialCameraPosition: const CameraPosition(
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

          // ── Dark mode tint — subtle overlay, keeps 3D buildings visible ───
          if (_isDark)
            IgnorePointer(
              child: Container(
                color: const Color(0xFF0A0A0A).withValues(alpha: 0.28),
              ),
            ),

          // ── You're Here marker ────────────────────────────────────────────
          if (_userScreenPosition != null)
            Positioned(
              left: _userScreenPosition!.dx - 40,
              top: _userScreenPosition!.dy - 72,
              child: const _YouAreHereMarker(),
            ),

          // ── Floating header ───────────────────────────────────────────────
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
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 9),
                      decoration: BoxDecoration(
                        color: _panelBg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _yellow.withValues(alpha: 0.45),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.map_rounded,
                              color: _yellow, size: 17),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Community Problems Map',
                              style: GoogleFonts.poppins(
                                color: _textColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          _HeaderBtn(
                            icon: Icons.my_location_rounded,
                            onPressed: () async {
                              await _resolveCurrentLocation();
                              await _moveCameraToUserLocation(force: true);
                            },
                          ),
                          const SizedBox(width: 8),
                          _HeaderBtn(
                            icon: _isDark
                                ? Icons.light_mode_rounded
                                : Icons.dark_mode_rounded,
                            onPressed: widget.onToggleTheme,
                          ),
                          const SizedBox(width: 8),
                          _HeaderBtn(
                            icon: Icons.refresh_rounded,
                            onPressed: () => setState(() {
                              _loading = true;
                              _errorMessage = null;
                              _loadIssues();
                            }),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Loading overlay ───────────────────────────────────────────────
          if (_loading)
            Container(
              color: Colors.black26,
              child: Center(
                child: CircularProgressIndicator(color: _yellow),
              ),
            ),

          // ── Issue count badge ─────────────────────────────────────────────
          if (!_loading)
            Positioned(
              bottom: 16,
              left: 16,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: _panelBg,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                          color: _yellow.withValues(alpha: 0.45)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.pin_drop,
                            size: 16, color: _yellow),
                        const SizedBox(width: 6),
                        Text(
                          '${_issues.length} validated issues',
                          style: GoogleFonts.poppins(
                            color: _textColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // ── Issue list sheet ──────────────────────────────────────────────
          if (!_loading && _issues.isNotEmpty)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _IssueListSheet(
                issues: _issues,
                onTap: _onPinTapped,
                panelBg: _panelBg,
                cardBg: _cardBg,
                textColor: _textColor,
                subtleText: _subtleText,
              ),
            ),

          // ── Idea dock ─────────────────────────────────────────────────────
          if (widget.showIdeaDock)
            Positioned(
              left: 16,
              right: 16,
              bottom: _issues.isNotEmpty ? 120 : 16,
              child: SafeArea(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                    child: Container(
                      decoration: BoxDecoration(
                        color: _panelBg,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: _yellow.withValues(alpha: 0.4),
                          width: 1.1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _yellow.withValues(alpha: 0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 14),
                          const Icon(Icons.search, color: _yellow),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _ideaController,
                              textInputAction: TextInputAction.search,
                              onSubmitted: (_) => _submitIdea(),
                              style: GoogleFonts.poppins(
                                color: _textColor,
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Match your ideas',
                                hintStyle: GoogleFonts.poppins(
                                  color: _subtleText,
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
                                backgroundColor: _yellow,
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

/// Small icon button used in the floating header.
class _HeaderBtn extends StatelessWidget {
  const _HeaderBtn({required this.icon, this.onPressed});
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Icon(icon, color: const Color(0xFFFFD60A), size: 18),
    );
  }
}

/// Glowing yellow "You're here" location pin overlay with pulse animation.
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
              color: const Color(0xFF1C1C1E).withValues(alpha: 0.88),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: const Color(0xFFFFD60A).withValues(alpha: 0.65)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFD60A).withValues(alpha: 0.3),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Text(
              "You're here",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: const Color(0xFFFFD60A),
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
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
                    color: const Color(0xFFFFD60A)
                        .withValues(alpha: 0.22 * _pulse.value),
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
                        color: const Color(0xFFFFD60A).withValues(alpha: 0.65),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.location_on,
                      size: 12, color: Color(0xFF1C1C1E)),
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
/// Colors are passed in from [_IssueMapPageState] so they adapt to theme mode.
class _IssueListSheet extends StatelessWidget {
  const _IssueListSheet({
    required this.issues,
    required this.onTap,
    required this.panelBg,
    required this.cardBg,
    required this.textColor,
    required this.subtleText,
  });

  final List<Issue> issues;
  final ValueChanged<Issue> onTap;
  final Color panelBg;
  final Color cardBg;
  final Color textColor;
  final Color subtleText;

  @override
  Widget build(BuildContext context) {
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
                color: panelBg,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
                border: Border.all(
                    color: const Color(0xFFFFD60A).withValues(alpha: 0.25)),
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
                            color: const Color(0xFFFFD60A)
                                .withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Reported Issues',
                          style: GoogleFonts.poppins(
                            color: textColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    );
                  }
                  final issue = issues[index - 1];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: const Color(0xFFFFD60A)
                              .withValues(alpha: 0.15)),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor:
                            const Color(0xFFFFD60A).withValues(alpha: 0.18),
                        child: const Icon(Icons.warning_amber_rounded,
                            color: Color(0xFFFFD60A)),
                      ),
                      title: Text(issue.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                              color: textColor,
                              fontWeight: FontWeight.w500,
                              fontSize: 13)),
                      subtitle: Text(issue.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                              color: subtleText, fontSize: 11)),
                      trailing: const Icon(Icons.chevron_right,
                          color: Color(0xFFFFD60A)),
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
