import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:maplibre_gl/maplibre_gl.dart';

import '../../../core/models/issue.dart';
import '../application/usecases/get_validated_issues_use_case.dart';
import '../application/usecases/submit_issue_use_case.dart';
import '../data/repositories/api_issue_repository.dart';
import '../../neural_mapper/presentation/idea_match_page.dart';
import '../../../app/app.dart' show AppTheme;
import 'issue_detail_page.dart';

// ─── Design tokens ──────────────────────────────────────────────────────
const _cyberGreen  = Color(0xFFFFD60A);
const _cyberRed    = Color(0xFFFF2D55);
const _darkBg      = Color(0xFF0A0E17);
const _darkPanel   = Color(0xFF0D1320);
const _gridLine    = Color(0xFF1A2A3A);
const _textPrimary = Color(0xFFE0FFF8);
const _textMuted   = Color(0xFF8A7340);
const _userLocBlue = Color(0xFF00BFFF);

/// Full-screen cyber-terminal map page — mobile variant.
///
/// Differences from web:
/// - GPS "You're Here" blip via Geolocator
/// - Native location permission handling
/// - Lighter animation footprint for smoother scrolling
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
  final String? initialIdeaText;
  final bool autoRun;

  @override
  State<IssueMapPage> createState() => _IssueMapPageState();
}

