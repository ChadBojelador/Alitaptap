import 'dart:convert';
import 'dart:math';
import 'dart:ui';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:maplibre_gl/maplibre_gl.dart';

import '../../../core/models/issue.dart';
import '../application/usecases/get_validated_issues_use_case.dart';
import '../application/usecases/submit_issue_use_case.dart';
import '../data/repositories/api_issue_repository.dart';
import '../../neural_mapper/presentation/idea_match_page.dart';
import '../../../app/app.dart' show AppTheme;
import 'issue_detail_page.dart';

// ─── Design tokens ────────────────────────────────────────────────────────────
const _cyberGreen  = Color(0xFF00FFB2);
const _cyberGreenD = Color(0xFF00CC8E); // dimmer variant
const _cyberRed    = Color(0xFFFF2D55);
const _darkBg      = Color(0xFF0A0E17);
const _darkPanel   = Color(0xFF0D1320);
const _gridLine    = Color(0xFF1A2A3A);
const _textPrimary = Color(0xFFE0FFF8);
const _textMuted   = Color(0xFF4A7A6A);

/// Full-screen cyber-terminal map page.
///
/// Redesigned to match the aesthetic of phadmindownloader.vercel.app:
/// - Near-black deep-space map with cyan/green neon accents
/// - Scanline grid overlay for terminal feel
/// - Left collapsible sidebar listing issues (replaces bottom sheet)
/// - Radar-blip glowing issue pins
/// - Monospace terminal-style top bar
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
  static const _mapStyleUrl =
      'https://tiles.openfreemap.org/styles/liberty';
  static const _defaultCenter = LatLng(12.8797, 121.7740);
  static const _defaultZoom   = 6.0;
  static const _userZoom      = 16.5;
  static final _philippinesBounds = LatLngBounds(
    southwest: LatLng(4.5,  116.0),
    northeast: LatLng(21.5, 127.0),
  );

  final _issueRepository   = ApiIssueRepository();
  final _ideaController    = TextEditingController();
  final _sidebarKey        = GlobalKey();

  late final GetValidatedIssuesUseCase _getValidatedIssues =
      GetValidatedIssuesUseCase(_issueRepository);
  late final SubmitIssueUseCase _submitIssueUseCase =
      SubmitIssueUseCase(_issueRepository);

  List<Issue> _issues      = [];
  String?     _errorMessage;
  Position?   _userPosition;

  bool _loading            = true;
  bool _styleLoaded        = false;
  bool _cameraMovedToUser  = false;
  bool _matchingIdea       = false;
  bool _generatingDemoIssue= false;
  bool _sidebarOpen        = false;

  MapLibreMapController? _mapController;
  Circle? _userLocationCircle;
  Offset? _userScreenPosition;
  final Map<String, Offset> _issueScreenPositions = {};
  double  _bearing         = 0.0;
  String? _patchedStyle;

  bool _isDarkMode         = true;
  bool get _isDark         => _isDarkMode;
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

  late final AnimationController _scanAnim = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  )..repeat();

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
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _submitIdea());
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final currentMode = AppTheme.of(context).themeMode;
    _isDarkMode = currentMode == ThemeMode.dark;
    if (_lastThemeMode != currentMode) {
      _styleLoaded  = false;
      _patchedStyle = null;
      _loadPatchedStyle();
      _lastThemeMode = currentMode;
    }
  }

  @override
  void dispose() {
    _mapController?.removeListener(_onCameraMove);
    _ideaController.dispose();
    _sidebarAnim.dispose();
    _scanAnim.dispose();
    super.dispose();
  }

  // ── Map style patching ──────────────────────────────────────────────────────

  /// Fetches and patches the liberty style to a deep-space cyber aesthetic.
  Future<void> _loadPatchedStyle() async {
    try {
      final res = await http.get(Uri.parse(_mapStyleUrl));
      if (res.statusCode != 200) return;
      final style  = jsonDecode(res.body) as Map<String, dynamic>;
      final layers = style['layers'] as List<dynamic>;

      // Cyber-terminal dark palette — near-black land, deep cyan water.
      const patches = <String, String>{
        'background':                     '#080C14',
        'park':                           '#081A10',
        'landuse_residential':            '#0A1018',
        'landcover_wood':                 '#061410',
        'landcover_grass':                '#081610',
        'landcover_wetland':              '#071218',
        'landcover_sand':                 '#0C140C',
        'landcover_ice':                  '#0C1420',
        'landuse_cemetery':               '#090F18',
        'landuse_hospital':               '#090F18',
        'landuse_school':                 '#090F18',
        'landuse_pitch':                  '#071410',
        'landuse_track':                  '#071410',
        'aeroway_fill':                   '#080C14',
        'water':                          '#003A4A',
        'waterway_river':                 '#004D5E',
        'waterway_other':                 '#003A4A',
        'waterway_tunnel':                '#002A36',
        'road_motorway':                  '#00FFB2',
        'road_motorway_casing':           '#009966',
        'road_motorway_link':             '#00FFB2',
        'road_motorway_link_casing':      '#009966',
        'road_trunk_primary':             '#00CC8E',
        'road_trunk_primary_casing':      '#007755',
        'road_secondary_tertiary':        '#009977',
        'road_secondary_tertiary_casing': '#005544',
        'road_minor':                     '#0D2030',
        'road_minor_casing':              '#091828',
        'road_link':                      '#009977',
        'road_link_casing':               '#005544',
        'road_service_track':             '#0B1C2C',
        'road_service_track_casing':      '#071420',
        'road_path_pedestrian':           '#0B1C2C',
        'bridge_motorway':                '#00FFB2',
        'bridge_motorway_casing':         '#009966',
        'bridge_trunk_primary':           '#00CC8E',
        'bridge_trunk_primary_casing':    '#007755',
        'bridge_secondary_tertiary':      '#009977',
        'bridge_street':                  '#0D2030',
        'bridge_motorway_link':           '#00FFB2',
        'bridge_link':                    '#009977',
        'bridge_service_track':           '#0B1C2C',
        'bridge_path_pedestrian':         '#0B1C2C',
        'tunnel_motorway':                '#009966',
        'tunnel_trunk_primary':           '#007755',
        'tunnel_secondary_tertiary':      '#005544',
        'tunnel_minor':                   '#091828',
        'building':                       '#0D1C30',
        'road_major_rail':                '#1A3040',
        'road_transit_rail':              '#1A3040',
        'bridge_major_rail':              '#1A3040',
        'bridge_transit_rail':            '#1A3040',
        'boundary_2':                     '#00FFB2',
        'boundary_3':                     '#00CC8E',
      };

      for (final layer in layers) {
        final map   = layer as Map<String, dynamic>;
        final id    = map['id']   as String? ?? '';
        final type  = map['type'] as String? ?? '';
        final paint = Map<String, dynamic>.from(
            map['paint'] as Map<String, dynamic>? ?? {});

        if (patches.containsKey(id)) {
          final color = patches[id]!;
          if (type == 'background') {
            paint['background-color'] = color;
          } else if (type == 'fill') {
            paint['fill-color']    = color;
            paint['fill-opacity']  = 1.0;
          } else if (type == 'line') {
            paint['line-color'] = color;
          }
          map['paint'] = paint;
        }
      }

      if (mounted) setState(() => _patchedStyle = jsonEncode(style));
    } catch (_) {}
  }

  // ── Data ────────────────────────────────────────────────────────────────────

  Future<void> _loadIssues() async {
    try {
      final issues = await _getValidatedIssues();
      if (mounted) {
        setState(() {
          _issues       = issues;
          _errorMessage = null;
          _loading      = false;
        });
        await _renderIssuePins();
        await _updateIssueScreenPositions();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading      = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  // ── Map callbacks ───────────────────────────────────────────────────────────

  void _onMapCreated(MapLibreMapController controller) {
    _mapController = controller;
    controller.addListener(_onCameraMove);
  }

  Future<void> _onStyleLoaded() async {
    _styleLoaded = true;
    final controller = _mapController;
    if (controller != null) {
      const labelSizes = {
        'label_country_1':   26.0,
        'label_country_2':   24.0,
        'label_country_3':   22.0,
        'label_state':       18.0,
        'label_city_capital':16.0,
        'label_city':        15.0,
        'label_town':        13.0,
        'label_village':     11.0,
        'label_other':       10.0,
      };

      for (final entry in labelSizes.entries) {
        try {
          await controller.setLayerProperties(
            entry.key,
            SymbolLayerProperties(
              textColor:      '#00FFB2',
              textSize:       entry.value,
              textHaloColor:  '#080C14',
              textHaloWidth:  2.5,
              textHaloBlur:   0,
            ),
          );
        } catch (_) {}
      }

      const hideLayers = [
        'poi_r20', 'poi_r7', 'poi_r1', 'poi_transit', 'airport',
      ];
      for (final layer in hideLayers) {
        try { await controller.setLayerVisibility(layer, false); } catch (_) {}
      }
    }
    await _moveCameraToUserLocation();
    await _renderIssuePins();
    await _updateIssueScreenPositions();
  }

  Future<void> _updateUserScreenPosition() async {
    final controller = _mapController;
    final pos        = _userPosition;
    if (controller == null || pos == null) return;
    final point = await controller.toScreenLocation(
      LatLng(pos.latitude, pos.longitude),
    );
    if (mounted) {
      setState(() => _userScreenPosition =
          Offset(point.x.toDouble(), point.y.toDouble()));
    }
  }

  void _onCameraMove() {
    unawaited(_updateUserScreenPosition());
    unawaited(_updateIssueScreenPositions());
    final bearing = _mapController?.cameraPosition?.bearing ?? 0.0;
    if (mounted) setState(() => _bearing = bearing);
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
          permission == LocationPermission.deniedForever) return;

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
    final pos        = _userPosition;
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
  }

  Future<void> _updateIssueScreenPositions() async {
    final controller = _mapController;
    if (!_styleLoaded || controller == null || _issues.isEmpty) {
      if (_issueScreenPositions.isNotEmpty && mounted) {
        setState(_issueScreenPositions.clear);
      }
      return;
    }

    final positions = <String, Offset>{};
    for (final issue in _issues) {
      try {
        final screenPoint = await controller
            .toScreenLocation(LatLng(issue.lat, issue.lng));
        positions[issue.issueId] =
            Offset(screenPoint.x.toDouble(), screenPoint.y.toDouble());
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
    final now   = DateTime.now();

    setState(() => _generatingDemoIssue = true);
    try {
      await _submitIssueUseCase(
        SubmitIssueInput(
          reporterId:  'demo-seed-user',
          title:       'Generated Problem #$index',
          description: 'Auto-generated pin at '
              '${now.hour.toString().padLeft(2, '0')}:'
              '${now.minute.toString().padLeft(2, '0')}.',
          lat: position.latitude,
          lng: position.longitude,
        ),
      );

      if (!mounted) return;
      await _loadIssues();
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
    final studentId = widget.studentId;
    if (studentId == null || studentId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Student session not found. Please sign in again.')),
      );
      return;
    }
    setState(() => _matchingIdea = true);
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => IdeaMatchPage(
          studentId:       studentId,
          initialIdeaText: idea,
          autoRun:         true,
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
            styleString: _patchedStyle ?? _mapStyleUrl,
            initialCameraPosition: const CameraPosition(
              target: _defaultCenter,
              zoom:   _defaultZoom,
              tilt:   60,
            ),
            cameraTargetBounds:
                CameraTargetBounds(_philippinesBounds),
            minMaxZoomPreference:
                const MinMaxZoomPreference(5.5, 20.0),
            onMapCreated:          _onMapCreated,
            onStyleLoadedCallback: _onStyleLoaded,
            onMapClick:            _onMapTap,
            compassEnabled:        false,
            myLocationEnabled:     false,
            attributionButtonMargins: const Point(-100, -100),
            logoViewMargins:          const Point(-100, -100),
          ),

          // ── Scanline overlay ───────────────────────────────────────────────
          IgnorePointer(
            child: CustomPaint(
              painter: _ScanlinePainter(_scanAnim),
              child: const SizedBox.expand(),
            ),
          ),

          // ── User location blip ─────────────────────────────────────────────
          if (_userScreenPosition != null)
            Positioned(
              left: _userScreenPosition!.dx - 32,
              top:  _userScreenPosition!.dy - 32,
              child: const _UserBlip(),
            ),

          // ── Issue pin overlays ─────────────────────────────────────────────
          for (final issue in _issues)
            if (_issueScreenPositions[issue.issueId] != null)
              Positioned(
                left: _issueScreenPositions[issue.issueId]!.dx - 10,
                top:  _issueScreenPositions[issue.issueId]!.dy - 10,
                child: GestureDetector(
                  onTap: () => _onPinTapped(issue),
                  child: const _RadarBlip(),
                ),
              ),

          // ── Top terminal bar ───────────────────────────────────────────────
          Positioned(
            top:   0,
            left:  0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                child: _TerminalTopBar(
                  issueCount:       _issues.length,
                  isDark:           _isDark,
                  sidebarOpen:      _sidebarOpen,
                  onToggleSidebar:  _toggleSidebar,
                  onLocate: () async {
                    await _resolveCurrentLocation();
                    await _moveCameraToUserLocation(force: true);
                  },
                  onRefresh: () => setState(() {
                    _loading      = true;
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
              top:    0,
              bottom: 0,
              left:   0,
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
                    issues:    _issues,
                    onTap:     _onPinTapped,
                    onClose:   _toggleSidebar,
                  ),
                ),
              ),
            ),

          // ── Compass ────────────────────────────────────────────────────────
          if (!_loading)
            Positioned(
              bottom: widget.showIdeaDock ? 96 : 24,
              right:  16,
              child: _MapCompass(
                bearing: _bearing,
                onTap: () => _mapController?.animateCamera(
                  CameraUpdate.newCameraPosition(
                    CameraPosition(
                      target: _mapController?.cameraPosition?.target ??
                          _defaultCenter,
                      zoom: _mapController?.cameraPosition?.zoom ??
                          _defaultZoom,
                      tilt: _mapController?.cameraPosition?.tilt ?? 60,
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
                      width:  48,
                      height: 48,
                      child: CircularProgressIndicator(
                        color:       _cyberGreen,
                        strokeWidth: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'LOADING CIVIC DATA...',
                      style: GoogleFonts.robotoMono(
                        color:     _cyberGreen,
                        fontSize:  11,
                        letterSpacing: 2.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // ── Idea dock ──────────────────────────────────────────────────────
          if (widget.showIdeaDock)
            Positioned(
              left:   16,
              right:  16,
              bottom: 16,
              child: SafeArea(
                child: _IdeaDock(
                  controller:  _ideaController,
                  isMatching:  _matchingIdea,
                  onSubmit:    _submitIdea,
                ),
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

/// Horizontal scanline grid drawn over the entire screen.
class _ScanlinePainter extends CustomPainter {
  _ScanlinePainter(this.animation) : super(repaint: animation);
  final Animation<double> animation;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF00FFB2).withValues(alpha: 0.028)
      ..strokeWidth = 1;

    const spacing = 4.0;
    final rows = (size.height / spacing).ceil();
    for (var i = 0; i < rows; i++) {
      final y = i * spacing;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Animated sweep line
    final sweepY = size.height * animation.value;
    canvas.drawLine(
      Offset(0, sweepY),
      Offset(size.width, sweepY),
      Paint()
        ..color = const Color(0xFF00FFB2).withValues(alpha: 0.12)
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(_ScanlinePainter old) => true;
}

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

  final int      issueCount;
  final bool     isDark;
  final bool     sidebarOpen;
  final VoidCallback  onToggleSidebar;
  final VoidCallback  onLocate;
  final VoidCallback  onRefresh;
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
            color:        _darkPanel.withValues(alpha: 0.88),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _cyberGreen.withValues(alpha: 0.30),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // Back
              if (onBack != null) ...[
                _TBtn(
                    icon: Icons.arrow_back_ios_rounded,
                    onPressed: onBack),
                const SizedBox(width: 4),
              ],

              // Sidebar toggle
              _TBtn(
                icon: sidebarOpen
                    ? Icons.menu_open_rounded
                    : Icons.menu_rounded,
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
                        color:         _cyberGreen,
                        fontSize:      10,
                        fontWeight:    FontWeight.w700,
                        letterSpacing: 1.8,
                      ),
                    ),
                    Text(
                      '${issueCount.toString().padLeft(4, '0')} ISSUES LOADED',
                      style: GoogleFonts.robotoMono(
                        color:         _textMuted,
                        fontSize:      8,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),

              // Controls
              _TBtn(icon: Icons.my_location_rounded,  onPressed: onLocate),
              const SizedBox(width: 8),
              _TBtn(icon: Icons.refresh_rounded,       onPressed: onRefresh),
              const SizedBox(width: 8),
              _TBtn(
                  icon: Icons.add_location_alt_rounded,
                  onPressed: onAddPin),
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
  final IconData     icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Icon(
        icon,
        color: onPressed == null
            ? _textMuted
            : _cyberGreen,
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
          width:  64,
          height: 64,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Pulse ring
              Container(
                width:  64 * t,
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
                width:  14,
                height: 14,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _cyberGreen,
                  boxShadow: [
                    BoxShadow(
                      color:       _cyberGreen.withValues(alpha: 0.7),
                      blurRadius:  10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
              // Inner dot
              Container(
                width:  6,
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
          width:  32,
          height: 32,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Pulse ring
              Container(
                width:  32 * t,
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
                width:  10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _cyberRed,
                  boxShadow: [
                    BoxShadow(
                      color:       _cyberRed.withValues(alpha: 0.6),
                      blurRadius:  8,
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
  final double       bearing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width:  48,
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
              color:       _cyberGreen.withValues(alpha: 0.20),
              blurRadius:  12,
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
    final cx = size.width  / 2;
    final cy = size.height / 2;
    final r  = size.width  * 0.30;

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
        text:  'N',
        style: GoogleFonts.robotoMono(
          color:      _darkBg,
          fontSize:   8,
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

  final List<Issue>        issues;
  final ValueChanged<Issue> onTap;
  final VoidCallback        onClose;

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
                const Icon(Icons.radar, color: _cyberGreen, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'ISSUE DATASETS',
                    style: GoogleFonts.robotoMono(
                      color:         _cyberGreen,
                      fontSize:      11,
                      fontWeight:    FontWeight.w700,
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
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color:        _cyberGreen.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: _cyberGreen.withValues(alpha: 0.30),
                    ),
                  ),
                  child: Text(
                    '${issues.length} ACTIVE',
                    style: GoogleFonts.robotoMono(
                      color:         _cyberGreen,
                      fontSize:      9,
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
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 4),
              itemCount: issues.length,
              itemBuilder: (context, i) {
                final issue = issues[i];
                return _SidebarIssueRow(
                  issue:  issue,
                  index:  i,
                  onTap:  () => onTap(issue),
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
                color:         _textMuted,
                fontSize:      8,
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

  final Issue        issue;
  final int          index;
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
      onTapUp:   (_) => setState(() => _hovered = false),
      onTapCancel: ()  => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration:     const Duration(milliseconds: 120),
        margin:       const EdgeInsets.only(bottom: 6),
        padding:      const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: _hovered
              ? _cyberGreen.withValues(alpha: 0.08)
              : _darkBg.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: _hovered
                ? _cyberGreen.withValues(alpha: 0.45)
                : _gridLine,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Index badge
            Container(
              width:  28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color:        _cyberRed.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                    color: _cyberRed.withValues(alpha: 0.35)),
              ),
              child: Text(
                '${(widget.index + 1).toString().padLeft(2, '0')}',
                style: GoogleFonts.robotoMono(
                  color:      _cyberRed,
                  fontSize:   9,
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
                    maxLines:  1,
                    overflow:  TextOverflow.ellipsis,
                    style: GoogleFonts.robotoMono(
                      color:      _textPrimary,
                      fontSize:   10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.issue.description,
                    maxLines:  2,
                    overflow:  TextOverflow.ellipsis,
                    style: GoogleFonts.robotoMono(
                      color:    _textMuted,
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
              size:  14,
            ),
          ],
        ),
      ),
    );
  }
}

/// Cyber-styled idea matching input dock.
class _IdeaDock extends StatelessWidget {
  const _IdeaDock({
    required this.controller,
    required this.isMatching,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final bool                  isMatching;
  final VoidCallback          onSubmit;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          decoration: BoxDecoration(
            color:        _darkPanel.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _cyberGreen.withValues(alpha: 0.35),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color:       _cyberGreen.withValues(alpha: 0.08),
                blurRadius:  20,
                spreadRadius: 0,
                offset:      const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              const SizedBox(width: 14),
              Text(
                '> ',
                style: GoogleFonts.robotoMono(
                  color:    _cyberGreen,
                  fontSize: 14,
                ),
              ),
              Expanded(
                child: TextField(
                  controller:      controller,
                  textInputAction: TextInputAction.search,
                  onSubmitted:     (_) => onSubmit(),
                  style: GoogleFonts.robotoMono(
                    color:    _textPrimary,
                    fontSize: 13,
                  ),
                  decoration: InputDecoration(
                    hintText: 'ENTER RESEARCH IDEA...',
                    hintStyle: GoogleFonts.robotoMono(
                      color:         _textMuted,
                      fontSize:      12,
                      letterSpacing: 0.8,
                    ),
                    border:  InputBorder.none,
                    filled:  false,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: isMatching
                    ? SizedBox(
                        width:  20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color:       _cyberGreen,
                          strokeWidth: 1.5,
                        ),
                      )
                    : GestureDetector(
                        onTap: onSubmit,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color:        _cyberGreen.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _cyberGreen.withValues(alpha: 0.45),
                            ),
                          ),
                          child: const Icon(
                            Icons.arrow_forward_rounded,
                            color: _cyberGreen,
                            size:  16,
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
