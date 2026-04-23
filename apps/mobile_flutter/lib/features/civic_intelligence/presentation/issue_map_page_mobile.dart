import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../../../core/models/issue.dart';
import '../application/usecases/get_validated_issues_use_case.dart';

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

// ─── Map overlay tokens (dark, readable over light map) ──────────────────────
const _barBg       = Color(0xFF1A1A2E);   // deep navy glass
const _barBorder   = Color(0xFFFFC700);   // logo yellow outline
const _barIcon     = Color(0xFFFFC700);   // logo yellow icons
const _barIconMuted = Color(0xFFFFE066);  // lighter yellow muted
const _barTitle    = Color(0xFFFFC700);   // logo yellow
const _barSubtitle = Color(0xFFFFE066);  // lighter yellow

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
  static const _defaultCenter = LatLng(13.7565, 121.0583); // Batangas City
  static const _defaultZoom   = 13.5;

  // ── Dependencies ───────────────────────────────────────────────────────
  final _issueRepository = ApiIssueRepository();
  final _ideaController  = TextEditingController();

  late final GetValidatedIssuesUseCase _getValidatedIssues =
      GetValidatedIssuesUseCase(_issueRepository);

  // ── State ──────────────────────────────────────────────────────────────
  List<Issue> _issues      = [];
  bool _loading            = true;
  bool _styleLoaded        = false;
  bool _matchingIdea       = false;
  bool _sidebarOpen        = false;

  MapLibreMapController? _mapController;
  final Map<String, Offset> _issueScreenPositions = {};
  double _zoom = _defaultZoom;

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

  // Shared pin animation controller to save resources
  late final AnimationController _pinPulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  )..repeat();

  Timer? _projectionTimer;

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
    _projectionTimer?.cancel();
    _ideaController.dispose();
    _sidebarAnim.dispose();
    _userLocPulse.dispose();
    _pinPulse.dispose();
    super.dispose();
  }

  // ── Data ───────────────────────────────────────────────────────────────

  Future<void> _loadIssues() async {
    try {
      final issues = await _getValidatedIssues();
      if (mounted) {
        setState(() {
          _issues       = issues;
          _loading      = false;
        });
        // Only project if style is already loaded; otherwise _onStyleLoaded will do it
        if (_styleLoaded) {
          await _tryProjectPins();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading      = false;
        });
      }
    }
  }

  /// Projects pins only when both issues are loaded AND the map style is ready.
  Future<void> _tryProjectPins() async {
    if (!_styleLoaded || _mapController == null || _issues.isEmpty) return;
    // Small delay to let the map finish tile rendering
    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) await _updateScreenPositions();
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

      const hideLayers = [
        'poi_r20', 'poi_r7', 'poi_r1', 'poi_transit', 'airport',
      ];
      for (final layer in hideLayers) {
        try { await controller.setLayerVisibility(layer, false); } catch (_) {}
      }

      // Add Batangas City Boundary Highlight (Simplified Polygon)
      try {
        await controller.addFill(
          FillOptions(
            geometry: [
              [
                LatLng(13.7300, 121.0300), LatLng(13.7300, 121.0800),
                LatLng(13.7800, 121.1000), LatLng(13.8200, 121.0500),
                LatLng(13.8000, 121.0000), LatLng(13.7300, 121.0300),
              ],
            ],
            fillColor: '#FFC700',
            fillOpacity: 0.08,
            fillOutlineColor: '#FFC700',
          ),
        );
      } catch (_) {}
    }

    await _renderIssuePins();
    // Gate: project only if issues are already loaded
    unawaited(_tryProjectPins());
    unawaited(_updateUserScreenPosition());
  }

  void _onCameraMove() {
    _projectionTimer?.cancel();
    _projectionTimer = Timer(const Duration(milliseconds: 16), () {
      if (mounted) {
        _updateScreenPositions();
        _updateUserScreenPosition();
      }
    });

    final pos = _mapController?.cameraPosition;
    if (mounted) {
      setState(() {
        _zoom    = pos?.zoom    ?? _zoom;
      });
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

    try {
      final futures = _issues.map((issue) => 
        controller.toScreenLocation(LatLng(issue.lat, issue.lng))
          .then((point) => MapEntry(issue.issueId, Offset(point.x.toDouble(), point.y.toDouble())))
      );
      
      final results = await Future.wait(futures);
      final positions = <String, Offset>{};
      for (final res in results) {
        if (res.value.dx > 1 || res.value.dy > 1) {
          positions[res.key] = res.value;
        }
      }

      if (mounted) {
        setState(() {
          _issueScreenPositions
            ..clear()
            ..addAll(positions);
        });
      }
    } catch (e) {
      if (kDebugMode) print('Error in _updateScreenPositions: $e');
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
              onCameraMove:          (pos) => _onCameraMove(),
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
              Builder(builder: (context) {
                final scale = ((_zoom - 13.0) * 0.18 + 1.0).clamp(0.5, 2.5);
                final half  = 18.0 * scale;
                return Positioned(
                  left: _issueScreenPositions[issue.issueId]!.dx - half,
                  top:  _issueScreenPositions[issue.issueId]!.dy - half,
                  child: GestureDetector(
                    onTap: () => _onPinTapped(issue),
                    child: _RadarBlip(zoom: _zoom, sdg: issue.aiSdgTag, animation: _pinPulse),
                  ),
                );
              }),

          // ── Regional Intelligence Panel ───────────────────────────────
          if (!_loading && _issues.isNotEmpty && _zoom > 12)
            Positioned(
              left: 12,
              right: 12,
              bottom: widget.showIdeaDock ? 150 : 30,
              child: _RegionalIntelligencePanel(issues: _issues),
            ),

          // ── Center on Batangas Button (Diagnostic) ──────────────────
          Positioned(
            right: 12,
            bottom: widget.showIdeaDock ? 240 : 120,
            child: FloatingActionButton.small(
              backgroundColor: _darkPanel,
              onPressed: () {
                _mapController?.animateCamera(
                  CameraUpdate.newLatLngZoom(_defaultCenter, _defaultZoom),
                );
              },
              child: const Icon(Icons.home_work, color: _cyberGreen, size: 18),
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
              bottom: 0, // Flush with navbar
              child: _IdeaDock(
                controller:  _ideaController,
                isMatching:  _matchingIdea,
                onSubmit:    _submitIdea,
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
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color:        _barBg.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _barBorder,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 12,
                offset: const Offset(0, 2),
              ),
            ],
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
                        color:         _barTitle,
                        fontSize:      10,
                        fontWeight:    FontWeight.w700,
                        letterSpacing: 1.8,
                      ),
                    ),
                    Text(
                      '${issueCount.toString().padLeft(4, '0')} ISSUES LOADED',
                      style: GoogleFonts.robotoMono(
                        color:         _barSubtitle,
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
        color: onPressed == null ? _barIconMuted : _barIcon,
        size: 18,
      ),
    );
  }
}

