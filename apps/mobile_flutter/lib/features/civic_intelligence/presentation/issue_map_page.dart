import 'dart:math';
import 'dart:ui';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../../../core/models/issue.dart';
import '../application/usecases/get_validated_issues_use_case.dart';
import '../application/usecases/submit_issue_use_case.dart';
import '../data/repositories/api_issue_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../neural_mapper/presentation/idea_match_page.dart';
import '../../../app/app.dart' show AppTheme;
import 'issue_detail_page.dart';
import 'issue_submit_page.dart';

// ─── Cyber theme colors ───────────────────────────────────────────────────────
const _darkBg = Color(0xFF080C14);
const _darkPanel = Color(0xFF0D1520);
const _cyberGreen = Color(0xFFFFD60A);
const _cyberRed = Color(0xFFFF3366);
const _textPrimary = Color(0xFFE0E0E0);
const _textMuted = Color(0xFF6B7280);
const _gridLine = Color(0xFF1A2332);

/// Full-screen cutesy map page for Alitaptap.
/// Warm pastel palette, rounded cards, friendly Nunito font.
class IssueMapPage extends StatefulWidget {
  const IssueMapPage({
    super.key,
    this.showIdeaDock = false,
    this.studentId,
    this.onToggleTheme,
    this.themeMode = ThemeMode.dark,
    this.initialIdeaText,
    this.autoRun = false,
  });

  final bool showIdeaDock;
  final String? studentId;
  final VoidCallback? onToggleTheme;
  final ThemeMode themeMode;

  /// Pre-fill the idea dock and auto-run matching on open.
  final String? initialIdeaText;
  final bool autoRun;

  @override
  State<IssueMapPage> createState() => _IssueMapPageState();
}