class _IssueMapPageState extends State<IssueMapPage>
    with TickerProviderStateMixin {

  // ── Constants ──────────────────────────────────────────────────────────
  static const _mapStyleUrl =
      'https://tiles.openfreemap.org/styles/liberty';
  static const _defaultCenter = LatLng(12.8797, 121.7740);
  static const _defaultZoom   = 6.0;

  // ── Dependencies ───────────────────────────────────────────────────────
  final _issueRepository = ApiIssueRepository();
  final _ideaController  = TextEditingController();

  late final GetValidatedIssuesUseCase _getValidatedIssues =
      GetValidatedIssuesUseCase(_issueRepository);
  late final SubmitIssueUseCase _submitIssueUseCase =
      SubmitIssueUseCase(_issueRepository);

  // ── State ──────────────────────────────────────────────────────────────
  List<Issue> _issues      = [];
  bool _loading            = true;
  bool _styleLoaded        = false;
  bool _matchingIdea       = false;
  bool _sidebarOpen        = false;
  String? _errorMessage;

  MapLibreMapController? _mapController;
  final Map<String, Offset> _issueScreenPositions = {};
  double _bearing = 0.0;

  bool _isDarkMode = true;
  bool get _isDark => _isDarkMode;
  ThemeMode? _lastThemeMode;

  // ── User location state ────────────────────────────────────────────────
  Position? _userPosition;
  Offset? _userScreenPosition;
  bool _locatingUser = false;

  // ── Animations (lightweight) ───────────────────────────────────────────
  late final AnimationController _sidebarAnim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
  );
  late final Animation<double> _sidebarSlide = CurvedAnimation(
    parent: _sidebarAnim,
    curve: Curves.easeOutExpo,
  );

  // User-location pulse — single repeating animation
  late final AnimationController _userLocPulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat();

  // ── Lifecycle ──────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    if (widget.initialIdeaText != null) {
      _ideaController.text = widget.initialIdeaText!;
    }
    _loadIssues();
    _resolveUserLocation();
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
      _styleLoaded = false;
      _lastThemeMode = currentMode;
    }
  }

  @override
  void dispose() {
    _mapController?.removeListener(_onCameraMove);
    _ideaController.dispose();
    _sidebarAnim.dispose();
    _userLocPulse.dispose();
    super.dispose();
  }

  // ── Data ───────────────────────────────────────────────────────────────

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
        await _updateScreenPositions();
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

  // ── User GPS location ──────────────────────────────────────────────────

  /// Resolve and fly to the user's current GPS location.
  Future<void> _resolveUserLocation() async {
    if (_locatingUser) return;
    setState(() => _locatingUser = true);
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location services are disabled.')),
          );
        }
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permission denied.')),
          );
        }
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      );
      if (!mounted) return;
      setState(() => _userPosition = position);

      // Fly to user location on map
      final controller = _mapController;
      if (_styleLoaded && controller != null) {
        await controller.animateCamera(
          CameraUpdate.newLatLngZoom(
            LatLng(position.latitude, position.longitude),
            14.0,
          ),
        );
        await _updateUserScreenPosition();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Location error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _locatingUser = false);
    }
  }

  /// Projects the user's lat/lng to screen coordinates.
  Future<void> _updateUserScreenPosition() async {
    final controller = _mapController;
    final pos = _userPosition;
    if (!_styleLoaded || controller == null || pos == null) {
      if (_userScreenPosition != null && mounted) {
        setState(() => _userScreenPosition = null);
      }
      return;
    }

    try {
      final sp = await controller.toScreenLocation(
          LatLng(pos.latitude, pos.longitude));
      if (mounted) {
        setState(() =>
            _userScreenPosition = Offset(sp.x.toDouble(), sp.y.toDouble()));
      }
    } catch (_) {}
  }

  // ── Map callbacks ─────────────────────────────────────────────────────

  void _onMapCreated(MapLibreMapController controller) {
    _mapController = controller;
    controller.addListener(_onCameraMove);
  }

  Future<void> _onStyleLoaded() async {
    _styleLoaded = true;
    final controller = _mapController;
    if (controller != null) {
      // Restyle labels to cyber-gold
      const labelSizes = {
        'label_country_1':    26.0,
        'label_country_2':    24.0,
        'label_country_3':    22.0,
        'label_state':        18.0,
        'label_city_capital': 16.0,
        'label_city':         15.0,
        'label_town':         13.0,
        'label_village':      11.0,
        'label_other':        10.0,
      };

      for (final entry in labelSizes.entries) {
        try {
          await controller.setLayerProperties(
            entry.key,
            SymbolLayerProperties(
              textColor:     '#FFD60A',
              textSize:      entry.value,
              textHaloColor: '#080C14',
              textHaloWidth: 2.5,
              textHaloBlur:  0,
            ),
          );
        } catch (_) {}
      }

      // Hide POI clutter
      const hideLayers = [
        'poi_r20', 'poi_r7', 'poi_r1', 'poi_transit', 'airport',
      ];
      for (final layer in hideLayers) {
        try { await controller.setLayerVisibility(layer, false); } catch (_) {}
      }
    }

    await _renderIssuePins();
    await _updateScreenPositions();
    await _updateUserScreenPosition();
  }

  void _onCameraMove() {
    unawaited(_updateScreenPositions());
    unawaited(_updateUserScreenPosition());
    final bearing = _mapController?.cameraPosition?.bearing ?? 0.0;
    if (mounted) {
      setState(() => _bearing = bearing);
    }
  }

  Future<void> _renderIssuePins() async {
    final controller = _mapController;
    if (!_styleLoaded || controller == null) return;
    await controller.clearCircles();
  }

  Future<void> _updateScreenPositions() async {
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

  // ── Build ─────────────────────────────────────────────────────────────

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
          // ── Base map ─────────────────────────────────────────────────
          Positioned.fill(
            child: MapLibreMap(
              styleString: _mapStyleUrl,
              initialCameraPosition: const CameraPosition(
                target: _defaultCenter,
                zoom:   _defaultZoom,
              ),
              onMapCreated:          _onMapCreated,
              onStyleLoadedCallback: _onStyleLoaded,
              onMapClick:            _onMapTap,
              compassEnabled:        false,
              myLocationEnabled:     false,
              attributionButtonMargins: const Point(-100, -100),
              logoViewMargins:          const Point(-100, -100),
            ),
          ),

          // ── "You're Here" user location blip ─────────────────────────
          if (_userScreenPosition != null)
            Positioned(
              left: _userScreenPosition!.dx - 20,
              top:  _userScreenPosition!.dy - 20,
              child: _UserLocationBlip(animation: _userLocPulse),
            ),

          // ── Issue pin overlays ────────────────────────────────────────
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

          // ── Top terminal bar ──────────────────────────────────────────
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
                  onLocate:         _locatingUser ? null : _resolveUserLocation,
                  onRefresh: () => setState(() {
                    _loading      = true;
                    _errorMessage = null;
                    _loadIssues();
                  }),
                  onBack: Navigator.of(context).canPop()
                      ? () => Navigator.of(context).pop()
                      : null,
                ),
              ),
            ),
          ),

          // ── Left sidebar ──────────────────────────────────────────────
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

          // ── Compass ───────────────────────────────────────────────────
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

          // ── Loading overlay ───────────────────────────────────────────
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
                      child: const CircularProgressIndicator(
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

          // ── Idea dock ─────────────────────────────────────────────────
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

/// "You're Here" pulsing blue blip for user GPS location on mobile.
class _UserLocationBlip extends StatelessWidget {
  const _UserLocationBlip({required this.animation});
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (_, __) {
        final t = animation.value;
        return SizedBox(
          width:  40,
          height: 40,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer pulse ring
              Container(
                width:  40 * t,
                height: 40 * t,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _userLocBlue.withValues(alpha: 0.5 * (1 - t)),
                    width: 1.5,
                  ),
                ),
              ),
              // Middle glow ring
              Container(
                width:  22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _userLocBlue.withValues(alpha: 0.15),
                ),
              ),
              // Core dot
              Container(
                width:  12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _userLocBlue,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color:       _userLocBlue.withValues(alpha: 0.6),
                      blurRadius:  10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
              // "YOU'RE HERE" label
              Positioned(
                bottom: -2,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: _darkPanel.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: _userLocBlue.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Text(
                    "YOU'RE HERE",
                    style: GoogleFonts.robotoMono(
                      color: _userLocBlue,
                      fontSize: 5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
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
    this.onBack,
  });

  final int      issueCount;
  final bool     isDark;
  final bool     sidebarOpen;
  final VoidCallback  onToggleSidebar;
  final VoidCallback? onLocate;
  final VoidCallback  onRefresh;
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
                (widget.index + 1).toString().padLeft(2, '0'),
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
                  ? const SizedBox(
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