/// Radar blip for issue pins — scales with map zoom for consistent visual size.
class _RadarBlip extends StatelessWidget {
  const _RadarBlip({required this.zoom, this.sdg, required this.animation});
  final double zoom;
  final String? sdg;
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    final scale = ((zoom - 13.0) * 0.18 + 1.0).clamp(0.6, 2.8);
    final outerSize = 36.0 * scale;
    final coreSize  = 12.0 * scale;

    final coreColor = const Color(0xFFFFC700);

    return AnimatedBuilder(
      animation: animation,
      builder: (_, __) {
        final t = animation.value;
        return SizedBox(
          width:  outerSize,
          height: outerSize,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width:  outerSize * t,
                height: outerSize * t,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: coreColor.withValues(alpha: 0.4 * (1 - t)),
                    width: 1.5,
                  ),
                ),
              ),
              Container(
                width: coreSize * 1.8,
                height: coreSize * 1.8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: coreColor.withValues(alpha: 0.15),
                ),
              ),
              Container(
                width:  coreSize,
                height: coreSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: coreColor,
                  border: Border.all(color: Colors.white, width: 1.5 * scale),
                  boxShadow: [
                    BoxShadow(
                      color: coreColor.withValues(alpha: 0.8),
                      blurRadius: 10 * scale,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    sdg?.replaceAll('SDG ', '') ?? '!',
                    style: GoogleFonts.robotoMono(
                      color: Colors.black,
                      fontSize: 6 * scale,
                      fontWeight: FontWeight.w900,
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

/// Floating Regional Intelligence Dashboard.
class _RegionalIntelligencePanel extends StatelessWidget {
  const _RegionalIntelligencePanel({required this.issues});
  final List<Issue> issues;

  @override
  Widget build(BuildContext context) {
    // ── Calculate Stats ──────────────────────────────────────────────────
    final Map<String, int> sdgCounts = {};
    final Map<String, int> brgyCounts = {};
    
    for (var issue in issues) {
      final tag = issue.aiSdgTag ?? 'UNKNOWN';
      sdgCounts[tag] = (sdgCounts[tag] ?? 0) + 1;
      
      final brgy = issue.locationName ?? 'Other';
      brgyCounts[brgy] = (brgyCounts[brgy] ?? 0) + 1;
    }

    final topSdgs = sdgCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    final topBrgys = brgyCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final total = issues.length;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _barBg.withValues(alpha: 0.75),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _barBorder.withValues(alpha: 0.5), width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'BATANGAS CITY INTELLIGENCE',
                        style: GoogleFonts.robotoMono(
                          color: _barTitle,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                      ),
                      Text(
                        'LIVE SDG IMPACT MAPPING',
                        style: GoogleFonts.robotoMono(
                          color: _barSubtitle,
                          fontSize: 8,
                          letterSpacing: 2.0,
                        ),
                      ),
                    ],
                  ),
                  const Icon(Icons.hub_rounded, color: _barIcon, size: 20),
                ],
              ),
              const Divider(color: Colors.white10, height: 20),
              
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // SDG Percentages
                  Expanded(
                    flex: 6,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'TOP IMPACT AREAS',
                          style: GoogleFonts.robotoMono(color: Colors.white54, fontSize: 8, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        ...topSdgs.take(2).map((e) {
                          final percent = (e.value / total);
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      e.key,
                                      style: GoogleFonts.robotoMono(color: _barTitle, fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      '${(percent * 100).toInt()}%',
                                      style: GoogleFonts.robotoMono(color: _barTitle, fontSize: 10),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                LinearProgressIndicator(
                                  value: percent,
                                  backgroundColor: Colors.white10,
                                  color: _barBorder,
                                  minHeight: 3,
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  // Barangay Leaderboard
                  Expanded(
                    flex: 4,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'TOP BARANGAYS',
                          style: GoogleFonts.robotoMono(color: Colors.white54, fontSize: 8, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        ...topBrgys.take(3).map((e) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  e.key.toUpperCase(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.robotoMono(color: Colors.white, fontSize: 9),
                                ),
                              ),
                              Text(
                                e.value.toString(),
                                style: GoogleFonts.robotoMono(color: _barBorder, fontSize: 9, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        )),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
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
            color:        _darkPanel.withValues(alpha: 0.55),
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
                    color:    const Color(0xFFFFC700),
                    fontSize: 13,
                  ),
                  decoration: InputDecoration(
                    hintText: 'ENTER RESEARCH IDEA...',
                    hintStyle: GoogleFonts.robotoMono(
                      color:         const Color(0xFFFFE066),
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