class _IssueMapPageState extends State<IssueMapPage>
    with TickerProviderStateMixin {
  static const _mapStyleUrl = '{"version":8,"sources":{"osm":{"type":"raster","tiles":["https://tile.openstreetmap.org/{z}/{x}/{y}.png"],"tileSize":256,"attribution":"\u00a9 OpenStreetMap contributors"}},"layers":[{"id":"osm","type":"raster","source":"osm"}]}';
  static const _defaultCenter = LatLng(12.8797, 121.7740);
  static const _defaultZoom = 6.0;
  static const _userZoom = 15.0;

  LatLngBounds get _philippinesBounds => LatLngBounds(
        southwest: const LatLng(4.5, 116.0),
        northeast: const LatLng(21.5, 127.5),
      );

  final _issueRepository = ApiIssueRepository();
  final _ideaController = TextEditingController();

  late final GetValidatedIssuesUseCase _getValidatedIssues =
      GetValidatedIssuesUseCase(_issueRepository);
  late final SubmitIssueUseCase _submitIssueUseCase =
      SubmitIssueUseCase(_issueRepository);

  List<Issue> _issues = [];
  Position? _userPosition;

  bool _loading = true;
  bool _styleLoaded = false;
  bool _mapReady = false;
  bool _cameraMovedToUser = false;
  bool _matchingIdea = false;
  bool _generatingDemoIssue = false;
  bool _sidebarOpen = false;


  // ✅🔥 THIS IS THE FIX (missing variable)
  String? _errorMessage;

  MapLibreMapController? _mapController;
  Circle? _userLocationCircle;
  Offset? _userScreenPosition;
  final Map<String, Offset> _issueScreenPositions = {};
  double _bearing = 0.0;

  bool _isDarkMode = true;
  bool get _isDark => _isDarkMode;
  ThemeMode? _lastThemeMode;

  // Animations
  late final AnimationController _sidebarAnim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
  );
  late final Animation<double> _sidebarSlide = CurvedAnimation(
    parent: _sidebarAnim,
    curve: Curves.easeOutExpo,
  );

  // ── Lifecycle ───────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    if (widget.initialIdeaText != null) {
      _ideaController.text = widget.initialIdeaText!;
    }
    _resolveCurrentLocation();
    _loadIssues();
    if (widget.autoRun && (widget.initialIdeaText?.length ?? 0) >= 5) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _submitIdea());
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final currentMode = AppTheme.of(context).themeMode;
    _isDarkMode = currentMode == ThemeMode.dark;
    _lastThemeMode = currentMode;
  }

  @override
  void dispose() {
    _mapController?.removeListener(_onCameraMove);
    _ideaController.dispose();
    _sidebarAnim.dispose();
    super.dispose();
  }

  // ── Data ────────────────────────────────────────────────────────────────────

  Future<void> _loadIssues() async {
    try {
      final issues = await _getValidatedIssues();
      if (mounted) {
        setState(() {
          _issues = issues;
          _errorMessage = null;
          _loading = false;
        });
        // Wait for map to be ready before projecting coordinates
        if (_styleLoaded && _mapReady) {
          await _renderIssuePins();
          await Future.delayed(const Duration(milliseconds: 300));
          await _updateIssueScreenPositions();
        }
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

  // ── Map callbacks ───────────────────────────────────────────────────────────

  void _onMapCreated(MapLibreMapController controller) {
    _mapController = controller;
    controller.addListener(_onCameraMove);
    setState(() => _mapReady = true);
  }

  Future<void> _onStyleLoaded() async {
    _styleLoaded = true;
    await _moveCameraToUserLocation();
    await _renderIssuePins();
    await Future.delayed(const Duration(milliseconds: 600));
    await _updateIssueScreenPositions();
    await _updateUserScreenPosition();
  }

  Future<void> _updateUserScreenPosition() async {
    final controller = _mapController;
    final pos = _userPosition;
    if (controller == null || pos == null || !_styleLoaded) return;
    try {
      final point = await controller.toScreenLocation(
        LatLng(pos.latitude, pos.longitude),
      );
      if (mounted) {
        setState(() => _userScreenPosition =
            Offset(point.x.toDouble(), point.y.toDouble()));
      }
    } catch (_) {}
  }

  void _onCameraMove() {
    unawaited(_updateUserScreenPosition());
    unawaited(_updateIssueScreenPositions());
    final bearing = _mapController?.cameraPosition?.bearing ?? 0.0;
    if (mounted) {
      setState(() => _bearing = bearing);
    }
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
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
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
    if (controller == null || pos == null) return;
    if (!_styleLoaded && !force) return;

    final userLatLng = LatLng(pos.latitude, pos.longitude);

    if (_userLocationCircle != null) {
      await controller.removeCircle(_userLocationCircle!);
      _userLocationCircle = null;
    }

    await controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: userLatLng, zoom: _userZoom, tilt: 0),
      ),
    );

    await Future.delayed(const Duration(milliseconds: 600));
    await _updateUserScreenPosition();
    _cameraMovedToUser = true;
  }

  Future<void> _renderIssuePins() async {
    final controller = _mapController;
    if (!_styleLoaded || controller == null) return;
    await controller.clearCircles();
  }

  Future<void> _updateIssueScreenPositions() async {
    final controller = _mapController;
    if (!_styleLoaded || !_mapReady || controller == null || _issues.isEmpty) {
      if (_issueScreenPositions.isNotEmpty && mounted) {
        setState(_issueScreenPositions.clear);
      }
      return;
    }

    final positions = <String, Offset>{};
    for (final issue in _issues) {
      try {
        final screenPoint =
            await controller.toScreenLocation(LatLng(issue.lat, issue.lng));
        final offset = Offset(screenPoint.x.toDouble(), screenPoint.y.toDouble());
        // Only keep positions that are actually on-screen (non-zero)
        if (offset.dx != 0 || offset.dy != 0) {
          positions[issue.issueId] = offset;
        }
      } catch (_) {}
    }

    if (!mounted) return;
    setState(() {
      _issueScreenPositions
        ..clear()
        ..addAll(positions);
    });
  }

  Future<void> _generateProblemAtUserLocation() async {
    if (_generatingDemoIssue) return;

    Position? position = _userPosition;
    if (position == null) {
      await _resolveCurrentLocation();
      position = _userPosition;
    }

    if (position == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Location not available. Allow location access.')),
      );
      return;
    }

    final index = _issues.length + 1;
    final now = DateTime.now();

    setState(() => _generatingDemoIssue = true);
    try {
      await _submitIssueUseCase(
        SubmitIssueInput(
          reporterId: 'demo-seed-user',
          title: 'Generated Problem #$index',
          description: 'Auto-generated pin at '
              '${now.hour.toString().padLeft(2, '0')}:'
              '${now.minute.toString().padLeft(2, '0')}.',
          lat: position.latitude,
          lng: position.longitude,
        ),
      );

      if (!mounted) return;
      await _loadIssues();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Problem pinned on map.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _generatingDemoIssue = false);
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
      MaterialPageRoute(
          builder: (_) => IssueDetailPage(issueId: issue.issueId)),
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
    final studentId =
        widget.studentId ?? FirebaseAuth.instance.currentUser?.uid ?? 'anon';
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

  void _toggleSidebar() {
    setState(() => _sidebarOpen = !_sidebarOpen);
    if (_sidebarOpen) {
      _sidebarAnim.forward();
    } else {
      _sidebarAnim.reverse();
    }
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _darkBg,
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: Size.zero,
        child: AppBar(backgroundColor: Colors.transparent),
      ),
      body: Stack(
        children: [
          // ── Base map ───────────────────────────────────────────────────────
          MapLibreMap(
            styleString: _mapStyleUrl,
            initialCameraPosition: const CameraPosition(
              target: _defaultCenter,
              zoom: _defaultZoom,
              tilt: 0,
            ),
            cameraTargetBounds: CameraTargetBounds(_philippinesBounds),
            minMaxZoomPreference: const MinMaxZoomPreference(5.5, 20.0),
            onMapCreated: _onMapCreated,
            onStyleLoadedCallback: _onStyleLoaded,
            onMapClick: _onMapTap,
            compassEnabled: false,
            myLocationEnabled: false,
            attributionButtonMargins: const Point(-100, -100),
            logoViewMargins: const Point(-100, -100),
          ),

          // ── User location blip ─────────────────────────────────────────────
          if (_userScreenPosition != null)
            Positioned(
              left: _userScreenPosition!.dx - 32,
              top: _userScreenPosition!.dy - 32,
              child: const _UserBlip(),
            ),

          // ── Issue pin overlays ─────────────────────────────────────────────
          for (final issue in _issues)
            if (_issueScreenPositions[issue.issueId] != null)
              Positioned(
                left: _issueScreenPositions[issue.issueId]!.dx - 10,
                top: _issueScreenPositions[issue.issueId]!.dy - 10,
                child: GestureDetector(
                  onTap: () => _onPinTapped(issue),
                  child: const _RadarBlip(),
                ),
              ),

          // ── Top terminal bar ───────────────────────────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                child: _TerminalTopBar(
                  issueCount: _issues.length,
                  isDark: _isDark,
                  sidebarOpen: _sidebarOpen,
                  onToggleSidebar: _toggleSidebar,
                  onLocate: () async {
                    await _resolveCurrentLocation();
                    await _moveCameraToUserLocation(force: true);
                  },
                  onRefresh: () => setState(() {
                    _loading = true;
                    _errorMessage = null;
                    _loadIssues();
                  }),
                  onAddPin: _generatingDemoIssue
                      ? null
                      : _generateProblemAtUserLocation,
                  onBack: Navigator.of(context).canPop()
                      ? () => Navigator.of(context).pop()
                      : null,
                ),
              ),
            ),
          ),

          // ── Left sidebar ───────────────────────────────────────────────────
          if (!_loading)
            Positioned(
              top: 0,
              bottom: 0,
              left: 0,
              child: SafeArea(
                child: AnimatedBuilder(
                  animation: _sidebarSlide,
                  builder: (context, child) {
                    const w = 280.0;
                    final dx = -w * (1 - _sidebarSlide.value);
                    return Transform.translate(
                      offset: Offset(dx, 0),
                      child: child,
                    );
                  },
                  child: _IssueSidebar(
                    issues: _issues,
                    onTap: _onPinTapped,
                    onClose: _toggleSidebar,
                  ),
                ),
              ),
            ),

          // ── FAB cluster ───────────────────────────────────────────────────
          if (!_loading)
            Positioned(
              bottom: 90,
              left: 16,
              child: _MapFabCluster(
                onReport: () {
                  final uid = FirebaseAuth.instance.currentUser?.uid ?? 'anon';
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => IssueSubmitPage(reporterId: uid),
                  ));
                },
                onResearch: () {
                  final uid = FirebaseAuth.instance.currentUser?.uid ?? 'anon';
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => IdeaMatchPage(
                      studentId: uid,
                      initialIdeaText: '',
                      autoRun: false,
                    ),
                  ));
                },
              ),
            ),

          // ── Compass ────────────────────────────────────────────────────────
          if (!_loading)
            Positioned(
              bottom: 24,
              right: 16,
              child: _MapCompass(
                bearing: _bearing,
                onTap: () => _mapController?.animateCamera(
                  CameraUpdate.newCameraPosition(
                    CameraPosition(
                      target: _mapController?.cameraPosition?.target ??
                          _defaultCenter,
                      zoom:
                          _mapController?.cameraPosition?.zoom ?? _defaultZoom,
                      tilt: 0,
                      bearing: 0,
                    ),
                  ),
                ),
              ),
            ),

          // ── Loading overlay ────────────────────────────────────────────────
          if (_loading)
            Container(
              color: _darkBg.withValues(alpha: 0.85),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 48,
                      height: 48,
                      child: CircularProgressIndicator(
                        color: _cyberGreen,
                        strokeWidth: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'LOADING CIVIC DATA...',
                      style: GoogleFonts.robotoMono(
                        color: _cyberGreen,
                        fontSize: 11,
                        letterSpacing: 2.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // ── Idea dock ──────────────────────────────────────────────────────
          if (!_loading)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _IdeaDock(
                controller: _ideaController,
                isMatching: _matchingIdea,
                onSubmit: _submitIdea,
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

/// Terminal-style top navigation bar.
class _TerminalTopBar extends StatelessWidget {
  const _TerminalTopBar({
    required this.issueCount,
    required this.isDark,
    required this.sidebarOpen,
    required this.onToggleSidebar,
    required this.onLocate,
    required this.onRefresh,
    this.onAddPin,
    this.onBack,
  });

  final int issueCount;
  final bool isDark;
  final bool sidebarOpen;
  final VoidCallback onToggleSidebar;
  final VoidCallback onLocate;
  final VoidCallback onRefresh;
  final VoidCallback? onAddPin;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: const Color(0xFFFFD60A).withValues(alpha: 0.45),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // Back
              if (onBack != null) ...[
                _TBtn(icon: Icons.arrow_back_ios_rounded, onPressed: onBack),
                const SizedBox(width: 4),
              ],

              // Sidebar toggle
              _TBtn(
                icon:
                    sidebarOpen ? Icons.menu_open_rounded : Icons.menu_rounded,
                onPressed: onToggleSidebar,
              ),
              const SizedBox(width: 10),

              // Title
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'ALITAPTAP // CIVIC-INTEL',
                      style: GoogleFonts.robotoMono(
                        color: _cyberGreen,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.8,
                      ),
                    ),
                    Text(
                      '${issueCount.toString().padLeft(4, '0')} ISSUES LOADED',
                      style: GoogleFonts.robotoMono(
                        color: _textMuted,
                        fontSize: 8,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),

              // Controls
              _TBtn(icon: Icons.my_location_rounded, onPressed: onLocate),
              const SizedBox(width: 8),
              _TBtn(icon: Icons.refresh_rounded, onPressed: onRefresh),
              const SizedBox(width: 8),
              _TBtn(icon: Icons.add_location_alt_rounded, onPressed: onAddPin),
            ],
          ),
        ),
      ),
    );
  }
}

/// Small icon button used in the terminal top bar.
class _TBtn extends StatelessWidget {
  const _TBtn({required this.icon, this.onPressed});
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Icon(
        icon,
        color: onPressed == null ? _textMuted : _cyberGreen,
        size: 18,
      ),
    );
  }
}

/// Glowing user location blip (cyan ripple).
class _UserBlip extends StatefulWidget {
  const _UserBlip();

  @override
  State<_UserBlip> createState() => _UserBlipState();
}

class _UserBlipState extends State<_UserBlip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat();

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) {
        final t = _anim.value;
        return SizedBox(
          width: 64,
          height: 64,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Pulse ring
              Container(
                width: 64 * t,
                height: 64 * t,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _cyberGreen.withValues(alpha: 0.5 * (1 - t)),
                    width: 1.5,
                  ),
                ),
              ),
              // Core dot
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _cyberGreen,
                  boxShadow: [
                    BoxShadow(
                      color: _cyberGreen.withValues(alpha: 0.7),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
              // Inner dot
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: _darkBg,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Radar blip for issue pins — small red glowing dot with pulse.
class _RadarBlip extends StatefulWidget {
  const _RadarBlip();

  @override
  State<_RadarBlip> createState() => _RadarBlipState();
}

class _RadarBlipState extends State<_RadarBlip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) {
        final t = _anim.value;
        return SizedBox(
          width: 32,
          height: 32,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Pulse ring
              Container(
                width: 32 * t,
                height: 32 * t,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _cyberRed.withValues(alpha: 0.55 * (1 - t)),
                    width: 1,
                  ),
                ),
              ),
              // Core
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _cyberRed,
                  boxShadow: [
                    BoxShadow(
                      color: _cyberRed.withValues(alpha: 0.6),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Compass rose that rotates with map bearing, snaps north on tap.
class _MapCompass extends StatelessWidget {
  const _MapCompass({required this.bearing, required this.onTap});
  final double bearing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _darkPanel,
          border: Border.all(
            color: _cyberGreen.withValues(alpha: 0.4),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: _cyberGreen.withValues(alpha: 0.20),
              blurRadius: 12,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Transform.rotate(
          angle: -bearing * (pi / 180),
          child: CustomPaint(painter: _CompassPainter()),
        ),
      ),
    );
  }
}

class _CompassPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width * 0.30;

    // North — cyber green
    canvas.drawPath(
      Path()
        ..moveTo(cx, cy - r * 1.5)
        ..lineTo(cx - r * 0.5, cy + r * 0.25)
        ..lineTo(cx + r * 0.5, cy + r * 0.25)
        ..close(),
      Paint()..color = _cyberGreen,
    );

    // South — muted
    canvas.drawPath(
      Path()
        ..moveTo(cx, cy + r * 1.5)
        ..lineTo(cx - r * 0.5, cy - r * 0.25)
        ..lineTo(cx + r * 0.5, cy - r * 0.25)
        ..close(),
      Paint()..color = _textMuted,
    );

    // Center
    canvas.drawCircle(
      Offset(cx, cy),
      r * 0.28,
      Paint()..color = _darkPanel,
    );

    // N label
    final tp = TextPainter(
      text: TextSpan(
        text: 'N',
        style: GoogleFonts.robotoMono(
          color: _darkBg,
          fontSize: 8,
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(cx - tp.width / 2, cy - r * 1.5 + 2));
  }

  @override
  bool shouldRepaint(_CompassPainter old) => false;
}

/// Left collapsible sidebar listing all validated issues.
class _IssueSidebar extends StatelessWidget {
  const _IssueSidebar({
    required this.issues,
    required this.onTap,
    required this.onClose,
  });

  final List<Issue> issues;
  final ValueChanged<Issue> onTap;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: _darkPanel.withValues(alpha: 0.94),
        border: Border(
          right: BorderSide(
            color: _cyberGreen.withValues(alpha: 0.22),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 52, 16, 12),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: _cyberGreen.withValues(alpha: 0.15),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.radar, color: _cyberGreen, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'ISSUE DATASETS',
                    style: GoogleFonts.robotoMono(
                      color: _cyberGreen,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.6,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: onClose,
                  child: const Icon(
                    Icons.close_rounded,
                    color: _textMuted,
                    size: 18,
                  ),
                ),
              ],
            ),
          ),

          // Issue count chip
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
            child: Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _cyberGreen.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: _cyberGreen.withValues(alpha: 0.30),
                    ),
                  ),
                  child: Text(
                    '${issues.length} ACTIVE',
                    style: GoogleFonts.robotoMono(
                      color: _cyberGreen,
                      fontSize: 9,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              itemCount: issues.length,
              itemBuilder: (context, i) {
                final issue = issues[i];
                return _SidebarIssueRow(
                  issue: issue,
                  index: i,
                  onTap: () => onTap(issue),
                );
              },
            ),
          ),

          // Footer
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: _cyberGreen.withValues(alpha: 0.12),
                  width: 1,
                ),
              ),
            ),
            child: Text(
              'ALITAPTAP CIVIC-INTEL v2.0',
              style: GoogleFonts.robotoMono(
                color: _textMuted,
                fontSize: 8,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarIssueRow extends StatefulWidget {
  const _SidebarIssueRow({
    required this.issue,
    required this.index,
    required this.onTap,
  });

  final Issue issue;
  final int index;
  final VoidCallback onTap;

  @override
  State<_SidebarIssueRow> createState() => _SidebarIssueRowState();
}

class _SidebarIssueRowState extends State<_SidebarIssueRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _hovered = true),
      onTapUp: (_) => setState(() => _hovered = false),
      onTapCancel: () => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: _hovered
              ? _cyberGreen.withValues(alpha: 0.08)
              : _darkBg.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: _hovered ? _cyberGreen.withValues(alpha: 0.45) : _gridLine,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Index badge
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _cyberRed.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: _cyberRed.withValues(alpha: 0.35)),
              ),
              child: Text(
                (widget.index + 1).toString().padLeft(2, '0'),
                style: GoogleFonts.robotoMono(
                  color: _cyberRed,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.issue.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.robotoMono(
                      color: _textPrimary,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.issue.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.robotoMono(
                      color: _textMuted,
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              Icons.chevron_right_rounded,
              color: _hovered ? _cyberGreen : _textMuted,
              size: 14,
            ),
          ],
        ),
      ),
    );
  }
}

/// Floating action button cluster — Report a Problem + Research Idea.
class _MapFabCluster extends StatelessWidget {
  const _MapFabCluster({
    required this.onReport,
    required this.onResearch,
  });

  final VoidCallback onReport;
  final VoidCallback onResearch;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _FabButton(
          icon: Icons.add_location_alt_rounded,
          label: 'REPORT PROBLEM',
          onTap: onReport,
        ),
        const SizedBox(height: 10),
        _FabButton(
          icon: Icons.auto_awesome_rounded,
          label: 'RESEARCH IDEA',
          onTap: onResearch,
        ),
      ],
    );
  }
}

class _FabButton extends StatelessWidget {
  const _FabButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFD60A).withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: const Color(0xFFFFD60A).withValues(alpha: 0.50),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFD60A).withValues(alpha: 0.15),
                  blurRadius: 16,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: _cyberGreen, size: 16),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: GoogleFonts.robotoMono(
                    color: _cyberGreen,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Cyber-styled idea matching input dock with collapsible nav behavior.
class _IdeaDock extends StatefulWidget {
  const _IdeaDock({
    required this.controller,
    required this.isMatching,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final bool isMatching;
  final VoidCallback onSubmit;

  @override
  State<_IdeaDock> createState() => _IdeaDockState();
}

class _IdeaDockState extends State<_IdeaDock>
    with SingleTickerProviderStateMixin {
  static const double _collapsedHeight = 56;
  static const double _expandedHeight = 128;

  late final AnimationController _sheetController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
    value: 0,
  );

  bool get _collapsed => _sheetController.value <= 0.02;

  void _toggleCollapsed() {
    if (_sheetController.value > 0.5) {
      _sheetController.fling(velocity: -2.0);
    } else {
      _sheetController.fling(velocity: 2.0);
    }
  }

  void _onDragUpdate(DragUpdateDetails details) {
    final dy = details.primaryDelta ?? 0;
    final range = _expandedHeight - _collapsedHeight;
    _sheetController.value = (_sheetController.value - (dy / range)).clamp(0, 1);
  }

  void _onDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;

    if (velocity.abs() > 220) {
      _sheetController.fling(velocity: velocity < 0 ? 2.2 : -2.2);
      return;
    }

    if (_sheetController.value > 0.5) {
      _sheetController.animateTo(1, curve: Curves.easeOutCubic);
    } else {
      _sheetController.animateTo(0, curve: Curves.easeOutCubic);
    }
  }

  @override
  void dispose() {
    _sheetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onVerticalDragUpdate: _onDragUpdate,
      onVerticalDragEnd: _onDragEnd,
      child: AnimatedBuilder(
        animation: _sheetController,
        builder: (context, _) {
          final progress = Curves.easeOutCubic.transform(_sheetController.value);
          final height =
              _collapsedHeight + ((_expandedHeight - _collapsedHeight) * progress);

          return Container(
            height: height,
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.98),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
              border: Border.all(
                color: const Color(0xFFE5E7EB),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.14),
                  blurRadius: 18,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: _toggleCollapsed,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 42,
                          height: 4,
                          decoration: BoxDecoration(
                            color: const Color(0xFFCBD5E1),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              Icons.lightbulb_rounded,
                              color: Color(0xFF111827),
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                progress < 0.3
                                    ? 'Pull up for research input'
                                    : 'Research idea input',
                                style: GoogleFonts.robotoMono(
                                  color: const Color(0xFF111827),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.7,
                                ),
                              ),
                            ),
                            Icon(
                              progress < 0.5
                                  ? Icons.keyboard_arrow_up_rounded
                                  : Icons.keyboard_arrow_down_rounded,
                              color: const Color(0xFF111827),
                              size: 18,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                if (progress > 0.05) ...[
                  Divider(
                    color: const Color(0xFFE5E7EB),
                    height: 1,
                    thickness: 1,
                  ),
                  Opacity(
                    opacity: progress,
                    child: Row(
                      children: [
                        const SizedBox(width: 12),
                        const Icon(
                          Icons.edit_rounded,
                          color: Color(0xFF111827),
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: widget.controller,
                            textInputAction: TextInputAction.search,
                            onSubmitted: (_) => widget.onSubmit(),
                            style: GoogleFonts.robotoMono(
                              color: const Color(0xFF111827),
                              fontSize: 13,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Enter research idea...',
                              hintStyle: GoogleFonts.robotoMono(
                                color: const Color(0xFF6B7280),
                                fontSize: 12,
                              ),
                              border: InputBorder.none,
                              filled: false,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: widget.isMatching
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Color(0xFF111827),
                                    strokeWidth: 1.8,
                                  ),
                                )
                              : GestureDetector(
                                  onTap: widget.onSubmit,
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF3F4F6),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: const Color(0xFFD1D5DB),
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.arrow_forward_rounded,
                                      color: Color(0xFF111827),
                                      size: 16,
                                    ),
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
